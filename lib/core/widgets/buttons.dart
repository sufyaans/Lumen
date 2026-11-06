import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../focus/focusable_card.dart';

enum PillTone { accent, primary, secondary, danger }

/// Rounded text button used across the app (prototype `.btn`, `.sbtn`).
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = PillTone.secondary,
    this.focusNode,
    this.autofocus = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final PillTone tone;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = LumenColors.of(context);
    final (bg, fg) = switch (tone) {
      PillTone.accent => (c.accent, Colors.white),
      PillTone.primary => (c.text, c.background),
      PillTone.secondary => (c.surfaceHigh, c.text),
      PillTone.danger => (c.surfaceHigh, c.accent),
    };
    final disabled = onPressed == null;
    final style = Theme.of(context).textTheme.labelLarge
        ?.copyWith(color: fg, fontWeight: FontWeight.w700);
    return FocusableCard(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      focusScale: 1.04,
      borderRadius: BorderRadius.circular(10),
      semanticLabel: label,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(label, style: style, overflow: TextOverflow.fade),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round icon button (prototype `.ibtn`).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.size = 40,
    this.background,
    this.foreground,
    this.child,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final double size;
  final Color? background;
  final Color? foreground;

  /// Replaces the icon (e.g. an avatar initial).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = LumenColors.of(context);
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: FocusableCard(
        onPressed: onPressed,
        focusScale: 1.0,
        borderRadius: BorderRadius.circular(size),
        semanticLabel: label,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: background ?? c.surfaceHigh,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child:
              child ??
              Icon(icon, size: size * 0.5, color: foreground ?? c.text),
        ),
      ),
    );
  }
}

/// Top-bar tab and filter chip (prototype `.tab` / `.chip`).
class TabPill extends StatelessWidget {
  const TabPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.filled = false,
    this.autofocus = false,
    this.focusNode,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final bool autofocus;
  final FocusNode? focusNode;

  /// Chips are filled when selected; tabs only change text colour.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = LumenColors.of(context);
    final t = Theme.of(context).textTheme;
    final bg = filled
        ? (selected ? c.text : c.surfaceHigh)
        : Colors.transparent;
    final fg = filled
        ? (selected ? c.background : c.text)
        : (selected ? c.text : c.muted);
    return Semantics(
      selected: selected,
      child: FocusableCard(
        onPressed: onPressed,
        autofocus: autofocus,
        focusNode: focusNode,
        focusScale: 1.0,
        borderRadius: BorderRadius.circular(LumenRadii.pill),
        semanticLabel: label,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(LumenRadii.pill),
          ),
          child: Text(
            label,
            style: t.labelLarge?.copyWith(color: fg),
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

/// Segmented control (prototype `.seg`), e.g. Auto / Dark / Light.
class Segmented<T> extends StatelessWidget {
  const Segmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = LumenColors.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surfaceHigh,
        borderRadius: BorderRadius.circular(LumenRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (v, label) in options)
            TabPill(
              label: label,
              selected: v == value,
              filled: v == value,
              onPressed: () => onChanged(v),
            ),
        ],
      ),
    );
  }
}
