import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/theme.dart';
import '../../core/focus/focus_memory.dart';
import '../../core/focus/focusable_card.dart';
import '../../core/widgets/artwork.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/content_row.dart';
import '../../core/widgets/fallback_art.dart';
import '../../domain/browse_queries.dart';
import '../../domain/media_summary.dart';
import '../player/play.dart';
import '../player/player_data.dart';

final itemDetailProvider = FutureProvider.autoDispose
    .family<ItemDetail?, String>(
      (ref, id) => ref.watch(browseQueriesProvider).detail(id),
    );

String _duration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  return h > 0 ? '${h}h ${m}m' : '$m min';
}

/// Movie and series detail (brief section 3): artwork, meta, plot, Play /
/// Resume, My list, and for series the seasons and episodes.
class DetailScreen extends ConsumerStatefulWidget {
  const DetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  /// Plays, then reloads so Resume, bars and ticks show the new position.
  Future<void> _play(BuildContext context, PlayRequest request) async {
    await playItem(context, request);
    if (mounted) ref.invalidate(itemDetailProvider(widget.itemId));
  }

  int? _season;
  bool? _inList;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(itemDetailProvider(widget.itemId));
    final c = LumenColors.of(context);
    final t = Theme.of(context).textTheme;
    final g = pageGutter(context);
    final d = async.value;
    final fallbackTitle = parseItemId(widget.itemId)?.$2 ?? '';
    final title = d?.summary.title ?? (async.isLoading ? '' : 'Not found');

    final inList = _inList ?? d?.inMyList ?? false;
    final seasons = d?.seasons.keys.toList() ?? const <int>[];
    final season = _season ?? (seasons.isEmpty ? null : seasons.first);
    final episodes = season == null
        ? const <EpisodeInfo>[]
        : d!.seasons[season]!;

    final meta = [
      if (d?.year != null) '${d!.year}',
      if (d?.duration != null) _duration(d!.duration!),
      if (seasons.isNotEmpty)
        seasons.length == 1 ? '1 season' : '${seasons.length} seasons',
      if (d?.genre != null) d!.genre!,
      if (d?.rating != null && d!.rating! > 0)
        '★ ${d.rating!.toStringAsFixed(1)}',
    ].join(' · ');

    final resume = d?.resumePosition;
    final isSeries = d?.summary.kind == MediaKind.series;
    EpisodeInfo? nextEpisode;
    if (isSeries) {
      for (final s in seasons) {
        for (final e in d!.seasons[s]!) {
          if ((e.progress ?? 0) > 0 && (e.progress ?? 0) < 0.95) {
            nextEpisode ??= e;
          }
        }
      }
    }

    return Scaffold(
      body: FocusMemory(
        debugLabel: 'detail',
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: (MediaQuery.sizeOf(context).height * 0.45).clamp(
                  240.0,
                  420.0,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (d?.backdropUrl != null)
                      Artwork(
                        title: title,
                        url: d!.backdropUrl,
                        width: MediaQuery.sizeOf(context).width,
                      )
                    else
                      FallbackArt(title: title.isEmpty ? fallbackTitle : title),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [c.background, c.background.withAlpha(0)],
                          stops: const [0, 0.75],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: EdgeInsets.all(g),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RoundIconButton(
                              icon: Icons.close,
                              label: 'Close',
                              background: const Color(0x80000000),
                              foreground: Colors.white,
                              onPressed: () => Navigator.of(context).maybePop(),
                            ),
                            const Spacer(),
                            Text(
                              title,
                              style: t.displayMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: g, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: async.isLoading && d == null
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : d == null
                    ? const EmptyState(
                        message: "This title isn't in your provider's catalogue any more.",
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (meta.isNotEmpty) Text(meta, style: t.bodySmall),
                          if (resume != null &&
                              d.duration != null &&
                              d.duration! > Duration.zero) ...[
                            const SizedBox(height: 10),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 360),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value:
                                      (resume.inMilliseconds /
                                              d.duration!.inMilliseconds)
                                          .clamp(0.0, 1.0),
                                  minHeight: 4,
                                  color: c.accent,
                                  backgroundColor: c.surfaceHigh,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_duration(d.duration! - resume)} left',
                              style: t.bodySmall?.copyWith(color: c.accent),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              PillButton(
                                label: resume != null
                                    ? 'Resume'
                                    : nextEpisode != null
                                    ? 'Resume S${nextEpisode.season} E${nextEpisode.number}'
                                    : 'Play',
                                icon: Icons.play_arrow,
                                tone: PillTone.primary,
                                autofocus: true,
                                onPressed: () => _play(
                                  context,
                                  resume != null
                                      ? PlayRequest(
                                          widget.itemId,
                                          start: resume,
                                        )
                                      : nextEpisode != null
                                      ? PlayRequest(
                                          widget.itemId,
                                          episodeId: nextEpisode.id,
                                        )
                                      : PlayRequest(
                                          widget.itemId,
                                          start: Duration.zero,
                                        ),
                                ),
                              ),
                              if (resume != null)
                                PillButton(
                                  label: 'Play from start',
                                  icon: Icons.replay,
                                  onPressed: () => _play(
                                    context,
                                    PlayRequest(
                                      widget.itemId,
                                      start: Duration.zero,
                                    ),
                                  ),
                                ),
                              PillButton(
                                label: inList ? 'In my list' : 'My list',
                                icon: inList ? Icons.check : Icons.add,
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  final now = await ref
                                      .read(browseQueriesProvider)
                                      .toggleMyList(widget.itemId);
                                  if (!mounted) return;
                                  setState(() => _inList = now);
                                  messenger
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          now
                                              ? 'Added to my list'
                                              : 'Removed from my list',
                                        ),
                                      ),
                                    );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 720),
                            child: Text(
                              d.plot ?? 'No description from this provider.',
                              style: t.bodyLarge?.copyWith(
                                color: c.muted,
                                height: 1.5,
                              ),
                            ),
                          ),
                          if (seasons.isNotEmpty) ...[
                            const SizedBox(height: 22),
                            FocusMemory(
                              debugLabel: 'seasons',
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final s in seasons)
                                    TabPill(
                                      label: 'Season $s',
                                      selected: s == season,
                                      filled: true,
                                      onPressed: () =>
                                          setState(() => _season = s),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            FocusMemory(
                              debugLabel: 'episodes',
                              child: Column(
                                children: [
                                  for (final e in episodes)
                                    _EpisodeTile(
                                      episode: e,
                                      seriesTitle: title,
                                      onPressed: () => _play(
                                        context,
                                        PlayRequest(
                                          widget.itemId,
                                          episodeId: e.id,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ] else if (isSeries)
                            const Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: Text(
                                'No episodes from this provider yet.',
                              ),
                            ),
                          const SizedBox(height: 40),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({
    required this.episode,
    required this.seriesTitle,
    required this.onPressed,
  });

  final EpisodeInfo episode;
  final String seriesTitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = LumenColors.of(context);
    final t = Theme.of(context).textTheme;
    final e = episode;
    final w = MediaQuery.sizeOf(context).width < 640 ? 84.0 : 116.0;
    final frac = (e.progress ?? 0).clamp(0.0, 1.0);
    final watched = frac >= MediaSummary.watchedThreshold;
    final inProgress = frac > MediaSummary.startedThreshold && !watched;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: FocusableCard(
        focusScale: 1.0,
        semanticLabel: 'Episode ${e.number}: ${e.title}',
        onPressed: onPressed,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '${e.number}',
                  textAlign: TextAlign.center,
                  style: t.titleLarge?.copyWith(
                    color: c.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: w,
                  height: w * 9 / 16,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Artwork(
                        title: '$seriesTitle${e.season}${e.number}',
                        url: e.imageUrl,
                        width: w,
                      ),
                      if (inProgress)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 4,
                          child: Row(
                            children: [
                              Expanded(
                                flex: (frac * 1000).round(),
                                child: ColoredBox(color: c.accent),
                              ),
                              Expanded(
                                flex: 1000 - (frac * 1000).round(),
                                child: const ColoredBox(
                                  color: Color(0x66FFFFFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (watched)
                        const Positioned(
                          top: 6,
                          right: 6,
                          child: WatchedBadge(size: 22),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title,
                      style: t.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (watched)
                      Text(
                        'Watched',
                        style: t.bodySmall?.copyWith(color: c.accent),
                      )
                    else if (inProgress && e.duration != null)
                      Text(
                        '${_duration(e.duration! * (1 - frac))} left',
                        style: t.bodySmall?.copyWith(color: c.accent),
                      )
                    else if (inProgress)
                      Text(
                        'In progress',
                        style: t.bodySmall?.copyWith(color: c.accent),
                      )
                    else if (e.duration != null)
                      Text(_duration(e.duration!), style: t.bodySmall),
                    if (e.plot != null)
                      Text(
                        e.plot!,
                        style: t.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
