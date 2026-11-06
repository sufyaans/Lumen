import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../core/network/connection_error.dart';
import '../../core/network/network_client.dart';
import '../../core/network/user_agents.dart';
import '../../data/db/app_database.dart';
import '../../data/db/secret_template.dart';
import '../../data/db/tables.dart';
import '../../data/repo/catalog_repository.dart';
import '../../data/secure/credential_store.dart';
import '../../data/xtream/server_endpoint.dart';
import '../../data/xtream/stream_probe.dart';
import '../../data/xtream/stream_urls.dart';
import '../../domain/browse_queries.dart';
import '../../domain/content_filters.dart';
import '../../domain/media_summary.dart';
import '../settings/app_settings.dart';
import 'playback_engine.dart';

/// What the user asked to play. Passed in memory (router `extra`).
@immutable
class PlayRequest {
  const PlayRequest(
    this.itemId, {
    this.episodeId,
    this.start,
    this.categoryId,
    this.title,
  });

  /// `live:…`, `movie:…` or `series:…`.
  final String itemId;
  final String? episodeId;
  final Duration? start;

  /// Live: the category to zap through (null = all channels).
  final String? categoryId;
  final String? title;
}

/// A resolved, playable item.
@immutable
class PlayableItem {
  const PlayableItem({
    required this.kind,
    required this.remoteId,
    required this.title,
    required this.sources,
    this.subtitle,
    this.seriesId,
    this.episodeId,
    this.channelNumber,
    this.nextEpisode,
  });

  final MediaKind kind;
  final String remoteId;
  final String title;
  final String? subtitle;

  /// In order: the preferred source, then alternates (other live format,
  /// short live URL form). Recovery walks this list.
  final List<PlaybackSource> sources;
  final String? seriesId;
  final String? episodeId;
  final int? channelNumber;

  /// For autoplay-next.
  final PlayRequest? nextEpisode;

  bool get isLive => kind == MediaKind.channel;
}

/// Data the player needs. Faked in widget tests.
abstract interface class PlayerData {
  Future<PlayableItem?> resolve(PlayRequest request);

  /// Channels to zap through, in order.
  Future<List<MediaSummary>> zapList(String? categoryId);

  /// Remembers which live format worked (`ts` / `m3u8`).
  Future<void> rememberLiveFormat(String ext);

  /// Opens the stream briefly to tell "too many devices" from other
  /// failures (only after playback already failed, so no slot is wasted).
  Future<ConnectionError?> classifyFailure(PlaybackSource source);

  Future<Duration?> savedPosition(PlayableItem item);
  Future<void> saveProgress(
    PlayableItem item,
    Duration position,
    Duration duration,
  );
  Future<void> markWatched(PlayableItem item);
  Future<bool> toggleFavourite(PlayableItem item);
  Future<bool> isFavourite(PlayableItem item);

  /// Max connections from the account, for the error message.
  int? get maxConnections;
}

String _extOf(Uri u) {
  final last = u.pathSegments.isEmpty ? '' : u.pathSegments.last;
  final dot = last.lastIndexOf('.');
  return dot < 0 ? '' : last.substring(dot + 1).toLowerCase();
}

/// [PlayerData] backed by the database and secure storage.
class RepositoryPlayerData implements PlayerData {
  RepositoryPlayerData({
    required this.repo,
    required this.store,
    required this.providerId,
    required this.profileId,
    required this.settings,
    required this.network,
    required this.queries,
    this.filter = ContentFilter.standard,
  });

  final CatalogRepository repo;
  final CredentialStore store;
  final String providerId;
  final int profileId;
  final AppSettings settings;
  final NetworkClient Function(ProviderRow) network;
  final BrowseQueries queries;
  final ContentFilter filter;

  AppDatabase get db => repo.db;
  ProviderRow? _p;
  int? _maxConnections;

  @override
  int? get maxConnections => _maxConnections;

  Future<ProviderRow?> _provider() async => _p ??= await (db.select(
    db.providers,
  )..where((t) => t.id.equals(providerId))).getSingleOrNull();

  Map<String, String> _headers(ProviderRow p, String? headersJson) {
    final h = <String, String>{
      'User-Agent':
          (UserAgentProfile.byId(p.userAgentId) ??
                  (p.kind == 'xtream'
                      ? UserAgentProfile.okhttp
                      : UserAgentProfile.vlc))
              .value,
    };
    if (headersJson != null) {
      try {
        final j = jsonDecode(headersJson);
        if (j is Map) {
          for (final e in j.entries) {
            h['${e.key}'] = '${e.value}';
          }
        }
      } catch (_) {}
    }
    return h;
  }

  @override
  Future<PlayableItem?> resolve(PlayRequest r) async {
    final p = await _provider();
    final parsed = parseItemId(r.itemId);
    if (p == null || parsed == null) return null;
    final (kind, id) = parsed;
    final untrusted = p.allowUntrustedCert;

    List<String> allowed = const [];
    if (p.userInfoJson != null) {
      try {
        final j = jsonDecode(p.userInfoJson!) as Map;
        allowed = [
          for (final f in (j['allowedOutputFormats'] as List? ?? const []))
            '$f',
        ];
        _maxConnections = j['maxConnections'] as int?;
      } catch (_) {}
    }

    XtreamUrls? urls;
    if (p.kind == 'xtream') {
      final pw = await store.readPassword(p.id);
      final e = ServerEndpoint.fromJson(
        p.endpointJson == null ? null : jsonDecode(p.endpointJson!),
      );
      if (pw is! SecretFound || e == null || p.username == null) return null;
      urls = XtreamUrls(e, p.username!, pw.value);
    }
    Uri? playlist;
    if (p.kind == 'm3u_url') {
      final s = await store.readSecretUrl(p.id);
      if (s is SecretFound) playlist = Uri.tryParse(s.value);
    }
    String? decode(String? url) => url == null
        ? null
        : SecretTemplate.decode(
            url,
            username: playlist?.queryParameters['username'],
            password: playlist?.queryParameters['password'],
          );

    switch (kind) {
      case MediaKind.channel:
        final c =
            await (db.select(db.channels)..where(
                  (t) =>
                      t.providerId.equals(providerId) & t.remoteId.equals(id),
                ))
                .getSingleOrNull();
        if (c == null) return null;
        final headers = _headers(p, c.headersJson);
        final List<PlaybackSource> sources;
        if (urls != null && int.tryParse(id) != null) {
          final order = liveExtensionOrder(
            setting: switch (settings.streamFormat) {
              StreamFormat.auto => LiveFormatSetting.auto,
              StreamFormat.ts => LiveFormatSetting.ts,
              StreamFormat.hls => LiveFormatSetting.hls,
            },
            allowedFormats: allowed,
            lastWorked: p.liveExtension,
          );
          sources = [
            for (final ext in order)
              PlaybackSource(
                url: urls.live(int.parse(id), ext: ext),
                headers: headers,
                isLive: true,
                allowUntrustedCert: untrusted,
              ),
            PlaybackSource(
              url: urls.liveShort(int.parse(id)),
              headers: headers,
              isLive: true,
              allowUntrustedCert: untrusted,
            ),
          ];
        } else {
          final u = Uri.tryParse(decode(c.url) ?? '');
          if (u == null) return null;
          sources = [
            PlaybackSource(
              url: u,
              headers: headers,
              isLive: true,
              allowUntrustedCert: untrusted,
            ),
          ];
        }
        return PlayableItem(
          kind: kind,
          remoteId: id,
          title: c.name,
          sources: sources,
          channelNumber: c.number,
        );

      case MediaKind.movie:
        final m =
            await (db.select(db.movies)..where(
                  (t) =>
                      t.providerId.equals(providerId) & t.remoteId.equals(id),
                ))
                .getSingleOrNull();
        if (m == null) return null;
        final u = urls != null && int.tryParse(id) != null
            ? urls.movie(int.parse(id), m.containerExtension)
            : Uri.tryParse(decode(m.url) ?? '');
        if (u == null) return null;
        return PlayableItem(
          kind: kind,
          remoteId: id,
          title: m.name,
          subtitle: m.year?.toString(),
          sources: [
            PlaybackSource(
              url: u,
              headers: _headers(p, m.headersJson),
              allowUntrustedCert: untrusted,
            ),
          ],
        );

      case MediaKind.series:
        final s =
            await (db.select(db.seriesTable)..where(
                  (t) =>
                      t.providerId.equals(providerId) & t.remoteId.equals(id),
                ))
                .getSingleOrNull();
        if (s == null) return null;
        if (urls == null) {
          // M3U "series" entries are single playable items.
          final u = Uri.tryParse(decode(s.url) ?? '');
          if (u == null) return null;
          return PlayableItem(
            kind: kind,
            remoteId: id,
            title: s.name,
            sources: [
              PlaybackSource(
                url: u,
                headers: _headers(p, s.headersJson),
                allowUntrustedCert: untrusted,
              ),
            ],
          );
        }
        var eps = await _episodes(id);
        if (eps.isEmpty) {
          await queries.detail(r.itemId); // fetches and caches episodes
          eps = await _episodes(id);
        }
        if (eps.isEmpty) return null;
        var idx = r.episodeId == null
            ? 0
            : eps.indexWhere((e) => e.episodeId == r.episodeId);
        if (r.episodeId == null) {
          // "Resume": the first partly-watched episode, else the first.
          final prog =
              await (db.select(db.progress)..where(
                    (t) =>
                        t.profileId.equals(profileId) &
                        t.providerId.equals(providerId) &
                        t.kind.equals(ContentKind.episode) &
                        t.seriesId.equals(id),
                  ))
                  .get();
          final partly = {
            for (final p in prog)
              if (p.positionMs > 5000 && p.positionMs < p.durationMs * 0.95)
                p.remoteId,
          };
          final i = eps.indexWhere((e) => partly.contains(e.episodeId));
          idx = i < 0 ? 0 : i;
        }
        if (idx < 0) return null;
        final e = eps[idx];
        final next = idx + 1 < eps.length ? eps[idx + 1] : null;
        return PlayableItem(
          kind: kind,
          remoteId: id,
          title: s.name,
          subtitle: 'S${e.season} E${e.episodeNum} · ${e.title}',
          seriesId: id,
          episodeId: e.episodeId,
          sources: [
            PlaybackSource(
              url: urls.episode(e.episodeId, e.containerExtension),
              headers: _headers(p, null),
              allowUntrustedCert: untrusted,
            ),
          ],
          nextEpisode: next == null
              ? null
              : PlayRequest(r.itemId, episodeId: next.episodeId),
        );
    }
  }

  Future<List<EpisodeRow>> _episodes(String seriesId) =>
      (db.select(db.episodes)
            ..where(
              (t) =>
                  t.providerId.equals(providerId) & t.seriesId.equals(seriesId),
            )
            ..orderBy([
              (t) => OrderingTerm(expression: t.season),
              (t) => OrderingTerm(expression: t.episodeNum),
            ]))
          .get();

  @override
  Future<List<MediaSummary>> zapList(String? categoryId) =>
      queries.page(MediaKind.channel, categoryId: categoryId, limit: 5000);

  @override
  Future<void> rememberLiveFormat(String ext) async {
    if (ext != 'ts' && ext != 'm3u8') return;
    await (db.update(db.providers)..where((t) => t.id.equals(providerId)))
        .write(ProvidersCompanion(liveExtension: Value(ext)));
    _p = null;
  }

  @override
  Future<ConnectionError?> classifyFailure(PlaybackSource source) async {
    final p = await _provider();
    if (p == null) return null;
    final r = await checkStream(
      network(p),
      source.url,
      headers: source.headers,
      maxConnections: _maxConnections,
    );
    return r.error;
  }

  String get _progressKind => ContentKind.movie;

  (String, String, String?) _progressKey(PlayableItem item) =>
      item.kind == MediaKind.series && item.episodeId != null
      ? (ContentKind.episode, item.episodeId!, item.seriesId)
      : (_progressKind, item.remoteId, null);

  @override
  Future<Duration?> savedPosition(PlayableItem item) async {
    if (item.isLive) return null;
    final (kind, id, _) = _progressKey(item);
    final p = await repo.progressFor(profileId, providerId, kind, id);
    if (p == null ||
        p.positionMs < 5000 ||
        p.positionMs > p.durationMs * 0.95) {
      return null;
    }
    return Duration(milliseconds: p.positionMs);
  }

  @override
  Future<void> saveProgress(
    PlayableItem item,
    Duration position,
    Duration duration,
  ) async {
    if (item.isLive || duration <= Duration.zero) return;
    final (kind, id, seriesId) = _progressKey(item);
    await repo.saveProgress(
      profileId: profileId,
      providerId: providerId,
      kind: kind,
      remoteId: id,
      seriesId: seriesId,
      position: position,
      duration: duration,
    );
  }

  @override
  Future<void> markWatched(PlayableItem item) async {
    if (item.isLive) {
      await repo.addRecent(
        profileId,
        providerId,
        ContentKind.live,
        item.remoteId,
      );
    }
  }

  @override
  Future<bool> toggleFavourite(PlayableItem item) => repo.toggleFavourite(
    profileId,
    providerId,
    ContentKind.live,
    item.remoteId,
  );

  @override
  Future<bool> isFavourite(PlayableItem item) =>
      repo.isFavourite(profileId, providerId, ContentKind.live, item.remoteId);
}

/// For debug preview content, which has no streams.
class NoStreamsPlayerData implements PlayerData {
  const NoStreamsPlayerData(this.queries);
  final BrowseQueries queries;

  @override
  Future<PlayableItem?> resolve(PlayRequest request) async => null;
  @override
  Future<List<MediaSummary>> zapList(String? categoryId) =>
      queries.page(MediaKind.channel, categoryId: categoryId, limit: 5000);
  @override
  Future<void> rememberLiveFormat(String ext) async {}
  @override
  Future<ConnectionError?> classifyFailure(PlaybackSource source) async => null;
  @override
  Future<Duration?> savedPosition(PlayableItem item) async => null;
  @override
  Future<void> saveProgress(
    PlayableItem item,
    Duration position,
    Duration duration,
  ) async {}
  @override
  Future<void> markWatched(PlayableItem item) async {}
  @override
  Future<bool> toggleFavourite(PlayableItem item) async => false;
  @override
  Future<bool> isFavourite(PlayableItem item) async => false;
  @override
  int? get maxConnections => null;
}

/// The extension a source URL ends with (`ts`, `m3u8`, `mp4`, '').
String sourceExtension(PlaybackSource s) => _extOf(s.url);
