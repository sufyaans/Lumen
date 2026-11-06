import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/data_providers.dart';
import 'core/platform/form_factor.dart';
import 'core/platform/orientation.dart';
import 'data/db/app_database.dart';
import 'features/settings/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final results = await Future.wait([
    SharedPreferences.getInstance(),
    detectDeviceProfile(),
  ]);
  final prefs = results[0] as SharedPreferences;
  final device = results[1] as DeviceProfile;

  configureForDevice(device);
  await OrientationPolicy.applyBrowsing(device.formFactor);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        deviceProfileProvider.overrideWithValue(device),
        appDatabaseProvider.overrideWithValue(AppDatabase.open()),
      ],
      child: const LumenApp(),
    ),
  );
}

/// Process-wide settings that depend on the device.
void configureForDevice(DeviceProfile device) {
  if (device.isTv) {
    // A remote is the only input: always draw focus.
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
  // Bounded image memory (brief section 10). Smaller on TV and in Lite mode.
  final cache = PaintingBinding.instance.imageCache;
  if (device.liteMode) {
    cache.maximumSize = 150;
    cache.maximumSizeBytes = 32 << 20;
  } else if (device.isTv) {
    cache.maximumSize = 300;
    cache.maximumSizeBytes = 64 << 20;
  } else {
    cache.maximumSize = 500;
    cache.maximumSizeBytes = 100 << 20;
  }
}
