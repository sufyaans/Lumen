import 'package:material_ui/material_ui.dart';

import '../../core/widgets/cards.dart';
import '../../core/widgets/content_row.dart';
import '../../domain/media_summary.dart';

typedef PageLoader = Future<List<MediaSummary>> Function(int offset, int limit);

/// Infinite, virtualised grid of cards as a sliver. Loads [pageSize] items
/// at a time when the user scrolls (or D-pads) near the end, so a category
/// with 10 000 channels never loads all at once (brief sections 4, 10).
class PagedGridSliver extends StatefulWidget {
  const PagedGridSliver({
    super.key,
    required this.load,
    required this.style,
    required this.onItemPressed,
    required this.emptyMessage,
    this.pageSize = 60,
  });

  final PageLoader load;
  final RowStyle style;
  final void Function(MediaSummary) onItemPressed;
  final String emptyMessage;
  final int pageSize;

  @override
  State<PagedGridSliver> createState() => _PagedGridSliverState();
}

class _PagedGridSliverState extends State<PagedGridSliver> {
  final _items = <MediaSummary>[];
  bool _loading = false;
  bool _done = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _more();
  }

  @override
  void didUpdateWidget(PagedGridSliver old) {
    super.didUpdateWidget(old);
    if (old.load != widget.load) {
      _items.clear();
      _done = false;
      _error = null;
      _more();
    }
  }

  Future<void> _more() async {
    if (_loading || _done) return;
    setState(() => _loading = true);
    final load = widget.load;
    try {
      final page = await load(_items.length, widget.pageSize);
      if (!mounted || load != widget.load) return;
      setState(() {
        _items.addAll(page);
        _done = page.length < widget.pageSize;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
        _done = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty && !_loading) {
      return SliverToBoxAdapter(
        child: EmptyState(
          message: _error == null
              ? widget.emptyMessage
              : "Couldn't load this list. Try again in a moment.",
        ),
      );
    }
    final m = CardMetrics.of(context);
    final g = pageGutter(context);
    final w = m.widthFor(widget.style);
    final h = m.heightFor(widget.style);
    const gap = 16.0;
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(g, 16, g, 40),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: w + gap,
          mainAxisExtent: h + gap,
        ),
        itemCount: _items.length + (_done ? 0 : 1),
        itemBuilder: (context, i) {
          if (i >= _items.length - 12) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _more());
          }
          if (i >= _items.length) {
            return const Center(
              child: SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          final item = _items[i];
          return Align(
            alignment: Alignment.topLeft,
            child: mediaCard(
              context,
              item,
              widget.style,
              onPressed: () => widget.onItemPressed(item),
            ),
          );
        },
      ),
    );
  }
}
