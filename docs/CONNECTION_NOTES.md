# Connection notes

Every provider quirk the connection layer handles, and the test that covers it.

Test files:
- **S** = `test/connection/scenarios_test.dart`: the 27 brief scenarios, run against the shelf mock provider over real loopback HTTP(S) with the real dio client.
- **E** = `test/xtream/server_endpoint_test.dart`
- **P** = `test/xtream/parsers_test.dart`
- **M** = `test/m3u/m3u_parser_test.dart`
- **N** = `test/network/network_units_test.dart`

## The 27 acceptance scenarios (brief §5.10)

| # | Behaviour | Where handled | Test | Status |
|---|---|---|---|---|
| 1 | Normal JSON, integers | `ConnectionDoctor.probe` | S1 | ✅ |
| 2 | Numbers as strings, `auth:"1"`, string `exp_date`, null `exp_date` → "No expiry" | `tolerant_json.dart` (`asInt`, `asBoolOrNull`, `asUnixTime`), `expiryLabel` | S2, P "UserInfo" | ✅ |
| 3 | BOM + whitespace; PHP warning before JSON | `decodeProviderBody` | S3, P | ✅ |
| 4 | `Content-Type: text/html` on a JSON body | Body decoded regardless of type | S4 | ✅ |
| 5 | gzip and deflate | `HttpClient.autoUncompress` (gzip) + manual zlib/raw deflate | S5 | ✅ |
| 6 | 301 http→https and https→http; new base saved | Manual redirects in `DioNetworkClient`; `ServerEndpoint.fromApiUrl` | S6 | ✅ |
| 7 | Host only: http first, then https; working one saved | `ServerEndpoint.parse` candidates | S7, E | ✅ |
| 8 | 403 unless `okhttp/*` or `VLC/*`; saved profile reused | User-agent loop; `WorkingProfile` | S8 | ✅ |
| 9 | `auth:0`; `{}` → auth_rejected (probe stops at once) | `_classifyAccount`, `AccountInfo.parse` | S9, P | ✅ |
| 10 | Expired / Banned / Disabled | `_classifyAccount` | S10 | ✅ |
| 11 | `active_cons == max_connections` → warning; refused stream → max_connections | `ProbeWarning.atConnectionLimit`, `checkStream` | S11 | ✅ connection layer. Player UI in Phase 4 |
| 12 | 60 MB `get_live_streams` after 10 s: progress, no jank, cancellable | Streaming read with progress, `parseListInIsolate`, `CancelSignal` | S12 | ✅ (main-isolate stall measured) |
| 13 | `get_live_streams` times out → per-category, ≤2 concurrent | `XtreamClient._bigList` fallback | S13 | ✅ |
| 14 | Cloudflare-style HTML → html_response (every agent tried) | `HtmlBody(cloudflare)` | S14, P | ✅ |
| 15 | Self-signed TLS → tls_error; works when allowed for that host only | `badCertificateCallback` per host | S15 | ✅ |
| 16 | Password `p@ss:w/rd?&#%+ é` in API and stream URLs | `Uri` query parameters + path segments only | S16, P "stream URLs", E | ✅ (server checks the decoded value) |
| 17 | Trailing space / newline / zero-width in credentials | `cleanCredential` (ends only) | S17, P "credentials" | ✅ |
| 18 | Full `get.php?username=&password=` pasted in server field | `ServerEndpoint.parse` | S18, E cases 28–31 | ✅ |
| 19 | `server_info.url` differs; entered host stays primary | Probe keeps entered endpoint; `ServerInfo` stored as fallback | S19 | ✅ |
| 20 | Missing fields, `false`, wrong types, duplicate ids, emoji | `xtream_parsers.dart` | S20, P "lists survive junk" | ✅ |
| 21 | Series `episodes` as map and as list; missing extension → mp4 | `parseSeriesInfo` | S21, P "series info" | ✅ |
| 22 | Live stream 302 to a tokenised URL plays | `checkStream` follows redirects | S22 | ✅ connection layer. Real playback in Phase 4 |
| 23 | Stream closes immediately → max_connections + Retry | `checkStream` (empty body, 401/403, closed) | S23 | ✅ classification. Retry button in Phase 4 |
| 24 | Network lost mid-session | Classified error; `getWithRetry` succeeds when the server returns | S24 | ✅ connection layer. Cached-catalog banner in Phase 2/3 |
| 25 | Secure storage throws → re-prompt, no crash | `SecureCredentialStore` never throws (`SecretUnavailable`) | S25, N | ✅ store. "Enter your password again" UI in Phase 3 |
| 26 | M3U: commas in attributes, `#EXTVLCOPT`, `#EXTHTTP`, CRLF, BOM, Windows-1252, 50 MB | `m3u_parser.dart`, `loadM3uLink` | S26, M | ✅ parsed with headers. Passing headers to the player in Phase 4 |
| 27 | Portal-style `/c/` URL → portal_unsupported | `looksLikePortal` + failed probe | S27, E 32–34 | ✅ |

## Other quirks handled

| Quirk | Where | Test |
|---|---|---|
| NBSP, smart quotes, wrapping quotes / `<>` | `cleanPastedAddress` | E 4, 11–14 |
| Mixed-case scheme/host; `http:/host` typo | `ServerEndpoint.parse` | E 8–10 |
| IPv4, IPv6 in brackets, IDN → punycode | `parse`, `punycode.dart` | E 15–19, N "punycode" |
| Stream URL pasted (`/live/U/P/1.ts`) → base + credentials | `parse` | E 26–27 |
| `user:pass@host` userinfo | `parse` | E 31 |
| `.m3u` link pasted into the Xtream field → M3U mode hint | `InputKind.m3uLink` | E 35 |
| Single-label LAN host only with a port | `parse` | E 36–37, 47 |
| Rejects rtmp/rtsp/udp, spaces in host, bad ports, bad IPv4 | `parse` | E 39–53 |
| Default ports only when none given; no port scanning | `parse` | E "default ports" |
| DNS failure skips the other user-agents | Probe | S extra "DNS failure" |
| 401 everywhere beats a timeout on one candidate | `ConnectionError.informativeness` | S extra, N |
| 404 at `player_api.php` → "not an Xtream address" | `classifyStatus` | S extra |
| Probe never opens a stream (saves a connection slot) | Probe | S extra |
| Probe total time bounded and cancellable | `budget`, `CancelSignal` | S extra, S12 |
| Server that accepts but never sends headers still times out | `.timeout()` guard in `DioNetworkClient` | S13 |
| Retry 0.5/1.5/4 s + jitter, `Retry-After` on 429/503, no retry on auth/TLS/DNS | `retry.dart` | N "retry policy" |
| Redaction of `username=`, `password=`, `user:pass@`, `/live/U/P/` | `Redactor` | N "redaction" |
| Diagnostics report: masked host, no credentials or stream URLs | `buildDiagnosticReport` | N "diagnostic report" |
| `get_short_epg` base64 titles; timestamps, not local strings | `parseShortEpg` | P |
| HTML entities, very long names, empty names | `asName` | P |
| Lists sent as index-keyed maps | `asList` | P |
| `exp_date` in milliseconds | `asUnixTime` | P |
| Server clock offset from `timestamp_now` | `ServerInfo.clockOffset` | P |
| M3U: name falls back to `tvg-name` then URL; `#EXTGRP`; `#KODIPROP` headers; `url|User-Agent=` headers; options before `#EXTINF` | `m3u_parser.dart` | M |
| M3U: UTF-16 with BOM | `decodePlaylistText` | — (simple path, untested) |
| M3U: playlist link returning a web page → html_response | `loadM3uLink` | — |

## Phase 2 additions (test file `test/db/catalog_sync_test.dart` = **D**, `test/db/app_state_test.dart` = **A**)

| Behaviour | Where | Test |
|---|---|---|
| Sync writes channels, movies, series, categories, search index and guide; no secrets in DB | `CatalogSync`, `sync_writers.dart` | D "Xtream sync…" |
| Saved working profile stops working → automatic re-probe, new agent saved | `CatalogSync._syncXtream` | D "saved profile stops working" |
| Refresh keeps favourites / My list / progress; stale rows removed | `syncToken` + separate user tables | D "refresh keeps…" |
| Failed refresh keeps the cached catalogue | `CatalogSync` | D "a failed refresh…" |
| Missing password → re-prompt state, provider kept (scenario 25, data half) | `SyncResult.needsPassword` | D "missing password…" |
| Expired on refresh → error, cache kept | `CatalogSync` | D "expired account…" |
| M3U link credentials replaced by placeholders in stored URLs; `url-tvg` saved | `SecretTemplate`, `writeM3u` | D "M3U link…" |
| XMLTV window, lineup filter, gzip, first title only, CDATA | `xmltv.dart` | D "guide keeps…" |
| 60 000 channels synced without stalling the UI isolate; paged reads | `computeWithDatabase` | D "60 000 channels…" |
| Network lost → banner over cached data → automatic retry on reconnect (scenario 24, data half) | `SyncController`, `offlineBannerProvider` | A "offline banner…" |
| Snapshot updates live when user data changes | `catalogSnapshotProvider` | A "first provider becomes active…" |
| Kids profile filtering | `ContentFilter`, `CatalogRepository` | A "kids profile…", D |
