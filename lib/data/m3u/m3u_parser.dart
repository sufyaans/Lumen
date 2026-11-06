/// Streaming, tolerant M3U / M3U8 playlist parser (brief section 5.5).
library;

import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import '../../core/network/connection_error.dart';
import '../../core/utils/text_clean.dart';

enum M3uKind { live, movie, series }

@immutable
class M3uEntry {
  const M3uEntry({
    required this.name,
    required this.url,
    required this.kind,
    this.group,
    this.tvgId,
    this.tvgName,
    this.logo,
    this.channelNumber,
    this.catchup,
    this.catchupDays,
    this.catchupSource,
    this.headers = const {},
  });

  final String name;
  final String url;
  final M3uKind kind;
  final String? group;
  final String? tvgId;
  final String? tvgName;
  final String? logo;
  final int? channelNumber;
  final String? catchup;
  final int? catchupDays;
  final String? catchupSource;

  /// HTTP headers the player must send for this entry, from
  /// `#EXTVLCOPT`, `#EXTHTTP`, `#KODIPROP` and `url|Header=value`.
  final Map<String, String> headers;
}

@immutable
class M3uPlaylist {
  const M3uPlaylist({required this.entries, this.epgUrl, this.encoding});

  final List<M3uEntry> entries;

  /// From `url-tvg` / `x-tvg-url` in the `#EXTM3U` header.
  final String? epgUrl;

  /// Detected text encoding, for diagnostics.
  final String? encoding;

  int count(M3uKind k) => entries.where((e) => e.kind == k).length;
}

/// Thrown (as [ConnectionError] with kind m3uInvalid) for non-playlists.
ConnectionError notAPlaylist(String why) =>
    ConnectionError(ConnectionErrorKind.m3uInvalid, details: why);

/// Parses in a background isolate so the UI stays at 60 fps.
Future<M3uPlaylist> parseM3uInIsolate(Uint8List bytes) =>
    Isolate.run(() => parseM3u(bytes));

// ---- Encoding --------------------------------------------------------------

/// Windows-1252 code points for bytes 0x80..0x9F (others match Latin-1).
const _cp1252 = [
  0x20AC, 0x0081, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021, //
  0x02C6, 0x2030, 0x0160, 0x2039, 0x0152, 0x008D, 0x017D, 0x008F,
  0x0090, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014,
  0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, 0x009D, 0x017E, 0x0178,
];

String decodeWindows1252(List<int> bytes) {
  final b = StringBuffer();
  for (final c in bytes) {
    b.writeCharCode(c >= 0x80 && c <= 0x9F ? _cp1252[c - 0x80] : c);
  }
  return b.toString();
}

/// UTF-8 (with or without BOM), UTF-16 with BOM, else Windows-1252.
(String, String) decodePlaylistText(Uint8List bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xEF &&
      bytes[1] == 0xBB &&
      bytes[2] == 0xBF) {
    return (utf8.decode(bytes.sublist(3), allowMalformed: true), 'utf-8-bom');
  }
  if (bytes.length >= 2 &&
      ((bytes[0] == 0xFF && bytes[1] == 0xFE) ||
          (bytes[0] == 0xFE && bytes[1] == 0xFF))) {
    final le = bytes[0] == 0xFF;
    final units = <int>[];
    for (var i = 2; i + 1 < bytes.length; i += 2) {
      units.add(
        le ? bytes[i] | (bytes[i + 1] << 8) : (bytes[i] << 8) | bytes[i + 1],
      );
    }
    return (String.fromCharCodes(units), le ? 'utf-16le' : 'utf-16be');
  }
  try {
    return (utf8.decode(bytes), 'utf-8');
  } on FormatException {
    return (decodeWindows1252(bytes), 'windows-1252');
  }
}

// ---- Parsing ---------------------------------------------------------------

/// Parses `key="value"` / `key=value` attributes starting at [start].
/// Returns the attributes and the index just after the attribute block.
(Map<String, String>, int) _parseAttributes(String s, int start) {
  final attrs = <String, String>{};
  var i = start;
  final n = s.length;
  while (i < n) {
    while (i < n && (s[i] == ' ' || s[i] == '\t')) {
      i++;
    }
    if (i >= n || s[i] == ',') break;
    final keyStart = i;
    while (i < n && s[i] != '=' && s[i] != ' ' && s[i] != ',') {
      i++;
    }
    if (i >= n || s[i] != '=') {
      // Not an attribute (bare token); stop the block here.
      i = keyStart;
      break;
    }
    final key = s.substring(keyStart, i).toLowerCase();
    i++; // '='
    String value;
    if (i < n && (s[i] == '"' || s[i] == "'")) {
      final q = s[i];
      final close = s.indexOf(q, i + 1);
      if (close < 0) {
        value = s.substring(i + 1);
        i = n;
      } else {
        value = s.substring(i + 1, close);
        i = close + 1;
      }
    } else {
      final vs = i;
      while (i < n && s[i] != ' ' && s[i] != ',') {
        i++;
      }
      value = s.substring(vs, i);
    }
    attrs[key] = decodeHtmlEntities(value.trim());
  }
  return (attrs, i);
}

class _Pending {
  String? name;
  Map<String, String> attrs = const {};
  String? group;
  final headers = <String, String>{};
}

void _addVlcOpt(String opt, Map<String, String> h) {
  final eq = opt.indexOf('=');
  if (eq < 0) return;
  final k = opt.substring(0, eq).trim().toLowerCase();
  final v = opt.substring(eq + 1).trim();
  if (v.isEmpty) return;
  switch (k) {
    case 'http-user-agent':
      h['User-Agent'] = v;
    case 'http-referrer':
    case 'http-referer':
      h['Referer'] = v;
    case 'http-origin':
      h['Origin'] = v;
    case 'http-cookie':
      h['Cookie'] = v;
  }
}

String _canonicalHeader(String k) {
  final lower = k.trim().toLowerCase();
  return switch (lower) {
    'user-agent' => 'User-Agent',
    'referer' || 'referrer' => 'Referer',
    'origin' => 'Origin',
    'cookie' => 'Cookie',
    _ => k.trim(),
  };
}

void _addHeaderPairs(String pairs, Map<String, String> h) {
  for (final part in pairs.split('&')) {
    final eq = part.indexOf('=');
    if (eq <= 0) continue;
    var v = part.substring(eq + 1);
    try {
      v = Uri.decodeComponent(v);
    } catch (_) {}
    if (v.trim().isEmpty) continue;
    h[_canonicalHeader(part.substring(0, eq))] = v.trim();
  }
}

M3uKind _kindFor(String url) {
  final l = url.toLowerCase();
  if (l.contains('/movie/')) return M3uKind.movie;
  if (l.contains('/series/')) return M3uKind.series;
  return M3uKind.live;
}

String _nameFromUrl(String url) {
  final u = Uri.tryParse(url);
  final last = u?.pathSegments.where((s) => s.isNotEmpty).lastOrNull;
  if (last == null || last.isEmpty) return 'Untitled';
  return last.replaceAll(RegExp(r'\.[a-z0-9]{2,5}$', caseSensitive: false), '');
}

/// Parses playlist bytes. Throws [ConnectionError] (m3uInvalid) when the
/// content isn't a playlist.
M3uPlaylist parseM3u(Uint8List bytes) {
  final (text, encoding) = decodePlaylistText(bytes);
  return parseM3uText(text, encoding: encoding);
}

M3uPlaylist parseM3uText(String text, {String? encoding}) {
  var body = text;
  if (body.startsWith('﻿')) body = body.substring(1);
  final head = body.trimLeft();
  final hasHeader =
      head.length >= 7 && head.substring(0, 7).toUpperCase() == '#EXTM3U';
  if (!hasHeader && !body.contains('#EXTINF')) {
    throw notAPlaylist('no #EXTM3U header and no #EXTINF lines');
  }

  String? epgUrl;
  final entries = <M3uEntry>[];
  _Pending? p;
  const ls = LineSplitter();

  for (final rawLine in ls.convert(body)) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;

    if (line.startsWith('#')) {
      final upper = line.length >= 8
          ? line.substring(0, 8).toUpperCase()
          : line.toUpperCase();
      if (upper.startsWith('#EXTM3U')) {
        final (attrs, _) = _parseAttributes(line, 7);
        final tvg = attrs['url-tvg'] ?? attrs['x-tvg-url'] ?? attrs['tvg-url'];
        if (tvg != null && tvg.isNotEmpty) {
          epgUrl ??= tvg.split(',').first.trim();
        }
      } else if (upper.startsWith('#EXTINF')) {
        final colon = line.indexOf(':');
        // Options that came before #EXTINF still belong to this entry.
        final prev = p;
        p = _Pending();
        if (prev != null && prev.name == null) {
          p.headers.addAll(prev.headers);
          p.group = prev.group;
        }
        if (colon < 0) continue;
        // Duration token, then attributes, then ",Name".
        var i = colon + 1;
        while (i < line.length && line[i] != ' ' && line[i] != ',') {
          i++;
        }
        final (attrs, end) = _parseAttributes(line, i);
        p.attrs = attrs;
        final comma = line.indexOf(',', end);
        if (comma >= 0) {
          p.name = decodeHtmlEntities(line.substring(comma + 1).trim());
        }
      } else if (upper.startsWith('#EXTGRP')) {
        final c = line.indexOf(':');
        if (c >= 0) (p ??= _Pending()).group = line.substring(c + 1).trim();
      } else if (upper.startsWith('#EXTVLCO')) {
        final c = line.indexOf(':');
        if (c >= 0) {
          _addVlcOpt(line.substring(c + 1), (p ??= _Pending()).headers);
        }
      } else if (upper.startsWith('#EXTHTTP')) {
        final c = line.indexOf(':');
        if (c >= 0) {
          try {
            final j = jsonDecode(line.substring(c + 1).trim());
            if (j is Map) {
              for (final e in j.entries) {
                final v = '${e.value}'.trim();
                if (v.isNotEmpty) {
                  (p ??= _Pending()).headers[_canonicalHeader('${e.key}')] = v;
                }
              }
            }
          } catch (_) {}
        }
      } else if (upper.startsWith('#KODIPRO')) {
        final c = line.indexOf(':');
        if (c >= 0) {
          final prop = line.substring(c + 1);
          const key = 'inputstream.adaptive.stream_headers=';
          final k = prop.toLowerCase().indexOf(key);
          if (k >= 0) {
            _addHeaderPairs(
              prop.substring(k + key.length),
              (p ??= _Pending()).headers,
            );
          }
        }
      }
      continue;
    }

    // A URL line.
    var url = line;
    final headers = <String, String>{...?p?.headers};
    final pipe = url.indexOf('|');
    if (pipe > 0) {
      _addHeaderPairs(url.substring(pipe + 1), headers);
      url = url.substring(0, pipe).trim();
    }
    if (!url.contains('://')) {
      p = null;
      continue;
    }

    final a = p?.attrs ?? const <String, String>{};
    final rawName = p?.name;
    final name = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : (a['tvg-name']?.isNotEmpty ?? false)
        ? a['tvg-name']!
        : _nameFromUrl(url);
    final group = a['group-title']?.trim();
    entries.add(
      M3uEntry(
        name: name,
        url: url,
        kind: _kindFor(url),
        group: (group != null && group.isNotEmpty) ? group : p?.group,
        tvgId: _nz(a['tvg-id']),
        tvgName: _nz(a['tvg-name']),
        logo: _nz(a['tvg-logo'] ?? a['logo']),
        channelNumber: int.tryParse(a['tvg-chno'] ?? a['channel-number'] ?? ''),
        catchup: _nz(a['catchup']),
        catchupDays: int.tryParse(a['catchup-days'] ?? ''),
        catchupSource: _nz(a['catchup-source']),
        headers: Map.unmodifiable(headers),
      ),
    );
    p = null;
  }

  if (entries.isEmpty && !hasHeader) {
    throw notAPlaylist('no playable entries');
  }
  return M3uPlaylist(entries: entries, epgUrl: epgUrl, encoding: encoding);
}

String? _nz(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
