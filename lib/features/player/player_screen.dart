import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../core/focus/focus_memory.dart';
import '../../core/focus/focusable_card.dart';
import '../../core/platform/form_factor.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/content_row.dart';
import '../../domain/media_summary.dart';
import '../settings/app_settings.dart';
import 'playback_engine.dart';
import 'player_controller.dart';
import 'player_data.dart';
import 'player_environment.dart';

String _clock(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
}

/// Full-screen player (brief section 7; prototype player).
///
/// * Back first closes panels, then hides the controls, then leaves.
/// * Live: Up/Down or Channel keys zap, digits enter a channel number, Left
///   opens the channel list, Select shows the controls.
/// * VOD: Left/Right seek 10 s, media keys play/pause and skip 30 s.
/// * Leaving the app for more than [backgroundGrace] stops live streams
///   (frees the provider connection) and pauses VOD.
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({
    super.key,
    required this.request,
    this.backgroundGrace = const Duration(seconds: 20),
  });

  final PlayRequest request;
  final Duration backgroundGrace;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

enum _Panel { none, channels, settings }

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late final PlaybackEngine _engine;
  late final PlayerController _c;
  late final PlaybackEnvironment _env;
  late final FormFactor _ff;
  late final AppLifecycleListener _lifecycle;

  final _rootFocus = FocusNode(debugLabel: 'player-root');
  final _primaryButton = FocusNode(debugLabel: 'player-primary');
  bool _overlay = true;
  _Panel _panel = _Panel.none;
  Timer? _hideTimer;
  Timer? _backgroundTimer;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(appSettingsProvider);
    _ff = ref.read(formFactorProvider);
    _engine = ref.read(playbackEngineFactoryProvider)(settings);
    _env = ref.read(playbackEnvironmentProvider);
    _c = PlayerController(
      engine: _engine,
      data: ref.read(playerDataProvider),
      settings: settings,
    )..addListener(_onController);
    unawaited(
      _env.enter(
        formFactor: _ff,
        rotateForVideo: settings.rotateForVideo,
        onInterrupted: () {
          if (_c.engineState.playing) unawaited(_c.togglePlay());
        },
      ),
    );
    unawaited(_c.start(widget.request));
    _lifecycle = AppLifecycleListener(
      onHide: () {
        _backgroundTimer?.cancel();
        _backgroundTimer = Timer(
          widget.backgroundGrace,
          () => unawaited(_c.background()),
        );
      },
      onShow: () {
        _backgroundTimer?.cancel();
        unawaited(_c.foreground());
      },
    );
    _scheduleHide();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _rootFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _backgroundTimer?.cancel();
    _lifecycle.dispose();
    _c.removeListener(_onController);
    unawaited(_shutdown());
    _rootFocus.dispose();
    _primaryButton.dispose();
    super.dispose();
  }

  Future<void> _shutdown() async {
    if (_closed) return;
    _closed = true;
    await _c.close();
    _c.dispose();
    await _engine.dispose();
    // Restore orientation and system UI, including after errors.
    await _env.exit(formFactor: _ff);
  }

  void _onController() {
    if (!mounted) return;
    final msg = _c.message;
    if (msg != null) {
      _c.clearMessage();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
        );
    }
    setState(() {});
  }

  bool get _keepOverlay =>
      _panel != _Panel.none ||
      _c.phase == PlayerPhase.failed ||
      _c.phase == PlayerPhase.unavailable ||
      _c.phase == PlayerPhase.ended ||
      (!_c.engineState.playing &&
          _c.phase == PlayerPhase.playing &&
          !(_c.item?.isLive ?? true));

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || _keepOverlay) return;
      setState(() => _overlay = false);
      _rootFocus.requestFocus();
    });
  }

  void _showOverlay({bool focusControls = false}) {
    final wasHidden = !_overlay;
    setState(() => _overlay = true);
    _scheduleHide();
    if (wasHidden && focusControls) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _primaryButton.context != null) {
          _primaryButton.requestFocus();
        }
      });
    }
  }

  /// Back: close a panel, then hide the controls, then leave.
  void _back() {
    if (_panel != _Panel.none) {
      setState(() => _panel = _Panel.none);
      _rootFocus.requestFocus();
      return;
    }
    if (_overlay && _ff == FormFactor.tv && _c.phase == PlayerPhase.playing) {
      setState(() => _overlay = false);
      _rootFocus.requestFocus();
      return;
    }
    unawaited(_leave());
  }

  Future<void> _leave() async {
    await _shutdown();
    if (mounted) Navigator.of(context).pop();
  }

  static final _digits = {
    LogicalKeyboardKey.digit0: '0',
    LogicalKeyboardKey.digit1: '1',
    LogicalKeyboardKey.digit2: '2',
    LogicalKeyboardKey.digit3: '3',
    LogicalKeyboardKey.digit4: '4',
    LogicalKeyboardKey.digit5: '5',
    LogicalKeyboardKey.digit6: '6',
    LogicalKeyboardKey.digit7: '7',
    LogicalKeyboardKey.digit8: '8',
    LogicalKeyboardKey.digit9: '9',
    LogicalKeyboardKey.numpad0: '0',
    LogicalKeyboardKey.numpad1: '1',
    LogicalKeyboardKey.numpad2: '2',
    LogicalKeyboardKey.numpad3: '3',
    LogicalKeyboardKey.numpad4: '4',
    LogicalKeyboardKey.numpad5: '5',
    LogicalKeyboardKey.numpad6: '6',
    LogicalKeyboardKey.numpad7: '7',
    LogicalKeyboardKey.numpad8: '8',
    LogicalKeyboardKey.numpad9: '9',
  };

  /// Keys that work whether or not the controls are visible.
  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final k = e.logicalKey;
    final live = _c.item?.isLive ?? false;
    final hidden = !_overlay && _panel == _Panel.none;

    if (k == LogicalKeyboardKey.mediaPlayPause ||
        k == LogicalKeyboardKey.mediaPlay ||
        k == LogicalKeyboardKey.mediaPause) {
      unawaited(_c.togglePlay());
      _showOverlay();
      return KeyEventResult.handled;
    }
    if (live) {
      if (k == LogicalKeyboardKey.channelUp) return _zap(-1);
      if (k == LogicalKeyboardKey.channelDown) return _zap(1);
      final d = _digits[k];
      if (d != null) {
        _c.enterDigit(d);
        _showOverlay();
        return KeyEventResult.handled;
      }
    } else {
      if (k == LogicalKeyboardKey.mediaFastForward) {
        return _seek(const Duration(seconds: 30));
      }
      if (k == LogicalKeyboardKey.mediaRewind) {
        return _seek(const Duration(seconds: -30));
      }
    }

    // Live: Up/Down always change channel unless a panel is open (the
    // controls are one row, so Left/Right still move between buttons).
    if (live && _panel == _Panel.none && _c.phase != PlayerPhase.failed) {
      if (k == LogicalKeyboardKey.arrowUp) return _zap(-1);
      if (k == LogicalKeyboardKey.arrowDown) return _zap(1);
    }
    if (!hidden) {
      _scheduleHide();
      return KeyEventResult.ignored; // normal D-pad focus movement
    }
    if (live) {
      if (k == LogicalKeyboardKey.arrowLeft) {
        setState(() {
          _overlay = true;
          _panel = _Panel.channels;
        });
        return KeyEventResult.handled;
      }
    } else {
      if (k == LogicalKeyboardKey.arrowLeft) {
        return _seek(const Duration(seconds: -10));
      }
      if (k == LogicalKeyboardKey.arrowRight) {
        return _seek(const Duration(seconds: 10));
      }
      if (k == LogicalKeyboardKey.space) {
        unawaited(_c.togglePlay());
        _showOverlay();
        return KeyEventResult.handled;
      }
    }
    if (k == LogicalKeyboardKey.select ||
        k == LogicalKeyboardKey.enter ||
        k == LogicalKeyboardKey.gameButtonA ||
        k == LogicalKeyboardKey.arrowUp ||
        k == LogicalKeyboardKey.arrowDown ||
        k == LogicalKeyboardKey.arrowRight) {
      _showOverlay(focusControls: true);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _zap(int delta) {
    _c.zap(delta);
    _showOverlay();
    return KeyEventResult.handled;
  }

  KeyEventResult _seek(Duration d) {
    unawaited(_c.seekBy(d));
    _showOverlay();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final it = _c.item;
    final live = it?.isLive ?? false;
    final s = _c.engineState;
    final showChannel =
        live && _c.channelIndex >= 0 && _c.channelIndex < _c.channels.length
        ? _c.channels[_c.channelIndex]
        : null;

    return PopScope(
      // Also blocks the iOS swipe-back gesture on this route.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Focus(
          focusNode: _rootFocus,
          autofocus: true,
          onKeyEvent: _onKey,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (_overlay && _panel == _Panel.none) {
                setState(() => _overlay = false);
              } else {
                _showOverlay();
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (it != null) _engine.view(aspect: _c.aspect),
                _StatusLayer(controller: _c, onRetry: _c.retry, onBack: _leave),
                if (_c.phase != PlayerPhase.failed &&
                    _c.phase != PlayerPhase.unavailable)
                  IgnorePointer(
                    ignoring: !_overlay,
                    child: AnimatedOpacity(
                      opacity: _overlay ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: _Controls(
                        controller: _c,
                        live: live,
                        channel: showChannel,
                        primaryFocus: _primaryButton,
                        onBack: _leave,
                        onChannels: () => setState(
                          () => _panel = _panel == _Panel.channels
                              ? _Panel.none
                              : _Panel.channels,
                        ),
                        onSettings: () => setState(
                          () => _panel = _panel == _Panel.settings
                              ? _Panel.none
                              : _Panel.settings,
                        ),
                        onInteract: _scheduleHide,
                      ),
                    ),
                  ),
                if (_c.pendingNumber.isNotEmpty)
                  Positioned(
                    top: 60,
                    right: 40,
                    child: Text(
                      _c.pendingNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(blurRadius: 14, color: Color(0x99000000)),
                        ],
                      ),
                    ),
                  ),
                if (_panel == _Panel.channels && live)
                  _ChannelPanel(
                    controller: _c,
                    onPicked: (i) {
                      unawaited(_c.tuneTo(i));
                      setState(() => _panel = _Panel.none);
                      _rootFocus.requestFocus();
                    },
                  ),
                if (_panel == _Panel.settings)
                  _SettingsPanel(controller: _c, state: s, live: live),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusLayer extends StatelessWidget {
  const _StatusLayer({
    required this.controller,
    required this.onRetry,
    required this.onBack,
  });

  final PlayerController controller;
  final Future<void> Function() onRetry;
  final Future<void> Function() onBack;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final t = Theme.of(context).textTheme;
    const white = TextStyle(color: Colors.white);
    Widget center(Widget child) => Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xCC0A0A0E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      ),
    );
    switch (c.phase) {
      case PlayerPhase.loading:
        if (c.engineState.hasVideo) return const SizedBox.shrink();
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      case PlayerPhase.reconnecting:
        return Center(
          child: Semantics(
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 14),
                Text('Reconnecting…', style: t.titleMedium?.merge(white)),
                Text(
                  'Attempt ${c.attempt} of 3',
                  style: t.bodySmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      case PlayerPhase.failed:
        final e = c.error!;
        return center(
          FocusMemory(
            debugLabel: 'player-error',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.title,
                  style: t.titleLarge?.copyWith(color: const Color(0xFFFF3347)),
                ),
                const SizedBox(height: 8),
                Text(e.body, style: t.bodyLarge?.merge(white)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    PillButton(
                      label: 'Retry',
                      tone: PillTone.accent,
                      autofocus: true,
                      onPressed: onRetry,
                    ),
                    PillButton(label: 'Back', onPressed: onBack),
                    if (c.hardwareDecoding != HardwareDecoding.off)
                      PillButton(
                        label: 'Turn off hardware decoding',
                        onPressed: () async {
                          await c.setHardwareDecoding(HardwareDecoding.off);
                          await onRetry();
                        },
                      ),
                  ],
                ),
                if (c.hardwareDecoding != HardwareDecoding.off)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'If the picture never appears on this device, turning off hardware decoding often fixes it.',
                      style: t.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ),
              ],
            ),
          ),
        );
      case PlayerPhase.unavailable:
        return center(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("This can't be played", style: t.titleLarge?.merge(white)),
              const SizedBox(height: 8),
              Text(
                'There is no stream for this item. Add your provider to play channels, movies and series.',
                style: t.bodyLarge?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              PillButton(label: 'Back', autofocus: true, onPressed: onBack),
            ],
          ),
        );
      case PlayerPhase.ended:
      case PlayerPhase.playing:
        if (c.engineState.buffering) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white54),
          );
        }
        return const SizedBox.shrink();
    }
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.focusNode,
    this.size = 48,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final FocusNode? focusNode;
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    excludeFromSemantics: true,
    child: FocusableCard(
      focusNode: focusNode,
      onPressed: onPressed,
      focusScale: 1.08,
      outlineColor: Colors.white,
      borderRadius: BorderRadius.circular(size),
      semanticLabel: label,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0x33FFFFFF),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    ),
  );
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.controller,
    required this.live,
    required this.channel,
    required this.primaryFocus,
    required this.onBack,
    required this.onChannels,
    required this.onSettings,
    required this.onInteract,
  });

  final PlayerController controller;
  final bool live;
  final MediaSummary? channel;
  final FocusNode primaryFocus;
  final VoidCallback onBack;
  final VoidCallback onChannels;
  final VoidCallback onSettings;
  final VoidCallback onInteract;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final s = c.engineState;
    final t = Theme.of(context).textTheme;
    final accent = LumenColors.of(context).accent;
    final g = pageGutter(context);
    final title = live
        ? [
            if (channel?.channelNumber != null) '${channel!.channelNumber}',
            channel?.title ?? c.item?.title ?? '',
          ].join('  ')
        : c.item?.title ?? '';
    final total = s.duration.inMilliseconds;
    final frac = total <= 0
        ? 0.0
        : (s.position.inMilliseconds / total).clamp(0.0, 1.0);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xA6000000),
            Color(0x00000000),
            Color(0x00000000),
            Color(0xCC000000),
          ],
          stops: [0, 0.28, 0.62, 1],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(g, 16, g, 20),
          child: FocusMemory(
            debugLabel: 'player-controls',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _GlassButton(
                      icon: Icons.arrow_back,
                      label: 'Back',
                      onPressed: onBack,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.titleMedium?.copyWith(color: Colors.white),
                          ),
                          if (live)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          else if (c.item?.subtitle != null)
                            Text(
                              c.item!.subtitle!,
                              style: t.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (live) ...[
                      _GlassButton(
                        icon: c.favourite ? Icons.star : Icons.star_border,
                        label: c.favourite
                            ? 'Remove from favourites'
                            : 'Add to favourites',
                        onPressed: () {
                          onInteract();
                          unawaited(c.toggleFavourite());
                        },
                      ),
                      const SizedBox(width: 10),
                      _GlassButton(
                        icon: Icons.list,
                        label: 'Channels',
                        focusNode: primaryFocus,
                        onPressed: onChannels,
                      ),
                      const SizedBox(width: 10),
                    ],
                    _GlassButton(
                      icon: Icons.tune,
                      label: 'Player settings',
                      onPressed: onSettings,
                    ),
                  ],
                ),
                const Spacer(),
                if (live)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        channel?.nowTitle ?? 'Live',
                        style: t.headlineSmall?.copyWith(color: Colors.white),
                      ),
                      if (channel?.nextTitle != null)
                        Text(
                          channel!.nextTitle!,
                          style: t.bodyMedium?.copyWith(color: Colors.white70),
                        ),
                      if (channel?.progress != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: channel!.progress!.clamp(0.0, 1.0),
                            minHeight: 4,
                            color: accent,
                            backgroundColor: const Color(0x4DFFFFFF),
                          ),
                        ),
                      ],
                    ],
                  )
                else ...[
                  Row(
                    children: [
                      Text(
                        _clock(s.position),
                        style: t.labelMedium?.copyWith(color: Colors.white),
                      ),
                      Expanded(
                        child: Slider(
                          value: frac,
                          activeColor: accent,
                          inactiveColor: const Color(0x4DFFFFFF),
                          onChanged: c.seekable == false || total <= 0
                              ? null
                              : (v) {
                                  onInteract();
                                  unawaited(
                                    c.engine.seek(
                                      Duration(
                                        milliseconds: (v * total).round(),
                                      ),
                                    ),
                                  );
                                },
                        ),
                      ),
                      Text(
                        _clock(s.duration),
                        style: t.labelMedium?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                  if (c.seekable == false)
                    Text(
                      "Skipping isn't available for this video.",
                      style: t.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _GlassButton(
                        icon: Icons.replay_10,
                        label: 'Back 10 seconds',
                        size: 56,
                        onPressed: () {
                          onInteract();
                          unawaited(c.seekBy(const Duration(seconds: -10)));
                        },
                      ),
                      const SizedBox(width: 18),
                      _GlassButton(
                        icon: s.playing ? Icons.pause : Icons.play_arrow,
                        label: s.playing ? 'Pause' : 'Play',
                        size: 64,
                        focusNode: primaryFocus,
                        onPressed: () {
                          onInteract();
                          unawaited(c.togglePlay());
                        },
                      ),
                      const SizedBox(width: 18),
                      _GlassButton(
                        icon: Icons.forward_10,
                        label: 'Forward 10 seconds',
                        size: 56,
                        onPressed: () {
                          onInteract();
                          unawaited(c.seekBy(const Duration(seconds: 10)));
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChannelPanel extends StatelessWidget {
  const _ChannelPanel({required this.controller, required this.onPicked});

  final PlayerController controller;
  final void Function(int index) onPicked;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final t = Theme.of(context).textTheme;
    final width = (MediaQuery.sizeOf(context).width * 0.88).clamp(0.0, 360.0);
    final start = (c.channelIndex - 3).clamp(
      0,
      c.channels.isEmpty ? 0 : c.channels.length - 1,
    );
    return Positioned(
      top: 0,
      bottom: 0,
      left: 0,
      width: width,
      child: Container(
        color: const Color(0xEB0A0A0E),
        child: SafeArea(
          child: FocusMemory(
            debugLabel: 'channel-panel',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Channels',
                    style: t.titleMedium?.copyWith(color: Colors.white),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: ScrollController(
                      initialScrollOffset: start * 60.0,
                    ),
                    itemExtent: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: c.channels.length,
                    itemBuilder: (context, i) {
                      final ch = c.channels[i];
                      final current = i == c.channelIndex;
                      return FocusableCard(
                        focusScale: 1.0,
                        outlineColor: Colors.white,
                        autofocus: current,
                        semanticLabel: ch.title,
                        onPressed: () => onPicked(i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: current ? const Color(0x1AFFFFFF) : null,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 44,
                                child: Text(
                                  '${ch.channelNumber ?? ''}',
                                  style: t.labelLarge?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ch.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: t.bodyLarge?.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (ch.nowTitle != null)
                                      Text(
                                        ch.nowTitle!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: t.bodySmall?.copyWith(
                                          color: Colors.white60,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.controller,
    required this.state,
    required this.live,
  });

  final PlayerController controller;
  final EngineState state;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final t = Theme.of(context).textTheme;
    final width = (MediaQuery.sizeOf(context).width * 0.9).clamp(0.0, 420.0);
    Widget section(String title, List<Widget> chips) => Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.labelLarge?.copyWith(color: Colors.white70)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ),
    );
    return Positioned(
      top: 0,
      bottom: 0,
      right: 0,
      width: width,
      child: Container(
        color: const Color(0xEB0A0A0E),
        child: SafeArea(
          child: FocusMemory(
            debugLabel: 'player-settings',
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Text(
                  'Player settings',
                  style: t.titleMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 16),
                if (state.audioTracks.length > 1)
                  section('Audio', [
                    for (final a in state.audioTracks)
                      TabPill(
                        label: a.label,
                        selected: a.id == state.audioTrackId,
                        filled: true,
                        onPressed: () => c.engine.setAudioTrack(a.id),
                      ),
                  ]),
                section('Subtitles', [
                  TabPill(
                    label: 'Off',
                    selected:
                        state.subtitleTrackId == null ||
                        state.subtitleTrackId == 'no',
                    filled: true,
                    onPressed: () => c.engine.setSubtitleTrack(null),
                  ),
                  for (final s in state.subtitleTracks)
                    TabPill(
                      label: s.label,
                      selected: s.id == state.subtitleTrackId,
                      filled: true,
                      onPressed: () => c.engine.setSubtitleTrack(s.id),
                    ),
                ]),
                section('Picture', [
                  for (final (a, label) in const [
                    (AspectMode.fit, 'Fit'),
                    (AspectMode.fill, 'Fill'),
                    (AspectMode.wide, '16:9'),
                    (AspectMode.standard, '4:3'),
                  ])
                    TabPill(
                      label: label,
                      selected: c.aspect == a,
                      filled: true,
                      onPressed: () => c.setAspect(a),
                    ),
                ]),
                section('Hardware decoding', [
                  for (final (h, label) in const [
                    (HardwareDecoding.auto, 'Auto'),
                    (HardwareDecoding.on, 'On'),
                    (HardwareDecoding.off, 'Off'),
                  ])
                    TabPill(
                      label: label,
                      selected: c.hardwareDecoding == h,
                      filled: true,
                      onPressed: () => c.setHardwareDecoding(h),
                    ),
                ]),
                Text(
                  'Turn hardware decoding off if the picture shows green blocks or stutters.',
                  style: t.bodySmall?.copyWith(color: Colors.white60),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
