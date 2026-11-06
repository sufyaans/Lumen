import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/app_config.dart';

/// Plain (non-secret) settings. Secrets never go here (brief section 5.8).
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.acceptedTermsVersion = 0,
    this.rotateForVideo = true,
  });

  final ThemeMode themeMode;
  final int acceptedTermsVersion;
  final bool rotateForVideo;

  bool get termsAccepted => acceptedTermsVersion >= AppConfig.termsVersion;

  AppSettings copyWith({
    ThemeMode? themeMode,
    int? acceptedTermsVersion,
    bool? rotateForVideo,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    acceptedTermsVersion: acceptedTermsVersion ?? this.acceptedTermsVersion,
    rotateForVideo: rotateForVideo ?? this.rotateForVideo,
  );
}

/// Overridden in main() with the loaded instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

class AppSettingsNotifier extends Notifier<AppSettings> {
  static const _kTheme = 'settings.theme';
  static const _kTerms = 'settings.termsVersion';
  static const _kRotate = 'settings.rotateForVideo';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final p = ref.watch(sharedPreferencesProvider);
    return AppSettings(
      themeMode: switch (p.getString(_kTheme)) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      },
      acceptedTermsVersion: p.getInt(_kTerms) ?? 0,
      rotateForVideo: p.getBool(_kRotate) ?? true,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(_kTheme, switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'auto',
    });
  }

  Future<void> acceptTerms() async {
    state = state.copyWith(acceptedTermsVersion: AppConfig.termsVersion);
    await _prefs.setInt(_kTerms, AppConfig.termsVersion);
  }

  Future<void> setRotateForVideo(bool value) async {
    state = state.copyWith(rotateForVideo: value);
    await _prefs.setBool(_kRotate, value);
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
