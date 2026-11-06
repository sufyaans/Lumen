/// Tolerant parsers for Xtream `player_api.php` responses (brief 5.4).
///
/// All are top-level pure functions so they can run in an isolate. They
/// never throw on odd shapes: wrong types, `false` for empty lists, missing
/// keys, duplicate ids, empty names and HTML entities are all handled.
library;

import 'dart:isolate';
import 'dart:typed_data';

import 'tolerant_json.dart';
import 'xtream_models.dart';

List<XCategory> parseCategories(Object? json) {
  final seen = <String>{};
  final out = <XCategory>[];
  for (final raw in asList(json)) {
    final m = asMap(raw);
    final id = asString(m['category_id']);
    if (id == null || !seen.add(id)) continue;
    out.add(
      XCategory(
        id: id,
        name: asName(m['category_name']) ?? 'Other',
        parentId: asString(m['parent_id']),
      ),
    );
  }
  return out;
}

List<XLiveStream> parseLiveStreams(Object? json) {
  final seen = <int>{};
  final out = <XLiveStream>[];
  for (final raw in asList(json)) {
    final m = asMap(raw);
    final id = asInt(m['stream_id']);
    if (id == null || !seen.add(id)) continue;
    final num = asInt(m['num']);
    final cats = asStringList(m['category_ids']);
    out.add(
      XLiveStream(
        streamId: id,
        name: asName(m['name']) ?? (num != null ? 'Channel $num' : 'Channel'),
        num: num,
        icon: asImageUrl(m['stream_icon']),
        epgChannelId: asString(m['epg_channel_id']),
        categoryId: asString(m['category_id']) ?? cats.firstOrNull,
        categoryIds: cats,
        tvArchive: asBool(m['tv_archive']),
        tvArchiveDays: asInt(m['tv_archive_duration']) ?? 0,
        directSource: asString(m['direct_source']),
        added: asUnixTime(m['added']),
      ),
    );
  }
  return out;
}

String _ext(Object? v, {String fallback = 'mp4'}) {
  final s = asString(v)?.toLowerCase().replaceAll('.', '');
  if (s == null || !RegExp(r'^[a-z0-9]{1,6}$').hasMatch(s)) return fallback;
  return s;
}

int? _year(Object? v) {
  final s = asString(v);
  if (s == null) return null;
  final m = RegExp(r'(19|20)\d{2}').firstMatch(s);
  return m == null ? null : int.parse(m[0]!);
}

List<XVod> parseVodStreams(Object? json) {
  final seen = <int>{};
  final out = <XVod>[];
  for (final raw in asList(json)) {
    final m = asMap(raw);
    final id = asInt(m['stream_id']);
    if (id == null || !seen.add(id)) continue;
    final name = asName(m['name']) ?? 'Untitled';
    out.add(
      XVod(
        streamId: id,
        name: name,
        icon: asImageUrl(m['stream_icon']),
        categoryId: asString(m['category_id']),
        containerExtension: _ext(m['container_extension']),
        rating: asDouble(m['rating']),
        added: asUnixTime(m['added']),
        directSource: asString(m['direct_source']),
        year: _year(m['year']) ?? _year(m['release_date']) ?? _year(name),
      ),
    );
  }
  return out;
}

List<XSeries> parseSeriesList(Object? json) {
  final seen = <int>{};
  final out = <XSeries>[];
  for (final raw in asList(json)) {
    final m = asMap(raw);
    final id = asInt(m['series_id']);
    if (id == null || !seen.add(id)) continue;
    final backdrop = m['backdrop_path'];
    out.add(
      XSeries(
        seriesId: id,
        name: asName(m['name']) ?? 'Untitled',
        cover: asImageUrl(m['cover']),
        plot: asName(m['plot'], maxLength: 2000),
        genre: asName(m['genre']),
        releaseDate: asString(m['releaseDate']) ?? asString(m['release_date']),
        rating: asDouble(m['rating']),
        categoryId: asString(m['category_id']),
        lastModified: asUnixTime(m['last_modified']),
        backdrop: asImageUrl(
          backdrop is List ? backdrop.firstOrNull : backdrop,
        ),
      ),
    );
  }
  return out;
}

XEpisode? _episode(Object? raw, int fallbackSeason, int fallbackNum) {
  final m = asMap(raw);
  final id = asString(m['id']) ?? asString(m['stream_id']);
  if (id == null) return null;
  final info = asMap(m['info']);
  final num = asInt(m['episode_num']) ?? fallbackNum;
  final season = asInt(m['season']) ?? fallbackSeason;
  return XEpisode(
    id: id,
    season: season,
    episodeNum: num,
    title: asName(m['title']) ?? 'Episode $num',
    containerExtension: _ext(m['container_extension']),
    plot: asName(info['plot'], maxLength: 2000),
    durationSecs: asInt(info['duration_secs']),
    image: asImageUrl(info['movie_image']),
  );
}

/// `episodes` is a map keyed by season number in most panels, but a plain
/// list (or list of lists) when there is one season.
XSeriesInfo parseSeriesInfo(Object? json) {
  final m = asMap(json);
  final info = asMap(m['info']);
  final bySeason = <int, Map<String, XEpisode>>{};

  void add(XEpisode? e) {
    if (e == null) return;
    (bySeason[e.season] ??= {})[e.id] ??= e;
  }

  final eps = m['episodes'];
  if (eps is Map) {
    for (final entry in eps.entries) {
      final season = asInt(entry.key) ?? 1;
      for (final (i, raw) in asList(entry.value).indexed) {
        add(_episode(raw, season, i + 1));
      }
    }
  } else if (eps is List) {
    for (final (i, raw) in eps.indexed) {
      if (raw is List) {
        // [[s1e1, s1e2], [s2e1]]
        for (final (j, r) in raw.indexed) {
          add(_episode(r, i + 1, j + 1));
        }
      } else {
        add(_episode(raw, 1, i + 1));
      }
    }
  }

  final seasons = bySeason.keys.toList()..sort();
  return XSeriesInfo(
    name: asName(info['name']) ?? 'Untitled',
    plot: asName(info['plot'], maxLength: 2000),
    cover: asImageUrl(info['cover']),
    episodesBySeason: {
      for (final s in seasons)
        s: bySeason[s]!.values.toList()
          ..sort((a, b) => a.episodeNum.compareTo(b.episodeNum)),
    },
  );
}

XVodInfo? parseVodInfo(Object? json, {int? requestedId}) {
  final m = asMap(json);
  final info = asMap(m['info']);
  final data = asMap(m['movie_data']);
  final id = asInt(data['stream_id']) ?? requestedId;
  if (id == null) return null;
  return XVodInfo(
    streamId: id,
    name: asName(data['name']) ?? asName(info['name']) ?? 'Untitled',
    containerExtension: _ext(data['container_extension']),
    plot: asName(info['plot'] ?? info['description'], maxLength: 2000),
    durationSecs: asInt(info['duration_secs']),
    cover: asImageUrl(info['movie_image'] ?? info['cover_big']),
    genre: asName(info['genre']),
    releaseDate: asString(info['releasedate'] ?? info['release_date']),
  );
}

/// `get_short_epg`: titles/descriptions are base64. Uses the unix
/// `start_timestamp`/`stop_timestamp`, never the local-time strings.
List<XEpgEntry> parseShortEpg(Object? json) {
  final m = asMap(json);
  final listings = asList(m['epg_listings'] ?? json);
  final out = <XEpgEntry>[];
  for (final raw in listings) {
    final e = asMap(raw);
    final start = asUnixTime(e['start_timestamp']);
    final stop = asUnixTime(e['stop_timestamp']);
    if (start == null || stop == null || !stop.isAfter(start)) continue;
    out.add(
      XEpgEntry(
        title: decodeMaybeBase64(e['title']),
        description: decodeMaybeBase64(e['description']),
        start: start,
        stop: stop,
      ),
    );
  }
  out.sort((a, b) => a.start.compareTo(b.start));
  return out;
}

// ---- Isolate helpers -------------------------------------------------------

/// Decodes and parses a (possibly 50 MB+) body off the UI isolate.
/// Returns null when the body isn't JSON.
Future<List<T>?> parseListInIsolate<T>(
  Uint8List bytes,
  List<T> Function(Object? json) parse,
) => Isolate.run(() {
  final body = decodeProviderBody(bytes);
  if (body is! JsonBody) return null;
  return parse(body.value);
});
