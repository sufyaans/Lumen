import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/widgets/buttons.dart';
import '../../domain/browse_catalog.dart';
import '../../domain/media_summary.dart';
import '../common/catalog_screen.dart';
import 'guide_view.dart';

enum LiveView { channels, guide }

/// Live TV: Channels view (rows or a paged grid per category) and Guide
/// view, sharing the category chips (brief section 3).
class LiveScreen extends ConsumerStatefulWidget {
  const LiveScreen({super.key});

  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen> {
  LiveView _view = LiveView.channels;

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(browseCatalogProvider);
    return CategoryBrowser(
      kind: MediaKind.channel,
      title: 'Live TV',
      allRows: c.live,
      includeFavourites: true,
      emptyMessage:
          'No channels yet. Add a provider in Account to see them here.',
      headerTrailing: Segmented<LiveView>(
        options: const [
          (LiveView.channels, 'Channels'),
          (LiveView.guide, 'Guide'),
        ],
        value: _view,
        onChanged: (v) => setState(() => _view = v),
      ),
      bodyBuilder: _view == LiveView.guide
          ? (context, categoryId, favourites) => SliverToBoxAdapter(
              child: GuideView(
                categoryId: categoryId,
                favouritesOnly: favourites,
              ),
            )
          : null,
    );
  }
}
