import 'package:flutter/foundation.dart';

enum MediaKind { channel, movie, series }

/// Minimal item shape the browsing UI renders. Phase 2 maps database rows
/// to this; in Phase 0 it is only filled by the debug preview catalog.
@immutable
class MediaSummary {
  const MediaSummary({
    required this.id,
    required this.kind,
    required this.title,
    this.subtitle = '',
    this.imageUrl,
    this.progress,
    this.channelNumber,
    this.nowTitle,
    this.nextTitle,
  });

  final String id;
  final MediaKind kind;
  final String title;
  final String subtitle;
  final String? imageUrl;

  /// 0..1 watch progress, or live programme progress for channels.
  final double? progress;
  final int? channelNumber;
  final String? nowTitle;
  final String? nextTitle;

  /// Finished (Netflix marks these with a tick instead of a bar).
  bool get watched =>
      kind != MediaKind.channel && (progress ?? 0) >= watchedThreshold;

  /// Started but not finished: show the red bar.
  bool get inProgress =>
      kind != MediaKind.channel &&
      (progress ?? 0) > startedThreshold &&
      !watched;

  static const startedThreshold = 0.01;
  static const watchedThreshold = 0.95;

  MediaSummary withProgress(double? p) => MediaSummary(
    id: id,
    kind: kind,
    title: title,
    subtitle: subtitle,
    imageUrl: imageUrl,
    progress: p,
    channelNumber: channelNumber,
    nowTitle: nowTitle,
    nextTitle: nextTitle,
  );
}

@immutable
class MediaRow {
  const MediaRow({required this.title, required this.items, this.style});

  final String title;
  final List<MediaSummary> items;

  /// Overrides the card style for the whole row (e.g. wide cards for
  /// "Continue watching").
  final RowStyle? style;
}

enum RowStyle { poster, wide, channel }
