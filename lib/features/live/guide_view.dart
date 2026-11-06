import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/theme.dart';
import '../../core/focus/focus_memory.dart';
import '../../core/focus/focusable_card.dart';
import '../../core/platform/form_factor.dart';
import '../../core/widgets/content_row.dart';
import '../../domain/browse_queries.dart';
import '../common/catalog_screen.dart';

/// TV guide grid (brief section 10):
/// * one fixed-width horizontal scroll area for the time window,
/// * inside it a vertically virtualised list of programme rows,
/// * a separate sticky channel column synced to the same vertical offset.
/// Channels load 40 at a time as the user scrolls; each row only lays out
/// programmes inside the window (now − 30 min … +6 h).
class GuideView extends ConsumerStatefulWidget {
  const GuideView({
    super.key,
    this.categoryId,
    this.favouritesOnly = false,
    this.now,
  });

  final String? categoryId;
  final bool favouritesOnly;
  final DateTime? now;

  @override
  ConsumerState<GuideView> createState() => _GuideViewState();
}

class _GuideViewState extends ConsumerState<GuideView> {
  static const _page = 40;
  static const windowMinutes = 390;

  final _channelScroll = ScrollController();
  final _rowsScroll = ScrollController();
  bool _syncing = false;

  final _rows = <GuideRow>[];
  bool _loading = false;
  bool _done = false;
  Object? _key;

  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    final now = widget.now ?? DateTime.now();
    _from = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute < 30 ? 0 : 30,
    ).subtract(const Duration(minutes: 30));
    _to = _from.add(const Duration(minutes: windowMinutes));
    void link(ScrollController a, ScrollController b) => a.addListener(() {
      if (_syncing || !b.hasClients) return;
      _syncing = true;
      if ((b.offset - a.offset).abs() > 0.5) {
        b.jumpTo(a.offset.clamp(0, b.position.maxScrollExtent));
      }
      _syncing = false;
    });
    link(_channelScroll, _rowsScroll);
    link(_rowsScroll, _channelScroll);
  }

  @override
  void dispose() {
    _channelScroll.dispose();
    _rowsScroll.dispose();
    super.dispose();
  }

  Future<void> _more(BrowseQueries q) async {
    if (_loading || _done) return;
    _loading = true;
    final key = _key;
    try {
      final page = await q.guide(
        categoryId: widget.categoryId,
        favouritesOnly: widget.favouritesOnly,
        from: _from,
        to: _to,
        offset: _rows.length,
        limit: _page,
      );
      if (!mounted || key != _key) return;
      setState(() {
        _rows.addAll(page);
        _done = page.length < _page;
      });
    } finally {
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = ref.watch(browseQueriesProvider);
    final version = ref.watch(catalogVersionProvider).value ?? 0;
    final key = (q, version, widget.categoryId, widget.favouritesOnly);
    if (key != _key) {
      _key = key;
      _rows.clear();
      _done = false;
      _loading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _more(q));
    }

    final c = LumenColors.of(context);
    final tv = ref.watch(formFactorProvider) == FormFactor.tv;
    final pxPerMin = tv ? 5.0 : 4.0;
    const rowH = 64.0;
    final chanW = tv ? 180.0 : 132.0;
    final width = windowMinutes * pxPerMin;
    final g = pageGutter(context);
    final height = (MediaQuery.sizeOf(context).height * 0.68).clamp(
      240.0,
      900.0,
    );
    final t = Theme.of(context).textTheme;
    final now = widget.now ?? DateTime.now();

    if (_rows.isEmpty && _done) {
      return EmptyState(
        message: widget.favouritesOnly
            ? 'No favourites yet. Open a channel and tap the star to add it.'
            : 'No channels in this category.',
      );
    }

    String hm(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: EdgeInsets.fromLTRB(g, 14, g, 0),
      height: height,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // Sticky channel column.
          SizedBox(
            width: chanW,
            child: Column(
              children: [
                Container(
                  height: 40,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Today',
                    style: t.labelMedium?.copyWith(color: c.muted),
                  ),
                ),
                Divider(height: 1, color: c.line),
                Expanded(
                  child: FocusMemory(
                    debugLabel: 'guide-channels',
                    child: ListView.builder(
                      controller: _channelScroll,
                      itemExtent: rowH,
                      itemCount: _rows.length + (_done ? 0 : 1),
                      itemBuilder: (context, i) {
                        if (i >= _rows.length - 8) {
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _more(q),
                          );
                        }
                        if (i >= _rows.length) return const SizedBox.shrink();
                        final ch = _rows[i].channel;
                        return FocusableCard(
                          focusScale: 1.0,
                          semanticLabel: ch.title,
                          onPressed: () => openItem(
                            context,
                            ch,
                            categoryId: widget.categoryId,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: c.line)),
                            ),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  if (ch.channelNumber != null)
                                    TextSpan(
                                      text: '${ch.channelNumber}  ',
                                      style: t.labelMedium,
                                    ),
                                  TextSpan(
                                    text: ch.title,
                                    style: t.labelMedium?.copyWith(
                                      color: c.muted,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          VerticalDivider(width: 1, color: c.line),
          // One horizontal scroll area: time header + programme rows.
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                child: Column(
                  children: [
                    SizedBox(
                      height: 40,
                      child: Stack(
                        children: [
                          for (var m = 0; m < windowMinutes; m += 30)
                            Positioned(
                              left: m * pxPerMin + 8,
                              top: 12,
                              child: Text(
                                hm(_from.add(Duration(minutes: m))),
                                style: t.labelSmall,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: c.line),
                    Expanded(
                      child: Stack(
                        children: [
                          FocusMemory(
                            debugLabel: 'guide-programmes',
                            child: ListView.builder(
                              controller: _rowsScroll,
                              itemExtent: rowH,
                              itemCount: _rows.length,
                              itemBuilder: (context, i) => _ProgrammeRow(
                                row: _rows[i],
                                categoryId: widget.categoryId,
                                from: _from,
                                to: _to,
                                now: now,
                                pxPerMin: pxPerMin,
                                height: rowH,
                              ),
                            ),
                          ),
                          // "Now" line.
                          if (now.isAfter(_from) && now.isBefore(_to))
                            Positioned(
                              left: now.difference(_from).inMinutes * pxPerMin,
                              top: 0,
                              bottom: 0,
                              child: IgnorePointer(
                                child: Container(width: 2, color: c.accent),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgrammeRow extends StatelessWidget {
  const _ProgrammeRow({
    required this.row,
    this.categoryId,
    required this.from,
    required this.to,
    required this.now,
    required this.pxPerMin,
    required this.height,
  });

  final GuideRow row;
  final String? categoryId;
  final DateTime from;
  final DateTime to;
  final DateTime now;
  final double pxPerMin;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = LumenColors.of(context);
    final t = Theme.of(context).textTheme;
    String hm(DateTime d) {
      final l = d.toLocal();
      return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
    }

    final progs = row.programmes;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: progs.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(5),
              child: FocusableCard(
                focusScale: 1.0,
                semanticLabel: '${row.channel.title}: no programme information',
                onPressed: () =>
                    openItem(context, row.channel, categoryId: categoryId),
                child: Container(
                  width: 420,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: c.surfaceHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'No programme information',
                    style: t.labelMedium?.copyWith(color: c.muted),
                  ),
                ),
              ),
            )
          : Stack(
              children: [
                for (final p in progs)
                  () {
                    final s = p.start.isBefore(from) ? from : p.start;
                    final e = p.stop.isAfter(to) ? to : p.stop;
                    final left = s.difference(from).inMinutes * pxPerMin;
                    final w = (e.difference(s).inMinutes * pxPerMin - 4).clamp(
                      24.0,
                      99999.0,
                    );
                    final isNow = !p.start.isAfter(now) && p.stop.isAfter(now);
                    return Positioned(
                      left: left + 2,
                      top: 5,
                      bottom: 5,
                      width: w,
                      child: FocusableCard(
                        focusScale: 1.0,
                        semanticLabel:
                            '${row.channel.title}: ${p.title} at ${hm(p.start)}',
                        onPressed: () {
                          if (isNow) {
                            openItem(
                              context,
                              row.channel,
                              categoryId: categoryId,
                            );
                          } else {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${p.title} starts at ${hm(p.start)} on ${row.channel.title}.',
                                  ),
                                ),
                              );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isNow
                                ? Color.lerp(c.surfaceHigh, c.accent, 0.22)
                                : c.surfaceHigh,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                p.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.labelMedium,
                              ),
                              Text(
                                hm(p.start),
                                maxLines: 1,
                                style: t.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }(),
              ],
            ),
    );
  }
}
