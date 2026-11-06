# Build brief: "Lumen", a Flutter IPTV player for Android phones, Android TV and iOS/iPadOS

You are building a production-quality, player-only IPTV app in Flutter. Read this whole brief before writing code. It covers the product, the architecture, the connection layer (the most important part), the UI, the player, platform specifics, testing and delivery.

Where this brief says "verify", check current documentation or pub.dev rather than relying on memory. Package APIs and platform requirements change.

---

## 1. Goals and non-goals

### Goals
1. One Flutter codebase that runs well on:
   - Android phones (portrait browsing, landscape playback)
   - Android TV and Fire TV (D-pad remote, 10-foot UI)
   - iPhone and iPad
2. A Netflix-style interface with these top-level areas: **Home, Live TV, Movies, TV Shows**, plus **Search** and **Account**.
3. **Reliable IPTV sign-in.** This is the top priority. Users of other apps hit authentication errors, host errors, wrong-address errors, blocked requests and cryptic failures. This app must accept messy real-world input, adapt to quirky providers automatically, and when something does fail, say exactly what failed and what to do next.
4. Smooth performance on mid-range phones and on weak Android TV sticks (1 GB RAM class), including catalogs of 10,000+ channels and 50,000+ VOD items.
5. Offline-friendly: cached catalog opens instantly; refresh happens in the background.

### Non-goals (do not build)
- No content of any kind is bundled. No default playlists, no provider names, no sample stream URLs in release builds.
- No features whose purpose is to evade ISP or network blocking, geo-restrictions or DRM. No VPN or DNS-bypass features.
- No cloud backend, accounts, analytics, telemetry or ad SDKs. Everything stays on the device.
- No Stalker/MAG portal support in v1. Detect it and show a clear "not supported yet" message.
- No Apple TV (tvOS) target.

### Legal and store posture
The app is a player for content the user is entitled to access, using login details from their own provider. Include a short Terms/disclaimer screen shown on first launch that says this. Keep the codebase clean of anything that would conflict with Apple or Google store policies.

---

## 2. Environment and constraints

- The developer has **no Mac**. Do not rely on Xcode or the iOS Simulator. You can build and run Android locally (emulators, including an Android TV emulator). **iOS is built in CI** on GitHub Actions macOS runners.
- The iPad build will be **sideloaded** (AltStore or similar, with a free Apple ID). Therefore:
  - Do **not** add any iOS capability or entitlement that needs a paid Apple Developer account (push notifications, iCloud, App Groups, Sign in with Apple, associated domains).
  - Keychain use through `flutter_secure_storage` with default settings is fine.
  - If the bundle ID changes after re-signing, secure storage can be empty. Handle that gracefully (see section 5.9).
- Use the **latest stable Flutter and Dart**. Run `flutter --version` and `flutter doctor` first and report the result.
- Make the app name and IDs easy to change in one place: `AppConfig.appName = 'Lumen'`, Android `applicationId` and iOS bundle ID as `com.example.lumen` placeholders. Document how to rename.
- Minimum OS targets: Android minSdk 21 if all dependencies allow (otherwise the lowest that works; report why), iOS 13.0 or whatever `media_kit` requires (verify).
- **State clearly what you could not verify.** You cannot run iOS or a real TV remote. Do not claim those work without evidence. List them in a "Needs manual testing" section of the README.

---

## 3. Visual design and UX

A working HTML prototype exists at `design/lumen-tv-prototype.html`. Open it and treat it as the **visual and interaction reference**: layout, row structure, focus behaviour, login flow, account page, player controls. Reimplement it natively in Flutter. Do not embed it in a web view.

### Design tokens (dark-first, with a light theme)
| Token | Dark | Light |
|---|---|---|
| background | `#0C0C10` | `#F5F5F7` |
| surface | `#17171E` | `#FFFFFF` |
| surface high | `#24242E` | `#E6E6EC` |
| text | `#F4F4F7` | `#14141A` |
| muted text | `#A0A0AE` | `#5D5D6B` |
| accent | `#FF3347` | `#E5243B` |

Appearance setting: Auto / Dark / Light.

- Corner radius 10 on cards, 999 on chips and pills, 16 on panels.
- Typography: bundle a font in `assets/fonts` (Inter or similar). **Do not** fetch fonts at runtime. Type scale must be larger on TV (body at least 18 sp).
- Cards: posters are 2:3, wide cards 16:9, channel cards show logo, name, now and next with a progress bar.
- Missing or broken artwork is common. When an image fails or is empty, show a generated gradient (hash the title to a hue) with the title text, as in the prototype. Never show a broken-image icon.
- Hero banner on Home: a featured title with Play and More info. Only show it if the catalog has a title with usable artwork; otherwise skip it.
- Rows: Continue watching, My list, Favourite channels, Trending movies, Popular series, Live now. Hide empty rows.

### Navigation by form factor
Define `FormFactor { phone, tablet, tv }` and resolve it once at startup.
- **tv**: device reports the `android.software.leanback` system feature (use `device_info_plus` `systemFeatures` or a small platform channel), or Fire TV.
- **tablet**: shortest side at least 600 dp (includes iPad).
- **phone**: everything else.

Navigation:
- Phone: bottom `NavigationBar` (Home, Live TV, Movies, TV Shows, Account) with Search in the app bar.
- Tablet and TV: top tab bar like the prototype, with search and profile at the right.

Orientation:
- Phone: portrait for browsing, **landscape locked during playback**, restored on exit.
- iPad: all orientations for browsing, landscape preferred in the player.
- TV: landscape only.

### Screens
1. **First-run**: terms, then Add provider.
2. **Add provider** (also reachable from Account): tabs **Xtream Codes**, **M3U link**, **M3U file**, plus a single "Paste a link from your provider" smart field (section 5.2).
3. **Home**, **Live TV** (Channels view and Guide view), **Movies**, **TV Shows**.
4. **Detail**: movie detail; series detail with seasons and episodes; My list toggle; Play and Resume.
5. **Search**: global across live, movies and series, with instant results.
6. **Player**.
7. **Account**: current profile, provider card (status, expiry, connections, counts, refresh), saved providers (use, remove with confirmation), profiles (switch, add, kids), settings, **Connection check** (section 5.7), sign out.
8. **Settings**: appearance, rotate to landscape for video, default stream format (Auto, TS, HLS), buffering profile (Low latency, Balanced, Stable), hardware decoding (Auto, On, Off), hide adult categories (PIN to change), update catalog on launch, clear cache.

### Copy rules
Sentence case. Plain verbs. Say what happened and what to do next. Errors never blame the user and never use jargon like "CORS" or "HTTP 403" in the headline. Technical detail goes behind a "Details" toggle and in the diagnostics report.

---

## 4. Architecture

### Stack (verify current versions and fitness on pub.dev before adding)
| Concern | Choice |
|---|---|
| State | `flutter_riverpod` (Notifier/AsyncNotifier) |
| Routing | `go_router` |
| HTTP | `dio` behind a `NetworkClient` interface so it can be swapped |
| Database | `drift` on SQLite (`sqlite3_flutter_libs`), FTS5 for search |
| Secrets | `flutter_secure_storage` |
| Plain settings | `shared_preferences` |
| Player | `media_kit`, `media_kit_video`, and the platform libs for each target (verify the exact package set) |
| Images | `cached_network_image` with a bounded cache |
| Files | `file_picker` |
| XML (EPG) | `xml` event-based streaming parser, `archive` for gzip |
| Device info | `device_info_plus` |
| Keep awake | `wakelock_plus` |
| iOS audio | `audio_session` (so sound plays with the silent switch on) |
| Tests | `flutter_test`, `integration_test`, `mocktail`, `shelf` (mock server) |

Do **not** use `json_serializable` for provider API responses. Provider JSON is inconsistent (numbers as strings, `false` instead of `[]`, missing keys). Write tolerant hand-written parsers (section 5.4). Codegen is fine for your own local models.

### Folder layout (feature-first)
```
lib/
  main.dart
  app/                 # app widget, router, theme, AppConfig
  core/
    platform/          # FormFactor, orientation, TV detection
    focus/             # focus engine, FocusableCard, shortcuts
    network/           # NetworkClient, retry, redaction, error types
    utils/
  data/
    db/                # drift tables, DAOs, migrations
    xtream/            # Xtream client + DTO parsers
    m3u/               # M3U parser (isolate-based)
    epg/               # XMLTV parser
    secure/            # credential store
  domain/              # models, repositories, use cases
  features/
    onboarding/ providers/ home/ live/ movies/ series/
    search/ detail/ player/ account/ settings/ diagnostics/
tool/mock_server/      # shelf-based fake Xtream server for tests
test/ integration_test/
design/lumen-tv-prototype.html
docs/ (DECISIONS.md, CONNECTION_NOTES.md)
```

### Data model (drift tables, summarised)
- `providers`: id, kind (xtream | m3u_url | m3u_file), name, display host (redacted), endpoint JSON (scheme, host, port, basePath), preferred user-agent id, preferred live extension, allow-untrusted-cert flag (per provider), epg url, last sync, last user-info snapshot JSON.
- Secrets are **not** in the database. Password and any URL that contains credentials live in secure storage, keyed by provider id.
- `categories`, `channels`, `movies`, `series`, `episodes` (cached lazily), `epg_programs` (indexed by channel epg id and time), `profiles`, `favourites`, `progress`, `recents`.
- FTS5 virtual table over names for search.
- Refresh = upsert in a transaction, remove stale rows, **keep user data** (favourites and progress are keyed by provider id plus remote id, so a refresh never wipes them).
- Never load a full table into memory. Paginate with limit and offset or keyset, expose as streams.

### Isolates
Anything heavy runs off the UI isolate: JSON decode of large responses, M3U parsing, XMLTV parsing, bulk DB writes. The UI must stay at 60 fps while a 60 MB catalog syncs.

---

## 5. The connection layer (highest priority)

Build this first, test it hardest, and do not move on until the scenario table in 5.10 passes against the mock server.

### 5.1 Principles
- Be liberal in what you accept, strict in what you store.
- Try sensible alternatives automatically (scheme, user-agent, stream format) and **remember what worked** per provider.
- Never hold more connections open than needed. Providers limit simultaneous streams, and a wasted connection can lock the user out of their own line.
- Classify every failure into a known class with a human message (5.6). Never show a raw exception.
- Never log secrets (5.8).

### 5.2 Input normalisation (`ServerEndpoint.parse`)
Input comes from copy-paste and is often dirty. Implement a pure, well-tested function that turns raw text into candidate endpoints and extracted credentials.

Handle all of these:
- Leading/trailing whitespace, newlines, tabs, NBSP, zero-width characters (U+200B/C/D, U+FEFF), smart quotes, a trailing slash.
- Missing scheme (`provider.example:8080`). Candidates: try `http` first, then `https`.
- Scheme given: try as given, then the flipped scheme. Default ports apply only when no port is given (80 for http, 443 for https). **Do not guess other ports** and do not scan ports.
- Mixed-case scheme and host: lowercase them.
- IP addresses, IPv6 literals in brackets, internationalised domains (punycode).
- Pasted URLs with extra path: strip known endpoints (`/player_api.php`, `/get.php`, `/xmltv.php`, `/panel_api.php`, `/c/`, `/portal.php`, `/live/...`, `/movie/...`, `/series/...`) and keep any remaining base path.
- **Full playlist URL pasted into the server field**, for example `http://host:port/get.php?username=U&password=P&type=m3u_plus`. Extract host, username and password and switch to Xtream mode, telling the user: "We found your login details in that link and filled them in."
- `http://user:pass@host` userinfo: extract the credentials.
- A `/c/` or portal-style path with no `player_api.php` hint: show the "portal (Stalker/MAG) not supported yet" message after a failed probe.
- Reject: empty host, spaces inside the host, unsupported schemes (`rtmp://`, `rtsp://`, `udp://`), and a host that is clearly not a host.

Credentials:
- Trim leading and trailing whitespace, newlines and zero-width characters only. **Never alter inner characters.**
- If the value has inner whitespace, show a gentle hint but still try it as typed.
- Build URLs only with `Uri` (query parameters and path segments encoded properly). Passwords containing `@ : / ? & # % + ` and non-ASCII characters must work in API calls **and** stream URLs.

### 5.3 Probe sequence (`ConnectionDoctor.probe`)
Run sequentially (never in parallel), stop at the first success, keep total time bounded (under about 40 s worst case, and cancellable).

1. For each candidate endpoint (from 5.2), for each user-agent profile in this order:
   - the provider's saved profile if it exists
   - `okhttp/4.12.0`
   - `VLC/3.0.20 LibVLC/3.0.20`
   - `Lavf/60.16.100`
   - the app default (`Lumen/<version>`)

   Send `GET {base}/player_api.php?username=U&password=P` (no `action`). Timeouts: connect 10 s, receive 20 s. Follow up to 5 redirects. If a redirect changes scheme or host, note it and use the final base from then on.
2. Decode the body **regardless of Content-Type**. Strip a UTF-8 BOM and leading whitespace. If the body has junk before the first `{` (for example a PHP warning), find the first `{` and try again. If it starts with `<`, classify it as an HTML response.
3. Interpret `user_info`:
   - `auth` can be `1`, `"1"`, `true`, `0`, `"0"`, `false` or missing. Normalise.
   - `status` is compared case-insensitively: Active, Expired, Banned, Disabled, Trial.
   - `exp_date` is a unix timestamp as a number or string, or null/empty/0 meaning no expiry. Treat values above 1e12 as milliseconds.
   - Read `max_connections`, `active_cons`, `is_trial`, `created_at`, `allowed_output_formats`.
   - Read `server_info` (url, port, https_port, server_protocol, timezone, timestamp_now) and store it. **Use the address the user entered as primary.** Use `server_info` only as a fallback if streams fail on the entered host.
4. Verify catalog access with `action=get_live_categories`. If auth passed but this fails, still save the provider and show a warning.
5. Do **not** open a stream during sign-in. That wastes a connection slot. Offer an optional "Test playback" button in the Connection check screen instead.
6. Persist the working profile (endpoint, user-agent id, preferred live extension) on the provider record. Reuse it next time and re-probe automatically if it stops working.

If all combinations fail, return the most informative failure class (for example, 401 on all attempts beats "timeout" on one), plus the full attempt log for diagnostics.

### 5.4 Tolerant Xtream parsing
The Xtream `player_api.php` API is the main interface. Implement:

| Action | Purpose |
|---|---|
| (none) | user and server info |
| `get_live_categories`, `get_vod_categories`, `get_series_categories` | categories |
| `get_live_streams`, `get_vod_streams`, `get_series` | catalog (optional `&category_id=`) |
| `get_vod_info&vod_id=`, `get_series_info&series_id=` | detail |
| `get_short_epg&stream_id=&limit=` | per-channel EPG fallback |
| `xmltv.php?username=&password=` | bulk EPG |

Quirks the parsers **must** survive (write unit tests with fixtures for each):
- Numbers sent as strings and vice versa (`stream_id`, `category_id`, `num`, `rating`, `added`).
- Fields that are `false`, `null`, `""`, `[]` or `{}` when empty. A list endpoint can return `false`.
- Missing keys, extra keys, duplicate IDs, empty names, very long names, emoji, HTML entities.
- `stream_icon` / `cover` empty or invalid URLs.
- `get_series_info`: `episodes` is a **map keyed by season number** in most panels but can be a **list** when there is one season. Missing `container_extension` defaults to `mp4`.
- `get_short_epg`: `title` and `description` are **base64-encoded**. Use `start_timestamp` and `stop_timestamp`, not the local-time strings, to avoid timezone bugs.
- Response sizes: `get_live_streams` and `get_vod_streams` can exceed 50 MB.

Handling big lists:
1. Download as bytes with progress, decode and parse in an isolate, and write to the database in batches inside that isolate.
2. If the all-at-once request times out or fails, **fall back to per-category requests** with at most 2 concurrent calls and a short delay between them. Some panels throttle or ban bursts.
3. Limit all API concurrency to 2 to 3 requests per provider.

Stream URL builders (centralised in one class, with tests):
- Live: `{base}/live/{user}/{pass}/{streamId}.{ext}` where ext is `ts` or `m3u8`. Fall back to `{base}/{user}/{pass}/{streamId}` if the first form returns 404 on that panel.
- Movie: `{base}/movie/{user}/{pass}/{streamId}.{containerExtension}`
- Episode: `{base}/series/{user}/{pass}/{episodeId}.{containerExtension}`
- Catch-up (when `tv_archive` is 1): `{base}/timeshift/{user}/{pass}/{durationMinutes}/{YYYY-MM-DD:HH-mm}/{streamId}.ts`. Optional feature, build the URL builder and tests but the UI can come later.
- Choose the live extension from `allowed_output_formats` and the user's setting (Auto prefers `m3u8` when offered and falls back to `ts` on failure, or vice versa based on what last worked).

### 5.5 M3U handling
- **M3U link**: download with the same error classification as Xtream. Treat the full URL as a secret if it contains credentials.
- **M3U file**: `file_picker`, read as bytes, detect encoding (UTF-8 with or without BOM, fall back to Latin-1/Windows-1252).
- Parse streaming, line by line, in an isolate. Support CRLF, blank lines, duplicates, very large files (50 MB+).
- Parse attributes (`tvg-id`, `tvg-name`, `tvg-logo`, `tvg-chno`, `group-title`, `catchup*`). Channel name is the text after the **last** comma that follows the attribute block (attributes themselves may contain commas inside quotes).
- Read the playlist header `url-tvg="..."` (or `x-tvg-url`) and offer it as the EPG source automatically.
- **Per-entry playback options**, which many playlists need: `#EXTVLCOPT:http-user-agent=`, `#EXTVLCOPT:http-referrer=`, and `#EXTHTTP:{...json headers...}`. Store them with the entry and pass them to the player as HTTP headers.
- Classify entries: URLs containing `/movie/` become movies, `/series/` become series, everything else is live. Group by `group-title`.
- If the file does not start with `#EXTM3U` (after BOM and whitespace) and contains no `#EXTINF`, show the "doesn't look like a playlist" message.

### 5.6 Error classes and messages
Every failure maps to one class. UI shows the title and body; "Details" shows the technical info.

| Class | Title | Body (with the next step) |
|---|---|---|
| invalid_input | That address doesn't look right | Enter the server address your provider gave you, for example http://example.com:8080. |
| dns_failure | Can't find that server | Check the address for typos and that you're online. If it keeps failing, ask your provider whether the address has changed. |
| timeout / refused | The server isn't answering | The address was found but the server didn't respond. Check the port number, or try again in a few minutes. |
| tls_error | Secure connection failed | Try http:// instead. If your provider uses a self-made certificate, you can allow it for this provider in Advanced. |
| http_401_403 | Your provider refused the request | Your username or password may be wrong, or the provider blocked this request. Check your details. The app already tried other connection settings. |
| http_404 | That isn't an Xtream address | Check the address. If your provider gave you an M3U link, use the M3U link tab. |
| html_response | Got a web page instead of data | The address leads to a website, not the provider's service. Check the address your provider gave you. |
| portal_unsupported | This looks like a portal address | Portal (MAG/Stalker) logins aren't supported yet. Ask your provider for an Xtream login or M3U link. |
| auth_rejected | Login rejected | The server says the username or password is incorrect. Check capital letters and extra spaces. |
| expired | Subscription expired | Your subscription ended on {date}. Renew it with your provider, then try again. |
| disabled | Account disabled | The provider has disabled or banned this account. Contact your provider. |
| max_connections | Too many devices in use | Your plan allows {n} at the same time. Stop playback on another device and try again. |
| empty_catalog | Signed in, but nothing came back | The account works but returned no channels, movies or series. Try Refresh, or ask your provider. |
| malformed | Unexpected response | The server sent data we couldn't read. Run the Connection check and share the report with your provider. |
| offline | No internet connection | Connect to a network and try again. Your saved catalog is still available. |
| m3u_invalid | That doesn't look like a playlist | Choose an .m3u or .m3u8 file, or check the link. |

### 5.7 Connection check screen (in Account and linked from every sign-in error)
A step-by-step diagnostic that shows each step live with pass/fail and timing:
1. Network reachable.
2. Address resolved.
3. Server connected.
4. Response readable.
5. Login accepted (status, expiry, connections in use and allowed).
6. Catalog reachable (counts).
7. Optional: Test playback on the first live channel.

Each failed step shows the plain-language message from 5.6. A **Copy report** button produces a plain-text report: app version, OS and device, provider host partially masked (first two characters plus TLD), each step's result, HTTP statuses, timings, which user-agent and scheme were tried. It contains **no username, password, tokens or stream URLs.**

### 5.8 Logging and secrets
- All network logging goes through one redaction layer. It removes `username`, `password` and any `user:pass@` and replaces credentials inside stream paths (`/live/U/P/...`).
- Release builds log warnings and errors only.
- Credentials: secure storage only. Never in `shared_preferences`, the database, crash output or the diagnostics report.

### 5.9 Resilience
- **Retries** (idempotent GETs only): network errors and timeouts, 3 attempts with 0.5 s, 1.5 s, 4 s delays plus jitter. Respect `Retry-After` on 429 and 503. Do not retry auth failures more than once. Stop immediately when the user cancels.
- **Secure storage failures**: some Android devices throw on keystore errors after a restore, and an iOS re-sign can change the keychain scope. Catch all read/write errors. If a saved provider's password is missing, show "Enter your password again to continue" for that provider and keep its other settings. Never crash.
- **Offline**: show cached catalog with a small "Offline, showing saved data" banner and retry when connectivity returns. Use `connectivity_plus` only as a hint, never as proof of reachability.
- **Server clock**: use `server_info.timestamp_now` to compute an offset for "now" in EPG and catch-up.
- **Certificates**: untrusted certificates are rejected by default. Only after the user enables "Allow untrusted certificate" for **that provider** do you accept them, and only for that host. Apply the matching option to the player (verify the mpv `tls-verify` property). Show a clear warning when enabling it.

### 5.10 Acceptance scenarios (build a mock server in `tool/mock_server` using `shelf`)
Each scenario needs an automated test (unit or integration) that passes.

| # | Mock server behaviour | Expected result |
|---|---|---|
| 1 | Normal JSON, integers | Sign-in succeeds |
| 2 | Numbers as strings, `auth:"1"`, `exp_date` string, null exp_date | Succeeds; null exp shown as "No expiry" |
| 3 | BOM and whitespace before JSON; PHP warning text before JSON | Succeeds |
| 4 | `Content-Type: text/html` on a JSON body | Succeeds |
| 5 | gzip and deflate responses | Succeeds |
| 6 | 301 http to https and https to http | Succeeds; new base saved |
| 7 | User enters host only (no scheme) | Tries http then https; saves the one that works |
| 8 | 403 unless user-agent is `okhttp/*` or `VLC/*` | Succeeds via fallback; saved profile reused next time |
| 9 | `auth:0`; and a `{}` response | auth_rejected message |
| 10 | Expired (past exp_date); status Banned; status Disabled | Correct class each |
| 11 | `active_cons` equals `max_connections` | Sign-in succeeds with a warning; playback shows max_connections if the stream is refused |
| 12 | `get_live_streams` takes 10 s and returns 60 MB | Progress shown, UI never janks, cancellable |
| 13 | `get_live_streams` times out | Falls back to per-category loading |
| 14 | Cloudflare-style HTML page | html_response message |
| 15 | Self-signed TLS | tls_error; works after the per-provider option is enabled |
| 16 | Password `p@ss:w/rd?&#%+ é` | API calls and stream URLs are encoded correctly (server verifies the decoded value) |
| 17 | Credentials with trailing space, newline, zero-width character | Trimmed; succeeds |
| 18 | Full `get.php?username=..&password=..` URL pasted in the server field | Credentials extracted and prefilled |
| 19 | `server_info.url` differs from the entered host | Entered host stays primary; fallback only on failure |
| 20 | Fields missing, `false`, wrong types, duplicate ids, emoji names | No crash; sane results |
| 21 | Series `episodes` as map and as list; missing extension | Both parse; defaults to `mp4` |
| 22 | Live stream 302 redirect to a tokenised URL | Plays |
| 23 | Stream closes immediately (max connections) | max_connections message with Retry |
| 24 | Network lost mid-session | Cached catalog browsable; banner; retry |
| 25 | Secure storage throws | Re-prompt for password; no crash |
| 26 | M3U with commas in attributes, `#EXTVLCOPT` and `#EXTHTTP` lines, CRLF, BOM, Windows-1252, 50 MB | Parsed correctly; headers passed to the player; UI responsive |
| 27 | Portal-style URL (`/c/`) | portal_unsupported message |

Add a `docs/CONNECTION_NOTES.md` listing every quirk handled and the test that covers it.

---

## 6. Catalog sync and caching
- First sign-in: show a progress screen with steps ("Signing in", "Loading categories", "Loading channels", "Loading movies", "Loading series"). Let the user start browsing as soon as categories and channels are in; movies and series can finish in the background.
- App start: show cached data immediately, refresh in the background if older than 6 hours (setting: on launch, daily, manual). Pull-to-refresh and a Refresh button in Account.
- Stale-while-revalidate everywhere. Never block the UI on the network after the first sync.
- EPG: prefer bulk XMLTV. Stream-parse it in an isolate, keep only channels in the user's lineup and a window from 2 hours ago to 48 hours ahead, and store compact rows. Support `.xml.gz`. If no XMLTV, fall back to `get_short_epg` only for **visible** channels, debounced, and limited to 2 concurrent requests.
- Adult content: categories whose names match an adult keyword list are hidden by default. A PIN-protected setting reveals them. Kids profiles also hide them and limit channels to kids-appropriate categories where the provider's category names allow it.

---

## 7. Player

### Engine
Use `media_kit` (libmpv). Wrap it behind a `PlaybackEngine` interface (play, pause, seek, tracks, state stream, dispose) so the engine could be swapped later. Verify the exact `media_kit` APIs and platform library packages in current docs.

### Behaviour
- **One active stream at a time.** Stop and dispose the previous before opening the next.
- **Debounce channel zapping** (about 350 ms) so rapid up/down presses do not open a dozen connections. After a stop, wait about 300 ms before opening the next stream.
- Pass the provider's user-agent (and any M3U per-entry headers) as HTTP headers. Use the same user-agent that worked at sign-in.
- Live buffering profiles (Low latency, Balanced, Stable) map to demuxer readahead, cache size and network timeout. Enable ffmpeg reconnect options for live streams (verify property names against mpv and ffmpeg docs).
- **Auto-recovery for live**: on stall or error, retry up to 3 times with backoff and an on-screen "Reconnecting…" state. On the first failure, switch the extension (`ts` to `m3u8` or the reverse) and remember what works.
- A stream that fails instantly with 401/403 or EOF right after connect is treated as **max_connections** and shows that message.
- VOD: HTTP range seeking. If the server does not support ranges, show seek as unavailable instead of failing. Save position every 10 s and on exit; resume prompt. Autoplay next episode (setting).
- Hardware decoding setting: Auto, On, Off. On devices where it misbehaves, "Off" must be one tap away from the player's settings menu.
- Tracks: audio and subtitle selection. Aspect modes: Fit, Fill, 16:9, 4:3.
- Live controls: channel up/down, number entry (1.3 s timeout), channel list overlay, now/next banner, favourite toggle. Do **not** auto-preview channels in browsing screens, because previews consume a connection slot.
- Keep the screen awake during playback. Stop or pause when the app goes to the background for more than a short grace period, which frees the provider connection.
- iOS: configure the audio session for playback so sound works with the silent switch on. Disable the swipe-back gesture on the player route.
- Android: handle audio focus; handle `PopScope` back so Back first hides overlays, then exits.
- Orientation: phones lock to landscape on entry, immersive system UI, and restore on exit (including after errors and on process resume).

---

## 8. Android TV and Fire TV specifics
- Manifest: `<uses-feature android:name="android.software.leanback" android:required="false"/>`, `<uses-feature android:name="android.hardware.touchscreen" android:required="false"/>`, a second intent filter with `android.intent.category.LEANBACK_LAUNCHER`, and a 320x180 `android:banner`. The same APK must install on phones and TVs.
- `android:usesCleartextTraffic="true"` with a `network_security_config` that permits cleartext (providers commonly use http). Permissions: INTERNET, ACCESS_NETWORK_STATE, WAKE_LOCK.
- Build both `arm64-v8a` and `armeabi-v7a`. Many sticks run a 32-bit userland. Verify the player libraries support both.
- **Focus engine** (`core/focus`):
  - Everything interactive is reachable and operable with D-pad and Select. Back always goes back and never traps the user.
  - A `FocusableCard` widget handles focus (scale about 1.06 to 1.08 plus a 3 px outline), tap, hover, and long-press alternatives. Visual focus effects are active only when the form factor is TV or a keyboard is in use.
  - Remember the last focused item per row and per screen, and restore it on return.
  - Scroll the focused item into view with margin. Add 5% safe-area padding on TV for overscan.
  - Map keys: Select, Enter and gameButtonA activate; media play/pause, fast-forward and rewind work in the player; channel up/down and the number keys zap in Live; Back pops.
  - Provide an automated widget test that walks every screen with scripted D-pad presses and asserts that all interactive elements are reachable, with no dead ends.
- **Text entry on TV is painful.** Make fields large, never autofocus, allow D-pad to leave a field, provide a Paste button, and support M3U import from a file picker. **Stretch goal (v1.1): "Sign in from your phone"**. The TV shows a QR code and a short code and runs a tiny LAN-only server (`shelf`) with a one-time random token. A phone browser posts the login details, the TV asks for confirmation, and the server shuts down after 5 minutes or on first use.
- Low-RAM devices: detect `ActivityManager.isLowRamDevice` (or memory under about 1.5 GB) and enable **Lite mode** automatically: no blur or heavy animation, smaller image cache and decode sizes, no hero animation.

---

## 9. iOS and iPadOS specifics
- Deployment target 13.0 or higher as required by dependencies. Targeted device family: iPhone and iPad.
- `Info.plist`: all orientations for iPad; add landscape for iPhone; `NSAppTransportSecurity` allowing arbitrary loads as a safety net (Dart sockets and libmpv do not go through ATS, but keep this set); `NSLocalNetworkUsageDescription` with a clear reason (providers or playlists on a home network).
- No paid-only entitlements (section 2).
- Support keyboard navigation and pointer hover on iPad. Support split-screen sizes.
- CI builds an **unsigned** IPA for sideloading (section 11).

---

## 10. Performance budget
Measure with `flutter run --profile` and DevTools, and report the numbers.
- Cold start to cached Home: under 2 s on a mid-range phone.
- Scrolling: no jank in release on a mid-range phone; target 60 fps on Chromecast with Google TV class devices, 30 fps acceptable on 1 GB sticks in Lite mode.
- 10,000+ channel list scrolls smoothly (virtualised lists, fixed extents where possible, `const` widgets, no `Opacity` or `BackdropFilter` in lists, no blur on TV).
- Images: decode at display size (`cacheWidth`/`memCacheWidth`), bounded memory cache (smaller on TV), limited concurrent loads, no unbounded prefetch.
- **EPG grid**: virtualised in both directions. Use one fixed-width horizontal scroll area containing a vertically virtualised list, with a separate sticky channel column synced to the same vertical controller.
- Memory: stay under about 300 MB on phones and under about 200 MB on TV sticks during browsing. Profile heap after a full catalog load.
- Release builds: R8 minify and shrink resources on Android. Verify the release build still plays video and parses (R8 can break reflection-based code).

---

## 11. Build, CI and delivery

### Local (Windows/Linux friendly)
- `flutter pub get`, `flutter analyze`, `flutter test`.
- Android: `flutter run` on an emulator (phone and Android TV profiles), `flutter build apk --release --split-per-abi` and also a universal APK for convenience.
- Document `adb connect <ip>:5555` and `adb install` for sideloading to a TV stick.

### GitHub Actions (`.github/workflows/`)
1. `ci.yml` on every push and PR: `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test`.
2. `android.yml`: build APKs and upload them as artifacts.
3. `ios.yml` on a **macOS runner**: build unsigned and package for sideloading.
   ```
   flutter build ios --release --no-codesign
   mkdir -p Payload
   cp -r build/ios/iphoneos/Runner.app Payload/
   zip -r Lumen-unsigned.ipa Payload
   ```
   Upload `Lumen-unsigned.ipa` as an artifact. Confirm the `flutter build ios` output path against current Flutter before relying on this. Check current GitHub Actions macOS minute allowances and mention them in the README (private repos can use minutes faster than Linux ones).
4. Document the optional Codemagic or paid TestFlight path in the README as an alternative (not required).

### README must include
- Setup for Windows/Linux, running on Android phone and Android TV emulators.
- Sideloading to Android TV or Fire TV.
- Getting the unsigned IPA from CI and installing with AltStore using a free Apple ID (7-day expiry, 3-app limit, refresh requirement).
- Renaming the app and changing IDs.
- A "Needs manual testing" list: real iPad playback, real TV remote, Fire TV, real provider sign-in.

---

## 12. Testing requirements
- Unit tests: `ServerEndpoint.parse` (table of at least 40 messy inputs), credential handling, every parser fixture (Xtream shapes and M3U variants), URL builders, error classification, retry logic, EPG time handling.
- Mock-server integration tests covering all 27 scenarios in 5.10.
- Widget tests: focus traversal on every screen, login form validation, error states.
- A smoke integration test: add provider (mock server) to browse to play (a local test stream served by the mock server, generated with ffmpeg if available) to resume.
- Keep tests fast and deterministic. No tests that hit real servers.

---

## 13. Delivery plan (work in this order, commit per milestone)

**Phase 0: foundation.** Project scaffold, lints, CI skeleton, theme, `FormFactor`, router and navigation shells for phone/tablet/TV, focus engine and its traversal test harness. Report `flutter doctor`.

**Phase 1: connection layer.** `ServerEndpoint.parse`, Xtream client and tolerant parsers, M3U parser, `ConnectionDoctor`, error classes, redaction, secure credential store, mock server, and all 27 scenarios green. **Do not continue until this phase passes.**

**Phase 2: data.** Drift schema, isolate-based sync, per-category fallback, favourites and progress tables, search (FTS5), offline behaviour.

**Phase 3: UI.** Add-provider flow (including Connection check screen), Home, Live (channels and guide), Movies, TV Shows, Detail, Search, Account, Settings, profiles.

**Phase 4: player.** Engine wrapper, live and VOD behaviours from section 7, orientation handling, recovery, tracks.

**Phase 5: polish and hardening.** TV QA via emulator, Lite mode, performance pass against section 10, release builds, CI for Android and iOS, README.

**Stretch (only after the above is solid):** sign-in from phone, catch-up UI, Picture-in-Picture, background audio, parental PIN polish.

At the end of each phase, output: what was built, what tests pass (with counts), what you could not verify, and the next phase's plan.

---

## 14. Working agreements
- Ask a question only when blocked. Otherwise choose the sensible default from this brief and record the decision in `docs/DECISIONS.md`.
- Verify package versions and APIs against pub.dev and official docs. Do not invent APIs.
- Keep commits small with clear messages. Run `dart format`, `flutter analyze` and the tests before each commit.
- Write tests alongside code, not afterwards.
- Never commit secrets, keystores or real provider details. Add them to `.gitignore`.
- Do not add dependencies that are unmaintained or that phone home. Prefer fewer, well-maintained packages.
- If something in this brief is impossible or unwise on a platform, say so, explain why, and propose the closest alternative before proceeding.

Start with Phase 0. First, read `design/lumen-tv-prototype.html`, run `flutter doctor`, and give me a short plan and any questions before you scaffold.
