import 'dart:async';

import 'package:flutter/widgets.dart';

import 'directional_focus.dart';

/// Remembers the last focused item inside its subtree and, when D-pad focus
/// re-enters the subtree from outside, sends focus back to that item instead
/// of the geometrically nearest one.
///
/// Use one per row (so moving up/down between rows returns to the same
/// column you left) and one per screen (so leaving the tab bar returns to
/// where you were).
///
/// Only D-pad/arrow traversal is redirected; touch, pointer and programmatic
/// focus (e.g. restoring focus after a route pops) are left alone. When several nested memories want to redirect for the same
/// focus change, the outermost one wins.
class FocusMemory extends StatefulWidget {
  const FocusMemory({super.key, required this.child, this.debugLabel});

  final Widget child;
  final String? debugLabel;

  @override
  State<FocusMemory> createState() => _FocusMemoryState();
}

class _FocusMemoryState extends State<FocusMemory> {
  late final FocusNode _group = FocusNode(
    debugLabel: 'FocusMemory(${widget.debugLabel ?? ''})',
    skipTraversal: true,
    canRequestFocus: false,
  );
  FocusNode? _last;
  bool _wasInside = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocusChanged);
    _group.dispose();
    super.dispose();
  }

  bool _isInside(FocusNode? node) =>
      node != null && node != _group && node.ancestors.contains(_group);

  int get _depth => _group.ancestors.length;

  void _onFocusChanged() {
    final primary = FocusManager.instance.primaryFocus;
    final inside = _isInside(primary);
    final entering = inside && !_wasInside;
    _wasInside = inside;
    if (!inside) return;

    final last = _last;
    final canRestore =
        entering &&
        DirectionalMove.active &&
        last != null &&
        last != primary &&
        last.context != null &&
        last.canRequestFocus &&
        _isInside(last);

    if (canRestore) {
      _RedirectCoordinator.propose(_depth, last);
    } else {
      _last = primary;
    }
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _group,
    skipTraversal: true,
    canRequestFocus: false,
    includeSemantics: false,
    child: widget.child,
  );
}

/// Collects redirect proposals made during one focus change and applies the
/// outermost one in a microtask.
abstract final class _RedirectCoordinator {
  static (int, FocusNode)? _best;
  static bool _scheduled = false;

  static void propose(int depth, FocusNode target) {
    final best = _best;
    if (best == null || depth < best.$1) _best = (depth, target);
    if (_scheduled) return;
    _scheduled = true;
    scheduleMicrotask(() {
      final chosen = _best;
      _best = null;
      _scheduled = false;
      final node = chosen?.$2;
      if (node != null && node.context != null && node.canRequestFocus) {
        node.requestFocus();
      }
    });
  }
}
