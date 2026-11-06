// Phase 2: sync from the mock provider into a real SQLite database
// (background isolate) and read it back through the repository.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/core/network/connection_error.dart';
import 'package:lumen/core/network/network_client.dart';
import 'package:lumen/core/network/user_agents.dart';
import 'package:lumen/data/db/app_database.dart';
import 'package:lumen/data/db/secret_template.dart';
import 'package:lumen/data/db/tables.dart';
import 'package:lumen/data/epg/xmltv.dart';
import 'package:lumen/data/repo/catalog_repository.dart';
import 'package:lumen/data/repo/provider_registry.dart';
import 'package:lumen/data/secure/credential_store.dart';
import 'package:lumen/data/sync/catalog_sync.dart';
import 'package:lumen/data/xtream/connection_doctor.dart';
import 'package:lumen/data/xtream/server_endpoint.dart';
import 'package:lumen/domain/content_filters.dart';

import '../../tool/mock_server/mock_xtream_server.dart';
import '../helpers/test_db.dart';

class MemoryBackend implements SecretBackend {
  final m = <String, String>{};
  @override
  Future<void> delete(String key) async => m.remove(key);
  @override
  Future<String?> read(String key) async => m[key];
  @override
  Future<void> write(String key, String value) async => m[key] = value;
}

late Directory dir;
late AppDatabase db;
late TestDb testDb;
late SecureCredentialStore store;
late ProviderRegistry registry;
late CatalogRepository repo;
late CatalogSync sync;
final servers = <MockXtreamServer>[];
final net = DioNetworkClient();

Future<MockXtreamServer> serve(MockProvider p) async {
  final s = await MockXtreamServer.start(p);
  servers.add(s);
  return s;
}

Future<String> addXtream(
  MockXtreamServer s, {
  UserAgentProfile ua = UserAgentProfile.okhttp,
}) async {
  final r = await ConnectionDoctor(network: net).probe(
    input: ServerEndpoint.parse('${s.base}'),
    username: 'user',
    password: 'pass',
  );
  expect(r, isA<ProbeSuccess>());
  return registry.addXtream(probe: r as ProbeSuccess, name: 'Mock');
}

void main() {
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('lumen_db');
    testDb = await TestDb.open(File('${dir.path}/t.db'));
    db = testDb.db;
    store = SecureCredentialStore(MemoryBackend());
    registry = ProviderRegistry(db, store);
    repo = CatalogRepository(db);
    sync = CatalogSync(db: db, store: store, networkFor: (_) => net);
  });

  tearDown(() async {
    await testDb.close();
    for (final s in servers) {
      await s.close();
    }
    servers.clear();
    try {
      await dir.delete(recursive: true);
    } catch (_) {}
  });

  tearDownAll(net.close);

  test(
    'Xtream sync writes catalogue, search and guide; secrets not in DB',
    () async {
      final p = MockProvider()
        ..categoryNames = ['News', 'Kids Club', 'Adult XXX'];
      final s = await serve(p);
      final id = await addXtream(s);

      final steps = <SyncStep>[];
      final r = await sync.sync(id, onProgress: (e) => steps.add(e.step));
      expect(r.ok, isTrue, reason: '${r.error} ${r.warnings}');
      expect(r.channels, 30);
      expect(r.movies, 10);
      expect(r.series, 5);
      expect(r.programmes, greaterThan(0));
      expect(
        steps.toSet(),
        containsAll([
          SyncStep.signingIn,
          SyncStep.categories,
          SyncStep.channels,
          SyncStep.movies,
          SyncStep.series,
          SyncStep.guide,
          SyncStep.done,
        ]),
      );
      // Channels come before movies and series (browse early).
      expect(
        steps.indexOf(SyncStep.channels),
        lessThan(steps.indexOf(SyncStep.movies)),
      );

      final row = (await registry.byId(id))!;
      expect(row.lastSyncAt, isNotNull);
      expect(row.lastSyncError, isNull);

      // No secret anywhere in the database file's tables.
      for (final t in [
        'providers',
        'channels',
        'movies',
        'series',
        'categories',
      ]) {
        final dump = (await db.customSelect('SELECT * FROM $t').get())
            .map((r) => r.data.values.join('|'))
            .join('\n');
        expect(dump, isNot(contains('password')), reason: t);
        expect(
          RegExp(r'\|pass(\||$)', multiLine: true).hasMatch(dump),
          isFalse,
          reason: t,
        );
      }
      expect(await store.readPassword(id), isA<SecretFound>());

      // Adult category hidden by default; visible when the filter allows.
      final visible = await repo.channelsPage(id);
      final all = await repo.channelsPage(
        id,
        filter: const ContentFilter(hideAdult: false),
      );
      expect(all, hasLength(30));
      expect(visible.length, lessThan(30));
      expect(visible.every((c) => !c.isAdult), isTrue);

      // Kids profile: only the kids category.
      final kids = await repo.channelsPage(id, filter: ContentFilter.kids);
      expect(kids, isNotEmpty);
      expect(kids.every((c) => c.categoryId == '2'), isTrue);

      // Search (FTS5, prefix, diacritics-insensitive).
      final hits = await repo.search(id, 'chann 1');
      expect(hits.map((h) => h.title), contains('Channel 1'));
      // Films in the adult category are hidden from search by default.
      expect(await repo.search(id, 'film'), hasLength(7));
      expect(
        await repo.search(
          id,
          'film',
          filter: const ContentFilter(hideAdult: false),
        ),
        hasLength(10),
      );
      expect(await repo.search(id, '   '), isEmpty);
      expect(await repo.search(id, '"; DROP TABLE x; --'), isEmpty);

      // Browse snapshot uses the guide for now/next.
      final b = await repo.browse(providerId: id, profileId: 1);
      final liveNow = b.home.firstWhere((r) => r.title == 'Live now');
      expect(liveNow.items, isNotEmpty);
      expect(liveNow.items.first.nowTitle, isNotNull);
      expect(liveNow.items.first.nextTitle, startsWith('Next at '));
      expect(b.movies, isNotEmpty);
      expect(b.liveCategories, isNot(contains('Adult XXX')));
    },
  );

  test(
    'guide keeps only the lineup and a -2 h..+48 h window; gzip works',
    () async {
      final s = await serve(
        MockProvider()
          ..xmltvGzip = true
          ..liveStreamCount = 3,
      );
      final id = await addXtream(s);
      final r = await sync.sync(id);
      expect(r.ok, isTrue);
      final rows = await db.select(db.epgPrograms).get();
      final now = DateTime.now();
      expect(rows.map((e) => e.channelEpgId).toSet(), {'ch1', 'ch2', 'ch3'});
      for (final e in rows) {
        expect(
          e.stop.isAfter(now.subtract(const Duration(hours: 2, minutes: 1))),
          isTrue,
        );
        expect(
          e.start.isBefore(now.add(const Duration(hours: 48, minutes: 1))),
          isTrue,
        );
      }
      // ~51 hourly slots per channel, not the full 77.
      expect(rows.length, inInclusiveRange(3 * 49, 3 * 53));
      expect(rows.first.title, contains('& friends'));
      expect(rows.first.description, contains('<b>'));
    },
  );

  test('refresh keeps favourites and progress; removes stale rows', () async {
    final p = MockProvider();
    final s = await serve(p);
    final id = await addXtream(s);
    expect((await sync.sync(id, includeGuide: false)).ok, isTrue);

    await repo.toggleFavourite(1, id, ContentKind.live, '30');
    await repo.toggleFavourite(1, id, ContentKind.live, '5');
    await repo.toggleMyList(1, id, ContentKind.movie, '1001');
    await repo.saveProgress(
      profileId: 1,
      providerId: id,
      kind: ContentKind.movie,
      remoteId: '1002',
      position: const Duration(minutes: 30),
      duration: const Duration(minutes: 100),
    );

    p.dropLastStreams = 5; // channels 26..30 disappear
    expect((await sync.sync(id, includeGuide: false)).ok, isTrue);

    expect(await repo.count(id, ContentKind.live), 25);
    expect(await repo.search(id, 'Channel 30'), isEmpty);
    // User data survives the refresh.
    expect(await repo.isFavourite(1, id, ContentKind.live, '30'), isTrue);
    expect(await repo.isFavourite(1, id, ContentKind.live, '5'), isTrue);
    final b = await repo.browse(providerId: id, profileId: 1);
    expect(
      b.home
          .firstWhere((r) => r.title == 'Favourite channels')
          .items
          .map((e) => e.title),
      ['Channel 5'],
    );
    expect(
      b.home.firstWhere((r) => r.title == 'My list').items.single.title,
      'Film 1',
    );
    final cw = b.home
        .firstWhere((r) => r.title == 'Continue watching')
        .items
        .single;
    expect(cw.title, 'Film 2');
    expect(cw.progress, closeTo(0.3, 0.001));

    // Toggle off.
    expect(await repo.toggleFavourite(1, id, ContentKind.live, '5'), isFalse);
  });

  test('a failed refresh leaves the cached catalogue intact', () async {
    final s = await serve(MockProvider());
    final id = await addXtream(s);
    expect((await sync.sync(id, includeGuide: false)).ok, isTrue);
    await s.close();
    servers.remove(s);

    final r = await sync.sync(id, includeGuide: false);
    expect(r.ok, isFalse);
    expect(r.error!.kind, ConnectionErrorKind.timeoutOrRefused);
    expect(await repo.count(id, ContentKind.live), 30);
    expect((await registry.byId(id))!.lastSyncError, 'timeoutOrRefused');
  });

  test(
    'saved profile stops working: re-probes and saves the new one',
    () async {
      final p = MockProvider();
      final s = await serve(p);
      final id = await addXtream(s);
      expect((await registry.byId(id))!.userAgentId, 'okhttp');

      p.requireUserAgent = RegExp(r'^Lavf/');
      final r = await sync.sync(id, includeGuide: false);
      expect(r.ok, isTrue, reason: '${r.error}');
      expect((await registry.byId(id))!.userAgentId, 'lavf');
    },
  );

  test('missing password asks for it again, keeps the provider', () async {
    final s = await serve(MockProvider());
    final id = await addXtream(s);
    await store.deleteAll(id);
    final r = await sync.sync(id);
    expect(r.needsPassword, isTrue);
    expect(await registry.byId(id), isNotNull);
    await registry.updatePassword(id, 'pass');
    expect((await sync.sync(id, includeGuide: false)).ok, isTrue);
  });

  test('expired account on refresh is reported, cache kept', () async {
    final p = MockProvider();
    final s = await serve(p);
    final id = await addXtream(s);
    expect((await sync.sync(id, includeGuide: false)).ok, isTrue);
    p.userInfo = {
      'exp_date': DateTime.now().millisecondsSinceEpoch ~/ 1000 - 10,
    };
    final r = await sync.sync(id, includeGuide: false);
    expect(r.error?.kind, ConnectionErrorKind.expired);
    expect(await repo.count(id, ContentKind.live), 30);
  });

  test(
    'M3U link: credentials kept out of stored URLs, guide from header',
    () async {
      final s0 = await serve(MockProvider()..liveStreamCount = 3);
      final playlist = StringBuffer(
        '#EXTM3U url-tvg="${s0.base}/xmltv.php?username=user&password=pass"\n',
      );
      for (var i = 1; i <= 3; i++) {
        playlist
          ..writeln('#EXTINF:-1 tvg-id="ch$i" group-title="News",Channel $i')
          ..writeln('#EXTVLCOPT:http-user-agent=VLC/3')
          ..writeln('${s0.base}/live/user/s3cr%2Bt/$i.ts');
      }
      playlist
        ..writeln('#EXTINF:-1 group-title="Films",A Film')
        ..writeln('${s0.base}/movie/user/s3cr%2Bt/9.mp4')
        ..writeln('#EXTINF:-1 group-title="XXX Adult",Hidden')
        ..writeln('${s0.base}/live/user/s3cr%2Bt/99.ts');
      final host = await serve(
        MockProvider()
          ..playlist = Uint8List.fromList(utf8.encode(playlist.toString())),
      );
      final url = host.base.replace(
        path: '/playlist.m3u',
        queryParameters: {'username': 'user', 'password': 's3cr+t'},
      );
      final id = await registry.addM3uUrl(url: url, name: 'List');
      final r = await sync.sync(id);
      expect(r.ok, isTrue, reason: '${r.error}');
      expect(r.channels, 4);
      expect(r.movies, 1);
      expect(r.programmes, greaterThan(0));
      expect((await registry.byId(id))!.epgUrl, contains('xmltv.php'));

      final ch = await repo.channelsPage(id);
      expect(ch, hasLength(3)); // adult group hidden
      expect(ch.first.url, contains(SecretTemplate.pass));
      expect(ch.first.url, isNot(contains('s3cr')));
      expect(jsonDecode(ch.first.headersJson!), {'User-Agent': 'VLC/3'});
      expect(
        SecretTemplate.decode(
          ch.first.url!,
          username: 'user',
          password: 's3cr+t',
        ),
        '${s0.base}/live/user/s3cr%2Bt/1.ts',
      );
      expect(await store.readSecretUrl(id), isA<SecretFound>());
      expect((await registry.byId(id))!.displayHost, isNot(contains('s3cr')));
    },
  );

  test('M3U file import and not-a-playlist', () async {
    final id = await registry.addM3uFile(fileName: 'my.m3u');
    final ok = await sync.importM3uFile(
      id,
      Uint8List.fromList(
        utf8.encode('#EXTM3U\n#EXTINF:-1,One\nhttp://h.invalid/1\n'),
      ),
    );
    expect(ok.ok, isTrue);
    expect(ok.channels, 1);
    final bad = await sync.importM3uFile(
      id,
      Uint8List.fromList(utf8.encode('hello')),
    );
    expect(bad.error?.kind, ConnectionErrorKind.m3uInvalid);
    // The earlier import is still there.
    expect(await repo.count(id, ContentKind.live), 1);
  });

  test('removing a provider deletes its rows, user data and secrets', () async {
    final s = await serve(MockProvider());
    final id = await addXtream(s);
    await sync.sync(id);
    await repo.toggleFavourite(1, id, ContentKind.live, '1');
    await registry.remove(id);
    for (final t in [
      'channels',
      'movies',
      'series',
      'categories',
      'epg_programs',
      'favourites',
      'search_index',
    ]) {
      final n =
          (await db.customSelect('SELECT COUNT(*) AS n FROM $t').getSingle())
              .read<int>('n');
      expect(n, 0, reason: t);
    }
    expect(await store.readPassword(id), isA<SecretMissing>());
  });

  test('60 000 channels sync without loading them on the UI isolate', () async {
    final s = await serve(
      MockProvider()
        ..liveStreamCount = 60000
        ..xmltv = false,
    );
    final id = await addXtream(s);
    var maxGap = Duration.zero;
    var last = DateTime.now();
    final ticker = Stream<void>.periodic(const Duration(milliseconds: 16))
        .listen((_) {
          final now = DateTime.now();
          if (now.difference(last) > maxGap) maxGap = now.difference(last);
          last = now;
        });
    final r = await sync.sync(id, includeGuide: false);
    await ticker.cancel();
    expect(r.channels, 60000);
    expect(await repo.count(id, ContentKind.live), 60000);
    final page = await repo.channelsPage(
      id,
      limit: 50,
      offset: 59950,
      filter: const ContentFilter(hideAdult: false),
    );
    expect(page, hasLength(50));
    expect(
      maxGap,
      // Generous: the whole suite runs in parallel on one machine; a parse on
      // the UI isolate would stall for many seconds, not ~1.
      lessThan(const Duration(seconds: 3)),
      reason: 'stall $maxGap',
    );
  }, timeout: const Timeout(Duration(minutes: 3)));

  group('helpers', () {
    test('xmltv time parsing', () {
      expect(
        parseXmltvTime('20240309070000 +0100'),
        DateTime.utc(2024, 3, 9, 6),
      );
      expect(parseXmltvTime('20240309070000'), DateTime.utc(2024, 3, 9, 7));
      expect(
        parseXmltvTime('202403090700 -05:30'),
        DateTime.utc(2024, 3, 9, 12, 30),
      );
      expect(parseXmltvTime('garbage'), isNull);
    });
    test('secret template avoids partial matches', () {
      final u = SecretTemplate.encode(
        'http://tv.example/live/tv/pw12/1.ts',
        username: 'tv',
        password: 'pw12',
      );
      expect(
        u,
        'http://tv.example/live/${SecretTemplate.user}/${SecretTemplate.pass}/1.ts',
      );
    });
    test('fts query building', () {
      expect(ftsQuery('Café, noir!'), '"café"* AND "noir"*');
      expect(ftsQuery('  '), isNull);
    });
    test('adult and kids keywords', () {
      expect(isAdultCategory('XXX Adult'), isTrue);
      expect(isAdultCategory('Essex News'), isFalse);
      expect(isAdultCategory('Sussex Sport'), isFalse);
      expect(isAdultCategory('18+ Movies'), isTrue);
      expect(isKidsCategory('Kids Club'), isTrue);
      expect(isKidsCategory('Cartoons'), isTrue);
      expect(isKidsCategory('News'), isFalse);
    });
  });
}
