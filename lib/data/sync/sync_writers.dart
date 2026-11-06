/// Bulk catalogue writes. Every function here takes the database as a
/// parameter and is designed to run inside [GeneratedDatabase.computeWithDatabase]
/// so decoding, parsing and SQL all happen off the UI isolate (brief 4).
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/content_filters.dart';
import '../db/app_database.dart';
import '../db/secret_template.dart';
import '../db/tables.dart';
import '../m3u/m3u_parser.dart';
import '../xtream/tolerant_json.dart';
import '../xtream/xtream_models.dart';
import '../xtream/xtream_parsers.dart';

const _chunk = 1000;

Future<void> _batched<T extends Table, R>(
  AppDatabase db,
  TableInfo<T, R> table,
  List<Insertable<R>> rows,
) async {
  for (var i = 0; i < rows.length; i += _chunk) {
    final end = i + _chunk > rows.length ? rows.length : i + _chunk;
    await db.batch(
      (b) => b.insertAllOnConflictUpdate(table, rows.sublist(i, end)),
    );
  }
}

/// Upserts categories and returns the ids flagged as adult.
Future<Set<String>> writeCategories(
  AppDatabase db, {
  required String providerId,
  required String kind,
  required List<XCategory> categories,
  required int token,
}) async {
  final adult = <String>{};
  await db.transaction(() async {
    await _batched(db, db.categories, [
      for (final (i, c) in categories.indexed)
        CategoriesCompanion.insert(
          providerId: providerId,
          kind: kind,
          remoteId: c.id,
          name: c.name,
          isAdult: Value(isAdultCategory(c.name) && adult.add(c.id)),
          isKids: Value(isKidsCategory(c.name)),
          sortOrder: Value(i),
          syncToken: Value(token),
        ),
    ]);
    await (db.delete(db.categories)..where(
          (t) =>
              t.providerId.equals(providerId) &
              t.kind.equals(kind) &
              t.syncToken.equals(token).not(),
        ))
        .go();
  });
  return adult;
}

/// Parses Xtream list bodies of one kind and upserts them in batches.
/// Stale rows are removed only when [complete] (every category fetched).
/// Returns the number of distinct items written.
Future<int> writeXtreamList(
  AppDatabase db, {
  required String providerId,
  required String kind,
  required List<Uint8List> bodies,
  required int token,
  required Set<String> adultCategoryIds,
  required bool complete,
}) async {
  var count = 0;
  final seen = <String>{};
  await db.transaction(() async {
    for (final body in bodies) {
      final decoded = decodeProviderBody(body);
      if (decoded is! JsonBody) continue;
      final json = decoded.value;
      switch (kind) {
        case ContentKind.live:
          final rows = <ChannelsCompanion>[];
          for (final s in parseLiveStreams(json)) {
            final id = '${s.streamId}';
            if (!seen.add(id)) continue;
            rows.add(
              ChannelsCompanion.insert(
                providerId: providerId,
                remoteId: id,
                name: s.name,
                number: Value(s.num),
                logo: Value(s.icon),
                epgId: Value(s.epgChannelId),
                categoryId: Value(s.categoryId),
                tvArchive: Value(s.tvArchive),
                archiveDays: Value(s.tvArchiveDays),
                isAdult: Value(adultCategoryIds.contains(s.categoryId)),
                sortOrder: Value(s.num ?? seen.length),
                syncToken: Value(token),
              ),
            );
          }
          await _batched(db, db.channels, rows);
          count += rows.length;
        case ContentKind.movie:
          final rows = <MoviesCompanion>[];
          for (final s in parseVodStreams(json)) {
            final id = '${s.streamId}';
            if (!seen.add(id)) continue;
            rows.add(
              MoviesCompanion.insert(
                providerId: providerId,
                remoteId: id,
                name: s.name,
                poster: Value(s.icon),
                categoryId: Value(s.categoryId),
                containerExtension: Value(s.containerExtension),
                rating: Value(s.rating),
                year: Value(s.year),
                added: Value(s.added),
                isAdult: Value(adultCategoryIds.contains(s.categoryId)),
                sortOrder: Value(seen.length),
                syncToken: Value(token),
              ),
            );
          }
          await _batched(db, db.movies, rows);
          count += rows.length;
        case ContentKind.series:
          final rows = <SeriesTableCompanion>[];
          for (final s in parseSeriesList(json)) {
            final id = '${s.seriesId}';
            if (!seen.add(id)) continue;
            rows.add(
              SeriesTableCompanion.insert(
                providerId: providerId,
                remoteId: id,
                name: s.name,
                poster: Value(s.cover),
                backdrop: Value(s.backdrop),
                plot: Value(s.plot),
                genre: Value(s.genre),
                rating: Value(s.rating),
                year: Value(_year(s.releaseDate)),
                categoryId: Value(s.categoryId),
                lastModified: Value(s.lastModified),
                isAdult: Value(adultCategoryIds.contains(s.categoryId)),
                sortOrder: Value(seen.length),
                syncToken: Value(token),
              ),
            );
          }
          await _batched(db, db.seriesTable, rows);
          count += rows.length;
      }
    }
    if (complete) {
      await deleteStale(db, providerId: providerId, kind: kind, token: token);
    }
  });
  return count;
}

int? _year(String? s) {
  if (s == null) return null;
  final m = RegExp(r'(19|20)\d{2}').firstMatch(s);
  return m == null ? null : int.parse(m[0]!);
}

Future<void> deleteStale(
  AppDatabase db, {
  required String providerId,
  required String kind,
  required int token,
}) async {
  switch (kind) {
    case ContentKind.live:
      await (db.delete(db.channels)..where(
            (t) =>
                t.providerId.equals(providerId) &
                t.syncToken.equals(token).not(),
          ))
          .go();
    case ContentKind.movie:
      await (db.delete(db.movies)..where(
            (t) =>
                t.providerId.equals(providerId) &
                t.syncToken.equals(token).not(),
          ))
          .go();
    case ContentKind.series:
      await (db.delete(db.seriesTable)..where(
            (t) =>
                t.providerId.equals(providerId) &
                t.syncToken.equals(token).not(),
          ))
          .go();
  }
}

/// Rebuilds the FTS5 rows for one provider from the catalogue tables.
Future<void> rebuildSearchIndex(AppDatabase db, String providerId) =>
    db.transaction(() async {
      await db.customStatement(
        'DELETE FROM search_index WHERE provider_id = ?',
        [providerId],
      );
      for (final (kind, table) in const [
        (ContentKind.live, 'channels'),
        (ContentKind.movie, 'movies'),
        (ContentKind.series, 'series'),
      ]) {
        await db.customStatement(
          'INSERT INTO search_index(name, kind, provider_id, remote_id, '
          'category_id, is_adult) SELECT name, ?, provider_id, remote_id, '
          'category_id, is_adult FROM $table WHERE provider_id = ?',
          [kind, providerId],
        );
      }
    });

/// Summary of an M3U import.
class M3uImportResult {
  const M3uImportResult(this.live, this.movies, this.series, this.epgUrl);
  final int live;
  final int movies;
  final int series;
  final String? epgUrl;
}

/// Parses playlist bytes and writes categories (from `group-title`),
/// channels, movies and series. Known credentials in entry URLs are
/// replaced with placeholders (see [SecretTemplate]).
///
/// Entry ids: `tvg-id` when present and unique, else `group|name`, so
/// favourites and progress survive refreshes even when stream URLs carry
/// rotating tokens.
Future<M3uImportResult> writeM3u(
  AppDatabase db, {
  required String providerId,
  required Uint8List bytes,
  required int token,
  String? username,
  String? password,
}) async {
  final playlist = parseM3u(bytes);
  final groups = <String, Map<String, int>>{
    ContentKind.live: {},
    ContentKind.movie: {},
    ContentKind.series: {},
  };
  final ids = <String, Set<String>>{
    ContentKind.live: {},
    ContentKind.movie: {},
    ContentKind.series: {},
  };
  final live = <ChannelsCompanion>[];
  final movies = <MoviesCompanion>[];
  final series = <SeriesTableCompanion>[];

  for (final e in playlist.entries) {
    final kind = switch (e.kind) {
      M3uKind.live => ContentKind.live,
      M3uKind.movie => ContentKind.movie,
      M3uKind.series => ContentKind.series,
    };
    final group = e.group ?? 'Uncategorised';
    final g = groups[kind]!;
    g.putIfAbsent(group, () => g.length);
    final adult = isAdultCategory(group);

    var id = e.tvgId ?? '$group|${e.name}';
    if (ids[kind]!.contains(id)) {
      id = '$group|${e.name}';
      var n = 2;
      while (ids[kind]!.contains(id)) {
        id = '$group|${e.name}#${n++}';
      }
    }
    ids[kind]!.add(id);

    final url = SecretTemplate.encode(
      e.url,
      username: username,
      password: password,
    );
    final headers = e.headers.isEmpty ? null : jsonEncode(e.headers);
    switch (kind) {
      case ContentKind.live:
        live.add(
          ChannelsCompanion.insert(
            providerId: providerId,
            remoteId: id,
            name: e.name,
            number: Value(e.channelNumber),
            logo: Value(e.logo),
            epgId: Value(e.tvgId),
            categoryId: Value(group),
            tvArchive: Value(e.catchup != null),
            archiveDays: Value(e.catchupDays ?? 0),
            url: Value(url),
            headersJson: Value(headers),
            isAdult: Value(adult),
            sortOrder: Value(e.channelNumber ?? live.length),
            syncToken: Value(token),
          ),
        );
      case ContentKind.movie:
        movies.add(
          MoviesCompanion.insert(
            providerId: providerId,
            remoteId: id,
            name: e.name,
            poster: Value(e.logo),
            categoryId: Value(group),
            url: Value(url),
            headersJson: Value(headers),
            isAdult: Value(adult),
            sortOrder: Value(movies.length),
            syncToken: Value(token),
          ),
        );
      default:
        series.add(
          SeriesTableCompanion.insert(
            providerId: providerId,
            remoteId: id,
            name: e.name,
            poster: Value(e.logo),
            categoryId: Value(group),
            url: Value(url),
            headersJson: Value(headers),
            isAdult: Value(adult),
            sortOrder: Value(series.length),
            syncToken: Value(token),
          ),
        );
    }
  }

  await db.transaction(() async {
    for (final entry in groups.entries) {
      await _batched(db, db.categories, [
        for (final g in entry.value.entries)
          CategoriesCompanion.insert(
            providerId: providerId,
            kind: entry.key,
            remoteId: g.key,
            name: g.key,
            isAdult: Value(isAdultCategory(g.key)),
            isKids: Value(isKidsCategory(g.key)),
            sortOrder: Value(g.value),
            syncToken: Value(token),
          ),
      ]);
    }
    await (db.delete(db.categories)..where(
          (t) =>
              t.providerId.equals(providerId) & t.syncToken.equals(token).not(),
        ))
        .go();
    await _batched(db, db.channels, live);
    await _batched(db, db.movies, movies);
    await _batched(db, db.seriesTable, series);
    for (final k in [ContentKind.live, ContentKind.movie, ContentKind.series]) {
      await deleteStale(db, providerId: providerId, kind: k, token: token);
    }
  });
  await rebuildSearchIndex(db, providerId);
  return M3uImportResult(
    live.length,
    movies.length,
    series.length,
    playlist.epgUrl,
  );
}
