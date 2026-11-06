import 'dart:async';

import 'package:flutter/widgets.dart';

/// True while a focus change caused by D-pad/arrow movement is being
/// applied. [FocusMemory] only redirects those, never programmatic or
/// pointer focus.
abstract final class DirectionalMove {
  static bool _active = false;
  static bool get active => _active;

  static void _begin() => _active = true;

  /// Called after the focus request: focus changes are applied in a
  /// microtask queued by requestFocus, and this one is queued after it.
  static void _end() => scheduleMicrotask(() => _active = false);
}

/// D-pad movement for the whole app.
///
/// Flutter's built-in directional traversal only searches inside the
/// focused node's nearest [FocusScope], and each shell tab has its own
/// navigator (and scope), so "Up" from the content could never reach the
/// tab bar. It also keeps a per-scope move history that makes results
/// depend on earlier presses. This action instead does one predictable
/// geometric search over every focusable control on the routes that are
/// currently showing:
///
/// * Left/Right only consider controls that overlap vertically (same band),
///   so Left on the first tab never jumps into the content below.
/// * Up/Down pick the nearest control, weighting sideways distance.
/// * If nothing real has focus yet, the top-left control is focused.
///
/// Text fields keep Left/Right for the caret; see [DpadEscapableField].
class LumenDirectionalFocusAction extends Action<DirectionalFocusIntent> {
  @override
  void invoke(DirectionalFocusIntent intent) {
    DirectionalMove._begin();
    try {
      _move(intent);
    } finally {
      DirectionalMove._end();
    }
  }

  /// Moves focus one step without going through the Actions tree.
  static void move(TraversalDirection direction) =>
      LumenDirectionalFocusAction().invoke(DirectionalFocusIntent(direction));

  void _move(DirectionalFocusIntent intent) {
    final primary = FocusManager.instance.primaryFocus;
    if (primary == null) return;

    final candidates = focusCandidates().where((n) => n != primary);

    if (primary is FocusScopeNode || primary.context == null) {
      topLeft(candidates)?.requestFocus();
      return;
    }

    pickInDirection(primary.rect, intent.direction, candidates)?.requestFocus();
  }
}

/// Every control that D-pad movement may land on right now.
Iterable<FocusNode> focusCandidates() =>
    FocusManager.instance.rootScope.traversalDescendants.where(_eligible);

FocusNode? topLeft(Iterable<FocusNode> nodes) {
  FocusNode? best;
  for (final n in nodes) {
    if (best == null) {
      best = n;
      continue;
    }
    final a = n.rect, b = best.rect;
    if (a.top < b.top - 1 || ((a.top - b.top).abs() <= 1 && a.left < b.left)) {
      best = n;
    }
  }
  return best;
}

bool _eligible(FocusNode n) {
  if (n is FocusScopeNode) return false;
  if (!n.canRequestFocus || n.skipTraversal) return false;
  final ctx = n.context;
  if (ctx == null || !ctx.mounted) return false;
  if (n.rect.isEmpty) return false;
  return _onCurrentRoutes(ctx);
}

/// True when every route between [ctx] and the root navigator is the top
/// route of its navigator, so covered screens are never focus targets.
bool _onCurrentRoutes(BuildContext ctx) {
  BuildContext? c = ctx;
  while (c != null && c.mounted) {
    final route = ModalRoute.of(c);
    if (route == null) return true;
    if (!route.isCurrent) return false;
    c = route.navigator?.context;
  }
  return true;
}

/// Picks the best candidate in [direction] from [from]. Score is the
/// distance along the direction plus a weighted sideways offset, like the
/// prototype's remote navigation.
FocusNode? pickInDirection(
  Rect from,
  TraversalDirection direction,
  Iterable<FocusNode> candidates,
) {
  final c = from.center;
  FocusNode? best;
  var bestScore = double.infinity;
  for (final n in candidates) {
    final r = n.rect;
    final b = r.center;
    final dx = b.dx - c.dx;
    final dy = b.dy - c.dy;
    final sameBand = r.top < from.bottom - 1 && r.bottom > from.top + 1;
    final (ok, primary, side, weight) = switch (direction) {
      TraversalDirection.right => (dx > 6 && sameBand, dx, dy.abs(), 4.0),
      TraversalDirection.left => (dx < -6 && sameBand, -dx, dy.abs(), 4.0),
      TraversalDirection.down => (dy > 6, dy, dx.abs(), 1.2),
      TraversalDirection.up => (dy < -6, -dy, dx.abs(), 1.2),
    };
    if (!ok) continue;
    final score = primary + side * weight;
    if (score < bestScore) {
      bestScore = score;
      best = n;
    }
  }
  return best;
}
