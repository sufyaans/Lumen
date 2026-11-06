import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/focus/focusable_card.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/content_row.dart';
import '../../domain/browse_catalog.dart';
import '../../domain/media_summary.dart';
import '../common/catalog_screen.dart';

/// Global search. Phase 2 swaps the in-memory filter for FTS5.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  static const _limit = 60;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(browseCatalogProvider);
    final q = _controller.text.trim().toLowerCase();
    final all = catalog.allItems.toList();
    final results = q.isEmpty
        ? const <MediaSummary>[]
        : all
              .where(
                (i) =>
                    i.title.toLowerCase().contains(q) ||
                    i.subtitle.toLowerCase().contains(q),
              )
              .toList();
    final g = pageGutter(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(g, 16, g, 8),
                child: Row(
                  children: [
                    RoundIconButton(
                      icon: Icons.arrow_back,
                      label: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DpadEscapableField(
                        controller: _controller,
                        // Never autofocus: on TV that pops the keyboard
                        // immediately (brief section 8).
                        child: TextField(
                          controller: _controller,
                          onChanged: (_) => setState(() {}),
                          textInputAction: TextInputAction.search,
                          style: Theme.of(context).textTheme.titleLarge,
                          decoration: const InputDecoration(
                            hintText: 'Search channels, movies and shows',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (q.isEmpty)
              const SliverToBoxAdapter(
                child: EmptyState(
                  message: 'Type a title, channel or genre to search.',
                ),
              )
            else if (results.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  message:
                      'Nothing matches "${_controller.text.trim()}". '
                      'Try a title, channel or genre.',
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: g, vertical: 16),
                sliver: SliverToBoxAdapter(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final item in results.take(_limit))
                        mediaCard(
                          context,
                          item,
                          defaultStyleFor(item.kind),
                          onPressed: () => openItem(context, item),
                        ),
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
