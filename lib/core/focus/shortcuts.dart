import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'directional_focus.dart';

/// "Go back" from a keyboard or remote key that isn't the system Back button
/// (Escape on a keyboard, browser-back keys). The system Back button on
/// Android/Android TV goes through the router's back button dispatcher, so
/// both paths end up in the same place.
class BackIntent extends Intent {
  const BackIntent();
}

/// Long-press alternative for remotes: the Menu / Info key.
class SecondaryActionIntent extends Intent {
  const SecondaryActionIntent();
}

/// Key map shared by every screen (brief section 8).
///
/// Arrow keys keep Flutter's default directional traversal. Select, Enter
/// and gamepad A activate the focused control.
const Map<ShortcutActivator, Intent> lumenShortcuts = {
  SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.escape): BackIntent(),
  SingleActivator(LogicalKeyboardKey.goBack): BackIntent(),
  SingleActivator(LogicalKeyboardKey.browserBack): BackIntent(),
  SingleActivator(LogicalKeyboardKey.gameButtonB): BackIntent(),
  SingleActivator(LogicalKeyboardKey.contextMenu): SecondaryActionIntent(),
  SingleActivator(LogicalKeyboardKey.info): SecondaryActionIntent(),
};

/// Wraps the app with [lumenShortcuts] and a [BackIntent] handler.
class LumenShortcuts extends StatelessWidget {
  const LumenShortcuts({super.key, required this.onBack, required this.child});

  /// Should behave exactly like the system Back button.
  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) => Shortcuts(
    shortcuts: lumenShortcuts,
    child: Actions(
      actions: {
        DirectionalFocusIntent: LumenDirectionalFocusAction(),
        BackIntent: CallbackAction<BackIntent>(
          onInvoke: (_) {
            onBack();
            return null;
          },
        ),
      },
      child: child,
    ),
  );
}
