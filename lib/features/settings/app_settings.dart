import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/app_config.dart';

/// When the catalogue refreshes automatically (brief section 6).
enum RefreshPolicy { onLaunch, daily, manual }

/// Whether a provider is due for a background refresh.
///
/// * [RefreshPolicy.onLaunch]: at launch when older than 6 hours.
/// * [RefreshPolicy.daily]: when older than 24 hours.
/// * [RefreshPolicy.manual]: never automatically (only the first sync).
bool isRefreshDue(DateTime? lastSync, RefreshPolicy policy, DateTime now) {
  if (lastSync == null) return true;
  final age = now.difference(lastSync);
  return switch (policy) {
    RefreshPolicy.onLaunch => age > const Duration(hours: 6),
    RefreshPolicy.daily => age > const Duration(hours: 24),
    RefreshPolicy.manual => false,
  };
}

/// Plain (non-secret) settings. Secrets never go here (brief section 5.8).
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.acceptedTermsVersion = 0,
    this.rotateForVideo = true,
    this.refreshPolicy = RefreshPolicy.onLaunch,
    this.hideAdult = true,
  });

  final ThemeMode themeMode;
  final int acceptedTermsVersion;
  final bool rotateForVideo;
  final RefreshPolicy refreshPolicy;

  /// Adult categories hidden; changing it needs the PIN (Phase 3 UI).
  final bool hideAdult;

  bool get termsAccepted => acceptedTermsVersion >= AppConfig.termsVersion;

  AppSettings copyWith({
    ThemeMode? themeMode,
    int? acceptedTermsVersion,
    bool? rotateForVideo,
    RefreshPolicy? refreshPolicy,
    bool? hideAdult,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    acceptedTermsVersion: acceptedTermsVersion ?? this.acceptedTermsVersion,
    rotateForVideo: rotateForVideo ?? this.rotateForVideo,
    refreshPolicy: refreshPolicy ?? this.refreshPolicy,
    hideAdult: hideAdult ?? this.hideAdult,
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
  static const _kRefresh = 'settings.refreshPolicy';
  static const _kHideAdult = 'settings.hideAdult';

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
      refreshPolicy: RefreshPolicy.values.firstWhere(
        (e) => e.name == p.getString(_kRefresh),
        orElse: () => RefreshPolicy.onLaunch,
      ),
      hideAdult: p.getBool(_kHideAdult) ?? true,
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

  Future<void> setRefreshPolicy(RefreshPolicy value) async {
    state = state.copyWith(refreshPolicy: value);
    await _prefs.setString(_kRefresh, value.name);
  }

  /// Callers must have checked the parental PIN first.
  Future<void> setHideAdult(bool value) async {
    state = state.copyWith(hideAdult: value);
    await _prefs.setBool(_kHideAdult, value);
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
