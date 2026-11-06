// DEBUG-ONLY generated preview content.
//
// Only referenced behind `kDebugMode`, so it is tree-shaken out of release
// builds. Titles are invented placeholders; there are no stream URLs, no
// images and no provider details here.

import '../domain/browse_catalog.dart';
import '../domain/media_summary.dart';

BrowseCatalog buildPreviewCatalog() {
  const movieGenres = {
    'Action': ['Midnight Circuit', 'Neon Run', 'Redline', 'Iron Meridian'],
    'Comedy': ['Little Thunder', 'Open Mic Night', 'The Plus One', 'Salt Road'],
    'Sci-Fi': ['The Quiet Orbit', 'Static Bloom', 'Glass Tide', 'Low Earth'],
    'Drama': ['Last Harbour', 'Paper Kingdoms', 'Golden Hour', 'Northbound'],
  };
  const seriesGenres = {
    'Crime': ['Harbour Lights', 'Brass & Bone', 'Cold Frontier', 'Kestrel Bay'],
    'Comedy': ['Open Season', 'The Long Table', 'Flatshare', 'Plan B'],
    'Sci-Fi': ['Signal Lost', 'Dust Bowl', 'Orbit Nine', 'Meridian'],
  };
  const channels = [
    (101, 'Preview News', 'News'),
    (102, 'Preview Sport', 'Sports'),
    (103, 'Preview Cinema', 'Movies'),
    (104, 'Preview Kids', 'Kids'),
    (105, 'Preview Nature', 'Docs'),
    (106, 'Preview Music', 'Music'),
    (107, 'Preview Comedy', 'Comedy'),
    (108, 'Preview Docs', 'Docs'),
  ];
  const shows = [
    'Evening Bulletin',
    'Match Day',
    'The Late Review',
    'Wild Planet',
    'Chart Countdown',
    'Classic Matinee',
  ];

  var n = 0;
  List<MediaSummary> titles(
    Map<String, List<String>> g,
    MediaKind kind,
    String genre,
  ) => [
    for (final t in g[genre]!)
      MediaSummary(
        id: '${kind.name}:${t.toLowerCase().replaceAll(' ', '-')}',
        kind: kind,
        title: t,
        subtitle: '${2019 + (n++ % 7)} · $genre',
      ),
  ];

  final movieRows = [
    for (final g in movieGenres.keys)
      MediaRow(title: g, items: titles(movieGenres, MediaKind.movie, g)),
  ];
  final seriesRows = [
    for (final g in seriesGenres.keys)
      MediaRow(title: g, items: titles(seriesGenres, MediaKind.series, g)),
  ];
  final chans = [
    for (final (i, c) in channels.indexed)
      MediaSummary(
        id: 'live:${c.$1}',
        kind: MediaKind.channel,
        title: c.$2,
        subtitle: c.$3,
        channelNumber: c.$1,
        nowTitle: shows[i % shows.length],
        nextTitle: 'Next: ${shows[(i + 1) % shows.length]}',
        progress: ((i * 23) % 80 + 10) / 100,
      ),
  ];
  final allMovies = movieRows.expand((r) => r.items).toList();
  final allSeries = seriesRows.expand((r) => r.items).toList();

  return BrowseCatalog(
    home: [
      MediaRow(
        title: 'Continue watching',
        style: RowStyle.wide,
        items: [
          for (final (i, m) in [
            allMovies[2],
            allSeries[1],
            allMovies[9],
          ].indexed)
            MediaSummary(
              id: m.id,
              kind: m.kind,
              title: m.title,
              subtitle: m.subtitle,
              progress: 0.25 + i * 0.2,
            ),
        ],
      ),
      MediaRow(title: 'Favourite channels', items: chans.take(3).toList()),
      MediaRow(title: 'Trending movies', items: allMovies.take(12).toList()),
      MediaRow(title: 'Popular series', items: allSeries.take(12).toList()),
      MediaRow(title: 'Live now', items: chans),
    ],
    live: [
      for (final cat in {for (final c in channels) c.$3})
        MediaRow(
          title: cat,
          items: chans.where((c) => c.subtitle == cat).toList(),
        ),
    ],
    movies: movieRows,
    series: seriesRows,
    liveCategories: {for (final c in channels) c.$3}.toList(),
    movieGenres: movieGenres.keys.toList(),
    seriesGenres: seriesGenres.keys.toList(),
  );
}
