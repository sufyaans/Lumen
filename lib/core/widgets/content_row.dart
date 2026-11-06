import 'package:material_ui/material_ui.dart';

import '../../domain/media_summary.dart';
import '../focus/focus_memory.dart';
import 'cards.dart';

/// Horizontal page gutter: 4 % of width, like the prototype's `4vw`.
double pageGutter(BuildContext context) =>
    MediaQuery.sizeOf(context).width * 0.04;

/// A titled, horizontally scrolling, virtualised row of cards.
/// Hidden entirely when empty (brief section 3).
class ContentRow extends StatelessWidget {
  const ContentRow({super.key, required this.row, this.onItemPressed});

  final MediaRow row;
  final void Function(MediaSummary item)? onItemPressed;

  @override
  Widget build(BuildContext context) {
    if (row.items.isEmpty) return const SizedBox.shrink();
    final style = row.style ?? defaultStyleFor(row.items.first.kind);
    final m = CardMetrics.of(context);
    final gutter = pageGutter(context);
    const gap = 12.0;
    // Vertical room for the focus scale (1.07) and outline.
    const vPad = EdgeInsets.only(top: 16, bottom: 22);

    return FocusMemory(
      debugLabel: row.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, 10, gutter, 0),
            child: Text(
              row.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          SizedBox(
            height: m.heightFor(style) + vPad.vertical,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: EdgeInsets.symmetric(horizontal: gutter).add(vPad),
              itemExtent: m.widthFor(style) + gap,
              itemCount: row.items.length,
              itemBuilder: (context, i) {
                final item = row.items[i];
                return Padding(
                  padding: const EdgeInsets.only(right: gap),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: mediaCard(
                      context,
                      item,
                      style,
                      onPressed: onItemPressed == null
                          ? null
                          : () => onItemPressed!(item),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Plain-language empty state.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: pageGutter(context),
        vertical: 40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: t.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}
