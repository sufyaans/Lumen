import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/network/connection_error.dart';
import '../../core/network/redaction.dart';
import '../../domain/media_summary.dart';
import '../settings/app_settings.dart';
import 'playback_engine.dart';
import 'player_data.dart';

enum PlayerPhase { loading, playing, reconnecting, failed, ended, unavailable }

/// Player behaviour from brief section 7, independent of the UI:
/// * one active stream; the previous one is stopped before the next opens,
///   with a short gap,
/// * channel zapping debounced so rapid presses don't open a dozen
///   connections,
/// * live auto-recovery: up to 3 retries with backoff, switching ts/m3u8 on
///   the first failure and remembering what works,
/// * instant 401/403/EOF after connect is classified as max_connections,
/// * VOD progress saved every 10 s and on exit; autoplay next episode.
class PlayerController extends ChangeNotifier {
  PlayerController({
    required this.engine,
    required this.data,
    required this.settings,
    this.zapDebounce = const Duration(milliseconds: 350),
    this.reopenGap = const Duration(milliseconds: 300),
    this.retryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ],
    this.progressEvery = const Duration(seconds: 10),
    this.connectWindow = const Duration(seconds: 6),
    this.stallTimeout = const Duration(seconds: 15),
    this.numberTimeout = const Duration(milliseconds: 1300),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _sub = engine.states.listen(_onEngine);
  }

  final PlaybackEngine engine;
  final PlayerData data;
  final AppSettings settings;
  final Duration zapDebounce;
  final Duration reopenGap;
  final List<Duration> retryDelays;
  final Duration progressEvery;
  final Duration connectWindow;
  final Duration stallTimeout;
  final Duration numberTimeout;
  final DateTime Function() _clock;

  late final StreamSubscription<EngineState> _sub;

  PlayableItem? item;
  PlayerPhase phase = PlayerPhase.loading;
  ConnectionError? error;
  int attempt = 0;
  int sourceIndex = 0;
  bool? seekable;
  bool favourite = false;
  AspectMode aspect = AspectMode.fit;
  late HardwareDecoding hardwareDecoding = settings.hardwareDecoding;

  /// Live: channels to zap through and the one shown.
  List<MediaSummary> channels = const [];
  int channelIndex = -1;
  String? categoryId;

  /// Digits typed on the remote, shown big until they resolve.
  String pendingNumber = '';

  /// One-off notices ("No channel 123").
  String? message;

  /// How many streams have been opened (for tests and diagnostics).
  int opens = 0;

  EngineState get engineState => engine.state;

  bool _hasOpen = false;
  bool _disposed = false;
  bool _recovering = false;
  DateTime? _openedAt;
  DateTime? _bufferingSince;
  Duration? _resumeAt;
  bool _gotVideo = false;
  Timer? _zapTimer;
  Timer? _numberTimer;
  Timer? _progressTimer;
  Timer? _stallTimer;
  int _generation = 0;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  // ---- start / open ------------------------------------------------------

  Future<void> start(PlayRequest request) async {
    await engine.configure(
      buffering: settings.buffering,
      hardwareDecoding: settings.hardwareDecoding,
    );
    categoryId = request.categoryId;
    final resolved = await data.resolve(request);
    if (_disposed) return;
    if (resolved == null) {
      item = null;
      phase = PlayerPhase.unavailable;
      _notify();
      return;
    }
    if (resolved.isLive) {
      channels = await data.zapList(request.categoryId);
      channelIndex = channels.indexWhere((c) => c.id == request.itemId);
      if (channelIndex < 0 && channels.isNotEmpty) {
        // Opened from somewhere else: zap through all channels.
        channels = await data.zapList(null);
        channelIndex = channels.indexWhere((c) => c.id == request.itemId);
      }
    }
    final start = request.start ?? await data.savedPosition(resolved);
    await _open(resolved, start: start);
  }

  Future<void> _open(
    PlayableItem next, {
    Duration? start,
    int source = 0,
  }) async {
    final gen = ++_generation;
    _stallTimer?.cancel();
    if (_hasOpen) {
      await _saveProgress();
      await engine.stop();
      _hasOpen = false;
      // Give the provider a moment to release the previous connection.
      await Future<void>.delayed(reopenGap);
      if (gen != _generation || _disposed) return;
    }
    item = next;
    sourceIndex = source;
    error = null;
    seekable = null;
    _gotVideo = false;
    _resumeAt = start;
    if (phase != PlayerPhase.reconnecting) {
      phase = PlayerPhase.loading;
      attempt = 0;
    }
    favourite = next.isLive ? await data.isFavourite(next) : false;
    _notify();
    _openedAt = _clock();
    _hasOpen = true;
    opens++;
    await engine.open(next.sources[sourceIndex], start: start);
    if (next.isLive) unawaited(data.markWatched(next));
    _progressTimer?.cancel();
    if (!next.isLive) {
      _progressTimer = Timer.periodic(progressEvery, (_) => _saveProgress());
    }
  }

  // ---- engine events -----------------------------------------------------

  void _onEngine(EngineState s) {
    final it = item;
    if (it == null || _disposed) return;

    if (s.error != null && !_recovering && phase != PlayerPhase.failed) {
      unawaited(_onFailure());
      return;
    }

    final started = s.hasVideo || (s.playing && s.position > Duration.zero);
    if (started && !_gotVideo) {
      _gotVideo = true;
      if (phase != PlayerPhase.playing) {
        phase = PlayerPhase.playing;
        if (it.isLive && sourceIndex > 0) {
          // The alternate format worked: use it first next time.
          unawaited(
            data.rememberLiveFormat(sourceExtension(it.sources[sourceIndex])),
          );
        }
        attempt = 0;
      }
      if (!it.isLive) unawaited(_checkSeekable());
    }

    // Live stall detection: buffering for too long counts as a failure.
    if (it.isLive && s.buffering && _gotVideo) {
      _bufferingSince ??= _clock();
      _stallTimer ??= Timer(stallTimeout, () {
        _stallTimer = null;
        if (engine.state.buffering && !_recovering) {
          unawaited(_onFailure(stalled: true));
        }
      });
    } else if (!s.buffering) {
      _bufferingSince = null;
      _stallTimer?.cancel();
      _stallTimer = null;
    }

    if (s.completed && !it.isLive && phase != PlayerPhase.ended) {
      phase = PlayerPhase.ended;
      unawaited(_onCompleted());
    }
    _notify();
  }

  Future<void> _checkSeekable() async {
    final v = await engine.seekable();
    if (_disposed) return;
    seekable = v;
    _notify();
  }

  Future<void> _onFailure({bool stalled = false}) async {
    final it = item;
    if (it == null || _recovering) return;
    _recovering = true;
    final gen = _generation;
    try {
      final failedFast =
          !_gotVideo &&
          _openedAt != null &&
          _clock().difference(_openedAt!) < connectWindow;
      final source = it.sources[sourceIndex];
      NetLog.w(
        'playback failed (attempt ${attempt + 1}, fast: $failedFast, stalled: $stalled): ${Redactor.redactUri(source.url)}',
      );
      await engine.stop();
      _hasOpen = false;
      if (gen != _generation || _disposed) return;

      // 401/403 or EOF straight after connect: almost always the account's
      // connection limit (brief section 7).
      if (failedFast && attempt == 0) {
        final e = await data.classifyFailure(source);
        if (gen != _generation || _disposed) return;
        if (e?.kind == ConnectionErrorKind.maxConnections) {
          _fail(e!);
          return;
        }
      }

      attempt++;
      if (attempt > retryDelays.length) {
        _fail(
          await data.classifyFailure(source) ??
              const ConnectionError(
                ConnectionErrorKind.timeoutOrRefused,
                details: 'playback failed after retries',
              ),
        );
        return;
      }
      phase = PlayerPhase.reconnecting;
      _notify();
      // Live: switch format on the first failure (ts <-> m3u8, then the short
      // URL form); later retries keep cycling through the alternates.
      final nextSource = it.isLive && it.sources.length > 1
          ? (sourceIndex + 1) % it.sources.length
          : sourceIndex;
      await Future<void>.delayed(retryDelays[attempt - 1]);
      if (gen != _generation || _disposed) return;
      final resume = it.isLive
          ? null
          : engine.state.position > Duration.zero
          ? engine.state.position
          : _resumeAt;
      _recovering = false;
      await _open(it, start: resume, source: nextSource);
    } finally {
      _recovering = false;
    }
  }

  void _fail(ConnectionError e) {
    error = e;
    phase = PlayerPhase.failed;
    _progressTimer?.cancel();
    _notify();
  }

  Future<void> _onCompleted() async {
    final it = item;
    if (it == null) return;
    await data.saveProgress(it, engine.state.duration, engine.state.duration);
    final next = it.nextEpisode;
    if (next != null && settings.autoplayNextEpisode) {
      final resolved = await data.resolve(next);
      if (resolved != null && !_disposed) await _open(resolved);
    }
  }

  // ---- user actions -------------------------------------------------------

  /// User tapped Retry after a failure.
  Future<void> retry() async {
    final it = item;
    if (it == null) return;
    attempt = 0;
    phase = PlayerPhase.loading;
    _notify();
    await _open(it, start: it.isLive ? null : engine.state.position);
  }

  /// Channel up/down. The target updates at once; the stream opens after
  /// [zapDebounce] of no further presses.
  void zap(int delta) {
    if (channels.isEmpty) return;
    channelIndex =
        ((channelIndex < 0 ? 0 : channelIndex) + delta) % channels.length;
    if (channelIndex < 0) channelIndex += channels.length;
    _notify();
    _zapTimer?.cancel();
    _zapTimer = Timer(zapDebounce, () => unawaited(_tuneTo(channelIndex)));
  }

  /// Jump straight to a channel from the list overlay.
  Future<void> tuneTo(int index) async {
    _zapTimer?.cancel();
    await _tuneTo(index);
  }

  Future<void> _tuneTo(int index) async {
    if (index < 0 || index >= channels.length) return;
    channelIndex = index;
    final c = channels[index];
    if (item != null &&
        item!.isLive &&
        'live:${item!.remoteId}' == c.id &&
        phase == PlayerPhase.playing) {
      return;
    }
    final resolved = await data.resolve(
      PlayRequest(c.id, categoryId: categoryId),
    );
    if (resolved == null || _disposed) return;
    phase = PlayerPhase.loading;
    attempt = 0;
    await _open(resolved);
  }

  /// Remote number keys: digits build a channel number, applied after
  /// [numberTimeout] (brief section 7: 1.3 s).
  void enterDigit(String digit) {
    if (channels.isEmpty) return;
    pendingNumber = (pendingNumber + digit);
    if (pendingNumber.length > 5) {
      pendingNumber = pendingNumber.substring(pendingNumber.length - 5);
    }
    _notify();
    _numberTimer?.cancel();
    _numberTimer = Timer(numberTimeout, () {
      final n = int.tryParse(pendingNumber);
      pendingNumber = '';
      final i = n == null
          ? -1
          : channels.indexWhere((c) => c.channelNumber == n);
      if (i < 0) {
        message = 'No channel $n';
        _notify();
      } else {
        _zapTimer?.cancel();
        unawaited(_tuneTo(i));
      }
    });
  }

  void clearMessage() {
    message = null;
  }

  Future<void> togglePlay() async {
    if (engine.state.playing) {
      await engine.pause();
      await _saveProgress();
    } else {
      await engine.play();
    }
  }

  Future<void> seekBy(Duration d) async {
    if (item?.isLive ?? true) return;
    if (seekable == false) {
      message = "This video can't be skipped through";
      _notify();
      return;
    }
    final s = engine.state;
    var to = s.position + d;
    if (to < Duration.zero) to = Duration.zero;
    if (s.duration > Duration.zero && to > s.duration) to = s.duration;
    await engine.seek(to);
  }

  Future<void> setAspect(AspectMode a) async {
    aspect = a;
    _notify();
  }

  Future<void> setHardwareDecoding(HardwareDecoding h) async {
    hardwareDecoding = h;
    await engine.setHardwareDecoding(h);
    _notify();
  }

  Future<void> toggleFavourite() async {
    final it = item;
    if (it == null || !it.isLive) return;
    favourite = await data.toggleFavourite(it);
    message = favourite ? 'Added to favourites' : 'Removed from favourites';
    _notify();
  }

  // ---- lifecycle ------------------------------------------------------------

  bool _stoppedForBackground = false;

  /// App went to the background for longer than the grace period: stop live
  /// streams (frees the provider connection) and pause VOD.
  Future<void> background() async {
    final it = item;
    if (it == null || !_hasOpen) return;
    await _saveProgress();
    if (it.isLive) {
      await engine.stop();
      _hasOpen = false;
      _stoppedForBackground = true;
    } else {
      await engine.pause();
    }
  }

  Future<void> foreground() async {
    final it = item;
    if (it == null || !_stoppedForBackground) return;
    _stoppedForBackground = false;
    await _open(it);
  }

  Future<void> _saveProgress() async {
    final it = item;
    if (it == null || it.isLive || !_hasOpen) return;
    final s = engine.state;
    if (s.position > Duration.zero && s.duration > Duration.zero) {
      await data.saveProgress(it, s.position, s.duration);
    }
  }

  /// Leaving the player: save progress and release the stream.
  Future<void> close() async {
    _zapTimer?.cancel();
    _numberTimer?.cancel();
    _progressTimer?.cancel();
    _stallTimer?.cancel();
    await _saveProgress();
    if (_hasOpen) await engine.stop();
    _hasOpen = false;
  }

  @override
  void dispose() {
    _disposed = true;
    _zapTimer?.cancel();
    _numberTimer?.cancel();
    _progressTimer?.cancel();
    _stallTimer?.cancel();
    unawaited(_sub.cancel());
    super.dispose();
  }
}
