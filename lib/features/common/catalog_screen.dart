import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../core/focus/focus_memory.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/content_row.dart';
import '../../domain/browse_queries.dart';
import '../../domain/media_summary.dart';
import 'paged_grid.dart';

/// Opens an item: movies and series go to their detail page; channels go
/// to the player (Phase 4).
void openItem(BuildContext context, MediaSummary item) {
  if (item.kind == MediaKind.channel) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${item.title}: playback arrives in the next update.'),
        ),
      );
    return;
  }
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

/// Horizontal filter chips (prototype `.chips`). Options are (id, label);
/// ids may repeat names, so selection is by id.
class ChipBar extends StatelessWidget {
  const ChipBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<(String?, String)> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

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
            label: options[i].$2,
            selected: options[i].$1 == selected,
            filled: true,
            onPressed: () => onSelected(options[i].$1),
          ),
        ),
      ),
    );
  }
}

/// Every visible category for a kind, refreshed when the catalogue changes.
final categoriesProvider = FutureProvider.family<List<CategoryInfo>, MediaKind>(
  (ref, kind) {
    ref.watch(catalogVersionProvider);
    return ref.watch(browseQueriesProvider).categories(kind);
  },
);

const favouritesChip = '\u0000favourites';

/// Shared body for Live TV, Movies and TV Shows: a header, chips for
/// "All" plus every provider category, and either the overview rows
/// ("All") or an infinite grid for the chosen category.
class CategoryBrowser extends ConsumerStatefulWidget {
  const CategoryBrowser({
    super.key,
    required this.kind,
    required this.title,
    required this.allRows,
    required this.emptyMessage,
    this.headerTrailing,
    this.includeFavourites = false,
    this.bodyBuilder,
  });

  final MediaKind kind;
  final String title;

  /// Overview rows shown for "All" (from the Home snapshot).
  final List<MediaRow> allRows;
  final String emptyMessage;
  final Widget? headerTrailing;
  final bool includeFavourites;

  /// Replaces the body sliver (the Live TV guide uses this).
  final Widget Function(
    BuildContext context,
    String? categoryId,
    bool favourites,
  )?
  bodyBuilder;

  @override
  ConsumerState<CategoryBrowser> createState() => _CategoryBrowserState();
}

class _CategoryBrowserState extends ConsumerState<CategoryBrowser> {
  String? _selected;
  Object? _loaderKey;
  PageLoader? _loader;

  PageLoader _loaderFor(BrowseQueries q, int version, String? id) {
    final key = (q, version, id);
    if (key != _loaderKey) {
      _loaderKey = key;
      final fav = id == favouritesChip;
      _loader = (offset, limit) => q.page(
        widget.kind,
        categoryId: fav ? null : id,
        favouritesOnly: fav,
        offset: offset,
        limit: limit,
      );
    }
    return _loader!;
  }

  @override
  Widget build(BuildContext context) {
    final queries = ref.watch(browseQueriesProvider);
    final version = ref.watch(catalogVersionProvider).value ?? 0;
    final cats =
        ref.watch(categoriesProvider(widget.kind)).value ??
        const <CategoryInfo>[];
    final rows = widget.allRows.where((r) => r.items.isNotEmpty).toList();
    final hasContent = cats.isNotEmpty || rows.isNotEmpty;
    if (_selected != null &&
        _selected != favouritesChip &&
        !cats.any((c) => c.id == _selected)) {
      _selected = null;
    }
    final fav = _selected == favouritesChip;
    final style = defaultStyleFor(widget.kind);

    Widget body;
    if (widget.bodyBuilder != null) {
      body = widget.bodyBuilder!(context, fav ? null : _selected, fav);
    } else if (_selected == null && rows.isNotEmpty) {
      body = SliverList.builder(
        itemCount: rows.length,
        itemBuilder: (context, i) => ContentRow(
          row: rows[i],
          onItemPressed: (item) => openItem(context, item),
        ),
      );
    } else {
      body = PagedGridSliver(
        load: _loaderFor(queries, version, _selected),
        style: style,
        onItemPressed: (item) => openItem(context, item),
        emptyMessage: fav
            ? 'No favourites yet. Open a channel and tap the star to add it.'
            : 'Nothing in this category.',
      );
    }

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
            SliverToBoxAdapter(
              child: ChipBar(
                options: [
                  (null, 'All'),
                  if (widget.includeFavourites) (favouritesChip, 'Favourites'),
                  for (final c in cats) (c.id, c.name),
                ],
                selected: _selected,
                onSelected: (id) => setState(() => _selected = id),
              ),
            ),
            body,
            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        ],
      ),
    );
  }
}
