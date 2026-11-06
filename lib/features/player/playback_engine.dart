import 'package:flutter/widgets.dart';

import '../settings/app_settings.dart';

/// What to play. URLs may contain credentials: never log them unredacted.
@immutable
class PlaybackSource {
  const PlaybackSource({
    required this.url,
    this.headers = const {},
    this.isLive = false,
    this.allowUntrustedCert = false,
  });

  final Uri url;
  final Map<String, String> headers;
  final bool isLive;
  final bool allowUntrustedCert;
}

@immutable
class TrackOption {
  const TrackOption(this.id, this.label);
  final String id;
  final String label;
}

@immutable
class EngineState {
  const EngineState({
    this.playing = false,
    this.buffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.completed = false,
    this.error,
    this.audioTracks = const [],
    this.subtitleTracks = const [],
    this.audioTrackId,
    this.subtitleTrackId,
    this.hasVideo = false,
  });

  final bool playing;
  final bool buffering;
  final Duration position;
  final Duration duration;
  final bool completed;

  /// Raw engine error text (technical; classify before showing).
  final String? error;
  final List<TrackOption> audioTracks;
  final List<TrackOption> subtitleTracks;
  final String? audioTrackId;
  final String? subtitleTrackId;

  /// The first frame has arrived.
  final bool hasVideo;

  EngineState copyWith({
    bool? playing,
    bool? buffering,
    Duration? position,
    Duration? duration,
    bool? completed,
    String? error,
    bool clearError = false,
    List<TrackOption>? audioTracks,
    List<TrackOption>? subtitleTracks,
    String? audioTrackId,
    String? subtitleTrackId,
    bool? hasVideo,
  }) => EngineState(
    playing: playing ?? this.playing,
    buffering: buffering ?? this.buffering,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    completed: completed ?? this.completed,
    error: clearError ? null : (error ?? this.error),
    audioTracks: audioTracks ?? this.audioTracks,
    subtitleTracks: subtitleTracks ?? this.subtitleTracks,
    audioTrackId: audioTrackId ?? this.audioTrackId,
    subtitleTrackId: subtitleTrackId ?? this.subtitleTrackId,
    hasVideo: hasVideo ?? this.hasVideo,
  );
}

enum AspectMode { fit, fill, wide, standard }

/// Engine-agnostic player (brief section 7), so libmpv could be swapped.
abstract interface class PlaybackEngine {
  Stream<EngineState> get states;
  EngineState get state;

  /// Applies buffering and decoding preferences. Call before [open].
  Future<void> configure({
    required BufferingProfile buffering,
    required HardwareDecoding hardwareDecoding,
  });

  Future<void> open(PlaybackSource source, {Duration? start});
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);

  /// Stops and releases the stream (frees the provider connection slot).
  Future<void> stop();

  /// Whether the current item supports seeking (HTTP range requests).
  Future<bool> seekable();

  Future<void> setAudioTrack(String id);
  Future<void> setSubtitleTrack(String? id);
  Future<void> setHardwareDecoding(HardwareDecoding mode);

  Widget view({required AspectMode aspect});

  Future<void> dispose();
}
