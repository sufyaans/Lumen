import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../core/network/connection_error.dart';
import '../../core/network/network_client.dart';
import '../../core/network/redaction.dart';
import '../../core/network/retry.dart';
import '../../core/network/user_agents.dart';
import '../db/app_database.dart';
import '../db/tables.dart';
import '../epg/xmltv.dart';
import '../secure/credential_store.dart';
import '../xtream/connection_doctor.dart';
import '../xtream/server_endpoint.dart';
import '../xtream/xtream_client.dart';
import '../xtream/xtream_models.dart';
import 'sync_writers.dart';

/// First-sync steps shown on the progress screen (brief section 6).
enum SyncStep { signingIn, categories, channels, movies, series, guide, done }

@immutable
class SyncProgress {
  const SyncProgress(this.step, {this.received, this.total});
  final SyncStep step;
  final int? received;
  final int? total;
}

@immutable
class SyncResult {
  const SyncResult({
    this.channels = 0,
    this.movies = 0,
    this.series = 0,
    this.programmes = 0,
    this.error,
    this.needsPassword = false,
    this.warnings = const [],
  });

  final int channels;
  final int movies;
  final int series;
  final int programmes;

  /// Set when the sync failed. Cached data is untouched.
  final ConnectionError? error;

  /// The saved password is missing (e.g. keychain reset after re-signing).
  final bool needsPassword;

  /// Non-fatal problems, e.g. "guide unavailable".
  final List<String> warnings;

  bool get ok => error == null && !needsPassword;
  bool get empty => channels + movies + series == 0;
}

/// Refreshes one provider's catalogue into the database.
///
/// * Stale-while-revalidate: rows are upserted, stale ones removed only
///   after a complete fetch; user data (favourites, progress, lists) is in
///   separate tables keyed by remote id, so it survives.
/// * Parsing and writing happen in a short-lived isolate attached to the
///   database ([GeneratedDatabase.computeWithDatabase]).
/// * If the saved working profile stops working, re-probes automatically
///   and saves the new one (brief 5.3 step 6).
class CatalogSync {
  CatalogSync({
    required this.db,
    required this.store,
    required this.networkFor,
    this.timeouts = const NetTimeouts(),
    this.guideTimeouts = const NetTimeouts(receive: Duration(seconds: 60)),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AppDatabase db;
  final CredentialStore store;

  /// A network client honouring the provider's certificate setting.
  final NetworkClient Function(ProviderRow provider) networkFor;
  final NetTimeouts timeouts;
  final NetTimeouts guideTimeouts;
  final DateTime Function() _clock;

  Future<ProviderRow?> _provider(String id) => (db.select(
    db.providers,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<SyncResult> sync(
    String providerId, {
    void Function(SyncProgress)? onProgress,
    CancelSignal? cancel,
    bool includeGuide = true,
  }) async {
    final p = await _provider(providerId);
    if (p == null) {
      return const SyncResult(
        error: ConnectionError(
          ConnectionErrorKind.invalidInput,
          details: 'provider not found',
        ),
      );
    }
    try {
      final result = switch (p.kind) {
        'xtream' => await _syncXtream(p, onProgress, cancel, includeGuide),
        'm3u_url' => await _syncM3uUrl(p, onProgress, cancel, includeGuide),
        _ => const SyncResult(), // Files are imported with [importM3uFile].
      };
      await _finish(p.id, result);
      onProgress?.call(const SyncProgress(SyncStep.done));
      return result;
    } on ConnectionError catch (e) {
      final r = SyncResult(error: e);
      await _finish(p.id, r);
      return r;
    }
  }

  Future<void> _finish(String id, SyncResult r) async {
    await (db.update(db.providers)..where((t) => t.id.equals(id))).write(
      ProvidersCompanion(
        lastSyncAt: r.ok ? Value(_clock()) : const Value.absent(),
        lastSyncError: Value(
          r.ok ? null : (r.error?.kind.name ?? 'needs_password'),
        ),
      ),
    );
  }

  // ---- Xtream ---------------------------------------------------------------

  Future<SyncResult> _syncXtream(
    ProviderRow p,
    void Function(SyncProgress)? onProgress,
    CancelSignal? cancel,
    bool includeGuide,
  ) async {
    final pw = await store.readPassword(p.id);
    if (pw is! SecretFound || p.username == null) {
      return const SyncResult(needsPassword: true);
    }
    final network = networkFor(p);
    var endpoint = ServerEndpoint.fromJson(
      p.endpointJson == null ? null : jsonDecode(p.endpointJson!),
    );
    if (endpoint == null) {
      throw const ConnectionError(
        ConnectionErrorKind.invalidInput,
        details: 'provider has no endpoint',
      );
    }
    var ua = UserAgentProfile.byId(p.userAgentId) ?? UserAgentProfile.okhttp;

    XtreamClient clientFor(ServerEndpoint e, UserAgentProfile a) =>
        XtreamClient(
          network: network,
          endpoint: e,
          username: p.username!,
          password: pw.value,
          userAgent: a,
          timeouts: timeouts,
        );

    onProgress?.call(const SyncProgress(SyncStep.signingIn));
    var client = clientFor(endpoint, ua);
    AccountInfo account;
    try {
      account = await client.account(cancel: cancel);
    } on ConnectionError catch (e) {
      if (_isAccountProblem(e.kind)) rethrow;
      // The saved profile stopped working: re-probe and remember the result.
      NetLog.w('saved profile failed (${e.kind.name}); re-probing');
      final probe = await ConnectionDoctor(network: network, timeouts: timeouts)
          .probe(
            input: ServerInput(
              candidates: [
                endpoint,
                endpoint.withScheme(
                  endpoint.scheme == 'http' ? 'https' : 'http',
                ),
              ],
            ),
            username: p.username!,
            password: pw.value,
            saved: WorkingProfile(endpoint: endpoint, userAgent: ua),
            cancel: cancel,
          );
      if (probe is ProbeFailure) throw probe.error;
      final ok = probe as ProbeSuccess;
      endpoint = ok.profile.endpoint;
      ua = ok.profile.userAgent;
      account = ok.account;
      client = clientFor(endpoint, ua);
      await (db.update(db.providers)..where((t) => t.id.equals(p.id))).write(
        ProvidersCompanion(
          endpointJson: Value(jsonEncode(endpoint.toJson())),
          userAgentId: Value(ua.id),
          displayHost: Value(endpoint.displayHost),
        ),
      );
    }
    await (db.update(db.providers)..where((t) => t.id.equals(p.id))).write(
      ProvidersCompanion(
        userInfoJson: Value(jsonEncode(account.user.toJson())),
        serverInfoJson: Value(
          account.server == null ? null : jsonEncode(account.server!.toJson()),
        ),
      ),
    );
    final u = account.user;
    if (u.status == AccountStatus.banned ||
        u.status == AccountStatus.disabled) {
      throw const ConnectionError(ConnectionErrorKind.disabled);
    }
    final exp = u.expiresAt;
    if (u.status == AccountStatus.expired ||
        (exp != null && exp.isBefore(_clock().toUtc()))) {
      throw ConnectionError(ConnectionErrorKind.expired, expiredOn: exp);
    }

    final token = _clock().microsecondsSinceEpoch;
    final warnings = <String>[];

    onProgress?.call(const SyncProgress(SyncStep.categories));
    final liveCats = await client.liveCategories(cancel: cancel);
    final movieCats =
        await _soft(
          () => client.vodCategories(cancel: cancel),
          warnings,
          'movie categories',
        ) ??
        [];
    final seriesCats =
        await _soft(
          () => client.seriesCategories(cancel: cancel),
          warnings,
          'series categories',
        ) ??
        [];
    final adultLive = await writeCategories(
      db,
      providerId: p.id,
      kind: ContentKind.live,
      categories: liveCats,
      token: token,
    );
    final adultMovie = await writeCategories(
      db,
      providerId: p.id,
      kind: ContentKind.movie,
      categories: movieCats,
      token: token,
    );
    final adultSeries = await writeCategories(
      db,
      providerId: p.id,
      kind: ContentKind.series,
      categories: seriesCats,
      token: token,
    );

    Future<int> list(
      String action,
      String kind,
      SyncStep step,
      List<XCategory> cats,
      Set<String> adult,
    ) async {
      onProgress?.call(SyncProgress(step));
      final bodies = await client.listBodies(
        action,
        cancel: cancel,
        categories: () async => cats,
        onProgress: (r, t) =>
            onProgress?.call(SyncProgress(step, received: r, total: t)),
      );
      if (!bodies.complete) {
        warnings.add('$kind: ${bodies.failedCategories} categories failed');
      }
      return _isolateWriteList(
        db,
        providerId: p.id,
        kind: kind,
        bodies: bodies.bodies,
        token: token,
        adult: adult,
        complete: bodies.complete,
      );
    }

    // Channels first: browsing can start as soon as they're in (brief 6).
    final channels = await list(
      'get_live_streams',
      ContentKind.live,
      SyncStep.channels,
      liveCats,
      adultLive,
    );
    final movies =
        await _soft(
          () => list(
            'get_vod_streams',
            ContentKind.movie,
            SyncStep.movies,
            movieCats,
            adultMovie,
          ),
          warnings,
          'movies',
        ) ??
        0;
    final series =
        await _soft(
          () => list(
            'get_series',
            ContentKind.series,
            SyncStep.series,
            seriesCats,
            adultSeries,
          ),
          warnings,
          'series',
        ) ??
        0;
    await _rebuildSearch(p.id);

    var programmes = 0;
    if (includeGuide) {
      programmes =
          await _soft(
            () => _importGuide(
              p.id,
              p.epgUrl != null ? Uri.parse(p.epgUrl!) : client.urls.xmltv(),
              network,
              ua,
              onProgress,
              cancel,
            ),
            warnings,
            'guide',
          ) ??
          0;
    }

    final r = SyncResult(
      channels: channels,
      movies: movies,
      series: series,
      programmes: programmes,
      warnings: warnings,
    );
    if (r.empty) throw const ConnectionError(ConnectionErrorKind.emptyCatalog);
    return r;
  }

  static bool _isAccountProblem(ConnectionErrorKind k) =>
      k == ConnectionErrorKind.authRejected ||
      k == ConnectionErrorKind.expired ||
      k == ConnectionErrorKind.disabled ||
      k == ConnectionErrorKind.offline;

  Future<T?> _soft<T>(
    Future<T> Function() f,
    List<String> warnings,
    String what,
  ) async {
    try {
      return await f();
    } on ConnectionError catch (e) {
      if (e.kind == ConnectionErrorKind.offline) rethrow;
      warnings.add('$what: ${e.kind.name}');
      return null;
    }
  }

  Future<void> _rebuildSearch(String providerId) =>
      _isolateRebuildSearch(db, providerId);

  Future<int> _importGuide(
    String providerId,
    Uri url,
    NetworkClient network,
    UserAgentProfile ua,
    void Function(SyncProgress)? onProgress,
    CancelSignal? cancel,
  ) async {
    onProgress?.call(const SyncProgress(SyncStep.guide));
    final bytes = await _download(
      network,
      url,
      ua,
      guideTimeouts,
      cancel,
      (r, t) =>
          onProgress?.call(SyncProgress(SyncStep.guide, received: r, total: t)),
    );
    return _isolateImportGuide(db, providerId, bytes, _clock().toUtc());
  }

  // ---- M3U ------------------------------------------------------------------

  Future<SyncResult> _syncM3uUrl(
    ProviderRow p,
    void Function(SyncProgress)? onProgress,
    CancelSignal? cancel,
    bool includeGuide,
  ) async {
    final secret = await store.readSecretUrl(p.id);
    if (secret is! SecretFound) return const SyncResult(needsPassword: true);
    final url = Uri.parse(secret.value);
    final network = networkFor(p);
    onProgress?.call(const SyncProgress(SyncStep.channels));
    final bytes = await _download(
      network,
      url,
      UserAgentProfile.vlc,
      const NetTimeouts(receive: Duration(seconds: 30)),
      cancel,
      (r, t) => onProgress?.call(
        SyncProgress(SyncStep.channels, received: r, total: t),
      ),
    );
    final head = String.fromCharCodes(bytes.take(512)).trimLeft().toLowerCase();
    if (head.startsWith('<!doctype html') || head.startsWith('<html')) {
      throw const ConnectionError(ConnectionErrorKind.htmlResponse);
    }
    return _importM3uBytes(
      p,
      bytes,
      username: url.queryParameters['username'],
      password: url.queryParameters['password'],
      network: network,
      onProgress: onProgress,
      cancel: cancel,
      includeGuide: includeGuide,
    );
  }

  /// Imports a playlist file the user picked (brief 5.5).
  Future<SyncResult> importM3uFile(
    String providerId,
    Uint8List bytes, {
    void Function(SyncProgress)? onProgress,
    bool includeGuide = true,
  }) async {
    final p = await _provider(providerId);
    if (p == null) {
      return const SyncResult(
        error: ConnectionError(ConnectionErrorKind.invalidInput),
      );
    }
    try {
      final r = await _importM3uBytes(
        p,
        bytes,
        network: networkFor(p),
        onProgress: onProgress,
        includeGuide: includeGuide,
      );
      await _finish(p.id, r);
      return r;
    } on ConnectionError catch (e) {
      return SyncResult(error: e);
    }
  }

  Future<SyncResult> _importM3uBytes(
    ProviderRow p,
    Uint8List bytes, {
    String? username,
    String? password,
    required NetworkClient network,
    void Function(SyncProgress)? onProgress,
    CancelSignal? cancel,
    required bool includeGuide,
  }) async {
    // Isolate.run rethrows ConnectionError (m3uInvalid) as-is.
    final res = await _isolateWriteM3u(
      db,
      providerId: p.id,
      bytes: bytes,
      token: _clock().microsecondsSinceEpoch,
      username: username,
      password: password,
    );

    final warnings = <String>[];
    final epg = p.epgUrl ?? res.epgUrl;
    if (p.epgUrl == null && res.epgUrl != null) {
      // Offer the playlist's guide automatically (brief 5.5).
      await (db.update(db.providers)..where((t) => t.id.equals(p.id))).write(
        ProvidersCompanion(epgUrl: Value(res.epgUrl)),
      );
    }
    var programmes = 0;
    if (includeGuide && epg != null) {
      final u = Uri.tryParse(epg);
      if (u != null && (u.scheme == 'http' || u.scheme == 'https')) {
        programmes =
            await _soft(
              () => _importGuide(
                p.id,
                u,
                network,
                UserAgentProfile.vlc,
                onProgress,
                cancel,
              ),
              warnings,
              'guide',
            ) ??
            0;
      }
    }
    final r = SyncResult(
      channels: res.live,
      movies: res.movies,
      series: res.series,
      programmes: programmes,
      warnings: warnings,
    );
    if (r.empty) throw const ConnectionError(ConnectionErrorKind.emptyCatalog);
    return r;
  }

  Future<Uint8List> _download(
    NetworkClient network,
    Uri url,
    UserAgentProfile ua,
    NetTimeouts t,
    CancelSignal? cancel,
    void Function(int, int?)? onProgress,
  ) async {
    NetResponse res;
    try {
      res = await getWithRetry(
        () => network.get(
          url,
          headers: {'User-Agent': ua.value, 'Accept': '*/*'},
          timeouts: t,
          cancel: cancel,
          onProgress: onProgress,
        ),
        cancel: cancel,
      );
    } on NetException catch (e) {
      throw classifyNetException(e);
    }
    final err = classifyStatus(res);
    if (err != null) throw err;
    return res.bytes;
  }
}

// ---- Isolate entry points ----------------------------------------------------
// Top-level so the closures sent to the isolate capture only plain values,
// never the CatalogSync instance or the database connection.

Future<int> _isolateWriteList(
  AppDatabase db, {
  required String providerId,
  required String kind,
  required List<Uint8List> bodies,
  required int token,
  required Set<String> adult,
  required bool complete,
}) => db.computeWithDatabase(
  computation: (AppDatabase d) => writeXtreamList(
    d,
    providerId: providerId,
    kind: kind,
    bodies: bodies,
    token: token,
    adultCategoryIds: adult,
    complete: complete,
  ),
  connect: AppDatabase.new,
);

Future<void> _isolateRebuildSearch(AppDatabase db, String providerId) =>
    db.computeWithDatabase(
      computation: (AppDatabase d) => rebuildSearchIndex(d, providerId),
      connect: AppDatabase.new,
    );

Future<int> _isolateImportGuide(
  AppDatabase db,
  String providerId,
  Uint8List bytes,
  DateTime now,
) => db.computeWithDatabase(
  computation: (AppDatabase d) =>
      importXmltv(d, providerId: providerId, bytes: bytes, now: now),
  connect: AppDatabase.new,
);

Future<M3uImportResult> _isolateWriteM3u(
  AppDatabase db, {
  required String providerId,
  required Uint8List bytes,
  required int token,
  String? username,
  String? password,
}) => db.computeWithDatabase(
  computation: (AppDatabase d) => writeM3u(
    d,
    providerId: providerId,
    bytes: bytes,
    token: token,
    username: username,
    password: password,
  ),
  connect: AppDatabase.new,
);
