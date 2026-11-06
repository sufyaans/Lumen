import 'package:drift/drift.dart';

import '../../domain/browse_catalog.dart';
import '../../domain/content_filters.dart';
import '../../domain/media_summary.dart';
import '../db/app_database.dart';
import '../db/tables.dart';

/// Read side for the browsing UI. Never loads a full table: every query is
/// limited/paged (brief 4).
class CatalogRepository {
  CatalogRepository(this.db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase db;
  final DateTime Function() _clock;

  static const rowLimit = 30;
  static const maxCategoryRows = 24;

  // ---- ids ------------------------------------------------------------------

  static String itemId(String kind, String remoteId) => '$kind:$remoteId';

  static (String kind, String remoteId)? parseId(String id) {
    final i = id.indexOf(':');
    if (i <= 0) return null;
    return (id.substring(0, i), id.substring(i + 1));
  }

  // ---- change notifications --------------------------------------------------

  /// Emits whenever catalogue or user data changes; screens re-query.
  Stream<void> watchChanges() => db
      .tableUpdates(
        TableUpdateQuery.onAllTables([
          db.categories,
          db.channels,
          db.movies,
          db.seriesTable,
          db.epgPrograms,
          db.favourites,
          db.myList,
          db.progress,
        ]),
      )
      .map((_) {});

  // ---- filtering ------------------------------------------------------------

  /// SQL condition for [filter] on a table with `provider_id`,
  /// `category_id` and `is_adult`, as (sql, args).
  (String, List<Object>) _filterSql(
    String table,
    String kind,
    ContentFilter f,
  ) {
    final parts = <String>[];
    final args = <Object>[];
    if (f.hideAdult || f.kidsOnly) parts.add('$table.is_adult = 0');
    if (f.kidsOnly) {
      parts.add(
        '$table.category_id IN (SELECT remote_id FROM categories c '
        'WHERE c.provider_id = $table.provider_id AND c.kind = ? AND c.is_kids = 1)',
      );
      args.add(kind);
    }
    return (parts.isEmpty ? '1 = 1' : parts.join(' AND '), args);
  }

  Future<List<CategoryRow>> categories(
    String providerId,
    String kind,
    ContentFilter f,
  ) =>
      (db.select(db.categories)
            ..where((t) {
              var c = t.providerId.equals(providerId) & t.kind.equals(kind);
              if (f.hideAdult || f.kidsOnly) c = c & t.isAdult.equals(false);
              if (f.kidsOnly) c = c & t.isKids.equals(true);
              return c;
            })
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
          .get();

  // ---- pages ----------------------------------------------------------------

  Future<List<ChannelRow>> channelsPage(
    String providerId, {
    String? categoryId,
    ContentFilter filter = ContentFilter.standard,
    int limit = 60,
    int offset = 0,
  }) async {
    final (f, args) = _filterSql('channels', ContentKind.live, filter);
    return db
        .customSelect(
          'SELECT * FROM channels WHERE provider_id = ? '
          '${categoryId == null ? '' : 'AND category_id = ? '}AND $f '
          'ORDER BY sort_order, name LIMIT ? OFFSET ?',
          variables: [
            Variable(providerId),
            if (categoryId != null) Variable(categoryId),
            for (final a in args) Variable(a),
            Variable(limit),
            Variable(offset),
          ],
          readsFrom: {db.channels, db.categories},
        )
        .asyncMap((r) => db.channels.map(r.data))
        .get();
  }

  Future<List<MovieRow>> moviesPage(
    String providerId, {
    String? categoryId,
    ContentFilter filter = ContentFilter.standard,
    int limit = 60,
    int offset = 0,
    bool newestFirst = false,
  }) async {
    final (f, args) = _filterSql('movies', ContentKind.movie, filter);
    return db
        .customSelect(
          'SELECT * FROM movies WHERE provider_id = ? '
          '${categoryId == null ? '' : 'AND category_id = ? '}AND $f '
          'ORDER BY ${newestFirst ? 'added DESC NULLS LAST, ' : ''}sort_order '
          'LIMIT ? OFFSET ?',
          variables: [
            Variable(providerId),
            if (categoryId != null) Variable(categoryId),
            for (final a in args) Variable(a),
            Variable(limit),
            Variable(offset),
          ],
          readsFrom: {db.movies, db.categories},
        )
        .asyncMap((r) => db.movies.map(r.data))
        .get();
  }

  Future<List<SeriesRow>> seriesPage(
    String providerId, {
    String? categoryId,
    ContentFilter filter = ContentFilter.standard,
    int limit = 60,
    int offset = 0,
    bool recentFirst = false,
  }) async {
    final (f, args) = _filterSql('series', ContentKind.series, filter);
    return db
        .customSelect(
          'SELECT * FROM series WHERE provider_id = ? '
          '${categoryId == null ? '' : 'AND category_id = ? '}AND $f '
          'ORDER BY ${recentFirst ? 'last_modified DESC NULLS LAST, ' : ''}sort_order '
          'LIMIT ? OFFSET ?',
          variables: [
            Variable(providerId),
            if (categoryId != null) Variable(categoryId),
            for (final a in args) Variable(a),
            Variable(limit),
            Variable(offset),
          ],
          readsFrom: {db.seriesTable, db.categories},
        )
        .asyncMap((r) => db.seriesTable.map(r.data))
        .get();
  }

  Future<int> count(String providerId, String kind) async {
    final table = switch (kind) {
      ContentKind.live => 'channels',
      ContentKind.movie => 'movies',
      _ => 'series',
    };
    final r = await db
        .customSelect(
          'SELECT COUNT(*) AS n FROM $table WHERE provider_id = ?',
          variables: [Variable(providerId)],
        )
        .getSingle();
    return r.read<int>('n');
  }

  // ---- now / next -----------------------------------------------------------

  /// Current and next programme per EPG id, using [now] (server-adjusted).
  Future<Map<String, (EpgProgramRow, EpgProgramRow?)>> nowNext(
    String providerId,
    Iterable<String> epgIds, {
    DateTime? now,
  }) async {
    final ids = epgIds.toSet().toList();
    if (ids.isEmpty) return {};
    final t = now ?? _clock();
    final rows =
        await (db.select(db.epgPrograms)
              ..where(
                (e) =>
                    e.providerId.equals(providerId) &
                    e.channelEpgId.isIn(ids) &
                    e.stop.isBiggerThanValue(t) &
                    e.start.isSmallerThanValue(
                      t.add(const Duration(hours: 12)),
                    ),
              )
              ..orderBy([(e) => OrderingTerm(expression: e.start)]))
            .get();
    final out = <String, (EpgProgramRow, EpgProgramRow?)>{};
    for (final r in rows) {
      final cur = out[r.channelEpgId];
      if (cur == null) {
        if (!r.start.isAfter(t)) out[r.channelEpgId] = (r, null);
      } else if (cur.$2 == null) {
        out[r.channelEpgId] = (cur.$1, r);
      }
    }
    return out;
  }

  // ---- mapping to UI models ---------------------------------------------------

  MediaSummary mapChannel(
    ChannelRow c,
    Map<String, (EpgProgramRow, EpgProgramRow?)> epg,
    DateTime now,
  ) {
    final nn = c.epgId == null ? null : epg[c.epgId];
    double? progress;
    if (nn != null) {
      final total = nn.$1.stop.difference(nn.$1.start).inSeconds;
      if (total > 0) progress = now.difference(nn.$1.start).inSeconds / total;
    }
    String hm(DateTime d) {
      final l = d.toLocal();
      return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
    }

    return MediaSummary(
      id: itemId(ContentKind.live, c.remoteId),
      kind: MediaKind.channel,
      title: c.name,
      imageUrl: c.logo,
      channelNumber: c.number,
      nowTitle: nn?.$1.title,
      nextTitle: nn?.$2 == null
          ? null
          : 'Next at ${hm(nn!.$2!.start)}: ${nn.$2!.title}',
      progress: progress,
    );
  }

  MediaSummary mapMovie(MovieRow m, {double? progress}) => MediaSummary(
    id: itemId(ContentKind.movie, m.remoteId),
    kind: MediaKind.movie,
    title: m.name,
    subtitle: m.year?.toString() ?? '',
    imageUrl: m.poster,
    progress: progress,
  );

  MediaSummary mapSeries(SeriesRow s, {double? progress}) => MediaSummary(
    id: itemId(ContentKind.series, s.remoteId),
    kind: MediaKind.series,
    title: s.name,
    subtitle: [
      if (s.year != null) '${s.year}',
      if (s.genre != null) s.genre!,
    ].join(' · '),
    imageUrl: s.poster,
    progress: progress,
  );

  Future<List<MediaSummary>> channelsWithEpg(
    String providerId,
    List<ChannelRow> rows,
  ) async {
    final now = _clock();
    final epg = await nowNext(
      providerId,
      rows.map((c) => c.epgId).whereType<String>(),
      now: now,
    );
    return [for (final c in rows) mapChannel(c, epg, now)];
  }

  // ---- browse snapshot ---------------------------------------------------------

  /// Everything the browsing screens show, with bounded row sizes.
  Future<BrowseCatalog> browse({
    required String providerId,
    required int profileId,
    ContentFilter filter = ContentFilter.standard,
  }) async {
    final liveCats = await categories(providerId, ContentKind.live, filter);
    final movieCats = await categories(providerId, ContentKind.movie, filter);
    final seriesCats = await categories(providerId, ContentKind.series, filter);

    Future<List<MediaRow>> perCategory<R>(
      List<CategoryRow> cats,
      Future<List<MediaSummary>> Function(String catId) load,
    ) async {
      final rows = <MediaRow>[];
      for (final c in cats.take(maxCategoryRows)) {
        final items = await load(c.remoteId);
        if (items.isNotEmpty) rows.add(MediaRow(title: c.name, items: items));
      }
      return rows;
    }

    final live = await perCategory(
      liveCats,
      (id) async => channelsWithEpg(
        providerId,
        await channelsPage(
          providerId,
          categoryId: id,
          filter: filter,
          limit: rowLimit,
        ),
      ),
    );
    final movies = await perCategory(
      movieCats,
      (id) async => [
        for (final m in await moviesPage(
          providerId,
          categoryId: id,
          filter: filter,
          limit: rowLimit,
        ))
          mapMovie(m),
      ],
    );
    final series = await perCategory(
      seriesCats,
      (id) async => [
        for (final s in await seriesPage(
          providerId,
          categoryId: id,
          filter: filter,
          limit: rowLimit,
        ))
          mapSeries(s),
      ],
    );

    final home = <MediaRow>[
      MediaRow(
        title: 'Continue watching',
        style: RowStyle.wide,
        items: await continueWatching(providerId, profileId, filter: filter),
      ),
      MediaRow(
        title: 'My list',
        items: await myList(providerId, profileId, filter: filter),
      ),
      MediaRow(
        title: 'Favourite channels',
        items: await favouriteChannels(providerId, profileId, filter: filter),
      ),
      MediaRow(
        title: 'Trending movies',
        items: [
          for (final m in await moviesPage(
            providerId,
            filter: filter,
            limit: 20,
            newestFirst: true,
          ))
            mapMovie(m),
        ],
      ),
      MediaRow(
        title: 'Popular series',
        items: [
          for (final s in await seriesPage(
            providerId,
            filter: filter,
            limit: 20,
            recentFirst: true,
          ))
            mapSeries(s),
        ],
      ),
      MediaRow(
        title: 'Live now',
        items: await channelsWithEpg(
          providerId,
          await channelsPage(providerId, filter: filter, limit: 12),
        ),
      ),
    ];

    // Red bars and ticks on every movie and series tile (Netflix-style).
    Future<List<MediaRow>> mark(List<MediaRow> rows) async => [
      for (final r in rows)
        r.title == 'Continue watching'
            ? r
            : MediaRow(
                title: r.title,
                style: r.style,
                items: await withProgress(providerId, profileId, r.items),
              ),
    ];

    return BrowseCatalog(
      home: await mark(home),
      live: live,
      movies: await mark(movies),
      series: await mark(series),
      liveCategories: [for (final r in live) r.title],
      movieGenres: [for (final r in movies) r.title],
      seriesGenres: [for (final r in series) r.title],
    );
  }

  /// Copies [items] with their watch progress for [profileId]:
  /// * movies: how far through the movie (1.0 = finished),
  /// * series: progress of the episode watched most recently, unless that
  ///   episode was finished.
  Future<List<MediaSummary>> withProgress(
    String providerId,
    int profileId,
    List<MediaSummary> items,
  ) async {
    final movieIds = <String>[];
    final seriesIds = <String>[];
    for (final i in items) {
      final p = parseId(i.id);
      if (p == null) continue;
      if (i.kind == MediaKind.movie) movieIds.add(p.$2);
      if (i.kind == MediaKind.series) seriesIds.add(p.$2);
    }
    if (movieIds.isEmpty && seriesIds.isEmpty) return items;
    double frac(ProgressRow r) =>
        r.durationMs <= 0 ? 0 : (r.positionMs / r.durationMs).clamp(0.0, 1.0);

    final movies = <String, double>{};
    if (movieIds.isNotEmpty) {
      for (final r
          in await (db.select(db.progress)..where(
                (t) =>
                    t.profileId.equals(profileId) &
                    t.providerId.equals(providerId) &
                    t.kind.equals(ContentKind.movie) &
                    t.remoteId.isIn(movieIds),
              ))
              .get()) {
        movies[r.remoteId] = frac(r);
      }
    }
    final series = <String, double?>{};
    if (seriesIds.isNotEmpty) {
      final rows =
          await (db.select(db.progress)
                ..where(
                  (t) =>
                      t.profileId.equals(profileId) &
                      t.providerId.equals(providerId) &
                      t.kind.equals(ContentKind.episode) &
                      t.seriesId.isIn(seriesIds),
                )
                ..orderBy([
                  (t) => OrderingTerm(
                    expression: t.updatedAt,
                    mode: OrderingMode.desc,
                  ),
                ]))
              .get();
      for (final r in rows) {
        if (series.containsKey(r.seriesId)) continue;
        final f = frac(r);
        series[r.seriesId!] = f < MediaSummary.watchedThreshold ? f : null;
      }
    }
    return [
      for (final i in items)
        switch (i.kind) {
          MediaKind.movie =>
            movies.containsKey(parseId(i.id)!.$2)
                ? i.withProgress(movies[parseId(i.id)!.$2])
                : i,
          MediaKind.series =>
            series.containsKey(parseId(i.id)!.$2)
                ? i.withProgress(series[parseId(i.id)!.$2])
                : i,
          MediaKind.channel => i,
        },
    ];
  }

  // ---- user data ----------------------------------------------------------------

  Future<List<MediaSummary>> continueWatching(
    String providerId,
    int profileId, {
    ContentFilter filter = ContentFilter.standard,
    int limit = 20,
  }) async {
    final rows =
        await (db.select(db.progress)
              ..where(
                (p) =>
                    p.profileId.equals(profileId) &
                    p.providerId.equals(providerId),
              )
              ..orderBy([
                (p) => OrderingTerm(
                  expression: p.updatedAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(limit * 2))
            .get();
    final out = <MediaSummary>[];
    final seenSeries = <String>{};
    for (final p in rows) {
      final frac = p.durationMs <= 0 ? 0.0 : p.positionMs / p.durationMs;
      if (frac < 0.01 || frac > 0.95) continue;
      if (p.kind == ContentKind.movie) {
        final m =
            await (db.select(db.movies)..where(
                  (t) =>
                      t.providerId.equals(providerId) &
                      t.remoteId.equals(p.remoteId),
                ))
                .getSingleOrNull();
        if (m == null || (filter.hideAdult && m.isAdult)) continue;
        out.add(mapMovie(m, progress: frac));
      } else if (p.seriesId != null && seenSeries.add(p.seriesId!)) {
        final s =
            await (db.select(db.seriesTable)..where(
                  (t) =>
                      t.providerId.equals(providerId) &
                      t.remoteId.equals(p.seriesId!),
                ))
                .getSingleOrNull();
        if (s == null || (filter.hideAdult && s.isAdult)) continue;
        out.add(mapSeries(s, progress: frac));
      }
      if (out.length >= limit) break;
    }
    return out;
  }

  Future<List<MediaSummary>> myList(
    String providerId,
    int profileId, {
    ContentFilter filter = ContentFilter.standard,
  }) async {
    final rows =
        await (db.select(db.myList)
              ..where(
                (p) =>
                    p.profileId.equals(profileId) &
                    p.providerId.equals(providerId),
              )
              ..orderBy([
                (p) => OrderingTerm(
                  expression: p.addedAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(40))
            .get();
    final out = <MediaSummary>[];
    for (final r in rows) {
      if (r.kind == ContentKind.movie) {
        final m =
            await (db.select(db.movies)..where(
                  (t) =>
                      t.providerId.equals(providerId) &
                      t.remoteId.equals(r.remoteId),
                ))
                .getSingleOrNull();
        if (m != null && !(filter.hideAdult && m.isAdult)) out.add(mapMovie(m));
      } else {
        final s =
            await (db.select(db.seriesTable)..where(
                  (t) =>
                      t.providerId.equals(providerId) &
                      t.remoteId.equals(r.remoteId),
                ))
                .getSingleOrNull();
        if (s != null && !(filter.hideAdult && s.isAdult)) {
          out.add(mapSeries(s));
        }
      }
    }
    return out;
  }

  Future<List<MediaSummary>> favouriteChannels(
    String providerId,
    int profileId, {
    ContentFilter filter = ContentFilter.standard,
  }) async {
    final rows = await db
        .customSelect(
          'SELECT c.* FROM favourites f JOIN channels c ON c.provider_id = f.provider_id '
          'AND c.remote_id = f.remote_id WHERE f.profile_id = ? AND f.provider_id = ? '
          "AND f.kind = 'live' ${filter.hideAdult || filter.kidsOnly ? 'AND c.is_adult = 0' : ''} "
          'ORDER BY f.added_at DESC LIMIT 60',
          variables: [Variable(profileId), Variable(providerId)],
          readsFrom: {db.favourites, db.channels},
        )
        .asyncMap((r) => db.channels.map(r.data))
        .get();
    return channelsWithEpg(providerId, rows);
  }

  Future<bool> toggleFavourite(
    int profileId,
    String providerId,
    String kind,
    String remoteId,
  ) => _toggle(db.favourites, profileId, providerId, kind, remoteId);

  Future<bool> toggleMyList(
    int profileId,
    String providerId,
    String kind,
    String remoteId,
  ) => _toggle(db.myList, profileId, providerId, kind, remoteId);

  /// Returns true when the item is now present.
  Future<bool> _toggle(
    TableInfo<Table, Object?> table,
    int profileId,
    String providerId,
    String kind,
    String remoteId,
  ) async {
    final name = table.actualTableName;
    final args = [
      Variable(profileId),
      Variable(providerId),
      Variable(kind),
      Variable(remoteId),
    ];
    final exists = await db
        .customSelect(
          'SELECT 1 FROM $name WHERE profile_id = ? AND provider_id = ? AND kind = ? AND remote_id = ?',
          variables: args,
        )
        .getSingleOrNull();
    if (exists != null) {
      await db.customUpdate(
        'DELETE FROM $name WHERE profile_id = ? AND provider_id = ? AND kind = ? AND remote_id = ?',
        variables: args,
        updates: {table},
        updateKind: UpdateKind.delete,
      );
      return false;
    }
    await db.customInsert(
      'INSERT INTO $name(profile_id, provider_id, kind, remote_id, added_at) VALUES (?, ?, ?, ?, ?)',
      variables: [...args, Variable(_clock())],
      updates: {table},
    );
    return true;
  }

  Future<bool> isFavourite(
    int profileId,
    String providerId,
    String kind,
    String remoteId,
  ) async =>
      await (db.select(db.favourites)..where(
            (t) =>
                t.profileId.equals(profileId) &
                t.providerId.equals(providerId) &
                t.kind.equals(kind) &
                t.remoteId.equals(remoteId),
          ))
          .getSingleOrNull() !=
      null;

  /// Saved every 10 s and on exit by the player (brief 7).
  Future<void> saveProgress({
    required int profileId,
    required String providerId,
    required String kind,
    required String remoteId,
    String? seriesId,
    required Duration position,
    required Duration duration,
  }) => db
      .into(db.progress)
      .insertOnConflictUpdate(
        ProgressCompanion.insert(
          profileId: profileId,
          providerId: providerId,
          kind: kind,
          remoteId: remoteId,
          seriesId: Value(seriesId),
          positionMs: position.inMilliseconds,
          durationMs: duration.inMilliseconds,
          updatedAt: _clock(),
        ),
      );

  Future<ProgressRow?> progressFor(
    int profileId,
    String providerId,
    String kind,
    String remoteId,
  ) =>
      (db.select(db.progress)..where(
            (t) =>
                t.profileId.equals(profileId) &
                t.providerId.equals(providerId) &
                t.kind.equals(kind) &
                t.remoteId.equals(remoteId),
          ))
          .getSingleOrNull();

  Future<void> addRecent(
    int profileId,
    String providerId,
    String kind,
    String remoteId,
  ) => db
      .into(db.recents)
      .insertOnConflictUpdate(
        RecentsCompanion.insert(
          profileId: profileId,
          providerId: providerId,
          kind: kind,
          remoteId: remoteId,
          at: _clock(),
        ),
      );

  // ---- search ---------------------------------------------------------------------

  /// FTS5 prefix search over channels, movies and series (brief 3, 4).
  Future<List<MediaSummary>> search(
    String providerId,
    String query, {
    ContentFilter filter = ContentFilter.standard,
    int limit = 60,
  }) async {
    final match = ftsQuery(query);
    if (match == null) return const [];
    final rows = await db
        .customSelect(
          'SELECT kind, remote_id FROM search_index WHERE search_index MATCH ? '
          'AND provider_id = ? ${filter.hideAdult || filter.kidsOnly ? "AND is_adult = 0" : ''} '
          'ORDER BY rank LIMIT ?',
          variables: [
            Variable(match),
            Variable(providerId),
            Variable(limit * 2),
          ],
        )
        .get();

    final byKind = <String, List<String>>{};
    final order = <String>[];
    for (final r in rows) {
      final k = r.read<String>('kind');
      final id = r.read<String>('remote_id');
      (byKind[k] ??= []).add(id);
      order.add(itemId(k, id));
    }

    final items = <String, MediaSummary>{};
    final liveIds = byKind[ContentKind.live] ?? const [];
    if (liveIds.isNotEmpty) {
      var chans =
          await (db.select(db.channels)..where(
                (t) =>
                    t.providerId.equals(providerId) & t.remoteId.isIn(liveIds),
              ))
              .get();
      if (filter.kidsOnly) {
        chans = await _kidsOnly(
          providerId,
          ContentKind.live,
          chans,
          (c) => c.categoryId,
        );
      }
      for (final m in await channelsWithEpg(providerId, chans)) {
        items[m.id] = m;
      }
    }
    final movieIds = byKind[ContentKind.movie] ?? const [];
    if (movieIds.isNotEmpty) {
      var ms =
          await (db.select(db.movies)..where(
                (t) =>
                    t.providerId.equals(providerId) & t.remoteId.isIn(movieIds),
              ))
              .get();
      if (filter.kidsOnly) {
        ms = await _kidsOnly(
          providerId,
          ContentKind.movie,
          ms,
          (m) => m.categoryId,
        );
      }
      for (final m in ms) {
        items[itemId(ContentKind.movie, m.remoteId)] = mapMovie(m);
      }
    }
    final seriesIds = byKind[ContentKind.series] ?? const [];
    if (seriesIds.isNotEmpty) {
      var ss =
          await (db.select(db.seriesTable)..where(
                (t) =>
                    t.providerId.equals(providerId) &
                    t.remoteId.isIn(seriesIds),
              ))
              .get();
      if (filter.kidsOnly) {
        ss = await _kidsOnly(
          providerId,
          ContentKind.series,
          ss,
          (s) => s.categoryId,
        );
      }
      for (final s in ss) {
        items[itemId(ContentKind.series, s.remoteId)] = mapSeries(s);
      }
    }
    return [
      for (final id in order)
        if (items[id] != null) items[id]!,
    ].take(limit).toList();
  }

  Future<List<T>> _kidsOnly<T>(
    String providerId,
    String kind,
    List<T> rows,
    String? Function(T) cat,
  ) async {
    final kids = (await categories(
      providerId,
      kind,
      ContentFilter.kids,
    )).map((c) => c.remoteId).toSet();
    return rows.where((r) => kids.contains(cat(r))).toList();
  }
}

/// Builds a safe FTS5 query: each word becomes a quoted prefix term, all
/// required. Returns null for empty input.
String? ftsQuery(String input) {
  final words = input
      .toLowerCase()
      .split(RegExp(r'[\s\p{P}\p{S}]+', unicode: true))
      .where((w) => w.isNotEmpty)
      .take(8)
      .toList();
  if (words.isEmpty) return null;
  return words.map((w) => '"${w.replaceAll('"', '""')}"*').join(' AND ');
}
