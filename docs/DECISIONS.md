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

## Phase 1

### D14. Redirects followed manually
`DioNetworkClient` sets `followRedirects: false` and follows up to 5 redirects itself. That's how a scheme or host change becomes visible, so the final base can be saved (scenario 6). It also means the per-host certificate rule applies to every hop.

### D15. Untrusted certificates are allowed per host, never globally
`badCertificateCallback` only returns true for a host the user explicitly allowed for that provider. The test checks that allowing one host doesn't allow another. The player (Phase 4) must mirror this with mpv's `tls-verify`.

### D16. The probe skips the user-agent loop on transport failures
DNS, refused, timeout and TLS failures skip the remaining user-agents for that endpoint, because the agent can't fix a dead socket. Only 401/403 and HTML/challenge pages try the next agent. This keeps the worst case under the 40 s budget: two candidates × one transport failure each. Without it, five agents × ten-second connect timeouts would blow the budget.

### D17. Definitive answers stop the probe
`auth:0`, `{}`, expired, banned/disabled and portal-detected responses end the probe at once. Retrying a wrong password with other agents could lock the account on strict panels.

### D18. Portal detection needs a failed probe
A `/c/` URL is still tried as Xtream, because some panels serve both. `portal_unsupported` is shown only when that probe fails with 404, HTML or unreadable data (brief §5.2).

### D19. M3U channel name
The name is the text after the comma that ends the attribute block. Attribute values are parsed with proper quote handling, so commas inside quotes are ignored and commas inside the name are kept ("Sport, Live, HD"). That is what the brief's "last comma that follows the attribute block" is aiming at. Splitting on the literal last comma would cut such names.

### D20. Stream checks live in the connection layer
`checkStream` opens at most 4 KB of a stream, following redirects. It treats 401/403, an empty 200 or an immediate close as max_connections. It runs only on demand ("Test playback" in Connection check, and later the player), never during sign-in.

### D21. Header timeout guard
dio's `receiveTimeout` covers gaps between body chunks. A server that accepts the connection and never sends headers is caught by an extra `connect + receive` timeout around the request (scenario 13).

### D22. Scenarios that span later phases
Scenarios 11, 22, 23, 24, 25 and 26 have a player or UI half: the playback banner, the Retry button, the offline banner over the cached catalogue, the password re-prompt screen, and headers reaching mpv. Phase 1 covers the connection-layer half: classification, redirects, the non-throwing store, and headers parsed per entry. The rest is tested in the phase that builds it (see CONNECTION_NOTES.md).

### D23. Mock server lives in `tool/`
`tool/mock_server/mock_xtream_server.dart` is shared by the tests and `dart run tool/mock_server/main.dart` (port 25461, `user` / `pass`). The TLS test uses a test-only self-signed certificate in `test/fixtures/tls/`.

## Phase 2

### D24. SQLite comes from `sqlite3` 3.x build hooks, not `sqlite3_flutter_libs`
`sqlite3_flutter_libs` is end-of-life (`0.6.0+eol`). `sqlite3` 3.x builds and bundles SQLite itself through Dart native-asset hooks, with FTS5 included. A debug APK builds with it, and the tests run against the same library on Windows.

### D25. Parse and write in one isolate
Big lists are downloaded on the main isolate as raw bytes, which costs no per-item work. They are then handed to `computeWithDatabase`, a short-lived isolate attached to the same database, which decodes, parses and upserts them in 1,000-row batches. The parsed objects never exist on the UI isolate (brief §4). The isolate entry points are top-level functions, so the closures capture only plain values.

### D26. The database runs in a multi-client drift isolate
`AppDatabase.open()` uses drift_flutter's `shareAcrossIsolates`. With `NativeDatabase.createInBackground`, which is single-client, a sync isolate disconnecting can shut the server down. A test caught that; tests now use a multi-client `DriftIsolate` too (`test/helpers/test_db.dart`).

### D27. Stale rows and user data
Every sync writes a `syncToken`, and rows with an older token are deleted only when the fetch was complete. A per-category fallback with failed categories keeps the old rows. Favourites, My list, progress and recents are separate tables keyed by provider id plus remote id, with no foreign keys, so refreshes never touch them.

### D28. M3U ids and credentials
M3U entries use `tvg-id` as their id when it's present and unique, otherwise `group|name`. That keeps favourites stable when stream URLs carry rotating tokens. Stored entry URLs have the playlist link's own `username`/`password` values replaced with placeholders (`SecretTemplate`), and only in the path and query, never the host. They're filled back in from secure storage at play time. Entries from a picked file are stored as they are, since the file is already on the device.

### D29. "Trending" and "Popular" without popularity data
Xtream doesn't expose popularity. "Trending movies" shows the newest additions (`added`) and "Popular series" the most recently updated (`last_modified`). The row titles follow the brief.

### D30. Refresh policy
On launch, the catalogue refreshes when the last sync is older than 6 hours. Daily means older than 24 hours. Manual never refreshes automatically. Cached data always shows first, and the refresh runs in the background with a thin progress bar.

### D31. Offline
`connectivity_plus` is only a hint. The banner reads "Offline, showing saved data" and appears when cached data exists and either connectivity reports none or the last refresh failed as unreachable (offline, DNS or timeout/refused). When connectivity comes back after an unreachable failure, the sync controller retries automatically. A Retry button is also offered.

### D32. Guide (XMLTV)
The guide is parsed with the `xml` package's event iterator inside the sync isolate, with `.xml.gz` detected by its magic bytes. Only channels in the lineup and programmes overlapping now −2 h … +48 h are kept, and the provider's previous guide is replaced. Xtream providers use `xmltv.php`. M3U providers use `url-tvg`/`x-tvg-url`, which is saved automatically. The `get_short_epg` fallback for visible channels is wired in Phase 3, alongside the guide UI that decides which channels are visible.

### D33. Adult and kids detection
Detection matches keywords on word boundaries, so "Essex" isn't adult. Adult categories are hidden by default (`AppSettings.hideAdult`; the PIN gate is Phase 3 UI). Kids profiles hide adult content and show only categories whose names look kids-appropriate.

## Phase 3

### D34. One data interface for the screens
Paged grids, detail, guide and search read through `BrowseQueries`. `RepositoryBrowseQueries` serves the database for the active provider and profile. `PreviewBrowseQueries` serves the debug preview and widget tests, so widget tests never need SQLite or a network. Home's rows still come from the bounded snapshot (`browseCatalogProvider`).

### D35. Every category is reachable
The category chips list every visible provider category, not just the first 24. "All" shows the overview rows (up to 24 categories × 30 items, like Netflix). Choosing a category opens an infinite grid that loads 60 items at a time as you scroll or D-pad toward the end.

### D36. Guide grid
There is one horizontal scroll area for a fixed window (now −30 min … +6 h). Inside it, the programme rows are a vertically virtualised list, and the sticky channel column is a separate list whose scroll offset is kept in sync with them. Channels load 40 at a time. Horizontally, each row only lays out programmes inside the window, so the width is bounded and doesn't need a second virtualised axis. When a channel has no XMLTV data, `get_short_epg` is fetched only for channels on screen, at most 2 at a time, once per channel per session, and the result is stored.

### D37. Channels open the player
Opening a channel (card, guide cell or "Now" programme) will start the player in Phase 4. Until then it shows a short "playback arrives in the next update" message. Future programmes show their start time.

### D38. First-run flow
Terms lead to Add provider. Release builds then redirect every screen to Add provider until a provider exists; the router re-checks whenever the provider list changes. Debug builds also offer "Browse preview (debug)".

### D39. Validating M3U providers
An M3U link or file is validated by the first sync itself, so the playlist isn't downloaded twice. If that sync fails, the progress screen shows the classified error with Try again, Connection check and Change details. Change details removes a provider that has never completed a sync.

### D40. Connection check
The check runs DNS lookup, TCP connect, response, login and catalogue as separate steps, using `dart:io` and the app's network client. Playlist providers skip the login step. Test playback runs only when you tap it, because it uses a connection slot. The report masks the host, removes URLs, and redacts known secrets.

### D41. Parental PIN
The PIN is 4 digits, stored in secure storage, and created the first time someone changes "Hide adult categories". Kids profiles always hide adult content.

### D42. Clear cache
Clear cache removes artwork, the TV guide and cached episode lists, then marks providers for a refresh. Providers, favourites, My list and progress stay.

### D43. Sign out
As in the prototype, Sign out deactivates the current provider and keeps saved providers. Removing a provider asks for confirmation and deletes its catalogue, user data and secrets.

### D44. Dialogs own their text controllers
A test caught the PIN dialog's controller being disposed while the dialog was still animating closed. That crashes on a real device too. `TextPromptDialog` now owns and disposes its controller.

### D45. Not in Phase 3
Not built yet:
- the player (Phase 4)
- "Sign in from your phone" (stretch)
- the catch-up UI (stretch; URL builder exists)
- a "Recently watched channels" row (recents are stored but have no row yet)

## Phase 4

### D46. Engine behind an interface
`PlaybackEngine` (open, play, pause, seek, stop, tracks, hardware decoding, view, state stream) is implemented by `MediaKitEngine` on media_kit / libmpv. All player behaviour lives in `PlayerController`, which tests drive with a fake engine.

### D47. mpv options used
These come from mpv's option names; each is applied with `NativePlayer.setProperty` and logged (redacted) if the build rejects it:
- Buffering profiles: `cache`, `demuxer-max-bytes`, `demuxer-readahead-secs`, `cache-secs` and `network-timeout`. Low latency is 8 MB / 1 s / 2 s / 10 s, Balanced 32 MB / 5 s / 10 s / 15 s, and Stable 64 MB / 20 s / 30 s / 20 s.
- Live reconnect: `stream-lavf-o=reconnect=1,reconnect_streamed=1,reconnect_on_network_error=1,reconnect_delay_max=5`.
- Hardware decoding: `hwdec` set to `auto-safe` (Auto), `auto` (On) or `no` (Off). It can be switched while playing.
- Headers: `user-agent` and `referrer`, plus the media's HTTP headers (the provider's working user-agent and M3U per-entry headers).

### D48. TLS verification in the player
When the user allows an untrusted certificate for a provider, the player sets `tls-verify=no`. Otherwise it keeps libmpv's default. Turning `tls-verify=yes` on everywhere needs a CA bundle that the Android libmpv build may not ship, and could break every HTTPS stream. Sign-in and catalogue traffic (dio) always verifies certificates, as the brief requires. This is on the "Needs manual testing" list.

### D49. Recovery rules
- **Max connections:** a stream that fails within 6 s of opening, before any video, is checked once with `checkStream` (the failed stream has already released its slot). If that reports 401/403/empty, the player shows "Too many devices in use" with Retry and doesn't loop.
- **Everything else:** up to 3 retries with 1 s / 2 s / 4 s backoff. Live retries cycle through the alternates: the other format (`m3u8` / `ts`), then the short `/{user}/{pass}/{id}` URL. A format that works after switching is saved on the provider and tried first next time.
- **Stalls:** buffering for 15 s after video has started counts as a failure.

### D50. One stream at a time
Opening anything stops the previous stream first, then waits 300 ms. Zapping updates the channel shown at once, but only opens it after 350 ms without another press. Number entry resolves 1.3 s after the last digit.

### D51. Background
After 20 s in the background, live streams stop (freeing the provider connection) and VOD pauses with progress saved. Returning reopens live streams. Audio interruptions (calls, another app taking audio focus, headphones unplugged) pause playback.

### D52. Remote keys
- **Live:** Up/Down (or Channel ±) change channel unless a panel is open. Digits enter a channel number. Left opens the channel list when the controls are hidden.
- **VOD:** Left/Right seek 10 s while the controls are hidden, and Fast-forward / Rewind skip 30 s.
- **Both:** Play/Pause keys work everywhere. Back closes a panel, then hides the controls (TV), then leaves the player.

### D53. Orientation and system UI
On entry, phones lock to landscape when "Rotate to landscape for video" is on, and the system UI goes immersive. iPad and TV follow the brief. Leaving restores everything, including after errors. `PopScope(canPop: false)` disables the iOS swipe-back gesture on the player.

## After Phase 4: TV feedback

### D54. Display canvas for TV and tablet
On a 1080p Android TV (960×540 logical), phone-sized layouts filled the screen. `DisplayCanvas` lays the app out on a larger virtual canvas and scales it to fit: 0.75 (1280×720) on TV by default, and 0.875 on tablets. A **Display size** setting (Compact, Standard, Large) changes this. With Compact, TV body text ends up around 15 dp, below the brief's 18 sp. That was a deliberate trade for density after user feedback; Large keeps the old size.

### D55. Non-standard HTTP codes
Codes like 512 or 509 come from panels and firewalls rejecting a request, not from a server that's down. They now map to "Your provider refused the request", and sign-in tries every identity before giving up. Only 500/502/503/504 and Cloudflare's 52x origin errors still mean "The server isn't answering".

### D56. Extra identity, pacing, and a more useful Connection check
- A standard Android Chrome user-agent (`browser`) is tried after Lavf and before the app's own.
- Sign-in waits 400 ms after each refused attempt, so providers never see a burst.
- The Connection check's response step tries each identity in turn. If a different one works, it's saved for that provider.
- When every identity is refused, the check shows a short excerpt of the provider's reply, with secrets and links removed.
- The report now shows the masked host, port and scheme (the old line was being scrubbed as a link), the identities tried and their status codes, and whether the address has IPv4 and/or IPv6.

### D57. Software decoding on emulators; first-frame watchdog
Emulator logs showed the stream opening (video size known) while the emulator's hardware decoder (`c2.goldfish.h264.decoder`) dropped every frame. media_kit forces software decoding on emulators by itself, but only when the app doesn't pass `hwdec`; Lumen always passed `auto-safe`, which overrode that. "Auto" now means software (`hwdec=no`) on emulators and simulators (`isPhysicalDevice == false`), and `auto-safe` elsewhere.

Separately, a stream whose playback position doesn't move within 25 s of opening counts as failed, which triggers retries and then an error screen, never an endless spinner. The error screen offers a one-tap "Turn off hardware decoding" (brief §7).

### D58. Engine "errors" are not all fatal
media_kit forwards every error-level libmpv log line (ffmpeg `tcp:` messages, including its own reconnect notices, plus `stream`, `vd` and `ad`) on its error stream. Lumen used to stop and reopen on any of them, which killed live streams that were playing fine, and the quick reopen could then collide with the provider's connection limit. Now an engine error is fatal only before the playback position has moved. After that, errors are logged as warnings, and a failure is detected when the position doesn't move for `stallTimeout` (15 s) while not paused by the user.

### D59. The emulator isn't a valid video test target
On the Android TV emulator, the hardware decoder drops every frame, and with software decoding libmpv's GPU output renders black. Audio frames reach Android's audio system, but the emulator may not pass sound through to the host. Video playback must be tested on a real phone, TV or iPad.

### D60. Branding comes from one script
The app icon (legacy, adaptive and monochrome layers), TV banner, Android 12+ splash icon, older-Android splash and iOS icons and launch image are all generated by `tool/branding/generate_icons.py` from one design: the Inter ExtraBold "Lumen" wordmark in the accent red (#FF3347) on the app background (#0C0C10), with the sign-in screen's red glow. Splash screens are dark in both system themes (Lumen is dark-first), and the window behind Flutter is the same colour, so there's no white flash at launch.

### D61. App ID app.lumen.player and a real release key
The Android application ID and iOS bundle ID are `app.lumen.player`. Changing the ID makes it a different app, so earlier test installs (`com.example.lumen`) must be uninstalled and their data doesn't carry over. Release builds are signed with the key in `android/key.properties` (gitignored, with the keystore beside it), and fall back to the debug key when that file is absent, so a fresh checkout still builds.

### D62. A generated test clip, and a device smoke test
FFmpeg isn't available here, and binary videos don't belong in the repo, so the mock server builds a Motion-JPEG AVI at runtime from a few embedded JPEG frames, plus an 8 kHz PCM audio track. libmpv decodes both formats in software. The audio isn't optional: on the TV emulator, libmpv can't create a GLES context, so there's no video output at all, and a video-only file reaches end-of-file at once (it was saved as "finished"). With audio, the clock runs and position, progress saving and resume can be tested on emulators. `integration_test/smoke_test.dart` covers add provider, first sync, browse, play, leave and resume on a device. Debug builds also print libmpv warnings to the console.

### D63. Recently watched channels
Home has a "Recently watched channels" row (newest first, up to 20), built from the `recents` table that the player already filled when a live channel starts. It respects the adult filter and refreshes when that table changes.

