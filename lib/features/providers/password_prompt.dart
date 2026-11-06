import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../core/utils/text_clean.dart';
import '../../core/widgets/text_prompt_dialog.dart';

/// "Enter your password again to continue" (brief 5.9): shown when secure
/// storage lost the password (keystore reset, iOS re-sign). Other provider
/// settings are kept. Returns true when a password was saved.
Future<bool> promptForPassword(
  BuildContext context,
  WidgetRef ref,
  String providerId,
) async {
  final v = await askText(
    context,
    const TextPromptDialog(
      title: 'Enter your password again',
      message: "This device couldn't read your saved password. Your other settings are kept.",
      hint: 'Password',
      obscure: true,
      confirmLabel: 'Save',
    ),
  );
  final pw = cleanCredential(v ?? '');
  if (pw.isEmpty) return false;
  return ref.read(providerRegistryProvider).updatePassword(providerId, pw);
}
