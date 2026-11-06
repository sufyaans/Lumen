import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/app/theme.dart';
import 'package:lumen/core/platform/form_factor.dart';
import 'package:lumen/core/widgets/fallback_art.dart';
import 'package:lumen/domain/browse_catalog.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('first launch shows the terms, then Add provider', (
    tester,
  ) async {
    await pumpLumen(tester, termsAccepted: false);
    expect(find.text('Before you start'), findsOneWidget);
    await tester.ensureVisible(find.text('I understand, continue'));
    await tester.tap(find.text('I understand, continue'));
    await tester.pumpAndSettle();
    expect(find.text('Connect your IPTV provider'), findsOneWidget);
    expect(find.text('Xtream Codes'), findsOneWidget);
    expect(find.text('M3U link'), findsOneWidget);
    expect(find.text('M3U file'), findsOneWidget);
  });

  testWidgets('phone uses a bottom navigation bar with five tabs', (
    tester,
  ) async {
    await pumpLumen(tester, formFactor: FormFactor.phone);
    expect(find.byType(NavigationBar), findsOneWidget);
    for (final label in ['Home', 'Live TV', 'Movies', 'TV Shows', 'Account']) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }
    await tester.tap(find.text('Movies').last);
    await tester.pumpAndSettle();
    expect(find.text('Midnight Circuit'), findsWidgets);
  });

  for (final b in Brightness.values) {
    testWidgets('active bottom tab is red (${b.name})', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = b;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await pumpLumen(tester, formFactor: FormFactor.phone);
      expect(
        Theme.of(tester.element(find.byType(NavigationBar))).brightness,
        b,
      );
      final ctx = tester.element(find.byType(NavigationBar));
      final theme = NavigationBarTheme.of(ctx);
      final accent = LumenColors.of(ctx).accent;
      expect(theme.indicatorColor, accent);
      expect(
        theme.labelTextStyle!.resolve({WidgetState.selected})!.color,
        accent,
      );
      expect(
        theme.iconTheme!.resolve({WidgetState.selected})!.color,
        Colors.white,
      );
    });
  }

  for (final ff in [FormFactor.tablet, FormFactor.tv]) {
    testWidgets('${ff.name} uses the top tab bar', (tester) async {
      await pumpLumen(tester, formFactor: ff);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Live TV'), findsOneWidget);
      expect(find.bySemanticsLabel('Search'), findsWidgets);
      expect(find.bySemanticsLabel('Account'), findsWidgets);
    });
  }

  testWidgets('empty rows are hidden and the empty catalogue explains why', (
    tester,
  ) async {
    await pumpLumen(tester, catalog: BrowseCatalog.empty);
    expect(find.textContaining('Nothing to show yet'), findsOneWidget);
    expect(find.text('Continue watching'), findsNothing);
  });

  testWidgets('missing artwork is drawn as generated gradient art', (
    tester,
  ) async {
    await pumpLumen(tester);
    expect(find.byType(FallbackArt), findsWidgets);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('appearance setting switches theme', (tester) async {
    await pumpLumen(tester, formFactor: FormFactor.tablet);
    await tester.tap(find.bySemanticsLabel('Account').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    final ctx = tester.element(find.text('Appearance'));
    expect(Theme.of(ctx).brightness, Brightness.light);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Appearance'))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('search filters across live, movies and series', (tester) async {
    await pumpLumen(tester, formFactor: FormFactor.tablet);
    await tester.tap(find.bySemanticsLabel('Search').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'comedy');
    await tester.pumpAndSettle();
    expect(find.text('Preview Comedy'), findsOneWidget); // channel
    expect(find.text('Little Thunder'), findsOneWidget); // movie
    expect(find.text('Open Season'), findsOneWidget); // series
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();
    expect(find.textContaining('Nothing matches'), findsOneWidget);
  });
}
