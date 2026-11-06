import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/app/data_providers.dart';
import 'package:lumen/core/network/network_client.dart';
import 'package:lumen/data/db/app_database.dart';
import 'package:lumen/data/db/tables.dart';
import 'package:lumen/data/secure/credential_store.dart';
import 'package:lumen/data/xtream/connection_doctor.dart';
import 'package:lumen/data/xtream/server_endpoint.dart';
import 'package:lumen/domain/browse_catalog.dart';
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
  group('refresh policy', () {
    final now = DateTime(2026, 1, 1, 12);
    test('never synced is always due', () {
      for (final p in RefreshPolicy.values) {
        expect(isRefreshDue(null, p, now), isTrue);
      }
    });
    test('on launch: older than 6 hours', () {
      expect(
        isRefreshDue(
          now.subtract(const Duration(hours: 5)),
          RefreshPolicy.onLaunch,
          now,
        ),
        isFalse,
      );
      expect(
        isRefreshDue(
          now.subtract(const Duration(hours: 7)),
          RefreshPolicy.onLaunch,
          now,
        ),
        isTrue,
      );
    });
    test('daily: older than 24 hours', () {
      expect(
        isRefreshDue(
          now.subtract(const Duration(hours: 20)),
          RefreshPolicy.daily,
          now,
        ),
        isFalse,
      );
      expect(
        isRefreshDue(
          now.subtract(const Duration(hours: 25)),
          RefreshPolicy.daily,
          now,
        ),
        isTrue,
      );
    });
    test('manual: never automatically', () {
      expect(
        isRefreshDue(
          now.subtract(const Duration(days: 30)),
          RefreshPolicy.manual,
          now,
        ),
        isFalse,
      );
    });
  });

  group('app state with a real database', () {
    late Directory dir;
    late AppDatabase db;
    late TestDb testDb;
    late MockXtreamServer server;
    late MockProvider mock;
    late ProviderContainer c;
    late StreamController<bool> online;
    final net = DioNetworkClient();

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('lumen_state');
      testDb = await TestDb.open(File('${dir.path}/t.db'));
      db = testDb.db;
      mock = MockProvider()..liveStreamCount = 6;
      server = await MockXtreamServer.start(mock);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      online = StreamController<bool>.broadcast();
      c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          credentialStoreProvider.overrideWithValue(
            SecureCredentialStore(_Mem()),
          ),
          connectivityOnlineProvider.overrideWith((ref) => online.stream),
        ],
      );
    });

    tearDown(() async {
      c.dispose();
      // Let a snapshot re-query started by the last write finish before the
      // database closes underneath it.
      await Future<void>.delayed(const Duration(milliseconds: 800));
      await online.close();
      await testDb.close();
      await server.close();
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    });
    tearDownAll(net.close);

    Future<String> add() async {
      final r = await ConnectionDoctor(network: net).probe(
        input: ServerEndpoint.parse('${server.base}'),
        username: 'user',
        password: 'pass',
      );
      return c
          .read(providerRegistryProvider)
          .addXtream(probe: r as ProbeSuccess);
    }

    Future<T> until<T>(ProviderListenable<T> p, bool Function(T) ok) async {
      final done = Completer<T>();
      final sub = c.listen<T>(p, (_, v) {
        if (ok(v) && !done.isCompleted) done.complete(v);
      }, fireImmediately: true);
      try {
        return await done.future.timeout(const Duration(seconds: 20));
      } finally {
        sub.close();
      }
    }

    test('first provider becomes active; snapshot fills after sync and '
        'updates when user data changes', () async {
      final keepAlive = c.listen(browseCatalogProvider, (_, _) {});
      final id = await add();
      await until(activeProviderIdProvider, (v) => v == id);

      final r = await c
          .read(syncControllerProvider.notifier)
          .refresh(id, includeGuide: false);
      expect(r!.ok, isTrue);
      final snap = await until<BrowseCatalog>(
        browseCatalogProvider,
        (b) => b.live.isNotEmpty,
      );
      expect(snap.live.expand((r) => r.items), hasLength(6));

      await c
          .read(catalogRepositoryProvider)
          .toggleFavourite(1, id, ContentKind.live, '2');
      final withFav = await until<BrowseCatalog>(
        browseCatalogProvider,
        (b) => b.home.any(
          (r) => r.title == 'Favourite channels' && r.items.isNotEmpty,
        ),
      );
      expect(
        withFav.home
            .firstWhere((r) => r.title == 'Favourite channels')
            .items
            .single
            .title,
        'Channel 2',
      );
      keepAlive.close();
    });

    test(
      'offline banner shows with cached data and retries on reconnect',
      () async {
        final keepBanner = c.listen(offlineBannerProvider, (_, _) {});
        final id = await add();
        await until(activeProviderIdProvider, (v) => v == id);
        await c
            .read(syncControllerProvider.notifier)
            .refresh(id, includeGuide: false);
        await until<BrowseCatalog>(
          browseCatalogProvider,
          (b) => b.live.isNotEmpty,
        );

        online.add(true);
        expect(await until(offlineBannerProvider, (v) => v == false), isFalse);

        // Connectivity drops: banner, cached catalogue still browsable.
        online.add(false);
        expect(await until(offlineBannerProvider, (v) => v), isTrue);
        expect(c.read(browseCatalogProvider).live, isNotEmpty);

        // The server is unreachable for a refresh: still the banner.
        final port = server.port;
        await server.close();
        online.add(true);
        final failed = await c
            .read(syncControllerProvider.notifier)
            .refresh(id, includeGuide: false);
        expect(failed!.ok, isFalse);
        expect(c.read(syncControllerProvider).lastFailedUnreachable, isTrue);
        expect(c.read(offlineBannerProvider), isTrue);

        // Network returns: the controller retries automatically.
        server = await MockXtreamServer.start(mock, port: port);
        online.add(false);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        online.add(true);
        await until<SyncState>(
          syncControllerProvider,
          (s) => !s.running && (s.lastResult?.ok ?? false),
        );
        expect(await until(offlineBannerProvider, (v) => !v), isFalse);
        keepBanner.close();
      },
    );

    test('kids profile filters the snapshot', () async {
      mock.categoryNames = ['News', 'Kids Club', 'Movies'];
      final keepAlive = c.listen(browseCatalogProvider, (_, _) {});
      final id = await add();
      await until(activeProviderIdProvider, (v) => v == id);
      await c
          .read(syncControllerProvider.notifier)
          .refresh(id, includeGuide: false);
      await until<BrowseCatalog>(
        browseCatalogProvider,
        (b) => b.live.isNotEmpty,
      );

      final kidId = await db
          .into(db.profiles)
          .insert(
            ProfilesCompanion.insert(
              name: 'Kid',
              isKids: const Value(true),
              createdAt: DateTime.now(),
            ),
          );
      await c.read(activeProfileIdProvider.notifier).select(kidId);
      final kids = await until<BrowseCatalog>(
        browseCatalogProvider,
        (b) => b.live.isNotEmpty && b.live.every((r) => r.title == 'Kids Club'),
      );
      expect(kids.liveCategories, ['Kids Club']);
      keepAlive.close();
    });
  });
}
