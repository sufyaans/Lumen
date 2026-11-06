import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../core/focus/focus_memory.dart';
import '../../core/focus/focusable_card.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/content_row.dart';
import '../../domain/media_summary.dart';
import '../common/catalog_screen.dart';

/// Global search across live, movies and series with instant results
/// (FTS5 on the database; brief section 3).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<MediaSummary> _results = const [];
  String _query = '';
  bool _searching = false;
  int _generation = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () => _run(text));
  }

  Future<void> _run(String text) async {
    final q = text.trim();
    final gen = ++_generation;
    if (q.isEmpty) {
      setState(() {
        _query = '';
        _results = const [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    final r = await ref.read(browseQueriesProvider).search(q);
    if (!mounted || gen != _generation) return;
    setState(() {
      _query = q;
      _results = r;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                          onChanged: _onChanged,
                          onSubmitted: _run,
                          textInputAction: TextInputAction.search,
                          style: Theme.of(context).textTheme.titleLarge,
                          decoration: InputDecoration(
                            hintText: 'Search channels, movies and shows',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searching
                                ? const Padding(
                                    padding: EdgeInsets.all(14),
                                    child: SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_query.isEmpty)
              const SliverToBoxAdapter(
                child: EmptyState(
                  message: 'Type a title, channel or genre to search.',
                ),
              )
            else if (_results.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  message:
                      'Nothing matches "$_query". Try a title, channel or genre.',
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: g, vertical: 16),
                sliver: SliverToBoxAdapter(
                  child: FocusMemory(
                    debugLabel: 'results',
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        for (final item in _results)
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
              ),
          ],
        ),
      ),
    );
  }
}
