import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/widgets/buttons.dart';
import '../../domain/browse_catalog.dart';
import '../common/catalog_screen.dart';

enum LiveView { channels, guide }

/// Live TV. Phase 0 has the Channels view; the virtualised Guide grid
/// (brief section 10) lands in Phase 3.
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
    return CatalogScreen(
      title: 'Live TV',
      rows: _view == LiveView.channels ? c.live : const [],
      genres: c.liveCategories,
      emptyMessage: _view == LiveView.guide
          ? 'The TV guide arrives with programme data in a later build.'
          : 'No channels yet. Add a provider in Account to see them here.',
      headerTrailing: Segmented<LiveView>(
        options: const [
          (LiveView.channels, 'Channels'),
          (LiveView.guide, 'Guide'),
        ],
        value: _view,
        onChanged: (v) => setState(() => _view = v),
      ),
    );
  }
}
