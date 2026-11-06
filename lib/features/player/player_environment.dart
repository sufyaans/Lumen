import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../app/data_providers.dart';
import '../../core/platform/form_factor.dart';
import '../../core/platform/orientation.dart';
import '../settings/app_settings.dart';
import 'media_kit_engine.dart';
import 'playback_engine.dart';
import 'player_data.dart';

/// Device-level setup around playback (brief section 7): orientation,
/// immersive system UI, screen awake, audio session / focus. Faked in tests.
abstract interface class PlaybackEnvironment {
  /// [onInterrupted] is called when another app takes audio focus, a call
  /// comes in, or headphones are unplugged.
  Future<void> enter({
    required FormFactor formFactor,
    required bool rotateForVideo,
    required void Function() onInterrupted,
  });

  /// Restores everything [enter] changed. Safe to call more than once.
  Future<void> exit({required FormFactor formFactor});
}

class DevicePlaybackEnvironment implements PlaybackEnvironment {
  final _subs = <StreamSubscription<Object?>>[];

  @override
  Future<void> enter({
    required FormFactor formFactor,
    required bool rotateForVideo,
    required void Function() onInterrupted,
  }) async {
    try {
      await OrientationPolicy.applyPlayback(
        formFactor,
        rotateForVideo: rotateForVideo,
      );
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } catch (_) {}
    try {
      await WakelockPlus.enable();
    } catch (_) {}
    try {
      // "Movie playback" so sound plays with the iOS silent switch on, and
      // Android audio focus is requested for media.
      final session = await AudioSession.instance;
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionMode: AVAudioSessionMode.moviePlayback,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.movie,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        ),
      );
      await session.setActive(true);
      _subs
        ..add(
          session.interruptionEventStream.listen((e) {
            if (e.begin) onInterrupted();
          }),
        )
        ..add(session.becomingNoisyEventStream.listen((_) => onInterrupted()));
    } catch (_) {}
  }

  @override
  Future<void> exit({required FormFactor formFactor}) async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    try {
      await WakelockPlus.disable();
    } catch (_) {}
    try {
      await (await AudioSession.instance).setActive(false);
    } catch (_) {}
    try {
      await SystemChrome.setEnabledSystemUIMode(
        formFactor == FormFactor.tv
            ? SystemUiMode.immersiveSticky
            : SystemUiMode.edgeToEdge,
      );
      await OrientationPolicy.applyBrowsing(formFactor);
    } catch (_) {}
  }
}

final playbackEnvironmentProvider = Provider<PlaybackEnvironment>(
  (ref) => DevicePlaybackEnvironment(),
);

/// Creates the engine for one player screen.
final playbackEngineFactoryProvider =
    Provider<PlaybackEngine Function(AppSettings)>(
      (ref) =>
          (s) => MediaKitEngine(hardwareDecoding: s.hardwareDecoding),
    );

final playerDataProvider = Provider<PlayerData>((ref) {
  final providerId = ref.watch(activeProviderIdProvider);
  final queries = ref.watch(browseQueriesProvider);
  if (providerId == null) return NoStreamsPlayerData(queries);
  return RepositoryPlayerData(
    repo: ref.watch(catalogRepositoryProvider),
    store: ref.watch(credentialStoreProvider),
    providerId: providerId,
    profileId: ref.watch(activeProfileIdProvider),
    settings: ref.watch(appSettingsProvider),
    network: ref.watch(networkForProvider),
    queries: queries,
    filter: ref.watch(contentFilterProvider),
  );
});
