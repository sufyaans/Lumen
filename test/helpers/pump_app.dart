import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/app/app.dart';
import 'package:lumen/app/app_config.dart';
import 'package:lumen/app/data_providers.dart';
import 'package:lumen/core/platform/form_factor.dart';
import 'package:lumen/dev/preview_catalog.dart';
import 'package:lumen/domain/browse_catalog.dart';
import 'package:lumen/features/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Logical screen sizes used by the tests.
const phoneSize = Size(390, 844);
const tabletSize = Size(1024, 768);
const tvSize = Size(960, 540); // 1080p at 2.0 dpr, typical Android TV

/// Pumps the whole app with a given form factor and catalogue.
Future<ProviderContainer> pumpLumen(
  WidgetTester tester, {
  FormFactor formFactor = FormFactor.phone,
  BrowseCatalog? catalog,
  bool termsAccepted = true,
  Size? size,
}) async {
  SharedPreferences.setMockInitialValues({
    if (termsAccepted) 'settings.termsVersion': AppConfig.termsVersion,
  });
  final prefs = await SharedPreferences.getInstance();

  final logical =
      size ??
      switch (formFactor) {
        FormFactor.phone => phoneSize,
        FormFactor.tablet => tabletSize,
        FormFactor.tv => tvSize,
      };
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = logical * 2.0;
  addTearDown(tester.view.reset);

  FocusManager.instance.highlightStrategy = formFactor == FormFactor.tv
      ? FocusHighlightStrategy.alwaysTraditional
      : FocusHighlightStrategy.automatic;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      deviceProfileProvider.overrideWithValue(
        DeviceProfile(formFactor: formFactor, liteMode: false),
      ),
      // No database, provider list or connectivity plugin in widget tests.
      providersListProvider.overrideWith((ref) => Stream.value(const [])),
      connectivityOnlineProvider.overrideWith((ref) => Stream.value(true)),
      browseCatalogProvider.overrideWithValue(catalog ?? buildPreviewCatalog()),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const LumenApp()),
  );
  await tester.pumpAndSettle();
  return container;
}
