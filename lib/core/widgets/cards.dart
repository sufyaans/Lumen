import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../domain/media_summary.dart';
import '../focus/focusable_card.dart';
import 'artwork.dart';
import 'fallback_art.dart';

/// Card sizes, mirroring the prototype's clamp() rules.
@immutable
class CardMetrics {
  const CardMetrics._(this.posterWidth, this.wideWidth, this.channelWidth);

  factory CardMetrics.of(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return CardMetrics._(
      (w * 0.14).clamp(116.0, 196.0),
      (w * 0.24).clamp(210.0, 340.0),
      (w * 0.26).clamp(220.0, 300.0),
    );
  }

  final double posterWidth;
  final double wideWidth;
  final double channelWidth;

  double get posterHeight => posterWidth * 3 / 2;
  double get wideHeight => wideWidth * 9 / 16;
  double get channelHeight => 148;

  double widthFor(RowStyle s) => switch (s) {
    RowStyle.poster => posterWidth,
    RowStyle.wide => wideWidth,
    RowStyle.channel => channelWidth,
  };

  double heightFor(RowStyle s) => switch (s) {
    RowStyle.poster => posterHeight,
    RowStyle.wide => wideHeight,
    RowStyle.channel => channelHeight,
  };
}

const _cardRadius = BorderRadius.all(Radius.circular(LumenRadii.card));

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, this.track});

  final double value;
  final Color? track;

  @override
  Widget build(BuildContext context) {
    final c = LumenColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: track ?? const Color(0x4DFFFFFF)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0),
              child: ColoredBox(color: c.accent),
            ),
          ],
        ),
      ),
    );
  }
}

/// 2:3 poster with the title drawn over generated art when there is no image.
class PosterCard extends StatelessWidget {
  const PosterCard({
    super.key,
    required this.item,
    required this.width,
    this.onPressed,
    this.focusNode,
  });

  final MediaSummary item;
  final double width;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return FocusableCard(
      focusNode: focusNode,
      onPressed: onPressed,
      semanticLabel: item.title,
      child: ClipRRect(
        borderRadius: _cardRadius,
        child: SizedBox(
          width: width,
          height: width * 3 / 2,
          child: Artwork(
            title: item.title,
            url: item.imageUrl,
            width: width,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  if (item.subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.labelSmall?.copyWith(
                          color: const Color(0xD9FFFFFF),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 16:9 card used for "Continue watching".
class WideCard extends StatelessWidget {
  const WideCard({
    super.key,
    required this.item,
    required this.width,
    this.onPressed,
    this.focusNode,
  });

  final MediaSummary item;
  final double width;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return FocusableCard(
      focusNode: focusNode,
      onPressed: onPressed,
      semanticLabel: item.title,
      child: ClipRRect(
        borderRadius: _cardRadius,
        child: SizedBox(
          width: width,
          height: width * 9 / 16,
          child: Artwork(
            title: item.title,
            url: item.imageUrl,
            width: width,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    item.kind == MediaKind.movie ? 'Movie' : 'Series',
                    style: t.labelSmall?.copyWith(
                      color: const Color(0xD9FFFFFF),
                    ),
                  ),
                  if (item.progress != null) ...[
                    const SizedBox(height: 8),
                    _ProgressBar(value: item.progress!),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Channel card: logo, name, number, now/next and programme progress.
class ChannelCard extends StatelessWidget {
  const ChannelCard({
    super.key,
    required this.item,
    required this.width,
    this.onPressed,
    this.focusNode,
  });

  final MediaSummary item;
  final double width;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;

  static String initials(String title) => title
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => String.fromCharCode(w.runes.first))
      .take(3)
      .join();

  @override
  Widget build(BuildContext context) {
    final c = LumenColors.of(context);
    final t = Theme.of(context).textTheme;
    return FocusableCard(
      focusNode: focusNode,
      onPressed: onPressed,
      semanticLabel: item.title,
      child: Container(
        width: width,
        height: 148,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: _cardRadius,
          border: Border.all(color: c.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: _cardRadius,
                  child: SizedBox.square(
                    dimension: 42,
                    child: item.imageUrl == null
                        ? FallbackArt(
                            title: item.title,
                            child: Center(
                              child: Text(
                                initials(item.title),
                                style: t.labelMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          )
                        : ColoredBox(
                            color: c.surfaceHigh,
                            child: Artwork(
                              title: item.title,
                              url: item.imageUrl,
                              width: 42,
                              fit: BoxFit.contain,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (item.channelNumber != null)
                        Text(
                          'Channel ${item.channelNumber}',
                          style: t.labelSmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: c.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    item.nowTitle ?? 'Live',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleSmall,
                  ),
                ),
              ],
            ),
            if (item.progress != null) ...[
              const SizedBox(height: 8),
              _ProgressBar(value: item.progress!, track: c.surfaceHigh),
            ],
            const SizedBox(height: 4),
            Text(
              item.nextTitle ?? item.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Picks the right card for an item and row style.
Widget mediaCard(
  BuildContext context,
  MediaSummary item,
  RowStyle style, {
  VoidCallback? onPressed,
}) {
  final m = CardMetrics.of(context);
  return switch (style) {
    RowStyle.poster => PosterCard(
      item: item,
      width: m.posterWidth,
      onPressed: onPressed,
    ),
    RowStyle.wide => WideCard(
      item: item,
      width: m.wideWidth,
      onPressed: onPressed,
    ),
    RowStyle.channel => ChannelCard(
      item: item,
      width: m.channelWidth,
      onPressed: onPressed,
    ),
  };
}

RowStyle defaultStyleFor(MediaKind k) =>
    k == MediaKind.channel ? RowStyle.channel : RowStyle.poster;
