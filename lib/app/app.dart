import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/focus/shortcuts.dart';
import '../core/focus/tv_safe_area.dart';
import '../core/platform/display_canvas.dart';
import '../core/platform/form_factor.dart';
import '../features/settings/app_settings.dart';
import 'app_config.dart';
import 'data_providers.dart';
import 'router.dart';
import 'theme.dart';

class LumenApp extends ConsumerStatefulWidget {
  const LumenApp({super.key});

  @override
  ConsumerState<LumenApp> createState() => _LumenAppState();
}

class _LumenAppState extends ConsumerState<LumenApp> {
  @override
  void initState() {
    super.initState();
    // Cached data shows immediately; refresh in the background when due.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(syncControllerProvider.notifier).refreshIfDue();
    });
  }

  @override
  Widget build(BuildContext context) {
    final device = ref.watch(deviceProfileProvider);
    final themeMode = ref.watch(appSettingsProvider.select((s) => s.themeMode));
    final router = ref.watch(routerProvider);
    final displaySize = ref.watch(
      appSettingsProvider.select((s) => s.displaySize),
    );
    final scale = switch (device.formFactor) {
      FormFactor.tv => (displaySize ?? DisplaySize.compact).scale,
      FormFactor.tablet => (displaySize ?? DisplaySize.standard).scale,
      FormFactor.phone => 1.0,
    };

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
        child: DisplayCanvas(
          scale: scale,
          child: TvSafeArea(
            enabled: device.isTv,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
