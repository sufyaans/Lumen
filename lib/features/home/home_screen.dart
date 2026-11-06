import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/focus/focus_memory.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/content_row.dart';
import '../../domain/browse_catalog.dart';
import '../common/catalog_screen.dart';

/// Home: hero (only when a title has usable artwork, Phase 3) and rows.
/// Empty rows are hidden by [ContentRow].
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(browseCatalogProvider);
    final rows = c.home.where((r) => r.items.isNotEmpty).toList();

    return FocusMemory(
      debugLabel: 'home',
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: PageHeader(title: 'Home')),
          if (rows.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                message:
                    'Nothing to show yet. Add your provider to load channels, '
                    'movies and series.',
                action: PillButton(
                  label: 'Add provider',
                  tone: PillTone.accent,
                  icon: Icons.add,
                  onPressed: () => context.push('/add-provider'),
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: rows.length,
              itemBuilder: (context, i) => ContentRow(
                row: rows[i],
                onItemPressed: (item) => openItem(context, item),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }
}
