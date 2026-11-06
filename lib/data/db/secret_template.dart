/// Keeps credentials out of URLs stored in the database (brief 5.8).
///
/// M3U playlists from a credential-bearing link usually repeat the same
/// username and password inside every stream URL. Before storing, those
/// values (raw and percent-encoded) are replaced with placeholders; at play
/// time they are filled back in from secure storage.
abstract final class SecretTemplate {
  static const user = '{{lumen:u}}';
  static const pass = '{{lumen:p}}';

  static String encode(String url, {String? username, String? password}) {
    // Only the path and query: never touch the scheme or host.
    final scheme = url.indexOf('://');
    final pathStart = scheme < 0 ? 0 : url.indexOf('/', scheme + 3);
    if (pathStart < 0) return url;
    final head = url.substring(0, pathStart);
    var s = url.substring(pathStart);
    // Longest first so a password containing the username stays intact.
    final pairs = <(String, String)>[
      if (password != null && password.length >= 2) (password, pass),
      if (username != null && username.length >= 2) (username, user),
    ]..sort((a, b) => b.$1.length.compareTo(a.$1.length));
    for (final (secret, token) in pairs) {
      for (final form in {
        Uri.encodeComponent(secret),
        Uri.encodeQueryComponent(secret),
        secret,
      }) {
        s = _replaceWhole(s, form, token);
      }
    }
    return '$head$s';
  }

  /// Replaces [from] only where it forms a whole URL component (between
  /// `/`, `?`, `&`, `=`, `.` or the ends), so a short username like "tv"
  /// doesn't corrupt a host name like "tv.example".
  static String _replaceWhole(String s, String from, String to) {
    if (from.isEmpty) return s;
    final re = RegExp('(?<=[/?&=]|^)${RegExp.escape(from)}(?=[/?&#.]|\$)');
    return s.replaceAll(re, to);
  }

  static String decode(String url, {String? username, String? password}) {
    var s = url;
    if (username != null) {
      s = s.replaceAll(user, Uri.encodeComponent(username));
    }
    if (password != null) {
      s = s.replaceAll(pass, Uri.encodeComponent(password));
    }
    return s;
  }

  static bool hasPlaceholders(String url) =>
      url.contains(user) || url.contains(pass);
}
