import 'package:flutter/foundation.dart';

import 'media_summary.dart';

@immutable
class CategoryInfo {
  const CategoryInfo(this.id, this.name);
  final String id;
  final String name;
}

@immutable
class EpisodeInfo {
  const EpisodeInfo({
    required this.id,
    required this.season,
    required this.number,
    required this.title,
    this.plot,
    this.duration,
    this.imageUrl,
    this.progress,
  });

  final String id;
  final int season;
  final int number;
  final String title;
  final String? plot;
  final Duration? duration;
  final String? imageUrl;

  /// 0..1 when partly watched.
  final double? progress;
}

@immutable
class ItemDetail {
  const ItemDetail({
    required this.summary,
    this.plot,
    this.genre,
    this.year,
    this.rating,
    this.duration,
    this.backdropUrl,
    this.resumePosition,
    this.inMyList = false,
    this.seasons = const {},
  });

  final MediaSummary summary;
  final String? plot;
  final String? genre;
  final int? year;
  final double? rating;
  final Duration? duration;
  final String? backdropUrl;

  /// Where "Resume" continues from, when partly watched.
  final Duration? resumePosition;
  final bool inMyList;

  /// Series only: episodes by season number.
  final Map<int, List<EpisodeInfo>> seasons;
}

@immutable
class GuideProgramme {
  const GuideProgramme(this.title, this.start, this.stop, {this.description});
  final String title;
  final DateTime start;
  final DateTime stop;
  final String? description;
}

@immutable
class GuideRow {
  const GuideRow(this.channel, this.programmes);
  final MediaSummary channel;
  final List<GuideProgramme> programmes;
}

/// Everything the browsing screens read beyond the Home snapshot. Paged
/// and bounded; implemented by the database (real providers) and by the
/// debug preview (also used by widget tests).
abstract interface class BrowseQueries {
  /// Every visible category for a kind, in provider order.
  Future<List<CategoryInfo>> categories(MediaKind kind);

  /// One page of items. [categoryId] null means all categories.
  Future<List<MediaSummary>> page(
    MediaKind kind, {
    String? categoryId,
    bool favouritesOnly = false,
    int offset = 0,
    int limit = 60,
  });

  Future<List<MediaSummary>> search(String query, {int limit = 60});

  /// Movie or series detail; for series, episodes are fetched and cached
  /// the first time.
  Future<ItemDetail?> detail(String itemId);

  Future<bool> toggleMyList(String itemId);
  Future<bool> toggleFavourite(String itemId);
  Future<bool> isFavourite(String itemId);

  /// Channels with programmes overlapping [from]..[to].
  Future<List<GuideRow>> guide({
    String? categoryId,
    bool favouritesOnly = false,
    required DateTime from,
    required DateTime to,
    int offset = 0,
    int limit = 40,
  });
}

/// `kind:remoteId` ids used across the UI.
(MediaKind, String)? parseItemId(String id) {
  final i = id.indexOf(':');
  if (i <= 0) return null;
  final k = switch (id.substring(0, i)) {
    'live' || 'channel' => MediaKind.channel,
    'movie' => MediaKind.movie,
    'series' => MediaKind.series,
    _ => null,
  };
  if (k == null) return null;
  return (k, id.substring(i + 1));
}
