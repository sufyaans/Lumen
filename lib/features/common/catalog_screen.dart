import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/focus/focus_memory.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/content_row.dart';
import '../../domain/media_summary.dart';

/// Opens an item: channels go to the player (Phase 4), everything else to
/// the detail screen.
void openItem(BuildContext context, MediaSummary item) {
  context.push('/detail/${Uri.encodeComponent(item.id)}');
}

/// Page header (prototype `.ph`): big title with optional trailing widget.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final g = pageGutter(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(g, 12, g, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Horizontal filter chips (prototype `.chips`).
class ChipBar extends StatelessWidget {
  const ChipBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final g = pageGutter(context);
    return FocusMemory(
      debugLabel: 'chips',
      child: SizedBox(
        height: 64,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: EdgeInsets.fromLTRB(g, 14, g, 8),
          itemCount: options.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) => TabPill(
            label: options[i],
            selected: options[i] == selected,
            filled: true,
            onPressed: () => onSelected(options[i]),
          ),
        ),
      ),
    );
  }
}

/// Shared body for Movies, TV Shows and Live TV: header, genre chips and a
/// vertically virtualised list of rows.
class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({
    super.key,
    required this.title,
    required this.rows,
    required this.genres,
    required this.emptyMessage,
    this.headerTrailing,
  });

  final String title;
  final List<MediaRow> rows;
  final List<String> genres;
  final String emptyMessage;
  final Widget? headerTrailing;

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  static const _all = 'All';
  String _genre = _all;

  @override
  Widget build(BuildContext context) {
    final rows = _genre == _all
        ? widget.rows
        : widget.rows.where((r) => r.title == _genre).toList();
    final hasContent = widget.rows.any((r) => r.items.isNotEmpty);

    return FocusMemory(
      debugLabel: widget.title,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PageHeader(
              title: widget.title,
              trailing: widget.headerTrailing,
            ),
          ),
          if (!hasContent)
            SliverToBoxAdapter(child: EmptyState(message: widget.emptyMessage))
          else ...[
            if (widget.genres.isNotEmpty)
              SliverToBoxAdapter(
                child: ChipBar(
                  options: [_all, ...widget.genres],
                  selected: _genre,
                  onSelected: (g) => setState(() => _genre = g),
                ),
              ),
            SliverList.builder(
              itemCount: rows.length,
              itemBuilder: (context, i) => ContentRow(
                row: rows[i],
                onItemPressed: (item) => openItem(context, item),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        ],
      ),
    );
  }
}
