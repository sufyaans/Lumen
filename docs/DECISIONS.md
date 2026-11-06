# Decisions

Choices made where the brief left room, or where the brief had to bend to reality. Newest last.

## Phase 0

### D1. Flutter 3.47.9 / Dart 3.13.7
Upgraded from 3.47.7 to the latest stable before scaffolding, as the brief asks.

### D2. Android minSdk is 24, not 21
Flutter 3.47 sets `flutter.minSdkVersion = 24` (`FlutterExtension.kt`). The framework itself no longer supports API 21–23, so 21 isn't possible. 24 is Android 7.0. Every Android TV and Fire TV device still getting app updates meets it. Fire TV Stick (1st gen, Fire OS 5 / API 22) is excluded.

### D3. iOS deployment target 15.0
This is the template default for this Flutter version. `media_kit` will be checked against it in Phase 4. If it needs more, the target goes up then.

### D4. `material_ui` package instead of `package:flutter/material.dart`
Material was split out of the framework into the `material_ui` package. `go_router` 18 already depends on it. Mixing the two Material libraries would give two different `Theme`/`MaterialApp` types, so the app imports `package:material_ui/material_ui.dart` everywhere. If a later dependency (likely `media_kit_video`) still uses the old import, wrap that subtree in `MaterialUiCompatibilityBridge`. That widget is deprecated and temporary, so it isn't used until something needs it.

### D5. Custom D-pad traversal (`core/focus/directional_focus.dart`)
Flutter's built-in directional focus only searches inside the focused node's nearest `FocusScope`. Each shell tab is its own navigator with its own scope, so pressing Up from the first content row could never reach the tab bar. The built-in policy also keeps a per-scope move history, so the same key from the same control could land in different places depending on earlier presses. The traversal test found both problems.

The replacement is one geometric search over every focusable control on the routes currently showing. Covered routes are excluded via `ModalRoute.isCurrent` up the navigator chain. Left and Right only consider controls in the same vertical band. Scoring follows the prototype's `move()`.

### D6. Focus memory redirects only D-pad moves
`FocusMemory` (one per row, per screen and on the tab bar) sends focus back to the last item when D-pad focus re-enters a group. It deliberately ignores programmatic focus (route pop restoration) and pointer focus, so it never fights Flutter's own restoration. When nested memories disagree, the outermost one wins.

### D7. Text fields on TV
- Never autofocused.
- Up and Down leave the field.
- Left at caret 0, or Right at the end, leave it too. Otherwise those keys move the caret.

This meets "allow D-pad to leave a field" without breaking editing.

### D8. Debug-only preview catalogue
Release builds contain no content (brief §1). Debug builds show generated placeholder titles (`lib/dev/preview_catalog.dart`), so layout and focus can be checked before Phase 2 exists. It is only reachable behind `kDebugMode`, a compile-time constant, so it is tree-shaken from release. It has no URLs, images or provider names. Phase 1 adds the mock server, which takes over this job for integration tests.

### D9. Hero banner deferred to Phase 3
The brief says to show the hero only when a title has usable artwork. Image loading (`cached_network_image`) arrives with real data, so Home has no hero yet.

### D10. "No provider → Add provider" redirect deferred to Phase 3
On first run the terms screen leads to Add provider. Phase 0 offers "Browse for now" there, because the sign-in forms don't exist yet. Phase 3 makes the redirect mandatory when no provider is saved.

### D11. `shared_preferences` legacy API
`SharedPreferences.getInstance()` is loaded once in `main()` and injected through a Riverpod override. It's the simplest synchronous read for a few non-secret settings. Secrets will never go there (brief §5.8).

### D12. TV safe area
The whole app gets 5% padding on all sides on TV (`TvSafeArea`). Rows keep `Clip.none` so cards can scale on focus without clipping.

### D13. Image cache bounds
These are set in `configureForDevice`: 100 MB / 500 images on phones, 64 MB / 300 on TV, 32 MB / 150 in Lite mode. Phase 5 tunes them against measured heap.
