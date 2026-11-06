import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/content_row.dart';
import '../../core/widgets/fallback_art.dart';
import '../../domain/browse_catalog.dart';

/// Detail placeholder. Seasons, episodes, My list and Resume land in Phase 3;
/// playback in Phase 4.
class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(browseCatalogProvider).byId(itemId);
    final c = LumenColors.of(context);
    final t = Theme.of(context).textTheme;
    final title = item?.title ?? 'Not found';

    return Scaffold(
      body: ListView(
        children: [
          SizedBox(
            height: 300,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FallbackArt(title: title),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [c.background, c.background.withAlpha(0)],
                      stops: const [0, 0.7],
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(pageGutter(context)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RoundIconButton(
                          icon: Icons.close,
                          label: 'Close',
                          background: const Color(0x80000000),
                          foreground: Colors.white,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        const Spacer(),
                        Text(title, style: t.displayMedium),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: pageGutter(context),
              vertical: 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item != null && item.subtitle.isNotEmpty)
                  Text(item.subtitle, style: t.bodySmall),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    PillButton(
                      label: 'Play',
                      icon: Icons.play_arrow,
                      tone: PillTone.primary,
                      autofocus: true,
                      onPressed: () => ScaffoldMessenger.of(context)
                          .showSnackBar(
                            const SnackBar(
                              content: Text('Playback arrives in Phase 4.'),
                            ),
                          ),
                    ),
                    PillButton(
                      label: 'My list',
                      icon: Icons.add,
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
