import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import 'directional_focus.dart';
import 'shortcuts.dart';

/// The one focusable building block for cards, tabs, chips and buttons.
///
/// * Tap / Select / Enter / gamepad A call [onPressed].
/// * Long-press, or the Menu/Info key on a remote, call [onLongPress].
/// * When focus is shown (TV, or a keyboard is in use) it scales up by
///   [focusScale] and draws a 3 px outline. Touch users never see it.
/// * The focused item is scrolled into view with a margin.
class FocusableCard extends StatefulWidget {
  const FocusableCard({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.focusNode,
    this.autofocus = false,
    this.focusScale = 1.07,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(LumenRadii.card),
    ),
    this.outlineColor,
    this.semanticLabel,
    this.scrollIntoView = true,
    this.onFocusChange,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final FocusNode? focusNode;
  final bool autofocus;
  final double focusScale;
  final BorderRadius borderRadius;
  final Color? outlineColor;
  final String? semanticLabel;
  final bool scrollIntoView;
  final ValueChanged<bool>? onFocusChange;

  @override
  State<FocusableCard> createState() => _FocusableCardState();
}

class _FocusableCardState extends State<FocusableCard> {
  bool _focusShown = false;
  bool _hover = false;

  void _activate() => widget.onPressed?.call();

  void _onFocusChange(bool focused) {
    widget.onFocusChange?.call(focused);
    if (focused &&
        widget.scrollIntoView &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional) {
      // Keep a margin around the focused item instead of pinning it to an
      // edge. Centre vertically, nearest horizontally.
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = LumenColors.of(context);
    final highlighted = _focusShown || _hover;
    final enabled = widget.onPressed != null || widget.onLongPress != null;

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      foregroundDecoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        border: _focusShown
            ? Border.all(
                color: widget.outlineColor ?? c.text,
                width: 3,
                strokeAlign: BorderSide.strokeAlignOutside,
              )
            : null,
      ),
      child: widget.child,
    );

    if (widget.focusScale != 1.0) {
      content = AnimatedScale(
        scale: highlighted ? widget.focusScale : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: content,
      );
    }

    return FocusableActionDetector(
      enabled: enabled,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onShowFocusHighlight: (v) => setState(() => _focusShown = v),
      onShowHoverHighlight: (v) => setState(() => _hover = v),
      onFocusChange: _onFocusChange,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _activate();
            return null;
          },
        ),
        SecondaryActionIntent: CallbackAction<SecondaryActionIntent>(
          onInvoke: (_) {
            widget.onLongPress?.call();
            return null;
          },
        ),
      },
      child: Semantics(
        button: true,
        enabled: enabled,
        label: widget.semanticLabel,
        // The label already describes the control; don't read inner text twice.
        excludeSemantics: widget.semanticLabel != null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          onLongPress: widget.onLongPress,
          child: content,
        ),
      ),
    );
  }
}

/// Text-field helper for TV (brief section 8): never autofocus, and let the
/// D-pad leave the field instead of trapping the user.
///
/// * Up/Down always move focus out of a single-line field.
/// * Left at the start of the text, or Right at the end, move focus out;
///   otherwise they move the caret as usual.
class DpadEscapableField extends StatelessWidget {
  const DpadEscapableField({
    super.key,
    required this.controller,
    required this.child,
  });

  final TextEditingController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) => Shortcuts(
    shortcuts: const {
      SingleActivator(LogicalKeyboardKey.arrowDown): _LeaveFieldIntent(
        TraversalDirection.down,
      ),
      SingleActivator(LogicalKeyboardKey.arrowUp): _LeaveFieldIntent(
        TraversalDirection.up,
      ),
      SingleActivator(LogicalKeyboardKey.arrowLeft): _LeaveFieldIntent(
        TraversalDirection.left,
      ),
      SingleActivator(LogicalKeyboardKey.arrowRight): _LeaveFieldIntent(
        TraversalDirection.right,
      ),
    },
    child: Actions(
      actions: {_LeaveFieldIntent: _LeaveFieldAction(controller)},
      child: child,
    ),
  );
}

class _LeaveFieldIntent extends Intent {
  const _LeaveFieldIntent(this.direction);

  final TraversalDirection direction;
}

class _LeaveFieldAction extends Action<_LeaveFieldIntent> {
  _LeaveFieldAction(this.controller);

  final TextEditingController controller;

  @override
  bool isEnabled(_LeaveFieldIntent intent) {
    final sel = controller.selection;
    return switch (intent.direction) {
      TraversalDirection.up || TraversalDirection.down => true,
      // When disabled, the key falls through to normal caret movement.
      TraversalDirection.left =>
        !sel.isValid || (sel.isCollapsed && sel.baseOffset <= 0),
      TraversalDirection.right =>
        !sel.isValid ||
            (sel.isCollapsed && sel.baseOffset >= controller.text.length),
    };
  }

  @override
  void invoke(_LeaveFieldIntent intent) =>
      LumenDirectionalFocusAction.move(intent.direction);
}
