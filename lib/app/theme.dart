import 'package:material_ui/material_ui.dart';

import '../core/platform/form_factor.dart';

/// Design tokens from the build brief (section 3) and the prototype CSS.
@immutable
class LumenColors extends ThemeExtension<LumenColors> {
  const LumenColors({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.text,
    required this.muted,
    required this.accent,
    required this.line,
    required this.shadow,
  });

  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color text;
  final Color muted;
  final Color accent;
  final Color line;
  final Color shadow;

  static const dark = LumenColors(
    background: Color(0xFF0C0C10),
    surface: Color(0xFF17171E),
    surfaceHigh: Color(0xFF24242E),
    text: Color(0xFFF4F4F7),
    muted: Color(0xFFA0A0AE),
    accent: Color(0xFFFF3347),
    line: Color(0x24FFFFFF),
    shadow: Color(0x99000000),
  );

  static const light = LumenColors(
    background: Color(0xFFF5F5F7),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFE6E6EC),
    text: Color(0xFF14141A),
    muted: Color(0xFF5D5D6B),
    accent: Color(0xFFE5243B),
    line: Color(0x1F000000),
    shadow: Color(0x47000000),
  );

  static LumenColors of(BuildContext context) =>
      Theme.of(context).extension<LumenColors>()!;

  @override
  LumenColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceHigh,
    Color? text,
    Color? muted,
    Color? accent,
    Color? line,
    Color? shadow,
  }) => LumenColors(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceHigh: surfaceHigh ?? this.surfaceHigh,
    text: text ?? this.text,
    muted: muted ?? this.muted,
    accent: accent ?? this.accent,
    line: line ?? this.line,
    shadow: shadow ?? this.shadow,
  );

  @override
  LumenColors lerp(LumenColors? other, double t) {
    if (other == null) return this;
    return LumenColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      line: Color.lerp(line, other.line, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

/// Corner radii from the brief.
abstract final class LumenRadii {
  static const double card = 10;
  static const double pill = 999;
  static const double panel = 16;
}

abstract final class LumenTheme {
  static const String fontFamily = 'Inter';

  static ThemeData build(Brightness brightness, FormFactor formFactor) {
    final c = brightness == Brightness.dark
        ? LumenColors.dark
        : LumenColors.light;
    // TV is viewed from ~3 m away: body text is at least 18 sp there.
    final scale = formFactor == FormFactor.tv ? 1.25 : 1.0;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: Colors.white,
      secondary: c.text,
      onSecondary: c.background,
      error: c.accent,
      onError: Colors.white,
      surface: c.surface,
      onSurface: c.text,
      onSurfaceVariant: c.muted,
      surfaceContainerLowest: c.background,
      surfaceContainerLow: c.background,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surfaceHigh,
      surfaceContainerHighest: c.surfaceHigh,
      outline: c.line,
      outlineVariant: c.line,
      shadow: c.shadow,
    );

    TextStyle s(double size, FontWeight w, {double ls = 0, Color? color}) =>
        TextStyle(
          fontFamily: fontFamily,
          fontSize: size * scale,
          fontWeight: w,
          letterSpacing: ls,
          color: color ?? c.text,
          height: 1.25,
        );

    final text = TextTheme(
      displayLarge: s(56, FontWeight.w800, ls: -1.6),
      displayMedium: s(44, FontWeight.w800, ls: -1.2),
      headlineLarge: s(34, FontWeight.w800, ls: -0.7),
      headlineMedium: s(28, FontWeight.w700, ls: -0.5),
      headlineSmall: s(22, FontWeight.w700, ls: -0.3),
      titleLarge: s(20, FontWeight.w700, ls: -0.2),
      titleMedium: s(16, FontWeight.w700),
      titleSmall: s(14, FontWeight.w600),
      bodyLarge: s(16, FontWeight.w400),
      bodyMedium: s(14.5, FontWeight.w400),
      bodySmall: s(12.5, FontWeight.w400, color: c.muted),
      labelLarge: s(15, FontWeight.w600),
      labelMedium: s(13, FontWeight.w600),
      labelSmall: s(12, FontWeight.w600, color: c.muted),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      extensions: [c],
      // Focus is drawn by FocusableCard / LumenFocusRing, not Material's
      // default highlight, so TV and keyboard users get one consistent ring.
      focusColor: Colors.transparent,
      splashFactory: formFactor == FormFactor.tv
          ? NoSplash.splashFactory
          : InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        indicatorColor: c.surfaceHigh,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
        height: 68,
      ),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceHigh,
        selectedColor: c.text,
        labelStyle: text.labelLarge,
        shape: const StadiumBorder(),
        side: BorderSide.none,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: Colors.white,
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          padding: EdgeInsets.symmetric(
            horizontal: 26 * scale,
            vertical: 14 * scale,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.background,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14 * scale,
          vertical: 14 * scale,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LumenRadii.card),
          borderSide: BorderSide(color: c.line, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LumenRadii.card),
          borderSide: BorderSide(color: c.line, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LumenRadii.card),
          borderSide: BorderSide(color: c.accent, width: 2),
        ),
      ),
    );
  }
}
