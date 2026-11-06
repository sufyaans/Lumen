// DEBUG-ONLY preview data source (also used by widget tests). Invented
// titles only; no URLs, images or provider details.

import '../domain/browse_catalog.dart';
import '../domain/browse_queries.dart';
import '../domain/media_summary.dart';
import 'preview_catalog.dart';

class PreviewBrowseQueries implements BrowseQueries {
  PreviewBrowseQueries([BrowseCatalog? catalog, DateTime Function()? clock])
    : catalog = catalog ?? buildPreviewCatalog(),
      _clock = clock ?? DateTime.now;

  final BrowseCatalog catalog;
  final DateTime Function() _clock;
  final _myList = <String>{};
  final _favs = <String>{'live:101', 'live:102', 'live:103'};

  List<MediaRow> _rows(MediaKind k) => switch (k) {
    MediaKind.channel => catalog.live,
    MediaKind.movie => catalog.movies,
    MediaKind.series => catalog.series,
  };

  @override
  Future<List<CategoryInfo>> categories(MediaKind kind) async => [
    for (final r in _rows(kind)) CategoryInfo(r.title, r.title),
  ];

  List<MediaSummary> _all(MediaKind kind, String? categoryId, bool favs) {
    final seen = <String>{};
    return [
      for (final r in _rows(kind))
        if (categoryId == null || r.title == categoryId)
          for (final i in r.items)
            if ((!favs || _favs.contains(i.id)) && seen.add(i.id)) i,
    ];
  }

  @override
  Future<List<MediaSummary>> page(
    MediaKind kind, {
    String? categoryId,
    bool favouritesOnly = false,
    int offset = 0,
    int limit = 60,
  }) async =>
      _all(kind, categoryId, favouritesOnly).skip(offset).take(limit).toList();

  @override
  Future<List<MediaSummary>> search(String query, {int limit = 60}) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return catalog.allItems
        .where(
          (i) =>
              i.title.toLowerCase().contains(q) ||
              i.subtitle.toLowerCase().contains(q),
        )
        .take(limit)
        .toList();
  }

  @override
  Future<ItemDetail?> detail(String itemId) async {
    final item = catalog.byId(itemId);
    if (item == null) return null;
    final isSeries = item.kind == MediaKind.series;
    return ItemDetail(
      summary: item,
      plot: 'A preview description. Real details come from your provider.',
      genre: item.subtitle.split(' · ').last,
      year: int.tryParse(item.subtitle.split(' · ').first),
      duration: isSeries ? null : const Duration(minutes: 104),
      inMyList: _myList.contains(itemId),
      resumePosition: (item.progress ?? 0) > 0
          ? const Duration(minutes: 31)
          : null,
      seasons: isSeries
          ? {
              for (var s = 1; s <= 2; s++)
                s: [
                  for (var e = 1; e <= 6; e++)
                    EpisodeInfo(
                      id: '${item.id}-s${s}e$e',
                      season: s,
                      number: e,
                      title: 'Episode $e',
                      duration: Duration(minutes: 38 + e),
                      progress: s == 1 && e == 1 ? 0.4 : null,
                    ),
                ],
            }
          : const {},
    );
  }

  @override
  Future<bool> toggleMyList(String itemId) async =>
      _myList.remove(itemId) ? false : _myList.add(itemId);

  @override
  Future<bool> toggleFavourite(String itemId) async =>
      _favs.remove(itemId) ? false : _favs.add(itemId);

  @override
  Future<bool> isFavourite(String itemId) async => _favs.contains(itemId);

  @override
  Future<List<GuideRow>> guide({
    String? categoryId,
    bool favouritesOnly = false,
    required DateTime from,
    required DateTime to,
    int offset = 0,
    int limit = 40,
  }) async {
    final chans = _all(
      MediaKind.channel,
      categoryId,
      favouritesOnly,
    ).skip(offset).take(limit);
    final now = _clock();
    final base = DateTime(now.year, now.month, now.day, now.hour);
    const shows = [
      'Bulletin',
      'Match Day',
      'Late Review',
      'Wild Planet',
      'Countdown',
      'Matinee',
    ];
    return [
      for (final (ci, c) in chans.indexed)
        GuideRow(
          c,
          [
            for (
              var h = -2, t = base.subtract(const Duration(hours: 2));
              t.isBefore(to);
              h++
            )
              () {
                final len = Duration(minutes: [30, 60, 90][(ci + h).abs() % 3]);
                final p = GuideProgramme(
                  shows[(ci + h).abs() % shows.length],
                  t,
                  t.add(len),
                );
                t = t.add(len);
                return p;
              }(),
          ].where((p) => p.stop.isAfter(from)).toList(),
        ),
    ];
  }
}
