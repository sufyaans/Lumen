import 'package:flutter/foundation.dart';

import '../../core/network/connection_error.dart';
import '../../core/network/network_client.dart';
import 'xtream_client.dart';

@immutable
class StreamCheck {
  const StreamCheck.ok(this.finalUrl, this.bytesRead) : error = null;
  const StreamCheck.failed(this.error) : finalUrl = null, bytesRead = 0;

  final Uri? finalUrl;
  final int bytesRead;
  final ConnectionError? error;

  bool get ok => error == null;
}

/// Opens a stream just long enough to see whether it plays, following
/// redirects (e.g. to a tokenised URL). Used by "Test playback" in the
/// Connection check; the player (Phase 4) applies the same classification.
///
/// A stream that is refused with 401/403, or that connects and immediately
/// closes with no data, means the account is at its connection limit
/// (brief section 7).
Future<StreamCheck> checkStream(
  NetworkClient network,
  Uri url, {
  Map<String, String> headers = const {},
  int? maxConnections,
  NetTimeouts timeouts = const NetTimeouts(
    connect: Duration(seconds: 10),
    receive: Duration(seconds: 8),
  ),
  CancelSignal? cancel,
}) async {
  try {
    final res = await network.get(
      url,
      headers: headers,
      timeouts: timeouts,
      maxBytes: 4096,
      cancel: cancel,
    );
    if (res.status == 401 || res.status == 403) {
      return StreamCheck.failed(
        ConnectionError(
          ConnectionErrorKind.maxConnections,
          maxConnections: maxConnections,
          details: 'stream refused: HTTP ${res.status}',
        ),
      );
    }
    if (!res.ok) {
      return StreamCheck.failed(
        classifyStatus(res) ??
            ConnectionError(
              ConnectionErrorKind.timeoutOrRefused,
              details: 'HTTP ${res.status}',
            ),
      );
    }
    if (res.bytes.isEmpty) {
      return StreamCheck.failed(
        ConnectionError(
          ConnectionErrorKind.maxConnections,
          maxConnections: maxConnections,
          details: 'stream closed immediately with no data',
        ),
      );
    }
    return StreamCheck.ok(res.finalUrl, res.bytes.length);
  } on NetException catch (e) {
    if (e.kind == NetFailureKind.closed) {
      return StreamCheck.failed(
        ConnectionError(
          ConnectionErrorKind.maxConnections,
          maxConnections: maxConnections,
          details: 'stream closed right after connect',
        ),
      );
    }
    return StreamCheck.failed(classifyNetException(e));
  }
}
