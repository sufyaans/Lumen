import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/connection_error.dart';
import '../core/network/network_client.dart';
import '../data/db/app_database.dart';
import '../data/repo/catalog_repository.dart';
import '../data/repo/provider_registry.dart';
import '../data/repo/repository_browse_queries.dart';
import '../data/secure/credential_store.dart';
import '../data/sync/catalog_sync.dart';
import '../dev/preview_browse_queries.dart';
import '../domain/browse_catalog.dart';
import '../domain/browse_queries.dart';
import '../domain/content_filters.dart';
import '../features/settings/app_settings.dart';

/// Overridden in main() with [AppDatabase.open].
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider not overridden'),
);

final credentialStoreProvider = Provider<CredentialStore>(
  (ref) => SecureCredentialStore(),
);

final providerRegistryProvider = Provider<ProviderRegistry>(
  (ref) => ProviderRegistry(
    ref.watch(appDatabaseProvider),
    ref.watch(credentialStoreProvider),
  ),
);

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.watch(appDatabaseProvider)),
);

/// One network client per provider, honouring its certificate setting.
final networkForProvider = Provider<NetworkClient Function(ProviderRow)>((ref) {
  final clients = <String, (bool, NetworkClient)>{};
  ref.onDispose(() {
    for (final c in clients.values) {
      c.$2.close();
    }
  });
  return (p) {
    final cached = clients[p.id];
    if (cached != null && cached.$1 == p.allowUntrustedCert) return cached.$2;
    cached?.$2.close();
    final host = p.displayHost
        .split(':')
        .first
        .replaceAll('[', '')
        .replaceAll(']', '');
    final c = DioNetworkClient(
      allowUntrustedCertFor: p.allowUntrustedCert ? (h) => h == host : null,
    );
    clients[p.id] = (p.allowUntrustedCert, c);
    return c;
  };
});

final catalogSyncProvider = Provider<CatalogSync>(
  (ref) => CatalogSync(
    db: ref.watch(appDatabaseProvider),
    store: ref.watch(credentialStoreProvider),
    networkFor: ref.watch(networkForProvider),
  ),
);

final providersListProvider = StreamProvider<List<ProviderRow>>(
  (ref) => ref.watch(providerRegistryProvider).watchAll(),
);

// ---- Active provider and profile ---------------------------------------------

class ActiveProviderNotifier extends Notifier<String?> {
  static const _k = 'active.providerId';

  @override
  String? build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(_k);
    final list = ref.watch(providersListProvider).value;
    if (list == null) return saved;
    if (list.isEmpty) return null;
    if (saved != null && list.any((p) => p.id == saved)) return saved;
    return list.first.id;
  }

  Future<void> select(String? id) async {
    state = id;
    final prefs = ref.read(sharedPreferencesProvider);
    if (id == null) {
      await prefs.remove(_k);
    } else {
      await prefs.setString(_k, id);
    }
  }
}

final activeProviderIdProvider =
    NotifierProvider<ActiveProviderNotifier, String?>(
      ActiveProviderNotifier.new,
    );

class ActiveProfileNotifier extends Notifier<int> {
  static const _k = 'active.profileId';

  @override
  int build() => ref.watch(sharedPreferencesProvider).getInt(_k) ?? 1;

  Future<void> select(int id) async {
    state = id;
    await ref.read(sharedPreferencesProvider).setInt(_k, id);
  }
}

final activeProfileIdProvider = NotifierProvider<ActiveProfileNotifier, int>(
  ActiveProfileNotifier.new,
);

final profilesProvider = StreamProvider<List<ProfileRow>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(
    db.profiles,
  )..orderBy([(t) => OrderingTerm(expression: t.id)])).watch();
});

/// What the active profile may see.
final contentFilterProvider = Provider<ContentFilter>((ref) {
  final hideAdult = ref.watch(appSettingsProvider.select((s) => s.hideAdult));
  final id = ref.watch(activeProfileIdProvider);
  final profiles = ref.watch(profilesProvider).value ?? const [];
  final kids = profiles.any((p) => p.id == id && p.isKids);
  return ContentFilter(hideAdult: hideAdult || kids, kidsOnly: kids);
});

// ---- Catalogue snapshot (stale-while-revalidate) ----------------------------

/// Re-queries the bounded browse snapshot whenever the database changes,
/// debounced so a sync writing in batches doesn't re-query every batch.
final catalogSnapshotProvider = StreamProvider<BrowseCatalog?>((ref) async* {
  final providerId = ref.watch(activeProviderIdProvider);
  if (providerId == null) {
    yield null;
    return;
  }
  final repo = ref.watch(catalogRepositoryProvider);
  final profileId = ref.watch(activeProfileIdProvider);
  final filter = ref.watch(contentFilterProvider);

  Future<BrowseCatalog> load() =>
      repo.browse(providerId: providerId, profileId: profileId, filter: filter);

  yield await load();
  await for (final _ in _debounce(
    repo.watchChanges(),
    const Duration(milliseconds: 400),
  )) {
    yield await load();
  }
});

Stream<void> _debounce(Stream<void> s, Duration d) {
  late StreamController<void> c;
  Timer? t;
  StreamSubscription<void>? sub;
  c = StreamController<void>(
    onListen: () {
      sub = s.listen((_) {
        t?.cancel();
        t = Timer(d, () => c.add(null));
      }, onDone: c.close);
    },
    onCancel: () {
      t?.cancel();
      return sub?.cancel();
    },
  );
  return c.stream;
}

/// Data source for paged grids, detail, guide and search.
final browseQueriesProvider = Provider<BrowseQueries>((ref) {
  final providerId = ref.watch(activeProviderIdProvider);
  if (providerId == null) {
    // Debug preview, or nothing at all in release builds.
    return PreviewBrowseQueries(ref.watch(browseCatalogProvider));
  }
  return RepositoryBrowseQueries(
    repo: ref.watch(catalogRepositoryProvider),
    providerId: providerId,
    profileId: ref.watch(activeProfileIdProvider),
    filter: ref.watch(contentFilterProvider),
    store: ref.watch(credentialStoreProvider),
    network: ref.watch(networkForProvider),
  );
});

/// Increments when the catalogue changes, so paged screens reload.
final catalogVersionProvider = StreamProvider<int>((ref) async* {
  final providerId = ref.watch(activeProviderIdProvider);
  var v = 0;
  yield v;
  if (providerId == null) return;
  final repo = ref.watch(catalogRepositoryProvider);
  await for (final _ in _debounce(
    repo.watchChanges(),
    const Duration(milliseconds: 600),
  )) {
    yield ++v;
  }
});

// ---- Connectivity and offline state ------------------------------------------

/// Connectivity as a hint only, never proof of reachability (brief 5.9).
final connectivityOnlineProvider = StreamProvider<bool>((ref) async* {
  final c = Connectivity();
  bool online(List<ConnectivityResult> r) =>
      r.any((e) => e != ConnectivityResult.none);
  try {
    yield online(await c.checkConnectivity());
  } catch (_) {
    yield true;
  }
  yield* c.onConnectivityChanged.map(online);
});

// ---- Sync controller ----------------------------------------------------------

class SyncState {
  const SyncState({
    this.running = false,
    this.progress,
    this.lastResult,
    this.providerId,
  });

  final bool running;
  final SyncProgress? progress;
  final SyncResult? lastResult;
  final String? providerId;

  /// The last refresh failed because the network or server was unreachable.
  bool get lastFailedUnreachable {
    final k = lastResult?.error?.kind;
    return k == ConnectionErrorKind.offline ||
        k == ConnectionErrorKind.dnsFailure ||
        k == ConnectionErrorKind.timeoutOrRefused;
  }
}

class SyncController extends Notifier<SyncState> {
  @override
  SyncState build() {
    // When connectivity comes back after an unreachable failure, retry.
    ref.listen(connectivityOnlineProvider, (prev, next) {
      final wasOffline = prev?.value == false;
      if (wasOffline && next.value == true && state.lastFailedUnreachable) {
        final id = state.providerId;
        if (id != null) unawaited(refresh(id));
      }
    });
    return const SyncState();
  }

  Future<SyncResult?> refresh(
    String providerId, {
    bool includeGuide = true,
  }) async {
    if (state.running) return null;
    state = SyncState(
      running: true,
      providerId: providerId,
      lastResult: state.lastResult,
    );
    final r = await ref
        .read(catalogSyncProvider)
        .sync(
          providerId,
          includeGuide: includeGuide,
          onProgress: (p) {
            if (ref.mounted) {
              state = SyncState(
                running: true,
                providerId: providerId,
                progress: p,
                lastResult: state.lastResult,
              );
            }
          },
        );
    if (ref.mounted) state = SyncState(providerId: providerId, lastResult: r);
    return r;
  }

  /// Imports a picked M3U file into [providerId] (brief 5.5).
  Future<SyncResult?> importFile(String providerId, Uint8List bytes) async {
    if (state.running) return null;
    state = SyncState(running: true, providerId: providerId);
    final r = await ref
        .read(catalogSyncProvider)
        .importM3uFile(
          providerId,
          bytes,
          onProgress: (p) {
            if (ref.mounted) {
              state = SyncState(
                running: true,
                providerId: providerId,
                progress: p,
              );
            }
          },
        );
    if (ref.mounted) state = SyncState(providerId: providerId, lastResult: r);
    return r;
  }

  /// Background refresh at launch when due (brief 6).
  Future<void> refreshIfDue() async {
    final id = ref.read(activeProviderIdProvider);
    if (id == null) return;
    final p = await ref.read(providerRegistryProvider).byId(id);
    if (p == null) return;
    final policy = ref.read(appSettingsProvider).refreshPolicy;
    if (isRefreshDue(p.lastSyncAt, policy, DateTime.now())) {
      await refresh(id);
    }
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncState>(
  SyncController.new,
);

/// Shows the "Offline, showing saved data" banner.
final offlineBannerProvider = Provider<bool>((ref) {
  final online = ref.watch(connectivityOnlineProvider).value ?? true;
  final sync = ref.watch(syncControllerProvider);
  final hasCache = ref.watch(catalogSnapshotProvider).value != null;
  return hasCache && (!online || sync.lastFailedUnreachable);
});
