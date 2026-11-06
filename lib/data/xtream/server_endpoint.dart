import 'package:flutter/foundation.dart';

import '../../core/network/connection_error.dart';
import '../../core/utils/punycode.dart';
import '../../core/utils/text_clean.dart';

/// A normalised server base: scheme, host, optional explicit port, base path.
@immutable
class ServerEndpoint {
  const ServerEndpoint({
    required this.scheme,
    required this.host,
    this.port,
    this.basePath = '',
  });

  /// `http` or `https`, lower-case.
  final String scheme;

  /// Lower-case ASCII host (IDN converted to punycode). IPv6 without
  /// brackets.
  final String host;

  /// Explicit port, or null to use the scheme default.
  final int? port;

  /// Path prefix without trailing slash, e.g. `''` or `/iptv`.
  final String basePath;

  int get effectivePort => port ?? (scheme == 'https' ? 443 : 80);

  List<String> get basePathSegments =>
      basePath.split('/').where((s) => s.isNotEmpty).toList();

  /// Base URI with no trailing slash.
  Uri get base => Uri(
    scheme: scheme,
    host: host,
    port: port,
    pathSegments: basePathSegments.isEmpty ? null : basePathSegments,
  );

  /// `{base}/{segments...}` with every segment percent-encoded, plus query.
  Uri resolve(List<String> segments, [Map<String, String>? query]) => Uri(
    scheme: scheme,
    host: host,
    port: port,
    pathSegments: [...basePathSegments, ...segments],
    queryParameters: (query == null || query.isEmpty) ? null : query,
  );

  /// Host and port only, for display. Never contains credentials.
  String get displayHost {
    final h = host.contains(':') ? '[$host]' : host;
    return port == null ? h : '$h:$port';
  }

  ServerEndpoint withScheme(String s) =>
      ServerEndpoint(scheme: s, host: host, port: port, basePath: basePath);

  /// Endpoint for a URL the server redirected us to (e.g. `.../player_api.php`
  /// on a new host): keeps the path prefix before the known file.
  static ServerEndpoint fromApiUrl(Uri url) {
    final segs = url.pathSegments.where((s) => s.isNotEmpty).toList();
    final idx = segs.indexWhere((s) => _knownFiles.contains(s.toLowerCase()));
    final baseSegs = idx >= 0 ? segs.sublist(0, idx) : segs;
    return ServerEndpoint(
      scheme: url.scheme.toLowerCase(),
      host: url.host.toLowerCase(),
      port: url.hasPort ? url.port : null,
      basePath: baseSegs.isEmpty ? '' : '/${baseSegs.join('/')}',
    );
  }

  Map<String, Object?> toJson() => {
    'scheme': scheme,
    'host': host,
    'port': port,
    'basePath': basePath,
  };

  static ServerEndpoint? fromJson(Object? json) {
    if (json is! Map) return null;
    final scheme = json['scheme'];
    final host = json['host'];
    if (scheme is! String || host is! String) return null;
    final port = json['port'];
    final base = json['basePath'];
    return ServerEndpoint(
      scheme: scheme,
      host: host,
      port: port is int ? port : null,
      basePath: base is String ? base : '',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ServerEndpoint &&
      other.scheme == scheme &&
      other.host == host &&
      other.effectivePort == effectivePort &&
      other.basePath == basePath;

  @override
  int get hashCode => Object.hash(scheme, host, effectivePort, basePath);

  @override
  String toString() => '$scheme://$displayHost$basePath';

  /// Parses messy pasted input into candidate endpoints and any credentials
  /// found in it (brief section 5.2). Pure; never throws.
  static ServerInput parse(String raw) => _parse(raw);
}

/// What the user most likely gave us.
enum InputKind { xtream, m3uLink }

@immutable
class ServerInput {
  const ServerInput({
    this.candidates = const [],
    this.username,
    this.password,
    this.credentialsFromLink = false,
    this.looksLikePortal = false,
    this.kind = InputKind.xtream,
    this.error,
    this.cleaned = '',
  });

  /// Endpoints to try, in order. Empty when [error] is set.
  final List<ServerEndpoint> candidates;
  final String? username;
  final String? password;

  /// Credentials were extracted from a pasted link: the UI fills them in
  /// and says "We found your login details in that link and filled them in."
  final bool credentialsFromLink;

  /// `/c/`, `portal.php` and similar: Stalker/MAG, not supported in v1.
  final bool looksLikePortal;

  /// A playlist link (e.g. a `.m3u` URL with no Xtream credentials).
  final InputKind kind;
  final ConnectionError? error;

  /// The input after invisible characters and wrapping quotes were removed.
  final String cleaned;

  bool get isValid => error == null && candidates.isNotEmpty;

  static const foundCredentialsMessage =
      'We found your login details in that link and filled them in.';
}

const _knownFiles = {
  'player_api.php',
  'get.php',
  'xmltv.php',
  'panel_api.php',
  'portal.php',
  'server_load.php',
};

const _streamRoots = {'live', 'movie', 'series', 'timeshift'};
const _unsupportedSchemes = {
  'rtmp',
  'rtmps',
  'rtsp',
  'rtp',
  'udp',
  'mms',
  'mmsh',
  'srt',
  'ftp',
  'file',
  'smb',
};

ServerInput _invalid(String cleaned, String why) => ServerInput(
  cleaned: cleaned,
  error: ConnectionError(ConnectionErrorKind.invalidInput, details: why),
);

final _schemeRe = RegExp(r'^([a-zA-Z][a-zA-Z0-9+.\-]*):');
final _ipv4Re = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$');
final _labelRe = RegExp(r'^[a-z0-9]([a-z0-9\-_]*[a-z0-9])?$');

ServerInput _parse(String raw) {
  var s = cleanPastedAddress(raw);
  final cleaned = s;
  if (s.isEmpty) return _invalid(cleaned, 'empty');

  // A pasted value can contain a trailing label or several lines; take the
  // first token that looks like an address.
  if (s.contains('\n')) {
    s = s
        .split(RegExp(r'[\r\n]+'))
        .firstWhere((l) => l.trim().isNotEmpty, orElse: () => s)
        .trim();
  }

  // Scheme handling. Fix "http:/host" and "http//host" typos.
  String? givenScheme;
  final fixed = s.replaceFirstMapped(
    RegExp(r'^(https?)(:/(?!/)|//)', caseSensitive: false),
    (m) => '${m[1]}://',
  );
  s = fixed;
  final sm = _schemeRe.firstMatch(s);
  if (sm != null && s.substring(sm.end).startsWith('//')) {
    final scheme = sm[1]!.toLowerCase();
    if (_unsupportedSchemes.contains(scheme)) {
      return _invalid(cleaned, 'unsupported scheme $scheme');
    }
    if (scheme != 'http' && scheme != 'https') {
      return _invalid(cleaned, 'unsupported scheme $scheme');
    }
    givenScheme = scheme;
    s = s.substring(sm.end + 2);
  } else if (sm != null && _unsupportedSchemes.contains(sm[1]!.toLowerCase())) {
    return _invalid(cleaned, 'unsupported scheme ${sm[1]}');
  }

  // Split authority from the rest manually so odd characters in a pasted
  // password don't confuse Uri.parse.
  final slash = s.indexOf(RegExp(r'[/?#]'));
  var authority = slash < 0 ? s : s.substring(0, slash);
  final rest = slash < 0 ? '' : s.substring(slash);

  String? user;
  String? pass;
  final at = authority.lastIndexOf('@');
  if (at >= 0) {
    final info = authority.substring(0, at);
    authority = authority.substring(at + 1);
    final colon = info.indexOf(':');
    String dec(String v) {
      try {
        return Uri.decodeComponent(v);
      } catch (_) {
        return v;
      }
    }

    user = dec(colon < 0 ? info : info.substring(0, colon));
    pass = colon < 0 ? null : dec(info.substring(colon + 1));
  }

  // Host and port.
  String host;
  int? port;
  if (authority.startsWith('[')) {
    final close = authority.indexOf(']');
    if (close < 0) return _invalid(cleaned, 'unclosed IPv6 bracket');
    host = authority.substring(1, close);
    final after = authority.substring(close + 1);
    if (after.isNotEmpty) {
      if (!after.startsWith(':')) return _invalid(cleaned, 'bad IPv6 port');
      port = int.tryParse(after.substring(1));
      if (port == null) return _invalid(cleaned, 'bad port');
    }
    if (!host.contains(':')) return _invalid(cleaned, 'bad IPv6 literal');
  } else {
    final colon = authority.lastIndexOf(':');
    if (colon >= 0 && authority.indexOf(':') == colon) {
      final p = authority.substring(colon + 1).trim();
      host = authority.substring(0, colon);
      if (p.isNotEmpty) {
        port = int.tryParse(p);
        if (port == null) return _invalid(cleaned, 'port is not a number');
      }
    } else if (colon >= 0) {
      // Bare IPv6 without brackets: accept if it parses as an address.
      host = authority;
      if (Uri.tryParse('http://[$host]/') == null) {
        return _invalid(cleaned, 'bad host');
      }
    } else {
      host = authority;
    }
  }
  if (port != null && (port < 1 || port > 65535)) {
    return _invalid(cleaned, 'port out of range');
  }

  host = host.trim();
  if (host.endsWith('.')) host = host.substring(0, host.length - 1);
  if (host.isEmpty) return _invalid(cleaned, 'empty host');
  if (host.contains(RegExp(r'\s'))) return _invalid(cleaned, 'space in host');

  final isIpv6 = host.contains(':');
  if (!isIpv6) {
    try {
      host = hostToAscii(host);
    } catch (_) {
      return _invalid(cleaned, 'bad international host');
    }
    final isIpv4 = _ipv4Re.hasMatch(host);
    if (isIpv4) {
      if (host.split('.').any((o) => int.parse(o) > 255)) {
        return _invalid(cleaned, 'bad IPv4');
      }
    } else {
      final labels = host.split('.');
      if (labels.any((l) => l.isEmpty || l.length > 63)) {
        return _invalid(cleaned, 'empty label');
      }
      if (!labels.every(_labelRe.hasMatch)) {
        return _invalid(cleaned, 'invalid characters in host');
      }
      // A single-label name is only accepted with an explicit port
      // (e.g. a box on the home network) or as localhost.
      if (labels.length == 1 && host != 'localhost' && port == null) {
        return _invalid(cleaned, 'not a full host name');
      }
      // All-numeric TLD that isn't an IPv4 is not a host.
      if (labels.length > 1 && RegExp(r'^\d+$').hasMatch(labels.last)) {
        return _invalid(cleaned, 'not a host');
      }
    }
  } else {
    host = host.toLowerCase();
  }

  // Path and query.
  final restUri = Uri.tryParse(rest.isEmpty ? '/' : rest);
  var segments = <String>[];
  var query = <String, String>{};
  if (restUri != null) {
    segments = restUri.pathSegments.where((p) => p.isNotEmpty).toList();
    try {
      query = restUri.queryParameters;
    } catch (_) {
      query = {};
    }
  } else {
    segments = rest
        .split(RegExp(r'[?#]'))
        .first
        .split('/')
        .where((p) => p.isNotEmpty)
        .toList();
  }

  var looksLikePortal = false;
  var kind = InputKind.xtream;
  final lower = segments.map((p) => p.toLowerCase()).toList();

  var cut = lower.indexWhere(_knownFiles.contains);
  if (cut >= 0 && lower[cut] == 'portal.php') looksLikePortal = true;
  final cIdx = lower.indexOf('c');
  if (cIdx >= 0 && (cut < 0 || cIdx < cut)) {
    looksLikePortal = true;
    cut = cIdx;
  }
  if (lower.contains('stalker_portal')) {
    looksLikePortal = true;
    cut = lower.indexOf('stalker_portal');
  }

  // Pasted stream URL: /live/U/P/123.ts -> base + credentials.
  final rootIdx = lower.indexWhere(_streamRoots.contains);
  if (rootIdx >= 0 && (cut < 0 || rootIdx < cut)) {
    if (segments.length >= rootIdx + 3) {
      user ??= segments[rootIdx + 1];
      pass ??= segments[rootIdx + 2];
    }
    cut = rootIdx;
  }

  if (cut >= 0) segments = segments.sublist(0, cut);

  final qUser = query['username'] ?? query['user'];
  final qPass = query['password'] ?? query['pass'];
  if (qUser != null && qUser.isNotEmpty) user = qUser;
  if (qPass != null && qPass.isNotEmpty) pass = qPass;

  // A direct playlist file with no Xtream credentials is an M3U link.
  final last = lower.isEmpty ? '' : lower.last;
  if ((last.endsWith('.m3u') || last.endsWith('.m3u8')) &&
      (user == null || pass == null)) {
    kind = InputKind.m3uLink;
  }

  final basePath = segments.isEmpty ? '' : '/${segments.join('/')}';
  final schemes = givenScheme == null
      ? const ['http', 'https']
      : [givenScheme, givenScheme == 'http' ? 'https' : 'http'];

  final candidates = [
    for (final sc in schemes)
      ServerEndpoint(scheme: sc, host: host, port: port, basePath: basePath),
  ];

  final foundCreds = user != null && pass != null;
  return ServerInput(
    cleaned: cleaned,
    candidates: candidates,
    username: user == null ? null : cleanCredential(user),
    password: pass == null ? null : cleanCredential(pass),
    credentialsFromLink: foundCreds,
    looksLikePortal: looksLikePortal,
    kind: kind,
  );
}
