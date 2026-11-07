// End-to-end smoke test on a real device or emulator (brief section 11):
// add a provider -> first sync -> browse -> play -> leave -> resume.
//
//   flutter test integration_test/smoke_test.dart -d <device>
//
// The mock Xtream provider runs inside the test process on the device, so
// no network or real provider is needed. It serves a real Motion-JPEG clip
// that libmpv decodes in software, which also works on emulators.

import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lumen/app/app.dart';
import 'package:lumen/app/app_config.dart';
import 'package:lumen/app/data_providers.dart';
import 'package:lumen/app/router.dart';
import 'package:lumen/core/platform/form_factor.dart';
import 'package:lumen/data/secure/credential_store.dart';
import 'package:lumen/features/player/player_screen.dart';
import 'package:lumen/features/settings/app_settings.dart';
import 'package:lumen/main.dart' show configureForDevice;
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/helpers/test_db.dart';
import '../tool/mock_server/mock_xtream_server.dart';
import '../tool/mock_server/test_clip.dart';

class _MemorySecrets implements SecretBackend {
  final m = <String, String>{};
  @override
  Future<void> delete(String key) async => m.remove(key);
  @override
  Future<String?> read(String key) async => m[key];
  @override
  Future<void> write(String key, String value) async => m[key] = value;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('add provider, browse, play and resume', (tester) async {
    MediaKit.ensureInitialized();
    final mock = MockProvider()
      ..liveStreamCount = 12
      ..videoClip = buildTestClip(seconds: 120);
    final server = await MockXtreamServer.start(mock);
    final dir = await Directory.systemTemp.createTemp('lumen_smoke');
    final testDb = await TestDb.open(File('${dir.path}/smoke.db'));
    addTearDown(() async {
      await testDb.close();
      await server.close();
    });

    SharedPreferences.setMockInitialValues({
      'settings.termsVersion': AppConfig.termsVersion,
    });
    final device = await detectDeviceProfile();
    configureForDevice(device);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
          deviceProfileProvider.overrideWithValue(device),
          appDatabaseProvider.overrideWithValue(testDb.db),
          credentialStoreProvider.overrideWithValue(
            SecureCredentialStore(_MemorySecrets()),
          ),
        ],
        child: const LumenApp(),
      ),
    );
    await settle(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LumenApp)),
    );
    final router = container.read(routerProvider);

    // ---- 1. Add provider (typed into the real form) ----
    unawaited(router.push(Routes.addProvider));
    await settle(tester);
    final fields = find.byType(EditableText);
    // Link, Name, Server address, Username, Password.
    await tester.enterText(fields.at(2), server.hostPort);
    await tester.enterText(fields.at(3), mock.username);
    await tester.enterText(fields.at(4), mock.password);
    await tester.pump();
    await tester.ensureVisible(find.text('Connect'));
    await tester.pump();
    await tester.tap(find.text('Connect'));

    // ---- 2. First sync finishes and lands on Home ----
    await pumpUntil(
      tester,
      () => container.read(activeProviderIdProvider) != null,
      what: 'provider saved',
    );
    final providerId = container.read(activeProviderIdProvider)!;
    await pumpUntil(
      tester,
      () => find.text('Trending movies').evaluate().isNotEmpty,
      what: 'home rows after sync',
      timeout: const Duration(seconds: 60),
    );
    expect(find.text('Film 1'), findsWidgets);

    // ---- 3. Browse into a movie and play it ----
    unawaited(router.push(Routes.detail('movie:1001')));
    await pumpUntil(
      tester,
      () => find.text('Play').evaluate().isNotEmpty,
      what: 'Play button',
    );
    await settle(tester);
    await tester.tap(find.text('Play').last);
    await pumpUntil(
      tester,
      () => find.byType(PlayerScreen).evaluate().isNotEmpty,
      what: 'player opens',
    );
    final repo = container.read(catalogRepositoryProvider);
    // Let it play until the periodic save records a moving position (which
    // proves the clip really decodes). Start-up time varies on emulators.
    Future<int> saved() async =>
        (await repo.progressFor(1, providerId, 'movie', '1001'))?.positionMs ??
        0;
    await pumpUntilAsync(
      tester,
      () async => await saved() > 6000, // Resume needs 5 s+
      what: 'playback position to move',
    );
    await tester.binding.handlePopRoute(); // system Back saves progress
    await pumpUntil(
      tester,
      () => find.byType(PlayerScreen).evaluate().isEmpty,
      what: 'player closes',
    );
    final first = await repo.progressFor(1, providerId, 'movie', '1001');
    expect(first, isNotNull, reason: 'progress saved on leaving');
    expect(
      first!.positionMs,
      greaterThan(5000),
      reason: 'the clip actually played',
    );

    // ---- 4. Detail now offers Resume; resuming continues from there ----
    await pumpUntil(
      tester,
      () => find.text('Resume').evaluate().isNotEmpty,
      what: 'Resume button',
    );
    await settle(tester);
    await tester.tap(find.text('Resume').last);
    await pumpUntil(
      tester,
      () => find.byType(PlayerScreen).evaluate().isNotEmpty,
      what: 'player reopens',
    );
    final before = await saved();
    await pumpUntilAsync(
      tester,
      () async => await saved() > before,
      what: 'progress saved while resuming',
    );
    await tester.binding.handlePopRoute();
    await pumpUntil(
      tester,
      () => find.byType(PlayerScreen).evaluate().isEmpty,
      what: 'player closes again',
    );
    final second = await repo.progressFor(1, providerId, 'movie', '1001');
    expect(
      second!.positionMs,
      greaterThan(first.positionMs + 5000),
      reason: 'resumed from the saved position, not from the start',
    );

    // The mock saw real stream requests with the user's credentials.
    expect(
      mock.requests.where((r) => r.path.startsWith('/movie/')),
      isNotEmpty,
    );
    expect(container.read(appSettingsProvider).termsAccepted, isTrue);
  });
}

/// Pumps frames for [d] of real time (the player has endless animations,
/// so pumpAndSettle never returns while it is open).
Future<void> pumpFor(WidgetTester tester, Duration d) async {
  final end = DateTime.now().add(d);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> settle(WidgetTester tester) =>
    pumpFor(tester, const Duration(seconds: 2));

Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() ok, {
  String what = 'condition',
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (!ok()) {
    if (DateTime.now().isAfter(end)) {
      throw TimeoutException('Timed out waiting for $what');
    }
    await tester.pump(const Duration(milliseconds: 200));
  }
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> pumpUntilAsync(
  WidgetTester tester,
  Future<bool> Function() ok, {
  String what = 'condition',
  Duration timeout = const Duration(seconds: 60),
}) async {
  final end = DateTime.now().add(timeout);
  while (!await tester.runAsync(ok).then((v) => v ?? false)) {
    if (DateTime.now().isAfter(end)) {
      throw TimeoutException('Timed out waiting for $what');
    }
    await tester.pump(const Duration(milliseconds: 500));
  }
}
