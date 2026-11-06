import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/network/redaction.dart';
import '../settings/app_settings.dart';
import 'playback_engine.dart';

/// mpv cache/readahead/timeout per buffering profile (brief section 7).
/// Property names are mpv options: demuxer-max-bytes, demuxer-readahead-secs,
/// cache, cache-secs, network-timeout.
Map<String, String> bufferingOptions(BufferingProfile p) => switch (p) {
  BufferingProfile.lowLatency => {
    'cache': 'yes',
    'demuxer-max-bytes': '${8 * 1024 * 1024}',
    'demuxer-readahead-secs': '1',
    'cache-secs': '2',
    'network-timeout': '10',
  },
  BufferingProfile.balanced => {
    'cache': 'yes',
    'demuxer-max-bytes': '${32 * 1024 * 1024}',
    'demuxer-readahead-secs': '5',
    'cache-secs': '10',
    'network-timeout': '15',
  },
  BufferingProfile.stable => {
    'cache': 'yes',
    'demuxer-max-bytes': '${64 * 1024 * 1024}',
    'demuxer-readahead-secs': '20',
    'cache-secs': '30',
    'network-timeout': '20',
  },
};

/// ffmpeg reconnect options for live streams (passed through mpv's
/// `stream-lavf-o`).
const liveReconnectOptions =
    'reconnect=1,reconnect_streamed=1,reconnect_on_network_error=1,reconnect_delay_max=5';

/// mpv `hwdec` for a setting. "Auto" means software decoding on emulators,
/// whose hardware decoders accept streams but drop every frame.
String hwdecValue(HardwareDecoding h, {bool emulator = false}) => switch (h) {
  HardwareDecoding.auto => emulator ? 'no' : 'auto-safe',
  HardwareDecoding.on => 'auto',
  HardwareDecoding.off => 'no',
};

/// [PlaybackEngine] on media_kit (libmpv).
class MediaKitEngine implements PlaybackEngine {
  MediaKitEngine({
    HardwareDecoding hardwareDecoding = HardwareDecoding.auto,
    this.emulator = false,
  }) : _player = Player(
         configuration: const PlayerConfiguration(bufferSize: 32 * 1024 * 1024),
       ) {
    _controller = VideoController(
      _player,
      configuration: VideoControllerConfiguration(
        hwdec: hwdecValue(hardwareDecoding, emulator: emulator),
        enableHardwareAcceleration:
            hwdecValue(hardwareDecoding, emulator: emulator) != 'no',
      ),
    );
    final s = _player.stream;
    _subs.addAll([
      s.playing.listen((v) => _emit(_state.copyWith(playing: v))),
      s.buffering.listen((v) => _emit(_state.copyWith(buffering: v))),
      s.position.listen((v) => _emit(_state.copyWith(position: v))),
      s.duration.listen((v) => _emit(_state.copyWith(duration: v))),
      s.completed.listen((v) => _emit(_state.copyWith(completed: v))),
      s.width.listen((w) {
        if ((w ?? 0) > 0) _emit(_state.copyWith(hasVideo: true));
      }),
      s.error.listen((e) {
        NetLog.w('player error: $e');
        _emit(_state.copyWith(error: e));
      }),
      s.tracks.listen(
        (t) => _emit(
          _state.copyWith(
            audioTracks: [
              for (final a in t.audio)
                if (a.id != 'auto' && a.id != 'no')
                  TrackOption(a.id, _label(a.title, a.language, a.id)),
            ],
            subtitleTracks: [
              for (final x in t.subtitle)
                if (x.id != 'auto' && x.id != 'no')
                  TrackOption(x.id, _label(x.title, x.language, x.id)),
            ],
          ),
        ),
      ),
      s.track.listen(
        (t) => _emit(
          _state.copyWith(
            audioTrackId: t.audio.id,
            subtitleTrackId: t.subtitle.id,
          ),
        ),
      ),
    ]);
  }

  final Player _player;

  /// Running on an emulator (see [hwdecValue]).
  final bool emulator;
  late final VideoController _controller;
  final _subs = <StreamSubscription<Object?>>[];
  final _states = StreamController<EngineState>.broadcast();
  EngineState _state = const EngineState();

  static String _label(String? title, String? lang, String id) => [
    if (title != null && title.isNotEmpty) title,
    if (lang != null && lang.isNotEmpty) lang.toUpperCase(),
  ].join(' · ').ifEmpty('Track $id');

  NativePlayer? get _native => _player.platform is NativePlayer
      ? _player.platform! as NativePlayer
      : null;

  void _emit(EngineState s) {
    _state = s;
    if (!_states.isClosed) _states.add(s);
  }

  Future<void> _set(String k, String v) async {
    try {
      await _native?.setProperty(k, v);
    } catch (e) {
      NetLog.w('mpv option $k failed: $e');
    }
  }

  @override
  Stream<EngineState> get states => _states.stream;

  @override
  EngineState get state => _state;

  @override
  Future<void> configure({
    required BufferingProfile buffering,
    required HardwareDecoding hardwareDecoding,
  }) async {
    for (final e in bufferingOptions(buffering).entries) {
      await _set(e.key, e.value);
    }
    await _set('hwdec', hwdecValue(hardwareDecoding, emulator: emulator));
  }

  @override
  Future<void> open(PlaybackSource source, {Duration? start}) async {
    _emit(const EngineState(buffering: true));
    final ua = source.headers['User-Agent'];
    if (ua != null) await _set('user-agent', ua);
    final referrer = source.headers['Referer'];
    if (referrer != null) await _set('referrer', referrer);
    await _set('stream-lavf-o', source.isLive ? liveReconnectOptions : '');
    // Untrusted certificates only when the user allowed them for this
    // provider (brief 5.9). See docs/DECISIONS.md D48 for the default.
    if (source.allowUntrustedCert) await _set('tls-verify', 'no');
    await _player.open(
      Media(source.url.toString(), httpHeaders: source.headers, start: start),
      play: true,
    );
  }

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    _emit(const EngineState());
  }

  @override
  Future<bool> seekable() async {
    try {
      return (await _native?.getProperty('seekable')) == 'yes';
    } catch (_) {
      return _state.duration > Duration.zero;
    }
  }

  @override
  Future<void> setAudioTrack(String id) async {
    final t = _player.state.tracks.audio.where((a) => a.id == id).firstOrNull;
    if (t != null) await _player.setAudioTrack(t);
  }

  @override
  Future<void> setSubtitleTrack(String? id) async {
    if (id == null) return _player.setSubtitleTrack(SubtitleTrack.no());
    final t = _player.state.tracks.subtitle
        .where((s) => s.id == id)
        .firstOrNull;
    if (t != null) await _player.setSubtitleTrack(t);
  }

  @override
  Future<void> setHardwareDecoding(HardwareDecoding mode) =>
      _set('hwdec', hwdecValue(mode, emulator: emulator));

  @override
  Widget view({required AspectMode aspect}) => Video(
    controller: _controller,
    controls: null, // our own controls (NoVideoControls is null)
    // The player screen owns wakelock and background handling.
    wakelock: false,
    pauseUponEnteringBackgroundMode: false,
    fit: switch (aspect) {
      AspectMode.fit => BoxFit.contain,
      AspectMode.fill => BoxFit.cover,
      AspectMode.wide || AspectMode.standard => BoxFit.fill,
    },
    aspectRatio: switch (aspect) {
      AspectMode.wide => 16 / 9,
      AspectMode.standard => 4 / 3,
      _ => null,
    },
  );

  @override
  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    await _states.close();
    await _player.dispose();
  }
}

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}
