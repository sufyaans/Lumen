import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import 'redaction.dart';

/// Transport-level failure classes. Mapped to user-facing
/// [ConnectionErrorKind]s by the callers that know the context.
enum NetFailureKind {
  dns,
  refused,
  timeout,
  tls,
  offline,
  closed,
  tooManyRedirects,
  tooLarge,
  cancelled,
  unknown,
}

class NetException implements Exception {
  NetException(this.kind, this.detail, {this.url});

  final NetFailureKind kind;
  final String detail;
  final Uri? url;

  @override
  String toString() =>
      'NetException(${kind.name}: ${Redactor.redact(detail)}'
      '${url == null ? '' : ' @ ${Redactor.redactUri(url!)}'})';
}

@immutable
class NetTimeouts {
  const NetTimeouts({
    this.connect = const Duration(seconds: 10),
    this.receive = const Duration(seconds: 20),
  });

  final Duration connect;

  /// Maximum gap between two chunks of the response.
  final Duration receive;
}

@immutable
class NetResponse {
  const NetResponse({
    required this.status,
    required this.headers,
    required this.bytes,
    required this.finalUrl,
    this.redirects = const [],
  });

  final int status;

  /// Lower-cased header names; repeated headers joined with ", ".
  final Map<String, String> headers;
  final Uint8List bytes;

  /// The URL that produced this response after following redirects.
  final Uri finalUrl;
  final List<Uri> redirects;

  bool get ok => status >= 200 && status < 300;
  String? header(String name) => headers[name.toLowerCase()];
}

/// Cancels in-flight requests. One signal can cover a whole sign-in probe.
class CancelSignal {
  final _tokens = <CancelToken>{};
  final _completer = Completer<void>();
  bool _cancelled = false;

  bool get isCancelled => _cancelled;
  Future<void> get whenCancelled => _completer.future;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final t in _tokens) {
      t.cancel('cancelled');
    }
    _completer.complete();
  }
}

/// HTTP abstraction so the engine can be swapped (brief section 4).
abstract interface class NetworkClient {
  /// GET [url]. Never throws for HTTP status codes; throws [NetException]
  /// for transport failures. Redirects (up to [maxRedirects]) are followed
  /// manually so scheme/host changes are visible in [NetResponse.redirects].
  Future<NetResponse> get(
    Uri url, {
    Map<String, String> headers = const {},
    NetTimeouts timeouts = const NetTimeouts(),
    int maxRedirects = 5,
    CancelSignal? cancel,
    void Function(int received, int? total)? onProgress,

    /// Stop reading after this many bytes (used to probe streams).
    int? maxBytes,
  });

  void close();
}

/// [NetworkClient] backed by dio.
class DioNetworkClient implements NetworkClient {
  DioNetworkClient({bool Function(String host)? allowUntrustedCertFor})
    : _allowUntrusted = allowUntrustedCertFor {
    _dio = Dio(
      BaseOptions(
        responseType: ResponseType.stream,
        followRedirects: false,
        validateStatus: (_) => true,
        // Bodies are decoded by the caller regardless of Content-Type.
        receiveDataWhenStatusError: true,
      ),
    );
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final c = HttpClient()
          ..autoUncompress = true
          ..idleTimeout = const Duration(seconds: 15)
          // Providers limit simultaneous connections; keep the pool small.
          ..maxConnectionsPerHost = 3;
        // Untrusted certificates are rejected unless the user allowed them
        // for this specific host (brief section 5.9).
        c.badCertificateCallback = (cert, host, port) =>
            _allowUntrusted?.call(host.toLowerCase()) ?? false;
        return c;
      },
    );
  }

  late final Dio _dio;
  final bool Function(String host)? _allowUntrusted;

  @override
  void close() => _dio.close(force: true);

  @override
  Future<NetResponse> get(
    Uri url, {
    Map<String, String> headers = const {},
    NetTimeouts timeouts = const NetTimeouts(),
    int maxRedirects = 5,
    CancelSignal? cancel,
    void Function(int received, int? total)? onProgress,
    int? maxBytes,
  }) async {
    var current = url;
    final chain = <Uri>[];
    for (var hop = 0; ; hop++) {
      if (cancel?.isCancelled ?? false) {
        throw NetException(NetFailureKind.cancelled, 'cancelled', url: current);
      }
      final token = CancelToken();
      cancel?._tokens.add(token);
      try {
        final res = await _dio
            .getUri<ResponseBody>(
              current,
              cancelToken: token,
              options: Options(
                headers: headers,
                connectTimeout: timeouts.connect,
                sendTimeout: timeouts.connect,
                receiveTimeout: timeouts.receive,
                responseType: ResponseType.stream,
                followRedirects: false,
                validateStatus: (_) => true,
                receiveDataWhenStatusError: true,
              ),
            )
            // A server that accepts the connection but never sends headers
            // must still time out.
            .timeout(
              timeouts.connect + timeouts.receive,
              onTimeout: () {
                token.cancel('header timeout');
                throw NetException(
                  NetFailureKind.timeout,
                  'no response headers',
                  url: current,
                );
              },
            );
        final status = res.statusCode ?? 0;
        final h = <String, String>{
          for (final e in res.headers.map.entries)
            e.key.toLowerCase(): e.value.join(', '),
        };
        final location = h['location'];
        if (status >= 300 && status < 400 && location != null) {
          // Drain the redirect body before moving on.
          await res.data?.stream.drain<void>().catchError((_) {});
          if (hop >= maxRedirects) {
            throw NetException(
              NetFailureKind.tooManyRedirects,
              'more than $maxRedirects redirects',
              url: current,
            );
          }
          current = current.resolve(location.trim());
          chain.add(current);
          continue;
        }
        final bytes = await _readBody(
          res.data,
          total: int.tryParse(h['content-length'] ?? ''),
          onProgress: onProgress,
          maxBytes: maxBytes,
          token: token,
          receiveTimeout: timeouts.receive,
        );
        return NetResponse(
          status: status,
          headers: h,
          bytes: _decodeContentEncoding(bytes, h['content-encoding']),
          finalUrl: current,
          redirects: List.unmodifiable(chain),
        );
      } on DioException catch (e) {
        throw _map(e, current);
      } on NetException {
        rethrow;
      } on SocketException catch (e) {
        throw _mapSocket(e, current);
      } on HandshakeException catch (e) {
        throw NetException(NetFailureKind.tls, e.message, url: current);
      } on TimeoutException catch (e) {
        throw NetException(
          NetFailureKind.timeout,
          e.message ?? 'timeout',
          url: current,
        );
      } on HttpException catch (e) {
        throw NetException(NetFailureKind.closed, e.message, url: current);
      } finally {
        cancel?._tokens.remove(token);
      }
    }
  }

  Future<Uint8List> _readBody(
    ResponseBody? body, {
    required int? total,
    required void Function(int, int?)? onProgress,
    required int? maxBytes,
    required CancelToken token,
    required Duration receiveTimeout,
  }) async {
    if (body == null) return Uint8List(0);
    final builder = BytesBuilder(copy: false);
    final done = Completer<Uint8List>();
    late StreamSubscription<Uint8List> sub;
    Timer? idle;
    void armIdle() {
      idle?.cancel();
      idle = Timer(receiveTimeout, () {
        if (done.isCompleted) return;
        sub.cancel();
        done.completeError(
          NetException(NetFailureKind.timeout, 'no data for $receiveTimeout'),
        );
      });
    }

    sub = body.stream.listen(
      (chunk) {
        builder.add(chunk);
        armIdle();
        onProgress?.call(builder.length, total);
        if (maxBytes != null && builder.length >= maxBytes) {
          idle?.cancel();
          sub.cancel();
          if (!done.isCompleted) done.complete(builder.takeBytes());
        }
      },
      onError: (Object e) {
        idle?.cancel();
        if (done.isCompleted) return;
        if (e is DioException) {
          done.completeError(_map(e, null));
        } else if (e is SocketException) {
          done.completeError(_mapSocket(e, null));
        } else if (e is HttpException) {
          done.completeError(NetException(NetFailureKind.closed, e.message));
        } else {
          done.completeError(NetException(NetFailureKind.unknown, '$e'));
        }
      },
      onDone: () {
        idle?.cancel();
        if (!done.isCompleted) done.complete(builder.takeBytes());
      },
      cancelOnError: true,
    );
    armIdle();
    unawaited(
      token.whenCancel.then((_) {
        idle?.cancel();
        sub.cancel();
        if (!done.isCompleted) {
          done.completeError(
            NetException(NetFailureKind.cancelled, 'cancelled'),
          );
        }
      }),
    );
    return done.future;
  }

  static Uint8List _decodeContentEncoding(Uint8List bytes, String? encoding) {
    final enc = encoding?.toLowerCase().trim();
    if (enc == null || enc.isEmpty || enc == 'identity') return bytes;
    // gzip is already handled by HttpClient.autoUncompress; this covers
    // deflate and servers that double-label.
    try {
      if (enc.contains('deflate')) {
        try {
          return Uint8List.fromList(ZLibDecoder().convert(bytes));
        } on FormatException {
          return Uint8List.fromList(ZLibDecoder(raw: true).convert(bytes));
        }
      }
      if (enc.contains('gzip') &&
          bytes.length > 2 &&
          bytes[0] == 0x1f &&
          bytes[1] == 0x8b) {
        return Uint8List.fromList(GZipCodec().decode(bytes));
      }
    } catch (_) {
      // Fall through with the raw bytes; the JSON layer will classify it.
    }
    return bytes;
  }

  static NetException _map(DioException e, Uri? url) {
    switch (e.type) {
      case DioExceptionType.cancel:
        return NetException(NetFailureKind.cancelled, 'cancelled', url: url);
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetException(NetFailureKind.timeout, e.type.name, url: url);
      case DioExceptionType.badCertificate:
        return NetException(NetFailureKind.tls, 'bad certificate', url: url);
      case DioExceptionType.badResponse:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        final inner = e.error;
        if (inner is NetException) return inner;
        if (inner is SocketException) return _mapSocket(inner, url);
        if (inner is HandshakeException || inner is TlsException) {
          return NetException(NetFailureKind.tls, '$inner', url: url);
        }
        if (inner is HttpException) {
          return NetException(NetFailureKind.closed, inner.message, url: url);
        }
        if (inner is TimeoutException) {
          return NetException(NetFailureKind.timeout, 'timeout', url: url);
        }
        return NetException(
          NetFailureKind.unknown,
          '${e.type.name}: ${inner ?? e.message}',
          url: url,
        );
    }
  }

  static NetException _mapSocket(SocketException e, Uri? url) {
    final msg = '${e.message} ${e.osError?.message ?? ''}'.toLowerCase();
    final code = e.osError?.errorCode;
    NetFailureKind kind;
    if (msg.contains('host lookup') ||
        msg.contains('no address associated') ||
        msg.contains('nodename nor servname') ||
        msg.contains('name or service not known') ||
        code == 11001 ||
        code == 7 ||
        code == 8) {
      kind = NetFailureKind.dns;
    } else if (msg.contains('network is unreachable') ||
        code == 101 ||
        code == 10051 ||
        code == 51) {
      kind = NetFailureKind.offline;
    } else if (msg.contains('refused') ||
        code == 111 ||
        code == 10061 ||
        code == 61) {
      kind = NetFailureKind.refused;
    } else if (msg.contains('timed out') ||
        code == 110 ||
        code == 10060 ||
        code == 60) {
      kind = NetFailureKind.timeout;
    } else if (msg.contains('reset') || msg.contains('closed')) {
      kind = NetFailureKind.closed;
    } else {
      kind = NetFailureKind.unknown;
    }
    return NetException(kind, '${e.message} (${e.osError})', url: url);
  }
}
