import 'dart:convert';
import 'dart:typed_data';

import '../../core/utils/text_clean.dart';

/// Result of decoding a provider response body regardless of Content-Type
/// (brief section 5.3 step 2).
sealed class BodyDecode {
  const BodyDecode();
}

class JsonBody extends BodyDecode {
  const JsonBody(this.value, {this.hadJunkPrefix = false});
  final Object? value;
  final bool hadJunkPrefix;
}

class HtmlBody extends BodyDecode {
  const HtmlBody(this.snippet, {this.cloudflare = false});
  final String snippet;

  /// A bot-check / challenge page: a different user-agent may get through.
  final bool cloudflare;
}

class EmptyBody extends BodyDecode {
  const EmptyBody();
}

class MalformedBody extends BodyDecode {
  const MalformedBody(this.detail);
  final String detail;
}

/// Decodes bytes as JSON tolerantly:
/// * strips a UTF-8 BOM and leading whitespace
/// * if the body starts with `<`, it's HTML
/// * if there's junk (e.g. a PHP warning) before the first `{` or `[`,
///   skips it and tries again; also trims junk after the last `}` / `]`
BodyDecode decodeProviderBody(Uint8List bytes) {
  var text = utf8.decode(bytes, allowMalformed: true);
  if (text.startsWith('﻿')) text = text.substring(1);
  text = text.trimLeft();
  if (text.isEmpty) return const EmptyBody();

  if (text.startsWith('<')) {
    final lower = text.length > 4000
        ? text.substring(0, 4000).toLowerCase()
        : text.toLowerCase();
    final cf =
        lower.contains('cloudflare') ||
        lower.contains('cf-ray') ||
        lower.contains('attention required') ||
        lower.contains('just a moment') ||
        lower.contains('challenge-platform');
    // Some panels prefix JSON with an HTML warning block: look for JSON.
    final j = _tryEmbedded(text);
    if (j != null && !cf) return JsonBody(j, hadJunkPrefix: true);
    return HtmlBody(_snippet(text), cloudflare: cf);
  }

  try {
    return JsonBody(jsonDecode(text));
  } on FormatException {
    final j = _tryEmbedded(text);
    if (j != null) return JsonBody(j, hadJunkPrefix: true);
    return MalformedBody('not JSON: ${_snippet(text)}');
  }
}

Object? _tryEmbedded(String text) {
  final brace = text.indexOf('{');
  final bracket = text.indexOf('[');
  final starts = [brace, bracket].where((i) => i >= 0).toList()..sort();
  for (final start in starts) {
    final open = text[start];
    final close = open == '{' ? '}' : ']';
    final end = text.lastIndexOf(close);
    if (end <= start) continue;
    try {
      return jsonDecode(text.substring(start, end + 1));
    } on FormatException {
      continue;
    }
  }
  return null;
}

String _snippet(String s) {
  final one = s.replaceAll(RegExp(r'\s+'), ' ');
  return one.length > 160 ? '${one.substring(0, 160)}…' : one;
}

// ---- Value coercion for inconsistent provider JSON -------------------------

int? asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.isFinite ? v.toInt() : null;
  if (v is bool) return v ? 1 : 0;
  if (v is String) {
    final t = v.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t) ?? double.tryParse(t)?.toInt();
  }
  return null;
}

double? asDouble(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim().replaceAll(',', '.'));
  return null;
}

/// Strings, numbers and bools become strings; `false`, `null`, `[]`, `{}`
/// and empty strings become null.
String? asString(Object? v) {
  if (v == null || v == false) return null;
  if (v is String) {
    final t = v.trim();
    return t.isEmpty ? null : t;
  }
  if (v is num || v == true) return '$v';
  return null;
}

bool asBool(Object? v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final t = v.trim().toLowerCase();
    return t == '1' || t == 'true' || t == 'yes' || t == 'on';
  }
  return false;
}

/// Tri-state for fields like `auth` where "missing" matters.
bool? asBoolOrNull(Object? v) {
  if (v == null) return null;
  if (v is String && v.trim().isEmpty) return null;
  return asBool(v);
}

/// Lists stay lists; maps become their values (some panels key lists by
/// index); anything else (`false`, `null`, `""`) is an empty list.
List<Object?> asList(Object? v) {
  if (v is List) return v;
  if (v is Map) return v.values.toList();
  return const [];
}

Map<String, Object?> asMap(Object? v) {
  if (v is Map) {
    return {for (final e in v.entries) '${e.key}': e.value};
  }
  return const {};
}

List<String> asStringList(Object? v) {
  if (v is String) {
    final t = v.trim();
    if (t.isEmpty) return const [];
    return t
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
  return asList(v).map(asString).whereType<String>().toList();
}

/// A display name: entities decoded, whitespace collapsed, capped length.
String? asName(Object? v, {int maxLength = 200}) {
  final s = asString(v);
  if (s == null) return null;
  final d = decodeHtmlEntities(s).replaceAll(RegExp(r'\s+'), ' ').trim();
  if (d.isEmpty) return null;
  if (d.runes.length <= maxLength) return d;
  return '${String.fromCharCodes(d.runes.take(maxLength))}…';
}

/// Absolute http(s) image URL, or null for empty / invalid values.
String? asImageUrl(Object? v) {
  final s = asString(v);
  if (s == null) return null;
  final u = Uri.tryParse(s.replaceAll(' ', '%20'));
  if (u == null || !u.hasAuthority || u.host.isEmpty) return null;
  if (u.scheme != 'http' && u.scheme != 'https') return null;
  return u.toString();
}

/// Unix timestamp (s or ms, number or string) to UTC; 0/empty is null.
DateTime? asUnixTime(Object? v) {
  final n = asDouble(v);
  if (n == null || n <= 0) return null;
  final ms = n > 1e12 ? n : n * 1000;
  return DateTime.fromMillisecondsSinceEpoch(ms.round(), isUtc: true);
}

/// Base64 that providers send in `get_short_epg`; falls back to the raw
/// text when it isn't valid base64.
String decodeMaybeBase64(Object? v) {
  final s = asString(v);
  if (s == null) return '';
  try {
    var t = s
        .replaceAll(RegExp(r'\s'), '')
        .replaceAll('-', '+')
        .replaceAll('_', '/');
    if (!RegExp(r'^[A-Za-z0-9+/]*={0,2}$').hasMatch(t)) return s;
    while (t.length % 4 != 0) {
      t += '=';
    }
    return utf8.decode(base64.decode(t), allowMalformed: false).trim();
  } catch (_) {
    return s;
  }
}
