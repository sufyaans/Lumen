// Walks every screen with scripted D-pad presses on a TV-sized window and
// asserts that every interactive element is reachable and none is a dead end
// (brief section 8).

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lumen/core/platform/form_factor.dart';
import 'package:lumen/domain/browse_catalog.dart';

import '../helpers/dpad.dart';
import '../helpers/pump_app.dart';

void expectFullyNavigable(WalkResult r, String screen) {
  expect(r.lost, isEmpty, reason: '$screen: lost track of ${r.lost}');
  expect(
    r.unreachable,
    isEmpty,
    reason: '$screen: controls not reachable by D-pad: ${r.unreachable}',
  );
  expect(
    r.deadEnds.where((d) => r.reached.length > 1),
    isEmpty,
    reason: '$screen: D-pad dead ends: ${r.deadEnds}',
  );
}

GoRouter routerOf(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Navigator).first));

Future<WalkResult> walkTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).first);
  await tester.pumpAndSettle();
  // Start the walk from the selected tab like a remote user would.
  final tab = find.text(label).first;
  Focus.of(tester.element(tab)).requestFocus();
  await tester.pumpAndSettle();
  return walkDpad(tester);
}

void main() {
  group('TV D-pad traversal', () {
    testWidgets('app starts with the Home tab focused', (tester) async {
      await pumpLumen(tester, formFactor: FormFactor.tv);
      await tester.pumpAndSettle();
      final focused = FocusManager.instance.primaryFocus;
      expect(focused, isNotNull);
      expect(focusId(focused!), contains('Home'));
    });

    for (final tab in ['Home', 'Live TV', 'Movies', 'TV Shows']) {
      testWidgets('$tab: every control reachable, no dead ends', (
        tester,
      ) async {
        await pumpLumen(tester, formFactor: FormFactor.tv);
        final r = await walkTab(tester, tab);
        expect(r.reached.length, greaterThan(5));
        expectFullyNavigable(r, tab);
      });
    }

    testWidgets('Account: every control reachable', (tester) async {
      await pumpLumen(tester, formFactor: FormFactor.tv);
      await tester.tap(find.bySemanticsLabel('Account').first);
      await tester.pumpAndSettle();
      Focus.of(tester.element(find.bySemanticsLabel('Account').first))
          .requestFocus();
      await tester.pumpAndSettle();
      final r = await walkDpad(tester);
      expect(r.reached.any((id) => id.contains('Add provider')), isTrue);
      expect(r.reached.any((id) => id.contains('Light')), isTrue);
      expectFullyNavigable(r, 'Account');
    });

    testWidgets('empty catalogue: Home still navigable', (tester) async {
      await pumpLumen(
        tester,
        formFactor: FormFactor.tv,
        catalog: BrowseCatalog.empty,
      );
      final r = await walkDpad(tester);
      expect(r.reached.any((id) => id.contains('Add provider')), isTrue);
      expectFullyNavigable(r, 'Home (empty)');
    });

    testWidgets('Detail: reachable controls and Back returns to the card', (
      tester,
    ) async {
      await pumpLumen(tester, formFactor: FormFactor.tv);
      await press(tester, LogicalKeyboardKey.arrowDown);
      await press(tester, LogicalKeyboardKey.arrowDown);
      final card = FocusManager.instance.primaryFocus!;
      final cardId = focusId(card);
      await press(tester, LogicalKeyboardKey.select);
      expect(find.text('Play'), findsOneWidget);

      final r = await walkDpad(tester);
      expect(r.reached.any((id) => id.contains('Play')), isTrue);
      expect(r.reached.any((id) => id.contains('My list')), isTrue);
      expect(r.reached.any((id) => id.contains('Close')), isTrue);
      expectFullyNavigable(r, 'Detail');

      await press(tester, LogicalKeyboardKey.escape);
      expect(find.text('Play'), findsNothing);
      expect(focusId(FocusManager.instance.primaryFocus!), cardId);
    });

    testWidgets('Search: field and back button reachable', (tester) async {
      await pumpLumen(tester, formFactor: FormFactor.tv);
      unawaited(routerOf(tester).push('/search'));
      await tester.pumpAndSettle();
      // Never autofocused on TV.
      expect(
        FocusManager.instance.primaryFocus?.context?.widget is EditableText,
        isFalse,
      );
      // Nothing is focused yet; the first press focuses the top-left control.
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(focusId(FocusManager.instance.primaryFocus!), contains('Back'));
      final r = await walkDpad(tester);
      // Back button and the search field (an unlabelled Focus node).
      expect(r.reached, hasLength(2));
      await press(tester, LogicalKeyboardKey.arrowRight);
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<EditableText>(),
        isNotNull,
        reason: 'Right from Back should land in the search field',
      );
      // Type, then Left walks the caret first and leaves at the start.
      await tester.enterText(find.byType(EditableText), 'ab');
      await tester.pumpAndSettle();
      await press(tester, LogicalKeyboardKey.arrowLeft);
      await press(tester, LogicalKeyboardKey.arrowLeft);
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<EditableText>(),
        isNotNull,
        reason: 'Caret moves inside the text before focus leaves',
      );
      await press(tester, LogicalKeyboardKey.arrowLeft);
      expect(focusId(FocusManager.instance.primaryFocus!), contains('Back'));
      expectFullyNavigable(r, 'Search');
    });

    testWidgets('Add provider: method tabs and button reachable', (
      tester,
    ) async {
      await pumpLumen(tester, formFactor: FormFactor.tv);
      unawaited(routerOf(tester).push('/add-provider'));
      await tester.pumpAndSettle();
      final r = await walkDpad(tester);
      for (final label in ['Xtream Codes', 'M3U link', 'M3U file', 'Close']) {
        expect(
          r.reached.any((id) => id.contains(label)),
          isTrue,
          reason: label,
        );
      }
      expectFullyNavigable(r, 'Add provider');
    });

    testWidgets('Terms: the continue button has focus on first run', (
      tester,
    ) async {
      await pumpLumen(tester, formFactor: FormFactor.tv, termsAccepted: false);
      expect(find.text('Before you start'), findsOneWidget);
      expect(
        focusId(FocusManager.instance.primaryFocus!),
        contains('I understand'),
      );
      await press(tester, LogicalKeyboardKey.select);
      expect(find.text('Connect your IPTV provider'), findsOneWidget);
    });
  });

  group('Back behaviour', () {
    testWidgets('Back on a non-Home tab returns to Home', (tester) async {
      await pumpLumen(tester, formFactor: FormFactor.tv);
      await tester.tap(find.text('Movies').first);
      await tester.pumpAndSettle();
      expect(find.text('Midnight Circuit'), findsWidgets);

      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(handled, isTrue);
      expect(find.text('Continue watching'), findsOneWidget);
    });

    testWidgets('Back on Home is not swallowed (app can exit)', (tester) async {
      await pumpLumen(tester, formFactor: FormFactor.tv);
      final handled = await tester.binding.handlePopRoute();
      expect(handled, isFalse);
    });
  });

  group('Focus memory', () {
    testWidgets('moving between rows returns to the column you left', (
      tester,
    ) async {
      await pumpLumen(tester, formFactor: FormFactor.tv);
      await press(tester, LogicalKeyboardKey.arrowDown); // row 1, item 1
      await press(tester, LogicalKeyboardKey.arrowRight); // row 1, item 2
      await press(tester, LogicalKeyboardKey.arrowRight); // row 1, item 3
      final remembered = focusId(FocusManager.instance.primaryFocus!);
      await press(tester, LogicalKeyboardKey.arrowDown); // row 2
      await press(tester, LogicalKeyboardKey.arrowLeft);
      await press(tester, LogicalKeyboardKey.arrowLeft); // row 2, item 1
      expect(focusId(FocusManager.instance.primaryFocus!), isNot(remembered));
      await press(tester, LogicalKeyboardKey.arrowUp); // back to row 1
      expect(focusId(FocusManager.instance.primaryFocus!), remembered);
    });
  });
}
