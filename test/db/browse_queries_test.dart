import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/app/data_providers.dart';
import 'package:lumen/core/network/connection_error.dart';
import 'package:lumen/data/db/app_database.dart';
import 'package:lumen/data/secure/credential_store.dart';
import 'package:lumen/domain/browse_queries.dart';
import 'package:lumen/domain/media_summary.dart';
import 'package:lumen/features/providers/sign_in_service.dart';
import 'package:lumen/features/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../tool/mock_server/mock_xtream_server.dart';
import '../helpers/test_db.dart';

class _Mem implements SecretBackend {
  final m = <String, String>{};
  @override
  Future<void> delete(String key) async => m.remove(key);
  @override
  Future<String?> read(String key) async => m[key];
  @override
  Future<void> write(String key, String value) async => m[key] = value;
}

void main() {
  late Directory dir;
  late TestDb testDb;
  late AppDatabase db;
  late MockXtreamServer server;
  late MockProvider mock;
  late ProviderContainer c;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('lumen_q');
    testDb = await TestDb.open(File('${dir.path}/t.db'));
    db = testDb.db;
    mock = MockProvider()..liveStreamCount = 8;
    server = await MockXtreamServer.start(mock);
    SharedPreferences.setMockInitialValues({});
    c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        appDatabaseProvider.overrideWithValue(db),
        credentialStoreProvider.overrideWithValue(
          SecureCredentialStore(_Mem()),
        ),
        connectivityOnlineProvider.overrideWith((ref) => Stream.value(true)),
      ],
    );
  });

  tearDown(() async {
    c.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await testDb.close();
    await server.close();
    try {
      await dir.delete(recursive: true);
    } catch (_) {}
  });

  Future<T> until<T>(T Function() read, bool Function(T) ok) async {
    for (var i = 0; i < 200; i++) {
      final v = read();
      if (ok(v)) return v;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    throw TimeoutException('condition not met');
  }

  test('real sign-in: probe, save, activate and first sync', () async {
    final sub = c.listen(syncControllerProvider, (_, _) {});
    final r = await c
        .read(signInServiceProvider)
        .xtream(
          name: 'Mock',
          server: ' ${server.base}/player_api.php ',
          username: 'user​',
          password: 'pass',
        );
    expect(r, isA<SignInOk>());
    final id = (r as SignInOk).providerId;
    expect(c.read(activeProviderIdProvider), id);
    final s = await until(
      () => c.read(syncControllerProvider),
      (s) => !s.running && s.lastResult != null,
    );
    expect(s.lastResult!.ok, isTrue, reason: '${s.lastResult!.error}');
    expect(s.lastResult!.channels, 8);
    sub.close();
  });

  test(
    'real sign-in failure returns the classified error and saves nothing',
    () async {
      final r = await c
          .read(signInServiceProvider)
          .xtream(
            server: '${server.base}',
            username: 'user',
            password: 'wrong',
          );
      expect((r as SignInFailed).error.kind, ConnectionErrorKind.authRejected);
      expect(await c.read(providerRegistryProvider).all(), isEmpty);
      final bad = await c
          .read(signInServiceProvider)
          .xtream(server: 'rtmp://x', username: 'u', password: 'p');
      expect(
        (bad as SignInFailed).error.kind,
        ConnectionErrorKind.invalidInput,
      );
    },
  );

  test(
    'database queries: categories, pages, series episodes cached, movie info',
    () async {
      final sub = c.listen(syncControllerProvider, (_, _) {});
      final r = await c
          .read(signInServiceProvider)
          .xtream(server: '${server.base}', username: 'user', password: 'pass');
      final id = (r as SignInOk).providerId;
      await until(
        () => c.read(syncControllerProvider),
        (s) => !s.running && s.lastResult != null,
      );
      final q = c.read(browseQueriesProvider);

      final cats = await q.categories(MediaKind.channel);
      expect(cats.map((e) => e.name), [
        'Category 1',
        'Category 2',
        'Category 3',
      ]);
      final p1 = await q.page(MediaKind.channel, limit: 5);
      final p2 = await q.page(MediaKind.channel, offset: 5, limit: 5);
      expect(p1, hasLength(5));
      expect(p2, hasLength(3));
      expect({...p1.map((e) => e.id), ...p2.map((e) => e.id)}, hasLength(8));

      // Series: first open fetches get_series_info and caches episodes.
      final d1 = await q.detail('series:501');
      expect(d1!.seasons.keys, [1, 2]);
      expect(d1.seasons[1]!.first.title, 'Pilot');
      final infoCalls = mock.withAction('get_series_info').length;
      final d2 = await q.detail('series:501');
      expect(d2!.seasons.keys, [1, 2]);
      expect(
        mock.withAction('get_series_info').length,
        infoCalls,
        reason: 'served from cache',
      );

      // Movie detail uses the cached row (vod info may be empty).
      final m = await q.detail('movie:1001');
      expect(m!.summary.title, 'Film 1');
      expect(m.inMyList, isFalse);
      expect(await q.toggleMyList('movie:1001'), isTrue);
      expect((await q.detail('movie:1001'))!.inMyList, isTrue);

      // Favourites page.
      await q.toggleFavourite('live:3');
      expect(
        (await q.page(MediaKind.channel, favouritesOnly: true)).single.title,
        'Channel 3',
      );

      // Search through the active profile's filter.
      expect(
        (await q.search('channel 7')).map((e) => e.title),
        contains('Channel 7'),
      );
      expect(id, isNotEmpty);
      sub.close();
    },
  );

  test(
    'guide: XMLTV rows, and get_short_epg fallback only when needed',
    () async {
      mock.xmltv = false; // no bulk guide: the fallback must kick in
      final sub = c.listen(syncControllerProvider, (_, _) {});
      final r = await c
          .read(signInServiceProvider)
          .xtream(server: '${server.base}', username: 'user', password: 'pass');
      expect(r, isA<SignInOk>());
      await until(
        () => c.read(syncControllerProvider),
        (s) => !s.running && s.lastResult != null,
      );
      final q = c.read(browseQueriesProvider);
      final now = DateTime.now();
      final rows = await q.guide(
        from: now.subtract(const Duration(minutes: 30)),
        to: now.add(const Duration(hours: 6)),
        limit: 4,
      );
      expect(rows, hasLength(4));
      expect(rows.every((r) => r.programmes.isNotEmpty), isTrue);
      expect(rows.first.programmes.first.title, 'Morning News');
      // Only the 4 visible channels were asked for.
      expect(mock.withAction('get_short_epg'), hasLength(4));
      // Asking again doesn't re-request.
      await q.guide(
        from: now.subtract(const Duration(minutes: 30)),
        to: now.add(const Duration(hours: 6)),
        limit: 4,
      );
      expect(mock.withAction('get_short_epg'), hasLength(4));
      sub.close();
    },
  );

  test(
    'tiles carry watch progress: movie bars, ticks and series episodes',
    () async {
      final sub = c.listen(syncControllerProvider, (_, _) {});
      final r = await c
          .read(signInServiceProvider)
          .xtream(server: '${server.base}', username: 'user', password: 'pass');
      final id = (r as SignInOk).providerId;
      await until(
        () => c.read(syncControllerProvider),
        (s) => !s.running && s.lastResult != null,
      );
      final repo = c.read(catalogRepositoryProvider);
      Future<void> save(String kind, String rid, int pos, {String? series}) =>
          repo.saveProgress(
            profileId: 1,
            providerId: id,
            kind: kind,
            remoteId: rid,
            seriesId: series,
            position: Duration(minutes: pos),
            duration: const Duration(minutes: 100),
          );
      await save('movie', '1001', 50);
      await save('movie', '1002', 99);
      await save('episode', '9001', 30, series: '501');

      final q = c.read(browseQueriesProvider);
      final movies = {
        for (final m in await q.page(MediaKind.movie)) m.title: m,
      };
      expect(movies['Film 1']!.inProgress, isTrue);
      expect(movies['Film 1']!.progress, closeTo(0.5, 0.001));
      expect(movies['Film 2']!.watched, isTrue);
      expect(movies['Film 3']!.progress, isNull);
      final shows = {
        for (final s in await q.page(MediaKind.series)) s.title: s,
      };
      expect(shows['Show 1']!.progress, closeTo(0.3, 0.001));

      // Finishing the episode removes the series bar (it moves on).
      await save('episode', '9001', 100, series: '501');
      final again = {
        for (final s in await q.page(MediaKind.series)) s.title: s,
      };
      expect(again['Show 1']!.progress, isNull);

      // Search results carry it too.
      expect((await q.search('Film 1')).first.inProgress, isTrue);
      sub.close();
    },
  );

  test('parseItemId', () {
    expect(parseItemId('live:12'), (MediaKind.channel, '12'));
    expect(parseItemId('channel:12'), (MediaKind.channel, '12'));
    expect(parseItemId('movie:a:b'), (MediaKind.movie, 'a:b'));
    expect(parseItemId('nope'), isNull);
    expect(parseItemId('x:1'), isNull);
  });
}
