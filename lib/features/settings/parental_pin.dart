import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/widgets/text_prompt_dialog.dart';
import '../../data/secure/credential_store.dart';

/// Parental PIN, kept in secure storage (brief section 3: "hide adult
/// categories (PIN to change)").
class ParentalPin {
  ParentalPin([SecretBackend? backend])
    : _b = backend ?? FlutterSecureBackend();

  final SecretBackend _b;
  static const _key = 'parental.pin';

  Future<String?> current() async {
    try {
      final v = await _b.read(_key);
      return (v == null || v.isEmpty) ? null : v;
    } catch (_) {
      return null;
    }
  }

  Future<bool> set(String pin) async {
    try {
      await _b.write(_key, pin);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final parentalPinProvider = Provider<ParentalPin>((ref) => ParentalPin());

Future<String?> _askPin(
  BuildContext context,
  String title, {
  String? message,
}) async {
  final v = await askText(
    context,
    TextPromptDialog(
      title: title,
      message: message,
      hint: '4 digits',
      obscure: true,
      digitsOnly: true,
      maxLength: 4,
    ),
  );
  return v != null && v.length == 4 ? v : null;
}

/// Asks for the PIN, or sets one up the first time. Returns true when the
/// user may change the protected setting.
Future<bool> requireParentalPin(BuildContext context, WidgetRef ref) async {
  final store = ref.read(parentalPinProvider);
  final existing = await store.current();
  if (!context.mounted) return false;
  if (existing == null) {
    final a = await _askPin(
      context,
      'Create a PIN',
      message: 'You will need this PIN to change adult content settings.',
    );
    if (a == null || !context.mounted) return false;
    final b = await _askPin(context, 'Enter the PIN again');
    if (b != a) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("The PINs didn't match. Try again.")),
        );
      }
      return false;
    }
    return store.set(a);
  }
  final entered = await _askPin(context, 'Enter your PIN');
  if (entered == existing) return true;
  if (entered != null && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("That PIN isn't right.")));
  }
  return false;
}
