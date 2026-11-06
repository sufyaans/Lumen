import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lumen/core/network/connection_error.dart';
import 'package:lumen/core/platform/form_factor.dart';
import 'package:lumen/features/player/player_data.dart';
import 'package:lumen/features/player/player_environment.dart';
import 'package:lumen/features/settings/app_settings.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';
import 'fakes.dart';

class FakeEnv implements PlaybackEnvironment {
  int enters = 0;
  int exits = 0;
  bool? rotate;
  void Function()? interrupt;

  @override
  Future<void> enter({
    required FormFactor formFactor,
    required bool rotateForVideo,
    required void Function() onInterrupted,
  }) async {
    enters++;
    rotate = rotateForVideo;
    interrupt = onInterrupted;
  }

  @override
  Future<void> exit({required FormFactor formFactor}) async => exits++;
}

class Rig {
  Rig(this.engine, this.env, this.data);
  final FakeEngine engine;
  final FakeEnv env;
  final FakePlayerData data;
}

Future<Rig> openPlayer(
  WidgetTester tester,
  PlayRequest request, {
  FormFactor ff = FormFactor.tv,
  FakePlayerData? data,
}) async {
  final engine = FakeEngine();
  final env = FakeEnv();
  final d = data ?? FakePlayerData(channels: channelList(6));
  await pumpLumen(
    tester,
    formFactor: ff,
    extraOverrides: [
      playbackEngineFactoryProvider.overrideWithValue((_) => engine),
      playbackEnvironmentProvider.overrideWithValue(env),
      playerDataProvider.overrideWithValue(d),
    ],
  );
  unawaited(
    GoRouter.of(tester.element(find.byType(Navigator).first))
        .push('/play', extra: request),
  );
  await settle(tester);
  return Rig(engine, env, d);
}

/// The player shows spinners, so pump fixed steps instead of settling.
Future<void> settle(
  WidgetTester tester, [
  Duration d = const Duration(milliseconds: 400),
]) async {
  await tester.pump();
  await tester.pump(d);
}

Future<void> key(
  WidgetTester tester,
  LogicalKeyboardKey k, [
  Duration after = const Duration(milliseconds: 50),
]) async {
  await tester.sendKeyEvent(k);
  await tester.pump(after);
}

void main() {
  testWidgets('live: opens once, shows the channel, enters playback mode', (
    tester,
  ) async {
    final r = await openPlayer(tester, const PlayRequest('live:2'));
    expect(r.engine.opened, hasLength(1));
    expect(r.env.enters, 1);
    r.engine.playingAt(Duration.zero);
    await settle(tester);
    expect(find.text('102  Channel 2'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('Show 2'), findsOneWidget);
  });

  testWidgets(
    'remote: Down zaps once after the debounce; digits tune by number',
    (tester) async {
      final r = await openPlayer(tester, const PlayRequest('live:1'));
      r.engine.playingAt(Duration.zero);
      await settle(tester, const Duration(seconds: 5)); // controls auto-hide
      await key(tester, LogicalKeyboardKey.arrowDown);
      await key(tester, LogicalKeyboardKey.arrowDown);
      expect(r.engine.opened, hasLength(1), reason: 'debounced');
      await settle(tester, const Duration(milliseconds: 800));
      expect(r.engine.opened, hasLength(2));
      expect(r.engine.opened.last.path, contains('/3.'));

      await key(tester, LogicalKeyboardKey.digit1);
      await key(tester, LogicalKeyboardKey.digit0);
      await key(tester, LogicalKeyboardKey.digit5);
      expect(find.text('105'), findsOneWidget);
      await settle(tester, const Duration(milliseconds: 1800));
      expect(r.engine.opened.last.path, contains('/5.'));
    },
  );

  testWidgets(
    'Back hides the controls first, then leaves and restores the device',
    (tester) async {
      final r = await openPlayer(tester, const PlayRequest('live:1'));
      r.engine.playingAt(Duration.zero);
      await settle(tester);
      expect(find.text('LIVE'), findsOneWidget);
      await key(
        tester,
        LogicalKeyboardKey.escape,
        const Duration(milliseconds: 300),
      );
      expect(r.env.exits, 0, reason: 'first Back only hides the controls');
      await key(
        tester,
        LogicalKeyboardKey.escape,
        const Duration(milliseconds: 300),
      );
      await settle(tester);
      expect(r.env.exits, 1);
      expect(
        r.engine.stops,
        greaterThanOrEqualTo(1),
        reason: 'stream released',
      );
      expect(
        GoRouter.of(tester.element(find.byType(Navigator).first))
            .state
            .uri
            .path,
        '/home',
      );
    },
  );

  testWidgets('a refused stream shows Too many devices with Retry', (
    tester,
  ) async {
    final d = FakePlayerData(channels: channelList(3))
      ..classify = const ConnectionError(
        ConnectionErrorKind.maxConnections,
        maxConnections: 2,
      );
    final r = await openPlayer(tester, const PlayRequest('live:1'), data: d);
    r.engine.fail('HTTP 403');
    await settle(tester);
    expect(find.text('Too many devices in use'), findsOneWidget);
    expect(find.textContaining('allows 2'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await settle(tester);
    expect(r.engine.opened, hasLength(2));
  });

  testWidgets('a dropped live stream shows Reconnecting…', (tester) async {
    final r = await openPlayer(tester, const PlayRequest('live:1'));
    r.engine.playingAt(Duration.zero);
    await settle(tester);
    r.engine.fail('stream ended');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Reconnecting…'), findsOneWidget);
    await settle(tester, const Duration(seconds: 2));
    expect(r.engine.opened.last.path, endsWith('.ts'));
  });

  testWidgets('Left opens the channel list; picking a channel tunes it', (
    tester,
  ) async {
    final r = await openPlayer(tester, const PlayRequest('live:1'));
    r.engine.playingAt(Duration.zero);
    await settle(tester, const Duration(seconds: 5));
    await key(
      tester,
      LogicalKeyboardKey.arrowLeft,
      const Duration(milliseconds: 300),
    );
    expect(find.text('Channels'), findsWidgets);
    await tester.tap(find.text('Channel 4').last);
    await settle(tester);
    expect(r.engine.opened.last.path, contains('/4.'));
  });

  testWidgets(
    'VOD: seek keys, play/pause, settings panel with hardware decoding',
    (tester) async {
      final r = await openPlayer(
        tester,
        const PlayRequest('movie:9'),
        ff: FormFactor.tablet,
      );
      r.engine.playingAt(
        const Duration(minutes: 1),
        duration: const Duration(minutes: 30),
      );
      await settle(tester);
      expect(find.text('1:00'), findsOneWidget);
      expect(find.text('30:00'), findsOneWidget);
      await settle(tester, const Duration(seconds: 5));
      await key(tester, LogicalKeyboardKey.arrowRight);
      expect(r.engine.seeks.last, const Duration(minutes: 1, seconds: 10));
      await key(tester, LogicalKeyboardKey.mediaPlayPause);
      expect(r.engine.state.playing, isFalse);

      await tester.tap(find.bySemanticsLabel('Player settings'));
      await settle(tester);
      expect(find.text('Hardware decoding'), findsOneWidget);
      await tester.tap(find.text('Off').last);
      await settle(tester);
      expect(r.engine.hw, HardwareDecoding.off);
      await tester.tap(find.text('Fill'));
      await settle(tester);
    },
  );

  testWidgets('audio interruption pauses playback', (tester) async {
    final r = await openPlayer(
      tester,
      const PlayRequest('movie:9'),
      ff: FormFactor.phone,
    );
    r.engine.playingAt(
      const Duration(seconds: 3),
      duration: const Duration(minutes: 3),
    );
    await settle(tester);
    expect(
      r.env.rotate,
      isTrue,
      reason: 'phone rotates to landscape by default',
    );
    r.env.interrupt!();
    await settle(tester);
    expect(r.engine.state.playing, isFalse);
  });

  testWidgets('nothing to play says so plainly', (tester) async {
    await openPlayer(tester, const PlayRequest('series:none'));
    expect(find.text("This can't be played"), findsOneWidget);
  });

  testWidgets('opening a channel from Live TV starts the player', (
    tester,
  ) async {
    final engine = FakeEngine();
    await pumpLumen(
      tester,
      formFactor: FormFactor.tablet,
      extraOverrides: [
        playbackEngineFactoryProvider.overrideWithValue((_) => engine),
        playbackEnvironmentProvider.overrideWithValue(FakeEnv()),
        playerDataProvider.overrideWithValue(
          FakePlayerData(channels: channelList(3)),
        ),
      ],
    );
    await tester.tap(find.text('Live TV').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preview News').first);
    await settle(tester);
    expect(engine.opened, hasLength(1));
    expect(engine.opened.single.path, contains('/101.'));
  });
}
