import 'package:flutter/foundation.dart';

/// The single redaction layer for anything that might be logged or shown
/// as technical detail (brief section 5.8).
///
/// Removes:
/// * `username=` / `password=` (and `user=`, `pass=`, `token=`) query values
/// * `user:pass@` userinfo in URLs
/// * credentials in Xtream stream paths: `/live/U/P/...`, `/movie/U/P/...`,
///   `/series/U/P/...`, `/timeshift/U/P/...`
/// * any explicitly known secret strings, raw or percent-encoded (this also
///   covers the short `/U/P/123` stream form)
abstract final class Redactor {
  static const mask = '***';

  static final _query = RegExp(
    r'([?&;](?:username|password|user|pass|pwd|token|auth|key|mac)=)[^&#\s"]*',
    caseSensitive: false,
  );
  static final _userInfo = RegExp(r'([a-zA-Z][a-zA-Z0-9+.-]*://)[^/@\s]+@');
  static final _streamPath = RegExp(
    r'(/(?:live|movie|series|timeshift)/)[^/\s?#]+/[^/\s?#]+(?=/)',
    caseSensitive: false,
  );

  static String redact(String text, {Iterable<String> secrets = const []}) {
    var s = text;
    for (final secret in secrets) {
      if (secret.length < 2) continue;
      for (final form in {
        secret,
        Uri.encodeComponent(secret),
        Uri.encodeQueryComponent(secret),
      }) {
        s = s.replaceAll(form, mask);
      }
    }
    s = s.replaceAllMapped(_query, (m) => '${m[1]}$mask');
    s = s.replaceAllMapped(_userInfo, (m) => '${m[1]}$mask@');
    s = s.replaceAllMapped(_streamPath, (m) => '${m[1]}$mask/$mask');
    return s;
  }

  static String redactUri(Uri uri, {Iterable<String> secrets = const []}) =>
      redact(uri.toString(), secrets: secrets);
}

/// Logging through the redaction layer. Release builds keep warnings and
/// errors only.
abstract final class NetLog {
  static void d(String message) {
    if (kReleaseMode) return;
    debugPrint('[net] ${Redactor.redact(message)}');
  }

  static void w(String message) =>
      debugPrint('[net] WARN ${Redactor.redact(message)}');

  static void e(String message, [Object? error]) => debugPrint(
    '[net] ERROR ${Redactor.redact(message)}'
    '${error == null ? '' : ': ${Redactor.redact('$error')}'}',
  );
}
