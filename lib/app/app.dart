import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/focus/shortcuts.dart';
import '../core/focus/tv_safe_area.dart';
import '../core/platform/form_factor.dart';
import '../features/settings/app_settings.dart';
import 'app_config.dart';
import 'router.dart';
import 'theme.dart';

class LumenApp extends ConsumerWidget {
  const LumenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(deviceProfileProvider);
    final themeMode = ref.watch(appSettingsProvider.select((s) => s.themeMode));
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: LumenTheme.build(Brightness.light, device.formFactor),
      darkTheme: LumenTheme.build(Brightness.dark, device.formFactor),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => LumenShortcuts(
        // Same path as the system Back button.
        onBack: router.routerDelegate.popRoute,
        child: TvSafeArea(
          enabled: device.isTv,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
