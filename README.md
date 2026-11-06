# Lumen

A player-only IPTV app for **Android phones, Android TV / Fire TV, iPhone and iPad**, built with Flutter. Lumen ships with no content. It plays what the user's own provider supplies, using their Xtream Codes login or M3U playlist.

Status: **Phase 2 (data layer) done.**
- Phase 0 built the navigation shells, theme, form-factor detection and TV focus engine.
- Phase 1 built sign-in, with all 27 acceptance scenarios passing.
- Phase 2 added the on-device SQLite catalogue: background-isolate sync, per-category fallback, FTS5 search, favourites, My list and progress, the XMLTV guide, the refresh policy and offline behaviour.

The full screens (including the sign-in forms) and the player follow in Phases 3–5. See [the build brief](design/lumen-flutter-claude-code-prompt.md) and [decisions](docs/DECISIONS.md).

## Setup (Windows or Linux)

1. Install Flutter stable (3.47.9 or newer) and Android Studio, which provides the Android SDK and a Java runtime.
2. `flutter doctor` should show Flutter and the Android toolchain as OK. You can ignore the Visual Studio warning unless you want Windows desktop builds; Lumen doesn't need them.
3. From the project folder:

```bash
flutter pub get
```

```bash
flutter analyze
```

```bash
flutter test
```

## Mock provider (for manual testing)

```bash
dart run tool/mock_server/main.dart
```

This serves a fake Xtream provider at `http://127.0.0.1:25461` (username `user`, password `pass`). From an Android emulator, use `10.0.2.2:25461`. It contains invented data only.

## Running

**Android phone emulator:** create a Pixel device in Android Studio's Device Manager, start it, then:

```bash
flutter run
```

**Android TV emulator:** in Device Manager, choose *Create device → TV → Television (1080p)* with an API 34+ image, start it, then `flutter run`. Use the arrow keys, Enter (Select) and Esc (Back) on your keyboard, or the emulator's D-pad panel.

Debug builds show generated preview titles so you can try navigation before a provider is added. Release builds show nothing until you add a provider.

## Building Android APKs

```bash
flutter build apk --release --split-per-abi
```

```bash
flutter build apk --release
```

The first command makes one APK per ABI (`arm64-v8a`, `armeabi-v7a`, `x86_64`). Many TV sticks run a 32-bit userland, so use `armeabi-v7a` for those. The second makes a universal APK. Output goes to `build/app/outputs/flutter-apk/`.

## Sideloading to Android TV or Fire TV

1. On the TV, turn on developer options and **ADB debugging**. On Fire TV: *Settings → My Fire TV → About*, press the device name 7 times, then *Developer options → ADB debugging*.
2. Find the TV's IP address under *Settings → Network*.
3. From your computer, on the same network:

```bash
adb connect 192.168.1.50:5555
```

```bash
adb install -r build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
```

Accept the prompt on the TV the first time. Lumen appears in the TV launcher row (it has a Leanback banner).

## iPad / iPhone: unsigned IPA from CI

You don't need a Mac. The `iOS (unsigned, for sideloading)` workflow builds on a GitHub macOS runner:

1. Push the repo to GitHub.
2. Go to *Actions → iOS (unsigned, for sideloading) → Run workflow*. Pushing a `v*` tag also runs it.
3. Download the `lumen-ios-unsigned` artifact and unzip it to get `Lumen-unsigned.ipa`.
4. Install with **AltStore** (or SideStore) using a free Apple ID. AltStore re-signs the app with your ID.

Free Apple ID limits:
- Apps expire after **7 days**. Refresh them in AltStore (AltServer on your PC, same Wi-Fi) before that.
- At most **3 sideloaded apps** at once, and 10 app IDs per week.
- Re-signing can change the keychain scope, so saved passwords may be lost. Lumen detects this and asks for the password again; other settings are kept.

**CI minutes:** on private repos, GitHub counts macOS runner minutes at 10x the Linux rate against your free allowance. The free plan currently includes 2,000 Linux-equivalent minutes a month, which is roughly 200 macOS minutes. Check current figures under *Settings → Billing*. Public repos don't use up minutes. That's why the iOS workflow only runs on demand or on tags.

**Alternatives (optional):** Codemagic's free tier can build and sign iOS apps. A paid Apple Developer account ($99/year) enables TestFlight and removes the 7-day expiry.

## Renaming the app and changing IDs

| What | Where |
|---|---|
| Display name used in code | `lib/app/app_config.dart` → `AppConfig.appName` |
| Android label | `android/app/src/main/AndroidManifest.xml` → `android:label` |
| Android ID | `android/app/build.gradle.kts` → `namespace` and `applicationId`; also move `android/app/src/main/kotlin/com/example/lumen/MainActivity.kt` to the matching package folder and update its `package` line |
| iOS display name | `ios/Runner/Info.plist` → `CFBundleDisplayName`, `CFBundleName` |
| iOS bundle ID | `ios/Runner.xcodeproj/project.pbxproj` → every `PRODUCT_BUNDLE_IDENTIFIER = com.example.lumen` |
| TV banner | `android/app/src/main/res/drawable-xhdpi/tv_banner.png` (320×180) |

Also update the placeholders in `AppConfig.androidApplicationId` and `AppConfig.iosBundleId`.

## Project layout

```
lib/
  app/        app widget, router, theme, AppConfig
  core/       platform (FormFactor, orientation), focus engine, widgets
  domain/     UI-facing models
  features/   one folder per screen
  dev/        debug-only preview data (tree-shaken from release)
test/         unit, widget and D-pad traversal tests
design/       the brief and the HTML prototype (visual reference)
docs/         DECISIONS.md, CONNECTION_NOTES.md
```

## Needs manual testing

These can't be verified automatically from this setup and still need a real-device check:

- [ ] Real Android TV remote, including Back, Select and media keys (tests use simulated key events)
- [ ] Fire TV: detection via the `amazon.hardware.fire_tv` feature or `AFT*` model, and the launcher banner
- [ ] Leanback launcher entry on a real Android TV
- [ ] iPhone and iPad: layout, rotation, split-screen, keyboard and pointer (no Mac or iOS simulator available; the IPA is built in CI only)
- [ ] AltStore install and the keychain behaviour after re-signing
- [ ] Real provider sign-in (Phase 1 onwards)
- [ ] Real playback on an iPad and on a TV stick (Phase 4 onwards)
- [ ] Performance on a 1 GB TV stick in Lite mode (Phase 5)
