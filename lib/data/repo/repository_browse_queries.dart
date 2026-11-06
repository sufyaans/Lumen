import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/network/connection_error.dart';
import '../../core/network/network_client.dart';
import '../../core/network/user_agents.dart';
import '../../domain/browse_queries.dart';
import '../../domain/content_filters.dart';
import '../../domain/media_summary.dart';
import '../db/app_database.dart';
import '../db/tables.dart';
import '../secure/credential_store.dart';
import '../xtream/server_endpoint.dart';
import '../xtream/xtream_client.dart';
import 'catalog_repository.dart';

String _kindOf(MediaKind k) => switch (k) {
  MediaKind.channel => ContentKind.live,
  MediaKind.movie => ContentKind.movie,
  MediaKind.series => ContentKind.series,
};

/// [BrowseQueries] over the database for one provider and profile.
/// Series episodes, movie info and (when there's no XMLTV) per-channel
/// guide data are fetched from the provider on demand and cached.
class RepositoryBrowseQueries implements BrowseQueries {
  RepositoryBrowseQueries({
    required this.repo,
    required this.providerId,
    required this.profileId,
    required this.filter,
    required this.store,
    required this.network,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final CatalogRepository repo;
  final String providerId;
  final int profileId;
  final ContentFilter filter;
  final CredentialStore store;
  final NetworkClient Function(ProviderRow) network;
  final DateTime Function() _clock;

  AppDatabase get db => repo.db;

  static final _pool = RequestPool(2);
  static final _shortEpgTried = <String>{};

  Future<XtreamClient?> _client() async {
    final p = await (db.select(
      db.providers,
    )..where((t) => t.id.equals(providerId))).getSingleOrNull();
    if (p == null || p.kind != 'xtream' || p.username == null) return null;
    final pw = await store.readPassword(p.id);
    final e = ServerEndpoint.fromJson(
      p.endpointJson == null ? null : jsonDecode(p.endpointJson!),
    );
    if (pw is! SecretFound || e == null) return null;
    return XtreamClient(
      network: network(p),
      endpoint: e,
      username: p.username!,
      password: pw.value,
      userAgent:
          UserAgentProfile.byId(p.userAgentId) ?? UserAgentProfile.okhttp,
      pool: _pool,
    );
  }

  @override
  Future<List<CategoryInfo>> categories(MediaKind kind) async => [
    for (final c in await repo.categories(providerId, _kindOf(kind), filter))
      CategoryInfo(c.remoteId, c.name),
  ];

  @override
  Future<List<MediaSummary>> page(
    MediaKind kind, {
    String? categoryId,
    bool favouritesOnly = false,
    int offset = 0,
    int limit = 60,
  }) async {
    switch (kind) {
      case MediaKind.channel:
        if (favouritesOnly) {
          final all = await repo.favouriteChannels(
            providerId,
            profileId,
            filter: filter,
          );
          return all.skip(offset).take(limit).toList();
        }
        return repo.channelsWithEpg(
          providerId,
          await repo.channelsPage(
            providerId,
            categoryId: categoryId,
            filter: filter,
            limit: limit,
            offset: offset,
          ),
        );
      case MediaKind.movie:
        return [
          for (final m in await repo.moviesPage(
            providerId,
            categoryId: categoryId,
            filter: filter,
            limit: limit,
            offset: offset,
          ))
            repo.mapMovie(m),
        ];
      case MediaKind.series:
        return [
          for (final s in await repo.seriesPage(
            providerId,
            categoryId: categoryId,
            filter: filter,
            limit: limit,
            offset: offset,
          ))
            repo.mapSeries(s),
        ];
    }
  }

  @override
  Future<List<MediaSummary>> search(String query, {int limit = 60}) =>
      repo.search(providerId, query, filter: filter, limit: limit);

  @override
  Future<bool> toggleMyList(String itemId) async {
    final p = parseItemId(itemId);
    if (p == null) return false;
    return repo.toggleMyList(profileId, providerId, _kindOf(p.$1), p.$2);
  }

  @override
  Future<bool> toggleFavourite(String itemId) async {
    final p = parseItemId(itemId);
    if (p == null) return false;
    return repo.toggleFavourite(profileId, providerId, _kindOf(p.$1), p.$2);
  }

  @override
  Future<bool> isFavourite(String itemId) async {
    final p = parseItemId(itemId);
    if (p == null) return false;
    return repo.isFavourite(profileId, providerId, _kindOf(p.$1), p.$2);
  }

  Future<bool> _inMyList(String kind, String id) async =>
      await (db.select(db.myList)..where(
            (t) =>
                t.profileId.equals(profileId) &
                t.providerId.equals(providerId) &
                t.kind.equals(kind) &
                t.remoteId.equals(id),
          ))
          .getSingleOrNull() !=
      null;

  @override
  Future<ItemDetail?> detail(String itemId) async {
    final parsed = parseItemId(itemId);
    if (parsed == null) return null;
    final (kind, id) = parsed;
    if (kind == MediaKind.movie) {
      final m =
          await (db.select(db.movies)..where(
                (t) => t.providerId.equals(providerId) & t.remoteId.equals(id),
              ))
              .getSingleOrNull();
      if (m == null) return null;
      final prog = await repo.progressFor(
        profileId,
        providerId,
        ContentKind.movie,
        id,
      );
      String? plot;
      String? genre;
      Duration? duration;
      String? cover;
      final client = await _client();
      final vid = int.tryParse(id);
      if (client != null && vid != null) {
        try {
          final info = await client.vodInfo(vid);
          plot = info?.plot;
          genre = info?.genre;
          cover = info?.cover;
          if (info?.durationSecs != null) {
            duration = Duration(seconds: info!.durationSecs!);
          }
        } on ConnectionError {
          // Detail extras are optional; the cached row is enough to play.
        }
      }
      return ItemDetail(
        summary: repo.mapMovie(m),
        plot: plot,
        genre: genre,
        year: m.year,
        rating: m.rating,
        duration: duration,
        backdropUrl: cover ?? m.poster,
        resumePosition:
            prog == null ||
                prog.positionMs < 5000 ||
                prog.positionMs > prog.durationMs * 0.95
            ? null
            : Duration(milliseconds: prog.positionMs),
        inMyList: await _inMyList(ContentKind.movie, id),
      );
    }
    if (kind == MediaKind.series) {
      final s =
          await (db.select(db.seriesTable)..where(
                (t) => t.providerId.equals(providerId) & t.remoteId.equals(id),
              ))
              .getSingleOrNull();
      if (s == null) return null;
      var eps =
          await (db.select(db.episodes)
                ..where(
                  (t) =>
                      t.providerId.equals(providerId) & t.seriesId.equals(id),
                )
                ..orderBy([
                  (t) => OrderingTerm(expression: t.season),
                  (t) => OrderingTerm(expression: t.episodeNum),
                ]))
              .get();
      final stale =
          eps.isEmpty ||
          _clock().difference(eps.first.fetchedAt) > const Duration(hours: 12);
      final client = await _client();
      final sid = int.tryParse(id);
      if (stale && client != null && sid != null) {
        try {
          final info = await client.seriesInfo(sid);
          final now = _clock();
          await db.transaction(() async {
            await (db.delete(db.episodes)..where(
                  (t) =>
                      t.providerId.equals(providerId) & t.seriesId.equals(id),
                ))
                .go();
            await db.batch(
              (b) => b.insertAllOnConflictUpdate(db.episodes, [
                for (final season in info.episodesBySeason.values)
                  for (final e in season)
                    EpisodesCompanion.insert(
                      providerId: providerId,
                      seriesId: id,
                      episodeId: e.id,
                      season: e.season,
                      episodeNum: e.episodeNum,
                      title: e.title,
                      containerExtension: Value(e.containerExtension),
                      plot: Value(e.plot),
                      durationSecs: Value(e.durationSecs),
                      image: Value(e.image),
                      fetchedAt: now,
                    ),
              ]),
            );
          });
          eps =
              await (db.select(db.episodes)
                    ..where(
                      (t) =>
                          t.providerId.equals(providerId) &
                          t.seriesId.equals(id),
                    )
                    ..orderBy([
                      (t) => OrderingTerm(expression: t.season),
                      (t) => OrderingTerm(expression: t.episodeNum),
                    ]))
                  .get();
        } on ConnectionError {
          // Offline: show cached episodes if any.
        }
      }
      final progress = {
        for (final p
            in await (db.select(db.progress)..where(
                  (t) =>
                      t.profileId.equals(profileId) &
                      t.providerId.equals(providerId) &
                      t.kind.equals(ContentKind.episode) &
                      t.seriesId.equals(id),
                ))
                .get())
          p.remoteId: p.durationMs <= 0 ? 0.0 : p.positionMs / p.durationMs,
      };
      final seasons = <int, List<EpisodeInfo>>{};
      for (final e in eps) {
        (seasons[e.season] ??= []).add(
          EpisodeInfo(
            id: e.episodeId,
            season: e.season,
            number: e.episodeNum,
            title: e.title,
            plot: e.plot,
            duration: e.durationSecs == null
                ? null
                : Duration(seconds: e.durationSecs!),
            imageUrl: e.image,
            progress: progress[e.episodeId],
          ),
        );
      }
      return ItemDetail(
        summary: repo.mapSeries(s),
        plot: s.plot,
        genre: s.genre,
        year: s.year,
        rating: s.rating,
        backdropUrl: s.backdrop ?? s.poster,
        inMyList: await _inMyList(ContentKind.series, id),
        seasons: seasons,
      );
    }
    return null;
  }

  @override
  Future<List<GuideRow>> guide({
    String? categoryId,
    bool favouritesOnly = false,
    required DateTime from,
    required DateTime to,
    int offset = 0,
    int limit = 40,
  }) async {
    final List<ChannelRow> chans;
    if (favouritesOnly) {
      final favIds =
          (await (db.select(db.favourites)..where(
                    (t) =>
                        t.profileId.equals(profileId) &
                        t.providerId.equals(providerId) &
                        t.kind.equals(ContentKind.live),
                  ))
                  .get())
              .map((f) => f.remoteId)
              .toList();
      chans =
          (await (db.select(db.channels)
                    ..where(
                      (t) =>
                          t.providerId.equals(providerId) &
                          t.remoteId.isIn(favIds),
                    )
                    ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
                  .get())
              .skip(offset)
              .take(limit)
              .toList();
    } else {
      chans = await repo.channelsPage(
        providerId,
        categoryId: categoryId,
        filter: filter,
        limit: limit,
        offset: offset,
      );
    }
    final epgIds = chans
        .map((c) => c.epgId)
        .whereType<String>()
        .toSet()
        .toList();
    var programmes = epgIds.isEmpty
        ? <EpgProgramRow>[]
        : await (db.select(db.epgPrograms)
                ..where(
                  (e) =>
                      e.providerId.equals(providerId) &
                      e.channelEpgId.isIn(epgIds) &
                      e.stop.isBiggerThanValue(from) &
                      e.start.isSmallerThanValue(to),
                )
                ..orderBy([(e) => OrderingTerm(expression: e.start)]))
              .get();

    // No XMLTV data for these channels: fetch get_short_epg for the visible
    // ones only, at most 2 at a time (brief section 6).
    final have = programmes.map((p) => p.channelEpgId).toSet();
    final missing = chans
        .where(
          (c) =>
              c.epgId != null &&
              !have.contains(c.epgId) &&
              _shortEpgTried.add('$providerId/${c.remoteId}'),
        )
        .toList();
    if (missing.isNotEmpty) {
      final client = await _client();
      if (client != null) {
        await Future.wait([
          for (final c in missing)
            if (int.tryParse(c.remoteId) != null)
              () async {
                try {
                  final list = await client.shortEpg(
                    int.parse(c.remoteId),
                    limit: 6,
                  );
                  if (list.isEmpty) return;
                  await db.batch(
                    (b) => b.insertAll(db.epgPrograms, [
                      for (final e in list)
                        EpgProgramsCompanion.insert(
                          providerId: providerId,
                          channelEpgId: c.epgId!,
                          start: e.start,
                          stop: e.stop,
                          title: e.title,
                          description: Value(
                            e.description.isEmpty ? null : e.description,
                          ),
                        ),
                    ]),
                  );
                } on ConnectionError {
                  // Leave the row empty.
                }
              }(),
        ]);
        programmes =
            await (db.select(db.epgPrograms)
                  ..where(
                    (e) =>
                        e.providerId.equals(providerId) &
                        e.channelEpgId.isIn(epgIds) &
                        e.stop.isBiggerThanValue(from) &
                        e.start.isSmallerThanValue(to),
                  )
                  ..orderBy([(e) => OrderingTerm(expression: e.start)]))
                .get();
      }
    }

    final byChannel = <String, List<GuideProgramme>>{};
    for (final p in programmes) {
      (byChannel[p.channelEpgId] ??= []).add(
        GuideProgramme(p.title, p.start, p.stop, description: p.description),
      );
    }
    final summaries = await repo.channelsWithEpg(providerId, chans);
    return [
      for (final (i, c) in chans.indexed)
        GuideRow(summaries[i], byChannel[c.epgId] ?? const []),
    ];
  }
}
