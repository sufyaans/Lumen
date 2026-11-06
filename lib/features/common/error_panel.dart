import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../core/network/connection_error.dart';
import '../../core/network/redaction.dart';
import '../../core/widgets/buttons.dart';

/// Shows a classified failure: plain title and body with the next step,
/// technical detail only behind "Details" (brief section 3 copy rules).
class ErrorPanel extends StatefulWidget {
  const ErrorPanel({
    super.key,
    required this.error,
    this.onRetry,
    this.onConnectionCheck,
    this.extraActions = const [],
    this.secrets = const [],
  });

  final ConnectionError error;
  final VoidCallback? onRetry;
  final VoidCallback? onConnectionCheck;
  final List<Widget> extraActions;

  /// Values to scrub from the details text (password etc).
  final List<String> secrets;

  @override
  State<ErrorPanel> createState() => _ErrorPanelState();
}

class _ErrorPanelState extends State<ErrorPanel> {
  bool _details = false;

  @override
  Widget build(BuildContext context) {
    final c = LumenColors.of(context);
    final t = Theme.of(context).textTheme;
    final e = widget.error;
    final details = Redactor.redact(
      '${e.kind.name}${e.details.isEmpty ? '' : ': ${e.details}'}',
      secrets: widget.secrets,
    );
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color.lerp(c.surface, c.accent, 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color.lerp(c.line, c.accent, 0.4)!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e.title, style: t.titleMedium?.copyWith(color: c.accent)),
            const SizedBox(height: 6),
            Text(e.body, style: t.bodyMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (widget.onRetry != null)
                  PillButton(
                    label: 'Try again',
                    tone: PillTone.primary,
                    onPressed: widget.onRetry,
                  ),
                if (widget.onConnectionCheck != null)
                  PillButton(
                    label: 'Connection check',
                    icon: Icons.network_check,
                    onPressed: widget.onConnectionCheck,
                  ),
                ...widget.extraActions,
                PillButton(
                  label: _details ? 'Hide details' : 'Details',
                  onPressed: () => setState(() => _details = !_details),
                ),
              ],
            ),
            if (_details) ...[
              const SizedBox(height: 10),
              SelectableText(
                details,
                style: t.bodySmall?.copyWith(fontFamily: 'monospace'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
