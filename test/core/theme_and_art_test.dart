import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/app/theme.dart';
import 'package:lumen/core/platform/form_factor.dart';
import 'package:lumen/core/widgets/cards.dart';
import 'package:lumen/core/widgets/fallback_art.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('titleHue', () {
    // Expected values computed with the prototype's JavaScript algorithm.
    test('matches the prototype', () {
      expect(titleHue('Lumen'), 213);
      expect(titleHue('Midnight Circuit'), 105);
      expect(titleHue(''), 0);
      expect(titleHue('Ash & Ember'), 67);
      expect(titleHue('日本'), 207);
      expect(titleHue('😀'), 259); // UTF-16 code units, like JS
    });
    test('is stable and in range', () {
      for (final t in ['a', 'Sport One HD', '  ', 'x' * 500]) {
        final h = titleHue(t);
        expect(h, inInclusiveRange(0, 359));
        expect(titleHue(t), h);
      }
    });
  });

  group('theme tokens', () {
    test('dark and light colours match the brief', () {
      expect(LumenColors.dark.background, const Color(0xFF0C0C10));
      expect(LumenColors.dark.surface, const Color(0xFF17171E));
      expect(LumenColors.dark.surfaceHigh, const Color(0xFF24242E));
      expect(LumenColors.dark.text, const Color(0xFFF4F4F7));
      expect(LumenColors.dark.muted, const Color(0xFFA0A0AE));
      expect(LumenColors.dark.accent, const Color(0xFFFF3347));
      expect(LumenColors.light.background, const Color(0xFFF5F5F7));
      expect(LumenColors.light.surface, const Color(0xFFFFFFFF));
      expect(LumenColors.light.surfaceHigh, const Color(0xFFE6E6EC));
      expect(LumenColors.light.text, const Color(0xFF14141A));
      expect(LumenColors.light.muted, const Color(0xFF5D5D6B));
      expect(LumenColors.light.accent, const Color(0xFFE5243B));
    });

    test('TV body text is at least 18 sp', () {
      final tv = LumenTheme.build(Brightness.dark, FormFactor.tv);
      expect(tv.textTheme.bodyLarge!.fontSize, greaterThanOrEqualTo(18));
      expect(tv.textTheme.bodyMedium!.fontSize, greaterThanOrEqualTo(18));
    });

    test('bundled Inter font is used', () {
      final t = LumenTheme.build(Brightness.light, FormFactor.phone);
      expect(t.textTheme.bodyMedium!.fontFamily, 'Inter');
    });
  });

  test('channel initials handle emoji and extra spaces', () {
    expect(ChannelCard.initials('Sport  One HD'), 'SOH');
    expect(ChannelCard.initials('😀 News'), '😀N');
    expect(ChannelCard.initials(''), '');
  });
}
