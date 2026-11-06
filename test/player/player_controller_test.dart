import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/core/network/connection_error.dart';
import 'package:lumen/domain/media_summary.dart';
import 'package:lumen/features/player/media_kit_engine.dart';
import 'package:lumen/features/player/playback_engine.dart';
import 'package:lumen/features/player/player_controller.dart';
import 'package:lumen/features/player/player_data.dart';
import 'package:lumen/features/settings/app_settings.dart';

import 'fakes.dart';

const ms = Duration(milliseconds: 1);

PlayerController make(
  FakeEngine e,
  FakePlayerData d, {
  AppSettings settings = const AppSettings(),
  Duration firstFrame = const Duration(seconds: 30),
}) => PlayerController(
  engine: e,
  data: d,
  settings: settings,
  zapDebounce: ms * 60,
  reopenGap: ms * 5,
  retryDelays: [ms * 10, ms * 20, ms * 30],
  progressEvery: ms * 40,
  connectWindow: const Duration(seconds: 5),
  stallTimeout: ms * 80,
  numberTimeout: ms * 60,
  firstFrameTimeout: firstFrame,
);

Future<void> wait(int millis) =>
    Future<void>.delayed(Duration(milliseconds: millis));

void main() {
  test('live: opens one stream, starts on the preferred format', () async {
    final e = FakeEngine();
    final d = FakePlayerData(channels: channelList(5));
    final c = make(e, d);
    await c.start(const PlayRequest('live:2'));
    expect(e.opened.single.path, endsWith('/2.m3u8'));
    expect(c.channelIndex, 1);
    e.playingAt(Duration.zero);
    expect(c.phase, PlayerPhase.playing);
    expect(
      d.remembered,
      isEmpty,
      reason: 'preferred format worked; nothing to remember',
    );
  });

  test(
    'rapid zapping opens only the final channel, after the debounce',
    () async {
      final e = FakeEngine();
      final c = make(e, FakePlayerData(channels: channelList(10)));
      await c.start(const PlayRequest('live:1'));
      e.playingAt(Duration.zero);
      for (var i = 0; i < 6; i++) {
        c.zap(1);
        await wait(10);
      }
      expect(c.channelIndex, 6);
      expect(e.opened, hasLength(1), reason: 'no stream opened mid-zap');
      await wait(120);
      expect(e.opened, hasLength(2));
      expect(e.opened.last.path, contains('/7.'));
      // The previous stream was stopped before the next opened.
      expect(e.stops, 1);
      expect(e.openCount, 1, reason: 'never more than one stream open');
    },
  );

  test('zap wraps around both ends', () async {
    final e = FakeEngine();
    final c = make(e, FakePlayerData(channels: channelList(3)));
    await c.start(const PlayRequest('live:1'));
    c.zap(-1);
    expect(c.channelIndex, 2);
    c.zap(1);
    expect(c.channelIndex, 0);
  });

  test(
    'live failure: reconnecting, switches format, remembers what works',
    () async {
      final e = FakeEngine();
      final d = FakePlayerData(channels: channelList(3));
      final c = make(e, d);
      await c.start(const PlayRequest('live:1'));
      e.playingAt(Duration.zero); // was playing, then drops
      e.fail('stream ended');
      await wait(1);
      expect(c.phase, PlayerPhase.reconnecting);
      await wait(40);
      expect(
        e.opened.last.path,
        endsWith('/1.ts'),
        reason: 'switched m3u8 -> ts',
      );
      e.playingAt(Duration.zero);
      expect(c.phase, PlayerPhase.playing);
      expect(d.remembered, ['ts']);
    },
  );

  test(
    'instant refusal is classified as max connections, no retry loop',
    () async {
      final e = FakeEngine();
      final d = FakePlayerData(channels: channelList(3))
        ..classify = const ConnectionError(
          ConnectionErrorKind.maxConnections,
          maxConnections: 2,
        );
      final c = make(e, d);
      await c.start(const PlayRequest('live:1'));
      e.fail('HTTP error 403 Forbidden');
      await wait(30);
      expect(c.phase, PlayerPhase.failed);
      expect(c.error!.kind, ConnectionErrorKind.maxConnections);
      expect(c.error!.body, contains('allows 2'));
      expect(e.opened, hasLength(1));

      // Retry opens again.
      await c.retry();
      expect(e.opened, hasLength(2));
    },
  );

  test('gives up after 3 retries with the classified error', () async {
    final e = FakeEngine();
    final d = FakePlayerData(channels: channelList(1));
    final c = make(e, d);
    await c.start(const PlayRequest('live:1'));
    for (var i = 0; i < 4; i++) {
      e.fail('network error');
      await wait(60);
    }
    expect(c.phase, PlayerPhase.failed);
    expect(c.error!.kind, ConnectionErrorKind.timeoutOrRefused);
    expect(e.opened, hasLength(4), reason: 'first open + 3 retries');
    // Cycled through every alternate.
    expect(e.opened.map((u) => u.path.split('/').last).toSet(), {
      '1.m3u8',
      '1.ts',
      '1',
    });
  });

  test('live stall counts as a failure and reconnects', () async {
    final e = FakeEngine();
    final c = make(e, FakePlayerData(channels: channelList(1)));
    await c.start(const PlayRequest('live:1'));
    e.playingAt(Duration.zero);
    e.emit(e.state.copyWith(buffering: true));
    await wait(140);
    expect(e.opened.length, greaterThanOrEqualTo(2));
  });

  test(
    'number entry tunes after the timeout; unknown numbers say so',
    () async {
      final e = FakeEngine();
      final c = make(e, FakePlayerData(channels: channelList(10)));
      await c.start(const PlayRequest('live:1'));
      c.enterDigit('1');
      c.enterDigit('0');
      c.enterDigit('5');
      expect(c.pendingNumber, '105');
      await wait(100);
      expect(c.pendingNumber, '');
      expect(c.channels[c.channelIndex].channelNumber, 105);
      expect(e.opened.last.path, contains('/5.'));
      c.enterDigit('9');
      c.enterDigit('9');
      await wait(100);
      expect(c.message, 'No channel 99');
    },
  );

  test('VOD: resumes from saved position and saves progress periodically and on exit', () async {
    final e = FakeEngine();
    final d = FakePlayerData(saved: const Duration(minutes: 12));
    final c = make(e, d);
    await c.start(const PlayRequest('movie:7'));
    expect(e.startedAt.single, const Duration(minutes: 12));
    e.playingAt(
      const Duration(minutes: 12),
      duration: const Duration(minutes: 90),
    );
    await wait(60);
    expect(d.progress, isNotEmpty);
    e.playingAt(
      const Duration(minutes: 13),
      duration: const Duration(minutes: 90),
    );
    await c.close();
    expect(d.progress.last.$2, const Duration(minutes: 13));
    expect(e.stops, 1);
  });

  test(
    'VOD: explicit start overrides saved position; seeking is clamped',
    () async {
      final e = FakeEngine();
      final c = make(e, FakePlayerData(saved: const Duration(minutes: 12)));
      await c.start(const PlayRequest('movie:7', start: Duration.zero));
      expect(e.startedAt.single, Duration.zero);
      e.playingAt(
        const Duration(seconds: 5),
        duration: const Duration(minutes: 1),
      );
      await wait(5);
      await c.seekBy(const Duration(seconds: -30));
      expect(e.seeks.last, Duration.zero);
      await c.seekBy(const Duration(minutes: 5));
      expect(e.seeks.last, const Duration(minutes: 1));
    },
  );

  test('VOD without range support reports seeking unavailable', () async {
    final e = FakeEngine()..canSeek = false;
    final c = make(e, FakePlayerData());
    await c.start(const PlayRequest('movie:7'));
    e.playingAt(
      const Duration(seconds: 1),
      duration: const Duration(minutes: 1),
    );
    await wait(5);
    expect(c.seekable, isFalse);
    await c.seekBy(const Duration(seconds: 10));
    expect(e.seeks, isEmpty);
    expect(c.message, contains("can't be skipped"));
  });

  test('autoplay next episode when the setting is on', () async {
    final e = FakeEngine();
    final d = FakePlayerData();
    d.extra['e1'] = movieItem(
      '1',
      kind: MediaKind.series,
      next: const PlayRequest('series:s1', episodeId: 'e2'),
    );
    d.extra['e2'] = movieItem('2', kind: MediaKind.series);
    final c = make(e, d);
    await c.start(const PlayRequest('series:s1', episodeId: 'e1'));
    e.playingAt(
      const Duration(minutes: 40),
      duration: const Duration(minutes: 40),
    );
    e.emit(e.state.copyWith(completed: true));
    await wait(30);
    expect(e.opened.last.path, endsWith('/2.mp4'));
    expect(
      d.progress.first.$1,
      'e1',
      reason: 'finished episode marked watched',
    );

    final e2 = FakeEngine();
    final d2 = FakePlayerData()..extra.addAll(d.extra);
    final off = make(
      e2,
      d2,
      settings: const AppSettings(autoplayNextEpisode: false),
    );
    await off.start(const PlayRequest('series:s1', episodeId: 'e1'));
    e2.playingAt(
      const Duration(minutes: 40),
      duration: const Duration(minutes: 40),
    );
    e2.emit(e2.state.copyWith(completed: true));
    await wait(30);
    expect(e2.opened, hasLength(1));
    expect(off.phase, PlayerPhase.ended);
  });

  test(
    'background stops live (frees the slot) and reopens on return',
    () async {
      final e = FakeEngine();
      final c = make(e, FakePlayerData(channels: channelList(2)));
      await c.start(const PlayRequest('live:1'));
      e.playingAt(Duration.zero);
      await c.background();
      expect(e.stops, 1);
      expect(e.openCount, 0);
      await c.foreground();
      expect(e.opened, hasLength(2));
    },
  );

  test('nothing to play shows unavailable', () async {
    final c = make(FakeEngine(), FakePlayerData());
    await c.start(const PlayRequest('series:none'));
    expect(c.phase, PlayerPhase.unavailable);
  });

  test('favourite toggles for live channels', () async {
    final d = FakePlayerData(channels: channelList(2));
    final c = make(FakeEngine(), d);
    await c.start(const PlayRequest('live:2'));
    await c.toggleFavourite();
    expect(c.favourite, isTrue);
    expect(d.favourites, {'2'});
  });

  test('hardware decoding preference is applied and switchable', () async {
    final e = FakeEngine();
    final c = make(
      e,
      FakePlayerData(),
      settings: const AppSettings(hardwareDecoding: HardwareDecoding.on),
    );
    await c.start(const PlayRequest('movie:1'));
    expect(e.hw, HardwareDecoding.on);
    await c.setHardwareDecoding(HardwareDecoding.off);
    expect(e.hw, HardwareDecoding.off);
  });

  test('no picture within the first-frame timeout: retries, then fails (never spins forever)', () async {
    final e = FakeEngine();
    final c = make(
      e,
      FakePlayerData(channels: channelList(1)),
      firstFrame: ms * 50,
    );
    await c.start(const PlayRequest('live:1'));
    // The demuxer knows the size but the decoder never produces frames:
    // position stays at zero.
    e.emit(const EngineState(hasVideo: true, buffering: true));
    await wait(500);
    expect(e.opened.length, greaterThan(1), reason: 'retried');
    expect(c.phase, PlayerPhase.failed);
  });

  test('moving playback cancels the first-frame watchdog', () async {
    final e = FakeEngine();
    final c = make(e, FakePlayerData(), firstFrame: ms * 50);
    await c.start(const PlayRequest('movie:1'));
    e.playingAt(
      const Duration(seconds: 1),
      duration: const Duration(minutes: 5),
    );
    await wait(120);
    expect(e.opened, hasLength(1));
    expect(c.phase, PlayerPhase.playing);
  });

  test('Auto decoding is software on emulators, hardware elsewhere', () {
    expect(hwdecValue(HardwareDecoding.auto), 'auto-safe');
    expect(hwdecValue(HardwareDecoding.auto, emulator: true), 'no');
    expect(hwdecValue(HardwareDecoding.on, emulator: true), 'auto');
    expect(hwdecValue(HardwareDecoding.off), 'no');
  });
}
