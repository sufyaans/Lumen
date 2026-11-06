import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../focus/focusable_card.dart';
import 'buttons.dart';

/// A small dialog asking for one line of text. Owns its controller, so it
/// is disposed only after the closing animation (disposing it right after
/// `showDialog` returns crashes the still-animating field).
class TextPromptDialog extends StatefulWidget {
  const TextPromptDialog({
    super.key,
    required this.title,
    this.message,
    this.hint,
    this.obscure = false,
    this.digitsOnly = false,
    this.maxLength,
    this.confirmLabel = 'OK',
    this.extra,
  });

  final String title;
  final String? message;
  final String? hint;
  final bool obscure;
  final bool digitsOnly;
  final int? maxLength;
  final String confirmLabel;

  /// Extra controls under the field (e.g. a Kids toggle). Receives a
  /// setState to rebuild the dialog.
  final Widget Function(StateSetter setState)? extra;

  @override
  State<TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<TextPromptDialog> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _ok() => Navigator.of(context).pop(_c.text);

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SizedBox(
      width: 400,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(widget.message!),
              ),
            DpadEscapableField(
              controller: _c,
              child: TextField(
                controller: _c,
                obscureText: widget.obscure,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: widget.digitsOnly ? TextInputType.number : null,
                maxLength: widget.maxLength,
                inputFormatters: widget.digitsOnly
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : null,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  counterText: '',
                ),
                onSubmitted: (_) => _ok(),
              ),
            ),
            if (widget.extra != null) ...[
              const SizedBox(height: 12),
              widget.extra!(setState),
            ],
          ],
        ),
      ),
    ),
    actions: [
      PillButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
      PillButton(
        label: widget.confirmLabel,
        tone: PillTone.accent,
        onPressed: _ok,
      ),
    ],
  );
}

/// Shows a [TextPromptDialog]; returns the text, or null when cancelled.
Future<String?> askText(BuildContext context, TextPromptDialog dialog) =>
    showDialog<String>(context: context, builder: (_) => dialog);
