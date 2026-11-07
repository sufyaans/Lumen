/// Single place for the app's name and identity.
///
/// Renaming the app also needs the Android `applicationId` / `namespace`
/// (android/app/build.gradle.kts), the Android label (AndroidManifest.xml)
/// and the iOS bundle ID / display name (ios/Runner). See README.md.
abstract final class AppConfig {
  static const String appName = 'Lumen';

  /// Placeholder IDs. Change them before publishing anywhere.
  static const String androidApplicationId = 'app.lumen.player';
  static const String iosBundleId = 'app.lumen.player';

  /// Keep in sync with `version:` in pubspec.yaml.
  static const String version = '1.0.0';

  /// Default user-agent, used last in the probe order (brief section 5.3).
  static const String defaultUserAgent = '$appName/$version';

  /// Bumped when the terms text changes, so users see it again.
  static const int termsVersion = 1;
}
