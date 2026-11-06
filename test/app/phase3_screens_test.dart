import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lumen/app/data_providers.dart';
import 'package:lumen/core/network/connection_error.dart';
import 'package:lumen/core/network/network_client.dart';
import 'package:lumen/core/platform/form_factor.dart';
import 'package:lumen/core/widgets/cards.dart';
import 'package:lumen/data/secure/credential_store.dart';
import 'package:lumen/data/sync/catalog_sync.dart';
import 'package:lumen/dev/preview_browse_queries.dart';
import 'package:lumen/domain/browse_catalog.dart';
import 'package:lumen/domain/browse_queries.dart';
import 'package:lumen/domain/media_summary.dart';
import 'package:lumen/features/common/error_panel.dart';
import 'package:lumen/features/diagnostics/connection_check.dart';
import 'package:lumen/features/diagnostics/connection_check_screen.dart';
import 'package:lumen/features/providers/sign_in_service.dart';
import 'package:lumen/features/settings/app_settings.dart';
import 'package:lumen/features/settings/parental_pin.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/dpad.dart';
import '../helpers/pump_app.dart';

class FakeSignIn implements SignInService {
  FakeSignIn(this.outcome);
  SignInOutcome outcome;
  final calls = <Map<String, String?>>[];

  @override
  Future<SignInOutcome> xtream({
    String? name,
    required String server,
    required String username,
    required String password,
    bool allowUntrustedCert = false,
    CancelSignal? cancel,
  }) async {
    calls.add({'server': server, 'username': username, 'password': password});
    return outcome;
  }

  @override
  Future<SignInOutcome> m3uUrl({
    String? name,
    required String url,
    String? epgUrl,
  }) async {
    calls.add({'url': url});
    return outcome;
  }

  @override
  Future<SignInOutcome> m3uFile({
    String? name,
    required String fileName,
    required Uint8List bytes,
  }) async => outcome;
}

class FakeSync extends SyncController {
  FakeSync(this.initial);
  final SyncState initial;
  @override
  SyncState build() => initial;
  void set(SyncState s) => state = s;
  @override
  Future<SyncResult?> refresh(
    String providerId, {
    bool includeGuide = true,
  }) async => null;
}

class FakeCheck implements ConnectionCheckRunner {
  @override
  Stream<List<CheckStep>> run() => Stream.value(const [
    CheckStep(
      'Network reachable',
      status: CheckStatus.passed,
      detail: 'Connected',
      elapsed: Duration(milliseconds: 3),
    ),
    CheckStep(
      'Address resolved',
      status: CheckStatus.passed,
      elapsed: Duration(milliseconds: 12),
    ),
    CheckStep(
      'Server connected',
      status: CheckStatus.passed,
      elapsed: Duration(milliseconds: 40),
    ),
    CheckStep('Response readable', status: CheckStatus.passed, httpStatus: 200),
    CheckStep(
      'Login accepted',
      status: CheckStatus.failed,
      error: ConnectionError(ConnectionErrorKind.authRejected),
    ),
    CheckStep(
      'Catalogue reachable',
      status: CheckStatus.skipped,
      detail: 'Skipped',
    ),
    CheckStep('Test playback', status: CheckStatus.skipped),
  ]);

  @override
  Future<CheckStep> testPlayback() async => const CheckStep(
    'Test playback',
    status: CheckStatus.passed,
    detail: 'Stream started',
  );

  @override
  String report({required String osAndDevice}) =>
      'REPORT for $osAndDevice: login authRejected';
}

class MemBackend implements SecretBackend {
  final m = <String, String>{};
  @override
  Future<void> delete(String key) async => m.remove(key);
  @override
  Future<String?> read(String key) async => m[key];
  @override
  Future<void> write(String key, String value) async => m[key] = value;
}

/// Many categories, counting page requests.
class CountingQueries extends PreviewBrowseQueries {
  CountingQueries() : super(BrowseCatalog.empty);
  final pages = <(String?, int)>[];

  @override
  Future<List<CategoryInfo>> categories(MediaKind kind) async => [
    for (var i = 1; i <= 40; i++) CategoryInfo('c$i', 'Category $i'),
  ];

  @override
  Future<List<MediaSummary>> page(
    MediaKind kind, {
    String? categoryId,
    bool favouritesOnly = false,
    int offset = 0,
    int limit = 60,
  }) async {
    pages.add((categoryId, offset));
    if (offset >= 150) return const [];
    return [
      for (var i = offset; i < offset + limit && i < 150; i++)
        MediaSummary(
          id: 'movie:$categoryId-$i',
          kind: MediaKind.movie,
          title: 'Film $i',
        ),
    ];
  }
}

GoRouter routerOf(WidgetTester t) =>
    GoRouter.of(t.element(find.byType(Navigator).first));

Future<void> openAddProvider(WidgetTester tester) async {
  unawaited(routerOf(tester).push('/add-provider'));
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

TextField fieldAfterLabel(WidgetTester tester, String label) {
  final all = tester.widgetList<TextField>(find.byType(TextField)).toList();
  final labels = [
    'Paste a link from your provider',
    'Name',
    'Server address',
    'Username',
    'Password',
  ];
  return all[labels.indexOf(label)];
}

void main() {
  group('Add provider', () {
    testWidgets('validates empty fields with plain messages', (tester) async {
      final svc = FakeSignIn(const SignInOk('p1'));
      await pumpLumen(
        tester,
        formFactor: FormFactor.tablet,
        extraOverrides: [signInServiceProvider.overrideWithValue(svc)],
      );
      await openAddProvider(tester);
      await tapText(tester, 'Connect');
      expect(find.textContaining('Enter the server address'), findsOneWidget);
      await tester.enterText(
        find.byType(TextField).at(2),
        'provider.example:8080',
      );
      await tapText(tester, 'Connect');
      expect(find.text('Enter your username.'), findsOneWidget);
      expect(svc.calls, isEmpty);
    });

    testWidgets('pasting a get.php link fills in the Xtream login', (
      tester,
    ) async {
      await pumpLumen(tester, formFactor: FormFactor.tablet);
      await openAddProvider(tester);
      await tester.enterText(
        find.byType(TextField).first,
        'http://provider.example:8080/get.php?username=bob&password=s3cret&type=m3u_plus',
      );
      await tapText(tester, 'Fill in from link');
      expect(
        find.text(
          'We found your login details in that link and filled them in.',
        ),
        findsOneWidget,
      );
      expect(
        fieldAfterLabel(tester, 'Server address').controller!.text,
        'http://provider.example:8080',
      );
      expect(fieldAfterLabel(tester, 'Username').controller!.text, 'bob');
      expect(fieldAfterLabel(tester, 'Password').controller!.text, 's3cret');
    });

    testWidgets('a plain .m3u link switches to M3U link', (tester) async {
      await pumpLumen(tester, formFactor: FormFactor.tablet);
      await openAddProvider(tester);
      await tester.enterText(
        find.byType(TextField).first,
        'https://cdn.example/list.m3u',
      );
      await tapText(tester, 'Fill in from link');
      expect(find.text('Playlist link'), findsOneWidget);
      expect(find.textContaining('went into M3U link'), findsOneWidget);
    });

    testWidgets(
      'a failed sign-in shows the class message, Details hides tech info',
      (tester) async {
        final svc = FakeSignIn(
          const SignInFailed(
            ConnectionError(
              ConnectionErrorKind.http401or403,
              details: 'HTTP 403 for s3cret',
            ),
          ),
        );
        await pumpLumen(
          tester,
          formFactor: FormFactor.tablet,
          extraOverrides: [signInServiceProvider.overrideWithValue(svc)],
        );
        await openAddProvider(tester);
        await tester.enterText(
          find.byType(TextField).at(2),
          'provider.example:8080',
        );
        await tester.enterText(find.byType(TextField).at(3), ' bob ');
        await tester.enterText(find.byType(TextField).at(4), 's3cret');
        await tapText(tester, 'Connect');
        expect(svc.calls.single['server'], 'provider.example:8080');
        expect(find.text('Your provider refused the request'), findsOneWidget);
        expect(
          find.textContaining('HTTP 403'),
          findsNothing,
          reason: 'jargon only behind Details',
        );
        await tapText(tester, 'Details');
        expect(find.textContaining('http401or403'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(ErrorPanel),
            matching: find.textContaining('s3cret'),
          ),
          findsNothing,
          reason: 'password is scrubbed from details',
        );
        expect(find.text('Connection check'), findsOneWidget);
      },
    );

    testWidgets('inner spaces in a password get a gentle hint', (tester) async {
      await pumpLumen(tester, formFactor: FormFactor.tablet);
      await openAddProvider(tester);
      await tester.enterText(find.byType(TextField).at(4), 'pa ss');
      await tester.pumpAndSettle();
      expect(find.textContaining('This contains a space'), findsOneWidget);
    });

    testWidgets('success goes to the sync progress screen', (tester) async {
      final svc = FakeSignIn(const SignInOk('p1'));
      await pumpLumen(
        tester,
        formFactor: FormFactor.tablet,
        extraOverrides: [
          signInServiceProvider.overrideWithValue(svc),
          syncControllerProvider.overrideWith(
            () => FakeSync(
              const SyncState(
                running: false,
                providerId: 'p1',
                progress: SyncProgress(SyncStep.categories),
              ),
            ),
          ),
        ],
      );
      await openAddProvider(tester);
      await tester.enterText(find.byType(TextField).at(2), 'provider.example');
      await tester.enterText(find.byType(TextField).at(3), 'bob');
      await tester.enterText(find.byType(TextField).at(4), 'pw');
      await tester.ensureVisible(find.text('Connect'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Connect'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Getting your channels ready'), findsOneWidget);
    });
  });

  group('Sync progress', () {
    Future<FakeSync> pumpSync(WidgetTester tester, SyncState s) async {
      final fake = FakeSync(s);
      await pumpLumen(
        tester,
        formFactor: FormFactor.tablet,
        extraOverrides: [syncControllerProvider.overrideWith(() => fake)],
      );
      unawaited(routerOf(tester).push('/syncing/p1'));
      // A running sync shows spinners, so pump a fixed time, not to settle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      return fake;
    }

    testWidgets('browsing unlocks once channels are in', (tester) async {
      final fake = await pumpSync(
        tester,
        const SyncState(
          running: true,
          providerId: 'p1',
          progress: SyncProgress(
            SyncStep.channels,
            received: 3 * 1024 * 1024,
            total: 6 * 1024 * 1024,
          ),
        ),
      );
      expect(find.text('Loading…'), findsOneWidget);
      expect(find.text('3.0 MB of 6.0 MB'), findsOneWidget);
      fake.set(
        const SyncState(
          running: true,
          providerId: 'p1',
          progress: SyncProgress(SyncStep.movies),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Start browsing'), findsOneWidget);
      expect(
        find.textContaining('keep loading in the background'),
        findsOneWidget,
      );
    });

    testWidgets('failure shows the error with Try again and Change details', (
      tester,
    ) async {
      await pumpSync(
        tester,
        const SyncState(
          providerId: 'p1',
          progress: SyncProgress(SyncStep.channels),
          lastResult: SyncResult(
            error: ConnectionError(ConnectionErrorKind.emptyCatalog),
          ),
        ),
      );
      expect(find.text('Signed in, but nothing came back'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Change details'), findsOneWidget);
    });

    testWidgets('lost password offers to enter it again', (tester) async {
      await pumpSync(
        tester,
        const SyncState(
          providerId: 'p1',
          lastResult: SyncResult(needsPassword: true),
        ),
      );
      expect(find.text('Enter password again'), findsOneWidget);
    });
  });

  testWidgets('Connection check shows each step and copies a report', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpLumen(
      tester,
      formFactor: FormFactor.tablet,
      extraOverrides: [
        connectionCheckRunnerProvider.overrideWith(
          (ref, args) async => FakeCheck(),
        ),
      ],
    );
    unawaited(
      routerOf(tester).push(
        '/connection-check',
        extra: const ConnectionCheckArgs(providerId: 'p1'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1. Network reachable'), findsOneWidget);
    expect(find.text('5. Login accepted'), findsOneWidget);
    expect(find.text('Login rejected'), findsOneWidget);
    expect(find.text('12 ms'), findsOneWidget);
    await tapText(tester, 'Copy report');
    expect(copied, startsWith('REPORT'));
    await tapText(tester, 'Test playback');
    expect(find.text('7. Test playback'), findsOneWidget);
    expect(find.text('Stream started'), findsOneWidget);
  });

  testWidgets('every category is a chip; a category pages its grid', (
    tester,
  ) async {
    final q = CountingQueries();
    await pumpLumen(
      tester,
      formFactor: FormFactor.tablet,
      catalog: BrowseCatalog.empty,
      queries: q,
    );
    await tester.tap(find.text('Movies').first);
    await tester.pumpAndSettle();
    // All 40 provider categories are offered, not just the first 24.
    final chipsEl = tester.element(
      find
          .ancestor(
            of: find.text('Category 1'),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    final chips = find.byElementPredicate((e) => e == chipsEl);
    await tester.scrollUntilVisible(
      find.text('Category 40'),
      300,
      scrollable: chips,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Category 40'));
    await tester.pumpAndSettle();
    expect(q.pages.where((p) => p.$1 == 'c40').map((p) => p.$2), [0]);
    expect(find.text('Film 0'), findsOneWidget);
    // Scrolling to the end loads the next page.
    final gridEl = tester.element(
      find
          .ancestor(of: find.text('Film 0'), matching: find.byType(Scrollable))
          .first,
    );
    final grid = find.byElementPredicate((e) => e == gridEl);
    await tester.scrollUntilVisible(
      find.text('Film 70'),
      400,
      scrollable: grid,
    );
    expect(
      q.pages.where((p) => p.$1 == 'c40').map((p) => p.$2),
      containsAll([0, 60]),
    );
  });

  testWidgets('Guide view shows channels and programmes; D-pad reaches them', (
    tester,
  ) async {
    await pumpLumen(tester, formFactor: FormFactor.tv);
    await tester.tap(find.text('Live TV').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guide'));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
    expect(find.textContaining('Preview News'), findsWidgets);
    expect(
      find.text('Bulletin').evaluate().isNotEmpty ||
          find.text('Match Day').evaluate().isNotEmpty,
      isTrue,
    );

    Focus.of(tester.element(find.text('Guide'))).requestFocus();
    await tester.pumpAndSettle();
    final r = await walkDpad(tester, maxNodes: 120);
    expect(r.reached.any((id) => id.contains('guide-programmes')), isTrue);
    expect(r.reached.any((id) => id.contains('guide-channels')), isTrue);
    expect(r.lost, isEmpty);
  });

  testWidgets('series detail lists seasons and episodes; My list toggles', (
    tester,
  ) async {
    await pumpLumen(tester, formFactor: FormFactor.tablet);
    unawaited(
      routerOf(tester)
          .push('/detail/${Uri.encodeComponent('series:harbour-lights')}'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Harbour Lights'), findsWidgets);
    expect(find.text('Season 1'), findsOneWidget);
    expect(find.text('Season 2'), findsOneWidget);
    expect(find.text('Resume S1 E1'), findsOneWidget);
    expect(find.text('Episode 6'), findsOneWidget);
    await tapText(tester, 'Season 2');
    expect(find.text('Episode 1'), findsOneWidget);
    await tapText(tester, 'My list');
    expect(find.text('Added to my list'), findsOneWidget);
    expect(find.text('In my list'), findsOneWidget);
  });

  testWidgets('showing adult categories needs a PIN', (tester) async {
    final pin = ParentalPin(MemBackend());
    final c = await pumpLumen(
      tester,
      formFactor: FormFactor.tablet,
      extraOverrides: [parentalPinProvider.overrideWithValue(pin)],
    );
    unawaited(routerOf(tester).push('/settings'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Show');
    expect(find.text('Create a PIN'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '1234');
    await tapText(tester, 'OK');
    await tester.enterText(find.byType(TextField).last, '1234');
    await tapText(tester, 'OK');
    expect(c.read(appSettingsProvider).hideAdult, isFalse);

    await tapText(tester, 'Hide');
    expect(find.text('Enter your PIN'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '0000');
    await tapText(tester, 'OK');
    expect(find.text("That PIN isn't right."), findsOneWidget);
    expect(c.read(appSettingsProvider).hideAdult, isFalse);
  });

  testWidgets('Settings: every control reachable by D-pad', (tester) async {
    await pumpLumen(tester, formFactor: FormFactor.tv);
    unawaited(routerOf(tester).push('/settings'));
    await tester.pumpAndSettle();
    await press(tester, LogicalKeyboardKey.arrowDown);
    final r = await walkDpad(tester);
    for (final label in [
      'Back',
      'Auto',
      'TS',
      'Low latency',
      'Stable',
      'Off',
      'Hide',
      'Daily',
      'Clear cache',
    ]) {
      expect(
        r.reached.any((id) => id.endsWith('/$label')),
        isTrue,
        reason: label,
      );
    }
    expect(r.unreachable, isEmpty);
    expect(r.lost, isEmpty);
  });

  testWidgets('tiles show a red bar when started and a tick when watched', (
    tester,
  ) async {
    const catalog = BrowseCatalog(
      movies: [
        MediaRow(
          title: 'Drama',
          items: [
            MediaSummary(
              id: 'movie:a',
              kind: MediaKind.movie,
              title: 'Half Way',
              progress: 0.5,
            ),
            MediaSummary(
              id: 'movie:b',
              kind: MediaKind.movie,
              title: 'All Done',
              progress: 1.0,
            ),
            MediaSummary(
              id: 'movie:c',
              kind: MediaKind.movie,
              title: 'Not Started',
            ),
          ],
        ),
      ],
      movieGenres: ['Drama'],
    );
    await pumpLumen(tester, formFactor: FormFactor.tablet, catalog: catalog);
    await tester.tap(find.text('Movies').first);
    await tester.pumpAndSettle();
    expect(find.byType(WatchedBadge), findsOneWidget);
    expect(find.bySemanticsLabel('All Done, watched'), findsOneWidget);
    expect(find.bySemanticsLabel('Half Way, 50% watched'), findsOneWidget);
    expect(find.bySemanticsLabel('Not Started'), findsOneWidget);
  });

  testWidgets('episodes show time left and Watched', (tester) async {
    await pumpLumen(tester, formFactor: FormFactor.tablet);
    unawaited(
      GoRouter.of(tester.element(find.byType(Navigator).first))
          .push('/detail/${Uri.encodeComponent('series:harbour-lights')}'),
    );
    await tester.pumpAndSettle();
    // Preview: S1E1 is 39 min long and 40 % watched.
    expect(find.text('23 min left'), findsOneWidget);
  });
}
