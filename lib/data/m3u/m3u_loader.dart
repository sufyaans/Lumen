import 'dart:typed_data';

import '../../core/network/connection_error.dart';
import '../../core/network/network_client.dart';
import '../../core/network/retry.dart';
import '../../core/network/user_agents.dart';
import '../xtream/xtream_client.dart';
import 'm3u_parser.dart';

/// Downloads an M3U link with the same error classification as Xtream
/// (brief 5.5) and parses it in an isolate. The URL may contain
/// credentials: callers keep it in secure storage only.
Future<M3uPlaylist> loadM3uLink(
  NetworkClient network,
  Uri url, {
  UserAgentProfile userAgent = UserAgentProfile.vlc,
  NetTimeouts timeouts = const NetTimeouts(),
  void Function(int received, int? total)? onProgress,
  CancelSignal? cancel,
}) async {
  if (url.scheme != 'http' && url.scheme != 'https') {
    throw const ConnectionError(
      ConnectionErrorKind.invalidInput,
      details: 'playlist link must start with http:// or https://',
    );
  }
  NetResponse res;
  try {
    res = await getWithRetry(
      () => network.get(
        url,
        headers: {'User-Agent': userAgent.value, 'Accept': '*/*'},
        timeouts: timeouts,
        onProgress: onProgress,
        cancel: cancel,
      ),
      cancel: cancel,
    );
  } on NetException catch (e) {
    throw classifyNetException(e);
  }
  final status = classifyStatus(res);
  if (status != null) {
    // A missing playlist file is "not a playlist", not "not Xtream".
    if (status.kind == ConnectionErrorKind.http404) {
      throw const ConnectionError(
        ConnectionErrorKind.m3uInvalid,
        details: 'HTTP 404',
      );
    }
    throw status;
  }
  return parseBytes(res.bytes);
}

Future<M3uPlaylist> parseBytes(Uint8List bytes) async {
  final head = String.fromCharCodes(bytes.take(512)).trimLeft().toLowerCase();
  if (head.startsWith('<!doctype html') || head.startsWith('<html')) {
    throw const ConnectionError(
      ConnectionErrorKind.htmlResponse,
      details: 'playlist link returned a web page',
    );
  }
  return parseM3uInIsolate(bytes);
}
