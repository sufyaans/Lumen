import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../core/focus/focus_memory.dart';
import '../../core/platform/form_factor.dart';
import '../../core/widgets/artwork.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/content_row.dart';
import '../../domain/browse_catalog.dart';
import '../../domain/media_summary.dart';
import '../common/catalog_screen.dart';

/// Home: a hero banner (only when a title has usable artwork) and the
/// rows from the brief. Empty rows are hidden by [ContentRow].
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(browseCatalogProvider);
    final rows = c.home.where((r) => r.items.isNotEmpty).toList();
    MediaSummary? hero;
    for (final r in c.home) {
      if (r.title != 'Trending movies' && r.title != 'Popular series') continue;
      for (final i in r.items) {
        if (i.imageUrl != null && i.imageUrl!.isNotEmpty) {
          hero = i;
          break;
        }
      }
      if (hero != null) break;
    }
    final needsPassword = ref.watch(
      syncControllerProvider.select(
        (s) => s.lastResult?.needsPassword ?? false,
      ),
    );

    return FocusMemory(
      debugLabel: 'home',
      child: CustomScrollView(
        slivers: [
          if (hero != null)
            SliverToBoxAdapter(child: _Hero(item: hero))
          else
            const SliverToBoxAdapter(child: PageHeader(title: 'Home')),
          if (needsPassword)
            SliverToBoxAdapter(
              child: EmptyState(
                message: 'Enter your password again to continue. Your saved details are kept.',
                action: PillButton(
                  label: 'Enter password',
                  tone: PillTone.accent,
                  onPressed: () => context.push('/account'),
                ),
              ),
            ),
          if (rows.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                message: 'Nothing to show yet. Add your provider to load channels, movies and series.',
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

class _Hero extends ConsumerWidget {
  const _Hero({required this.item});

  final MediaSummary item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final g = pageGutter(context);
    final t = Theme.of(context).textTheme;
    final lite = ref.watch(deviceProfileProvider).liteMode;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return SizedBox(
      height: (size.height * 0.62).clamp(260.0, 620.0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Artwork(title: item.title, url: item.imageUrl, width: size.width),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [bg, bg.withAlpha(0)],
                stops: const [0.04, 0.6],
              ),
            ),
          ),
          if (!lite)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0x73000000), Color(0x00000000)],
                  stops: [0, 0.65],
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(g, 0, g, 40),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.subtitle.isNotEmpty)
                      Text(
                        item.subtitle,
                        style: t.labelLarge?.copyWith(color: Colors.white),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.displayLarge?.copyWith(
                        color: Colors.white,
                        shadows: const [
                          Shadow(blurRadius: 20, color: Color(0x66000000)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        PillButton(
                          label: 'Play',
                          icon: Icons.play_arrow,
                          tone: PillTone.primary,
                          onPressed: () => ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${item.title}: playback arrives in the next update.',
                                ),
                              ),
                            ),
                        ),
                        PillButton(
                          label: 'More info',
                          icon: Icons.info_outline,
                          onPressed: () => openItem(context, item),
                        ),
                      ],
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
