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

/// Default live stream format (brief section 3).
enum StreamFormat { auto, ts, hls }

/// Live buffering profile; mapped to mpv cache settings in Phase 4.
enum BufferingProfile { lowLatency, balanced, stable }

/// Hardware decoding; "Off" is one tap away in the player (brief 7).
enum HardwareDecoding { auto, on, off }

/// How much fits on a TV or tablet screen. [compact] shows the most.
enum DisplaySize {
  compact(0.75),
  standard(0.875),
  large(1.0);

  const DisplaySize(this.scale);
  final double scale;
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
    this.streamFormat = StreamFormat.auto,
    this.buffering = BufferingProfile.balanced,
    this.hardwareDecoding = HardwareDecoding.auto,
    this.autoplayNextEpisode = true,
    this.displaySize,
  });

  final ThemeMode themeMode;
  final int acceptedTermsVersion;
  final bool rotateForVideo;
  final RefreshPolicy refreshPolicy;

  /// Adult categories hidden; changing it needs the PIN (Phase 3 UI).
  final bool hideAdult;
  final StreamFormat streamFormat;
  final BufferingProfile buffering;
  final HardwareDecoding hardwareDecoding;
  final bool autoplayNextEpisode;

  /// Null = the default for the device (compact on TV, standard on tablet).
  final DisplaySize? displaySize;

  bool get termsAccepted => acceptedTermsVersion >= AppConfig.termsVersion;

  AppSettings copyWith({
    ThemeMode? themeMode,
    int? acceptedTermsVersion,
    bool? rotateForVideo,
    RefreshPolicy? refreshPolicy,
    bool? hideAdult,
    StreamFormat? streamFormat,
    BufferingProfile? buffering,
    HardwareDecoding? hardwareDecoding,
    bool? autoplayNextEpisode,
    DisplaySize? displaySize,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    acceptedTermsVersion: acceptedTermsVersion ?? this.acceptedTermsVersion,
    rotateForVideo: rotateForVideo ?? this.rotateForVideo,
    refreshPolicy: refreshPolicy ?? this.refreshPolicy,
    hideAdult: hideAdult ?? this.hideAdult,
    streamFormat: streamFormat ?? this.streamFormat,
    buffering: buffering ?? this.buffering,
    hardwareDecoding: hardwareDecoding ?? this.hardwareDecoding,
    autoplayNextEpisode: autoplayNextEpisode ?? this.autoplayNextEpisode,
    displaySize: displaySize ?? this.displaySize,
  );
}

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) =>
    values.firstWhere((e) => e.name == name, orElse: () => fallback);

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
  static const _kFormat = 'settings.streamFormat';
  static const _kBuffer = 'settings.buffering';
  static const _kHw = 'settings.hardwareDecoding';
  static const _kAutoplay = 'settings.autoplayNext';
  static const _kDisplay = 'settings.displaySize';

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
      streamFormat: _enumByName(
        StreamFormat.values,
        p.getString(_kFormat),
        StreamFormat.auto,
      ),
      buffering: _enumByName(
        BufferingProfile.values,
        p.getString(_kBuffer),
        BufferingProfile.balanced,
      ),
      hardwareDecoding: _enumByName(
        HardwareDecoding.values,
        p.getString(_kHw),
        HardwareDecoding.auto,
      ),
      autoplayNextEpisode: p.getBool(_kAutoplay) ?? true,
      displaySize: DisplaySize.values
          .where((e) => e.name == p.getString(_kDisplay))
          .firstOrNull,
    );
  }

  Future<void> setDisplaySize(DisplaySize v) async {
    state = state.copyWith(displaySize: v);
    await _prefs.setString(_kDisplay, v.name);
  }

  Future<void> setStreamFormat(StreamFormat v) async {
    state = state.copyWith(streamFormat: v);
    await _prefs.setString(_kFormat, v.name);
  }

  Future<void> setBuffering(BufferingProfile v) async {
    state = state.copyWith(buffering: v);
    await _prefs.setString(_kBuffer, v.name);
  }

  Future<void> setHardwareDecoding(HardwareDecoding v) async {
    state = state.copyWith(hardwareDecoding: v);
    await _prefs.setString(_kHw, v.name);
  }

  Future<void> setAutoplayNextEpisode(bool v) async {
    state = state.copyWith(autoplayNextEpisode: v);
    await _prefs.setBool(_kAutoplay, v);
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
