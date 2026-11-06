import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import '../../core/network/connection_error.dart';
import '../../core/network/network_client.dart';
import '../../core/network/redaction.dart';
import '../../core/network/retry.dart';
import '../../core/network/user_agents.dart';
import 'server_endpoint.dart';
import 'stream_urls.dart';
import 'tolerant_json.dart';
import 'xtream_models.dart';
import 'xtream_parsers.dart';

/// Limits concurrent requests to one provider (brief 5.4: 2 to 3).
class RequestPool {
  RequestPool(this.maxConcurrent);

  final int maxConcurrent;
  int _running = 0;
  final _waiting = Queue<Completer<void>>();

  int get running => _running;

  Future<T> run<T>(Future<T> Function() task) async {
    if (_running >= maxConcurrent) {
      final c = Completer<void>();
      _waiting.add(c);
      await c.future;
    }
    _running++;
    try {
      return await task();
    } finally {
      _running--;
      if (_waiting.isNotEmpty) _waiting.removeFirst().complete();
    }
  }
}

/// Bodies for one list action. [complete] is false when some categories
/// failed, in which case stale rows must not be deleted.
class ListBodies {
  ListBodies(
    this.bodies, {
    required this.perCategory,
    this.failedCategories = 0,
  });

  final List<Uint8List> bodies;
  final bool perCategory;
  final int failedCategories;

  bool get complete => failedCategories == 0;
}

/// Progress for a catalogue download.
typedef ListProgress = void Function(int receivedBytes, int? totalBytes);

/// Talks to one Xtream provider with the working profile from sign-in.
class XtreamClient {
  XtreamClient({
    required this.network,
    required this.endpoint,
    required this.username,
    required this.password,
    this.userAgent = UserAgentProfile.okhttp,
    this.timeouts = const NetTimeouts(),
    this.retry = const RetryPolicy(),
    RequestPool? pool,
    this.categoryDelay = const Duration(milliseconds: 250),
  }) : pool = pool ?? RequestPool(2);

  final NetworkClient network;
  final ServerEndpoint endpoint;
  final String username;
  final String password;
  final UserAgentProfile userAgent;
  final NetTimeouts timeouts;
  final RetryPolicy retry;
  final RequestPool pool;

  /// Pause between per-category requests; some panels ban bursts.
  final Duration categoryDelay;

  XtreamUrls get urls => XtreamUrls(endpoint, username, password);

  Map<String, String> get headers => {
    'User-Agent': userAgent.value,
    'Accept': '*/*',
  };

  Future<NetResponse> _get(
    Uri url, {
    CancelSignal? cancel,
    ListProgress? onProgress,
  }) => pool.run(
    () => getWithRetry(
      () => network.get(
        url,
        headers: headers,
        timeouts: timeouts,
        cancel: cancel,
        onProgress: onProgress,
      ),
      policy: retry,
      cancel: cancel,
    ),
  );

  /// GET an action and decode its JSON body. Throws [ConnectionError].
  Future<Object?> action(
    String action, {
    Map<String, String> params = const {},
    CancelSignal? cancel,
  }) async {
    final res = await _guard(
      () => _get(urls.api(action, params), cancel: cancel),
    );
    return _decode(res);
  }

  /// Login call (no action): fresh user and server info. Throws
  /// [ConnectionError] (auth_rejected when the body has no user_info).
  Future<AccountInfo> account({CancelSignal? cancel}) async {
    final res = await _guard(() => _get(urls.api(), cancel: cancel));
    final info = AccountInfo.parse(_decode(res));
    if (info == null || info.user.auth == false) {
      throw const ConnectionError(
        ConnectionErrorKind.authRejected,
        details: 'login rejected on refresh',
      );
    }
    return info;
  }

  Future<List<XCategory>> liveCategories({CancelSignal? cancel}) async =>
      parseCategories(await action('get_live_categories', cancel: cancel));
  Future<List<XCategory>> vodCategories({CancelSignal? cancel}) async =>
      parseCategories(await action('get_vod_categories', cancel: cancel));
  Future<List<XCategory>> seriesCategories({CancelSignal? cancel}) async =>
      parseCategories(await action('get_series_categories', cancel: cancel));

  Future<XSeriesInfo> seriesInfo(int seriesId, {CancelSignal? cancel}) async =>
      parseSeriesInfo(
        await action(
          'get_series_info',
          params: {'series_id': '$seriesId'},
          cancel: cancel,
        ),
      );

  Future<XVodInfo?> vodInfo(int vodId, {CancelSignal? cancel}) async =>
      parseVodInfo(
        await action(
          'get_vod_info',
          params: {'vod_id': '$vodId'},
          cancel: cancel,
        ),
        requestedId: vodId,
      );

  Future<List<XEpgEntry>> shortEpg(
    int streamId, {
    int limit = 4,
    CancelSignal? cancel,
  }) async => parseShortEpg(
    await action(
      'get_short_epg',
      params: {'stream_id': '$streamId', 'limit': '$limit'},
      cancel: cancel,
    ),
  );

  Future<List<XLiveStream>> liveStreams({
    ListProgress? onProgress,
    CancelSignal? cancel,
    Future<List<XCategory>> Function()? categories,
  }) => _bigList(
    'get_live_streams',
    parseLiveStreams,
    (s) => s.streamId,
    onProgress: onProgress,
    cancel: cancel,
    categories: categories ?? () => liveCategories(cancel: cancel),
  );

  Future<List<XVod>> vodStreams({
    ListProgress? onProgress,
    CancelSignal? cancel,
    Future<List<XCategory>> Function()? categories,
  }) => _bigList(
    'get_vod_streams',
    parseVodStreams,
    (s) => s.streamId,
    onProgress: onProgress,
    cancel: cancel,
    categories: categories ?? () => vodCategories(cancel: cancel),
  );

  Future<List<XSeries>> series({
    ListProgress? onProgress,
    CancelSignal? cancel,
    Future<List<XCategory>> Function()? categories,
  }) => _bigList(
    'get_series',
    parseSeriesList,
    (s) => s.seriesId,
    onProgress: onProgress,
    cancel: cancel,
    categories: categories ?? () => seriesCategories(cancel: cancel),
  );

  /// Downloads a whole list at once, parsed in an isolate. If that times
  /// out or fails, falls back to one request per category, at most 2 at a
  /// time with a short pause between them (brief 5.4).
  Future<List<T>> _bigList<T>(
    String action,
    List<T> Function(Object?) parse,
    int Function(T) idOf, {
    required ListProgress? onProgress,
    required CancelSignal? cancel,
    required Future<List<XCategory>> Function() categories,
  }) async {
    final bodies = await listBodies(
      action,
      onProgress: onProgress,
      cancel: cancel,
      categories: categories,
    );
    final seen = <int>{};
    final out = <T>[];
    for (final body in bodies.bodies) {
      final list = await parseListInIsolate(body, parse);
      if (list == null) {
        if (!bodies.perCategory) {
          throw ConnectionError(
            ConnectionErrorKind.malformed,
            details: '$action returned non-JSON',
          );
        }
        continue;
      }
      for (final item in list) {
        if (seen.add(idOf(item))) out.add(item);
      }
    }
    return out;
  }

  /// Raw response bodies for a list action, so a sync isolate can parse
  /// and write them without the data ever touching the UI isolate.
  ///
  /// Tries the whole list first; on timeout, failure or a non-JSON body,
  /// fetches per category (at most 2 concurrent, paced).
  Future<ListBodies> listBodies(
    String action, {
    ListProgress? onProgress,
    CancelSignal? cancel,
    required Future<List<XCategory>> Function() categories,
  }) async {
    try {
      final res = await _guard(
        () => pool.run(
          () => network.get(
            urls.api(action),
            headers: headers,
            timeouts: timeouts,
            cancel: cancel,
            onProgress: onProgress,
          ),
        ),
      );
      _checkStatus(res);
      if (_looksLikeJsonList(res.bytes)) {
        return ListBodies([res.bytes], perCategory: false);
      }
      NetLog.w('$action: full list was not JSON, trying per category');
    } on ConnectionError catch (e) {
      if (cancel?.isCancelled ?? false) rethrow;
      // Auth and account problems won't be fixed by smaller requests.
      if (_conclusive(e.kind)) rethrow;
      NetLog.w('$action: full list failed (${e.kind.name}), per category');
    }

    final cats = await categories();
    final bodies = <Uint8List>[];
    final fallbackPool = RequestPool(2);
    var failures = 0;
    await Future.wait([
      for (final (i, c) in cats.indexed)
        fallbackPool.run(() async {
          if (cancel?.isCancelled ?? false) return;
          if (i >= fallbackPool.maxConcurrent) {
            await Future<void>.delayed(categoryDelay);
          }
          try {
            final res = await _guard(
              () =>
                  _get(urls.api(action, {'category_id': c.id}), cancel: cancel),
            );
            _checkStatus(res);
            bodies.add(res.bytes);
          } on ConnectionError {
            failures++;
          }
        }),
    ]);
    if (cancel?.isCancelled ?? false) {
      throw const ConnectionError(
        ConnectionErrorKind.timeoutOrRefused,
        details: 'cancelled',
      );
    }
    if (bodies.isEmpty && failures > 0) {
      throw ConnectionError(
        ConnectionErrorKind.timeoutOrRefused,
        details: '$action failed in full and per category ($failures)',
      );
    }
    return ListBodies(bodies, perCategory: true, failedCategories: failures);
  }

  static bool _looksLikeJsonList(Uint8List b) {
    for (var i = 0; i < b.length && i < 4096; i++) {
      final c = b[i];
      // Skip BOM bytes and whitespace.
      if (c == 0xEF || c == 0xBB || c == 0xBF || c <= 0x20) continue;
      // `[`, `{`, or text junk (PHP warnings) the tolerant decoder handles.
      return c != 0x3C; // '<' = HTML page
    }
    return false;
  }

  static bool _conclusive(ConnectionErrorKind k) =>
      k == ConnectionErrorKind.authRejected ||
      k == ConnectionErrorKind.http401or403 ||
      k == ConnectionErrorKind.expired ||
      k == ConnectionErrorKind.disabled;

  void _checkStatus(NetResponse res) {
    final e = classifyStatus(res);
    if (e != null) throw e;
  }

  Object? _decode(NetResponse res) {
    _checkStatus(res);
    final body = decodeProviderBody(res.bytes);
    return switch (body) {
      JsonBody(:final value) => value,
      EmptyBody() => null,
      HtmlBody(:final snippet) => throw ConnectionError(
        ConnectionErrorKind.htmlResponse,
        details: 'HTTP ${res.status}: $snippet',
      ),
      MalformedBody(:final detail) => throw ConnectionError(
        ConnectionErrorKind.malformed,
        details: detail,
      ),
    };
  }

  static Future<NetResponse> _guard(Future<NetResponse> Function() f) async {
    try {
      return await f();
    } on NetException catch (e) {
      throw classifyNetException(e);
    }
  }
}

/// HTTP status to error class; null for success.
ConnectionError? classifyStatus(NetResponse res) {
  final s = res.status;
  if (s >= 200 && s < 300) return null;
  if (s == 401 || s == 403) {
    return ConnectionError(
      ConnectionErrorKind.http401or403,
      details: 'HTTP $s',
    );
  }
  if (s == 404) {
    return const ConnectionError(
      ConnectionErrorKind.http404,
      details: 'HTTP 404',
    );
  }
  if (s == 429) {
    return const ConnectionError(
      ConnectionErrorKind.timeoutOrRefused,
      details: 'HTTP 429 (rate limited)',
    );
  }
  return ConnectionError(
    ConnectionErrorKind.timeoutOrRefused,
    details: 'HTTP $s',
  );
}

/// Transport failure to error class.
ConnectionError classifyNetException(NetException e) {
  final kind = switch (e.kind) {
    NetFailureKind.dns => ConnectionErrorKind.dnsFailure,
    NetFailureKind.offline => ConnectionErrorKind.offline,
    NetFailureKind.tls => ConnectionErrorKind.tlsError,
    NetFailureKind.refused ||
    NetFailureKind.timeout ||
    NetFailureKind.closed ||
    NetFailureKind.tooManyRedirects ||
    NetFailureKind.cancelled ||
    NetFailureKind.unknown => ConnectionErrorKind.timeoutOrRefused,
    NetFailureKind.tooLarge => ConnectionErrorKind.malformed,
  };
  return ConnectionError(kind, details: '${e.kind.name}: ${e.detail}');
}
