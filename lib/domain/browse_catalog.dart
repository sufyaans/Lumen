import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dev/preview_catalog.dart';
import 'media_summary.dart';

/// What the browsing screens show. Phase 2 replaces the source with the
/// drift-backed repository; screens only depend on this shape.
@immutable
class BrowseCatalog {
  const BrowseCatalog({
    this.home = const [],
    this.live = const [],
    this.movies = const [],
    this.series = const [],
    this.liveCategories = const [],
    this.movieGenres = const [],
    this.seriesGenres = const [],
  });

  static const empty = BrowseCatalog();

  final List<MediaRow> home;
  final List<MediaRow> live;
  final List<MediaRow> movies;
  final List<MediaRow> series;
  final List<String> liveCategories;
  final List<String> movieGenres;
  final List<String> seriesGenres;

  bool get isEmpty =>
      home.every((r) => r.items.isEmpty) &&
      live.isEmpty &&
      movies.isEmpty &&
      series.isEmpty;

  Iterable<MediaSummary> get allItems sync* {
    final seen = <String>{};
    for (final r in [...live, ...movies, ...series]) {
      for (final i in r.items) {
        if (seen.add(i.id)) yield i;
      }
    }
  }

  MediaSummary? byId(String id) {
    for (final i in allItems) {
      if (i.id == id) return i;
    }
    for (final r in home) {
      for (final i in r.items) {
        if (i.id == id) return i;
      }
    }
    return null;
  }
}

/// Release builds ship no content of any kind (brief section 1), so the
/// catalogue is empty until a provider is added. Debug builds show a
/// generated preview so layout and D-pad focus can be checked without a
/// provider. Tests override this provider directly.
final browseCatalogProvider = Provider<BrowseCatalog>(
  (ref) => kDebugMode ? buildPreviewCatalog() : BrowseCatalog.empty,
);
