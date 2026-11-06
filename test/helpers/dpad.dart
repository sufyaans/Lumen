import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/core/focus/focusable_card.dart';

const dpadKeys = {
  'up': LogicalKeyboardKey.arrowUp,
  'down': LogicalKeyboardKey.arrowDown,
  'left': LogicalKeyboardKey.arrowLeft,
  'right': LogicalKeyboardKey.arrowRight,
};

Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

/// A stable name for a focus node, so the same control is recognised even
/// after a lazily built list rebuilds it with a new [FocusNode].
String focusId(FocusNode node) {
  final ctx = node.context;
  if (ctx == null) return 'detached:${node.hashCode}';
  final card = ctx.findAncestorWidgetOfExactType<FocusableCard>();
  // FocusMemory groups carry readable labels; use them as a path.
  final memory = _memoryPath(ctx);
  if (card != null) {
    return '$memory/${card.semanticLabel ?? 'card@${card.hashCode}'}';
  }
  return '$memory/${node.debugLabel ?? ctx.widget.runtimeType}';
}

String _memoryPath(BuildContext ctx) {
  final labels = <String>[];
  ctx.visitAncestorElements((e) {
    final w = e.widget;
    if (w is Focus) {
      final label = w.focusNode?.debugLabel;
      if (label != null && label.startsWith('FocusMemory(')) {
        labels.add(label.substring(12, label.length - 1));
      }
    }
    return true;
  });
  return labels.reversed.join('>');
}

/// Every focusable, traversable node currently on screen in the top route.
List<FocusNode> visibleFocusables(WidgetTester tester) {
  final scope = FocusManager.instance.primaryFocus?.nearestScope;
  final root = FocusManager.instance.rootScope;
  final view = tester.view.physicalSize / tester.view.devicePixelRatio;
  final screen = Offset.zero & view;
  return root.traversalDescendants.where((n) {
    if (n is FocusScopeNode) return false;
    if (!n.canRequestFocus || n.skipTraversal || n.context == null) {
      return false;
    }
    if (scope != null && n.nearestScope != scope && !_inScope(n, scope)) {
      return false;
    }
    final r = n.rect;
    return r.width > 0 && r.height > 0 && r.overlaps(screen);
  }).toList();
}

bool _inScope(FocusNode n, FocusScopeNode scope) => n.ancestors.contains(scope);

class WalkResult {
  WalkResult(this.reached, this.seen, this.deadEnds, this.lost);

  final Set<String> reached;
  final Set<String> seen;

  /// Controls from which no D-pad direction moves focus anywhere.
  final Set<String> deadEnds;

  /// Controls that could not be found again to test from (should be empty).
  final Set<String> lost;

  Set<String> get unreachable => seen.difference(reached);
}

/// Breadth-first walk of the D-pad graph starting from the current focus.
///
/// From every reached control, presses all four directions and records
/// where focus lands. Controls that scroll into view during the walk are
/// added to [WalkResult.seen]. Lazily built lists dispose controls that
/// scroll away, so a control is re-reached by replaying the key presses
/// that first found it.
Future<WalkResult> walkDpad(WidgetTester tester, {int maxNodes = 400}) async {
  final start = FocusManager.instance.primaryFocus;
  expect(start, isNotNull, reason: 'Nothing has focus to start the walk');
  final startId = focusId(start!);

  final reached = <String>{startId};
  final seen = <String>{for (final n in visibleFocusables(tester)) focusId(n)};
  final deadEnds = <String>{};
  final lost = <String>{};
  final via = <String, (String, LogicalKeyboardKey)>{};
  final queue = <String>[startId];

  FocusNode? find(String id) {
    for (final n in FocusManager.instance.rootScope.traversalDescendants) {
      if (n.context != null && focusId(n) == id) return n;
    }
    return null;
  }

  Future<bool> reach(String id, [int depth = 0]) async {
    final node = find(id);
    if (node != null) {
      node.requestFocus();
      await tester.pumpAndSettle();
      return true;
    }
    final step = via[id];
    if (step == null || depth > 50) return false;
    if (!await reach(step.$1, depth + 1)) return false;
    await press(tester, step.$2);
    final now = FocusManager.instance.primaryFocus;
    return now != null && focusId(now) == id;
  }

  while (queue.isNotEmpty && reached.length < maxNodes) {
    final id = queue.removeAt(0);
    var moved = false;
    var tested = false;
    for (final key in dpadKeys.values) {
      if (!await reach(id)) continue;
      tested = true;
      await press(tester, key);
      final now = FocusManager.instance.primaryFocus;
      if (now == null) continue;
      final nowId = focusId(now);
      if (nowId != id) moved = true;
      seen.addAll(visibleFocusables(tester).map(focusId));
      if (reached.add(nowId)) {
        via[nowId] = (id, key);
        queue.add(nowId);
      }
    }
    if (!tested) {
      lost.add(id);
    } else if (!moved) {
      deadEnds.add(id);
    }
  }
  return WalkResult(reached, seen, deadEnds, lost);
}
