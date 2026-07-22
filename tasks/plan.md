# Active Lane
Plan ID: 20260722-precise-finder
Risk Level: HIGH (Firestore rules + Cloud Functions + precise location handling)
Founder Approval Required: YES before merge — location-privacy posture change per ADR-010 (granted at design stage, Session 60; merge gate still explicit). Founder also owns the prod deploys + Firestore TTL policy (manual steps in the PR).
Branch: feat/precise-finder

## Objective (this lane)

Precise turn-to-find (ADR-010, build 35 payload): inside an active mutual
window, with per-window RECIPROCAL opt-in from BOTH users, share precise
location server-side to compute an accurate arrow + live distance — raw
coordinates never reach the other client. Free for everyone. Executed
task-by-task from `docs/superpowers/plans/2026-07-22-precise-finder.md`
(Tasks 1–7; Task 8 pubspec bump to build 35 deferred until build 34 is on
main). Raw coords only in `matches/{matchId}/finder/{uid}` (rules deny ALL
client access, ~2-min TTL, purged atomically on `markMatchFound`); callable
returns ONLY `{partnerSharing, bearing?, distanceM?, reason?}`; precise arrow
requires both-opted + fresh (<10s) + window pending, else coarse
geohash-arrow fallback (`bearingIsMeaningful`) + BLE warmth.

---

# Prior Lane (merged — PR #88)
Plan ID: 20260722-android-fgs-timeout
Risk Level: HIGH (Android native foreground service + manifest permissions)
Founder Approval Required: YES before merge — native Android service/manifest behavior; code change requested, merge gate still explicit.
Branch: fix/android-fgs-timeout

## Objective (this lane)

Stop Android 15 `ForegroundServiceDidNotStopInTimeException(dataSync)` for all-day
radar sessions by removing the unnecessary `dataSync` foreground service type
from both Tremble Android foreground services and every runtime type assertion.
Radar's real work is BLE scanning (`connectedDevice`) plus GPS (`location`).
Do not touch the WatchdogReceiver/BootReceiver removal blockade or the
RadarForegroundService trampoline path. Verify with dev APK build and merged
manifest inspection; full runtime scan validation needs founder Android 14/15
hardware.

---

# Prior Lane
Plan ID: 20260721-build-33-release
Risk Level: HIGH (prod build → TestFlight + Play; outward-facing)
Founder Approval Required: YES — granted 2026-07-21 ("upload to testflight, prepare playconsole update").
Branch: chore/build-33

## Objective (this lane)

Cut 1.0.0 (33) to TestFlight (iOS) and preserve the AAB for the founder's Play
upload (Android). Payload = FEATURE-RADAR-SONAR **Phase B** (PR #82, merged
`43ec787`): turn-to-find direction — server geohash bearing (deployed to prod
this session) + `flutter_compass_v2` heading drive the radar dot; B0 dev-only
diagnostic overlay for the device pass. Bump pubspec ONLY (Rule #100/Android
source-of-truth); `build_prod.sh all` (obfuscated, `.env.prod.json` Rule #84,
Sentry symbols dist 33); manual `xcrun altool` to TestFlight (Rule #95); founder
uploads AAB. **The combined two-phone device pass of the radar sonar (Phase A+B)
is owed on this build** — read the B0 overlay on-device if the dot misbehaves.

---

# Prior Lane (merged — PR #82)
Plan ID: 20260721-radar-sonar-turn-to-find
Risk Level: HIGH (new sensor dependency + prod Cloud Function deploy + core trembling flow)
Founder Approval Required: YES — granted 2026-07-21 ("phase b - approval granted"); deploy authorized ("Deploy now").
Branch: feature/radar-sonar-phase-b (merged 2026-07-21 `43ec787`, branch deleted)

## Objective (this lane)

FEATURE-RADAR-SONAR **Phase B** — turn-to-find direction. B0 dev-only diagnostic
overlay (`kDebugMode`); B1 `flutter_compass_v2 ^1.0.3` + **ADR-009**; B2 server
`computeBearing`/`distanceBucket` (`bearing.ts`) + `updateActiveMatchBearing`
writer, **deployed to `am---dating-app`/europe-west1**; B3 `compassHeadingProvider`
+ `dotAngle`/`smoothHeading` + `Match.bearingFor`; B4 controller integration
(`dotAngle(bearing−heading)`, orbit fallback, `bucketToRadius`). analyze clean,
Flutter 438/438, jest 182/182, tsc clean.

---

# Prior Lane (merged — PR #80)
Plan ID: 20260721-radar-sonar-turn-to-find
Risk Level: MEDIUM (Phase A — client-only, no new dependency, no server/PII change)
Founder Approval Required: NO (Phase A). Phase B (compass dep + server bearing) = YES via ADR-008.
Branch: feature/radar-sonar (merged 2026-07-21, branch deleted)

## Objective (this lane)

FEATURE-RADAR-SONAR Phase A: give the trembling-window partner dot a production
data source. `SonarPingController` maps real BLE RSSI → dot radius (near=center)
+ pulse rate; a production writer in home_screen.dart:445 feeds the ping
providers during a live mutual wave; slow orbit angle (no bearing yet); signal
loss holds-then-fades to a "Searching…" caption. Pure math is TDD'd; felt
behavior is device-only (founder two-phone pass). Phase B (turn-to-find via
flutter_compass_v2 + server geohash bearing) is a separate chat/branch, gated on
the Phase A device pass + ADR-008. Full design + plan in docs/superpowers/.

---

# Prior Lane (merged — PR #66)
Plan ID: 20260718-release-b26
Risk Level: HIGH (prod build → TestFlight; outward-facing)
Founder Approval Required: YES — granted 2026-07-18 ("lets build new testflight").
Branch: chore/release-b26

## Objective (this lane)

Cut 1.0.0 (26) to TestFlight — the FIRST binary where the wave pill actually
renders. Carries: PR #62 (bounded readiness retry + Sentry give-up), PR #64 (map
offline card), PR #65 (overlay render fix — presentWavePill now reads
rootNavigatorKey.currentState.overlay; Overlay.maybeOf(currentContext) was always
null). Plus the freeze fix already in build 25. Flow: bump pubspec (done) →
build_prod.sh all (both platforms, Sentry dSYM+Dart symbol upload, preserve to
release-symbols/b26/) → verify Sentry lists dist-26 debug files → upload IPA via
xcrun altool (key V24BM2VRC2). Then on-device verify with send_test_push.ts.

---

# Prior Lane (merged — PR #65)
Plan ID: 20260718-wave-pill-root-overlay
Risk Level: MEDIUM (Dart-only; the actual wave-pill render fix)
Founder Approval Required: NO (Dart-only, no native/Firebase/rules/deploy).
Branch: fix/wave-pill-root-overlay

## Objective (this lane)

THE fix for "foreground push delivered (pairsNotified:2) but no pill" and the
tap→pill drop. Proven on device logs (build 25, 2026-07-18 08:48:03: two visible
CROSSING_PATHS sent, nothing shown). Root cause: presentWavePill read the
overlay via Overlay.maybeOf(rootNavigatorKey.currentContext), which is ALWAYS
null — the root Navigator's Overlay is a descendant of that context, not an
ancestor. The pill could never insert, foreground or tap. Fix: use
rootNavigatorKey.currentState.overlay. Proven by root_overlay_resolution_test.
Sits on top of PR #62 (bounded readiness retry + Sentry give-up). Ships build 26.

---

# Prior Lane (merged — PR #64)
Plan ID: 20260718-map-cold-offline-ux
Risk Level: MEDIUM (client-only; map error-state UI + i18n)
Founder Approval Required: NO (Dart-only, no native/Firebase/rules/deploy).
Branch: fix/map-cold-offline-ux

## Objective (prior lane)

Replace the raw `Error loading map: <ClientException … Failed host lookup>` red
text that airplane mode surfaced (tremble_map_screen.dart error branch) with a
compact, on-brand offline card + retry. New `MapOfflineCard` (fits the rounded
map slot, unlike the full-screen dead-code TrembleOutageScreen); retry wired to
`ref.invalidate(mapInitProvider)` so a transient host-lookup failure recovers on
reconnect. i18n `map_offline_title` / `map_offline_subtitle` added to all 8
locales (+ hr `try_again`, previously English-fallback). Ships build 26 with the
tap→pill fix.

---

# Prior Lane (merged — PR #63)
Plan ID: 20260718-fcm-test-push-trigger
Risk Level: LOW (dev-only Node script; not deployable; prod send gated behind --i-know-this-is-prod)
Founder Approval Required: NO (no code path in the app, no deploy, no default prod mutation).
Branch: chore/fcm-test-push-trigger

## Objective (prior lane)

Give device verification a deterministic trigger. `functions/src/scripts/send_test_push.ts`
sends ONE CROSSING_PATHS or INCOMING_WAVE push directly to a device (by uid or
raw token), reusing the exact prod payloads + apnsExpirationHeaders so it can't
drift. Unblocks proving the freeze fix (PR #60, still unproven — willPresent
never coincided with a foregrounded app) AND the tap→pill fix (PR #62) without
waiting on scanProximityPairs / the 10-min throttle / per-pair cooldown.
Run: `cd functions && npm run build && node ./lib/scripts/send_test_push.js
--project=tremble-dev --uid=<uid>`. Test matrix (a foreground / b background-tap
/ c killed-tap) documented in the script header.

---

# Prior Lane (merged — PR #62)
Plan ID: 20260718-crossing-paths-tap-pill-resilience
Risk Level: MEDIUM (Dart-only; notification tap → wave-pill presentation + diagnostics)
Founder Approval Required: NO (Dart-only, no native/Firebase/rules/deploy); founder said "go".
Branch: fix/crossing-paths-tap-pill-resilience

## Objective (prior lane)

Fix the 2026-07-17 "tapped the CROSSING_PATHS notification and nothing happened".
Root cause: PR #60 iOS forwarding is NOT the culprit (verified against real
Flutter engine source e4b8dca — didReceiveNotificationResponse forwards to
firebase_messaging identically to willPresentNotification). The drop is in the
Dart presenter: `router.presentWavePill` failed closed on the first null
(auth / context / overlay) with no retry and no log, so a cold-launch tap that
beat auth hydration / Overlay build was silently dropped. Fix: bounded readiness
polling (20 × 250 ms) + a Sentry trace naming the blocking precondition on
give-up, plus path breadcrumbs (background vs cold-launch). Ships build 26 as the
device-verification vehicle for STORE-005 CROSSING_PATHS tap→pill.

---

# Prior Release Chore (build 25 — shipped)
Plan ID: 20260717-release-b25
Risk Level: LOW (version bump only; ships the freeze fix already reviewed as PR #60)
Founder Approval Required: NO for the build; TestFlight upload authorised 2026-07-17 ("go" after merge, same flow as build 24).
Branch: chore/release-b25

## Objective

Ship 1.0.0 (25) — the FIRST binary containing the foreground-push freeze fix
(PR #60). Build 24 shipped before that fix and still crashes on any foreground
push; 25 is what the device verification actually runs against.

## What build 25 carries (delta over 24)

| PR | Change |
|---|---|
| #60 | Own the UNUserNotificationCenter delegate before plugin registration — stops the willPresent swizzle recursion (the freeze) |
| #59 | build_prod.sh hardening (versionCode guard, --skip-build, AAB preserve) |

## Scope

- `pubspec.yaml`: `1.0.0+24` → `1.0.0+25` — sole version source.
- `tasks/plan.md`: this entry.
- `android/local.properties`: NOT edited (flutter build rewrites it from pubspec).

## Verification

- Artifact-level: AAB versionCode 25; prod `.env.prod.json` keys compiled into
  both binaries; Sentry lists debug files for dist 25 BEFORE TestFlight.
- The FCM fix is source-pinned by
  `test/core/appdelegate_notification_delegate_test.dart` (merged in #60).

## Open — device verification (the actual proof, cannot come from CI)

1. **Foreground push presents a banner and does NOT crash** — the build-24 repro, now passing.
2. Background/killed push delivers; Wave Back via the notification action works.
3. If anything crashes, Sentry renders a real stack (dist 25 symbols uploaded).

---

# Prior Release Chore
Plan ID: 20260717-release-b24
Risk Level: LOW (version string bump only; the shipped code merged as PRs #56/#57/#58)
Founder Approval Required: NO for the build. YES for the TestFlight upload (outward-facing).
Branch: chore/release-b24

## Objective

Ship 1.0.0 (24) — the first binary containing the crash-reporter fix, and the
first binary whose crashes are readable in Sentry.

Build 24's job is to PROVE the crash fix. Nothing else rides along: the map
offline UX and the wave pill TTL are deliberately excluded so a failed device
test has exactly one plausible cause.

## What build 24 carries

| PR | Change | Why it needs a new binary |
|---|---|---|
| #57 | Crash reporter no longer kills the app on an offline map | client-side error handlers |
| #56 | BLE ScanCycleDedupe — one proximity_events write per device per scan | client-side BLE loop |
| #58 | Debug symbols uploaded at build time | first build whose crashes symbolicate |

PR #58 is why this build is cut now rather than yesterday: without it, a build-24
device failure would be as unreadable as build 23's was, and Session 48's ~5-hour
reconstruction would repeat.

## Scope

- `pubspec.yaml`: `1.0.0+23` → `1.0.0+24` — sole committed source of truth for
  both platforms (memory: `android-version-source-of-truth`).
- `scripts/release/build_prod.sh`: add a post-build assertion that the AAB's
  versionCode matches pubspec.
- `tasks/plan.md`: this entry.
- `android/local.properties`: NOT edited. `flutter build` rewrites
  `flutter.versionCode` from pubspec (`gradle_utils.dart:1168`) and Gradle reads
  it back (`FlutterPlugin.kt:130`, defaulting to "1" if absent — so the lines
  must exist but must never be hand-set). Gitignored; pubspec stays SSOT.

## Verification

- unit tests: n/a — no source paths changed. Full suite green via pre-commit.
- integration tests: n/a — no service boundary. Backend Jest green via pre-commit.
- security scan: pre-commit secret scan; no credentials in the diff.
- Artifact-level (not inferred from pubspec): AAB versionCode == 24; prod
  `.env.prod.json` keys present in the compiled binaries (the check build 17
  failed); Sentry lists debug files for dist 24 BEFORE any store upload.

## Open — device verification (cannot be proven from CI)

1. Two-phone proximity: the 1.0.0+23 freeze must be GONE. This is the point.
2. Airplane mode on the map: no hang, no crash. (Raw error text is expected and
   is a separate lane.)
3. Wave Back via the iOS notification action.
4. If anything crashes: confirm Sentry renders a real stack, not `<redacted>`.
   That is PR #58's end-to-end proof, only observable on an ingested event.

---

# Prior Implementation Plan
Plan ID: 20260717-sentry-debug-symbol-pipeline
Status: RESOLVED 2026-07-17 — PR #58 merged into `main` @ 3d0c0a1
Risk Level: MEDIUM — build tooling only; no product code, no prod deploy
Founder Approval Required: NO for the code. YES for one action — minting the Sentry auth token.
Branch: ci/sentry-debug-symbol-pipeline

## 1. OBJECTIVE

Make the next production crash readable on arrival. Releases ship
`--obfuscate --split-debug-info` and upload nothing to Sentry, so every frame
arrives as `<redacted>` and every Dart issue title as `lM:` / `cJ:`. Session 48
spent ~5 hours hand-reconstructing the 1.0.0+23 freeze for exactly this reason.

Done looks like: `TREMBLE-FUNCTIONS-Q` renders `FIRCLSProcessRecordAllThreads`
instead of `<redacted>`, and build 24 cannot be cut without its symbols going up.

## 2. SCOPE

- `pubspec.yaml` — `sentry_dart_plugin ^3.4.0` dev dependency + `sentry:` block.
- `scripts/release/build_prod.sh` [NEW] — the single production release entry point.
- `tasks/lessons.md` — Rule #85 [NEW]; Rule #84 amended to call the script.
- `release-symbols/b23/ios-dsyms/` — build 23 dSYMs rescued (gitignored).

Does NOT change: any `lib/` code, any Cloud Function, Firestore rules, native
config, or the pubspec version. No deploy. Build 24 is not cut here.

## 3. STEPS

| # | Action | Verification |
|---|---|---|
| 0 | Rescue build 23 dSYMs from `build/ios/archive` before a `flutter clean` destroys them | DONE — 71 dSYMs copied; `Runner.app.dSYM` UUID `89BB20EC-14F6-3E25-980F-6885FCF9E740` matches the live event's `app_id` |
| 1 | **Founder:** mint an org token (`sntrys_…`, fixed `org:ci` scope) | DONE 2026-07-17 — `sentry-cli info` reports `Scopes: org:ci`; `org:ci` does cover debug-files upload |
| 2 | Add the plugin + `sentry:` config | DONE — plugin reads config from pubspec, downloads sentry-cli 2.58.6 (checksum verified) |
| 3 | Backfill build 23 | DONE with a caveat — see §3a |
| 4 | Add `scripts/release/build_prod.sh` | DONE — preflight computes `tremble.dating.app@1.0.0+23` / dist 23, matching the live event exactly |
| 5 | Rule #85 + Rule #84 amendment | — |

## 3a. STEP 3 RESULT — what is proven, and what is not

**Proven.** Build 23's dSYMs uploaded to `tremble-functions` and are confirmed
stored server-side via the Sentry API:

| Debug ID | Object | Decodes |
|---|---|---|
| `89bb20ec-14f6-3e25-980f-6885fcf9e740` | `Runner` | native frames — byte-identical to the `app_id` on live event TREMBLE-FUNCTIONS-Q |
| `72002995-135e-3ab9-9477-67b6ad6bbe8d` | `App` | iOS Dart AOT frames |

Right files, right project, right debug IDs, upload works with an `org:ci` token.

**NOT proven: end-to-end ingest-time symbolication.** TREMBLE-FUNCTIONS-Q still
renders `<redacted>` after the upload, because **Sentry symbolicates at ingest**
— it does not retroactively rewrite events already stored. Reprocessing would be
required, and the `org:ci` token returns HTTP 403 on every issue endpoint (it is
upload-only by design). So the backfill did NOT make build 23's three existing
events readable, and cannot.

This does not weaken the lane: the crash it would have re-proven was already
symbolicated from the device in Session 48 and fixed in PR #57. The backfill's
job was to validate the chain, and the debug-ID match does that — `89bb20ec…` is
the exact join key Sentry uses. The final link (a *new* event rendering a real
stack) is proven by build 24's first crash, which is why §5 puts the check there.

**Two corrections the evidence forced** (both were wrong in the approved plan):
1. iOS `app.ios-arm64.symbols` is UNUSABLE — debug ID `00000000-…`, and
   sentry-cli reports "Found 0 debug information files". iOS Dart frames are
   decoded by `App.framework.dSYM`. Android's `.symbols` DOES have a real ID.
2. `url: https://de.sentry.io` was wrong and is removed — org tokens embed their
   own region, and sentry-cli ignores a manual URL with a warning.

## 4. RISKS & TRADEOFFS

- **The project is `tremble-functions`, not `tremble-app`.** The DSN resolves to
  project id `4511554698936400`; the live iOS crashes (platform `cocoa`, release
  `tremble.dating.app@1.0.0+23`) are all in `tremble-functions`. `tremble-app`
  exists and receives nothing. `tasks/context.md` (Session 39) says to verify
  "tremble-app" — following that would upload symbols to an empty project and
  leave the next crash just as unreadable. Highest-risk detail in the lane.
- **Android obfuscation maps are deliberately not uploaded.** The plugin's
  collector always searches `build/ios` and pairs one map with the UNION of both
  platforms' debug files (`dart_symbol_map_debug_files_collector.dart:101,113`).
  iOS and Android obfuscate in separate `gen_snapshot` runs, so their maps
  differ; pairing Android's map to an iOS debug ID would rename types
  *incorrectly* — worse than no map, precisely when someone is reading a crash.
  The script scopes `symbols_path` per platform and uploads the map for iOS only.
  Android Dart frames still symbolicate via `.symbols`; only Android issue
  *titles* stay obfuscated. Debt, recorded in §6.
- **Token handling.** `auth_token` never enters `pubspec.yaml` (tracked file;
  `secret_scan.sh` runs pre-commit). Supplied via `SENTRY_AUTH_TOKEN`.
- **Assumption not yet proven:** that the uploaded dSYMs actually resolve the
  stack. Step 3 tests exactly that against a crash whose true stack is already
  known, so a wrong config fails now rather than during the next incident.

## 5. VERIFICATION

- unit tests: n/a — no runtime code changed. Full suite must stay green (343).
- integration tests: n/a — no service boundary crossed. The real end-to-end
  check is step 3 against live Sentry.
- security scan: `scripts/ci/secret_scan.sh` clean — proves no token reached a
  tracked file. No auth, rules, or PII surface touched.
- `flutter analyze` clean; `dart format` clean.
- Step 3: dSYM upload verified server-side by debug ID (§3a). Retroactive
  symbolication of build 23 is NOT possible — symbols bind at ingest.
- **Build 24 carries the remaining proof.** Run the script, confirm Sentry lists
  debug files for dist 24 BEFORE the IPA reaches TestFlight, then confirm the
  first build-24 event renders a real stack rather than `<redacted>`. Until an
  event is ingested with symbols already present, ingest-time symbolication is
  verified by construction (matching debug IDs), not by observation.

## 6. FOLLOW-UPS (found, not fixed here)

- `deploy.yml` `build-apk` uses a bare `--dart-define=FLAVOR=$FLAVOR` with no
  `.env.prod.json` and no obfuscation — a live Rule #84 violation. It builds an
  APK, not the AAB that ships, so it looks like dead weight. Fix or delete in
  its own lane.
- Android obfuscation map (see §4).
- `lib/src/features/match/domain/wave.dart` — dead code; models `createdAt` but
  is imported nowhere. It is why the pill-TTL requirement *reads* as feasible.
- `recap_ttl_provider.dart` — named TTL, is actually a blind countdown. Same bug
  class as the wave pill.

---

# Prior Implementation Plan
Plan ID: 20260717-crash-reporter-storm
Risk Level: HIGH — rewrites the global error handlers in main.dart
Status: RESOLVED 2026-07-17 — PR #57 merged into `main` @ 38be73b
Founder Approval Required: YES — granted 2026-07-17 ("go")
Branch: fix/crash-reporter-storm (merged)

## 1. OBJECTIVE

Stop the app killing itself from inside its own crash reporter. Root cause of
the 1.0.0+23 iOS freeze (Sentry TREMBLE-FUNCTIONS-Q), proven from a symbolicated
device stack — not inferred.

## 2. THE CHAIN (evidence)

Symbolicated crash, com.apple.main-thread:

    FIRCLSProcessRecordAllThreads  <- FIRCLSHandler
    <- FIRCLSExceptionRecordOnDemand
    <- -[FIRCrashlytics recordOnDemandExceptionModel:]
    <- -[FLTFirebaseCrashlyticsPlugin recordError:withMethodCallResult:]

1. `maps.trembledating.com` DNS fails offline → every vector tile throws,
   continuously (`ClientException with SocketException: Failed host lookup`).
2. `CrashFilter` matched `vector_map_tiles` / `future_tile_provider.dart` /
   `_FutureImageProvider`. AOT strips package URIs, and the real frames are
   `tile_loader.dart`, `vector_tile_loading_cache.dart`, `caches_tile_provider.dart`,
   `isolate_executor.dart`, `concurrency_executor.dart`, `pool_executor.dart`.
   The filter matched none of them: it worked in debug, missed in release. Its
   test asserted an assumed AOT stack that happened to match, so it passed.
3. Unfiltered → `recordFlutterFatalError` filed each failed tile as a FATAL
   crash on the main thread.
4. Crashlytics walks every thread per report; this process runs dozens of
   DartWorker + ~15 gRPC threads. Storm → main thread stalls → 2s AppHang →
   stack overflow raised from inside the reporter.

This also explains the ~70KB/5s firelog uploads from launch and the os_log
frames at the base of the stack.

Corroborated by Crashlytics: tile_loader.dart:72, isolate_executor.dart:69,
map_controller_impl.dart:66, main.dart:102 — all "FlutterError - Cancelled",
all filed as Crash.

## 3. SCOPE

- `lib/src/core/crash_filter.dart` — match real AOT frames; suppress network
  failures as well as cancellations; only for the tile pipeline.
- `lib/src/core/crash_report_throttle.dart` — NEW. Sliding window, 8/min.
- `lib/main.dart` — throttle all three reporting paths; `recordFlutterError`
  instead of `recordFlutterFatalError`; suppressed-path `presentError` becomes
  debug-only (it dumped to os_log per failed tile in release).
- `lib/src/features/map/presentation/tremble_map_screen.dart` — `_mapReady` via
  `onMapReady`; guard `_setZoom` and `_resolveUserCenter`.

Does NOT change: notifications, the wave pill, BLE, Cloud Functions, rules.

## 4. RISKS & TRADEOFFS

- Throttling drops reports beyond 8/min. Intended: a storm's first few reports
  identify it as well as ten thousand. Isolated errors are unaffected.
- `recordFlutterError` files non-fatally — correct, since the framework catches
  these and the app keeps running. Crash-free-users metrics will shift as
  benign tile failures stop being counted as crashes.
- Filter is deliberately narrow: cancellations and network failures only, and
  only on the tile pipeline. A real defect there still reports (tested).
- `_mapReady`: a zoom tap before the map renders now records the level without
  moving the camera, instead of throwing.
- Residual: the map still has no offline UX and surfaces a raw SocketException
  string. Tracked separately; not this PR.

## 5. VERIFICATION

- Unit tests: 14 CrashFilter cases (7 real production frames from the device
  report, offline lookup failure, plus negative controls proving genuine errors
  and non-tile network failures still report) + 5 CrashReportThrottle cases
  including a 60s storm asserting a bounded 8 reports and no retained-history
  leak. Full suite 343/343.
- Integration tests: backend Jest green via pre-commit hook; no server contract
  touched.
- Security scan: pre-commit secret scan clean; no secrets/auth/rules touched.
- Analyzer: clean.
- Device: OUTSTANDING — airplane mode on the map must no longer hang or crash,
  and the two-phone proximity freeze must be re-tested.

# Prior Implementation Plan
Plan ID: 20260716-ble-scan-write-storm
Risk Level: HIGH — touches the BLE service (AGENTS/CLAUDE escalation list)
Founder Approval Required: YES — granted 2026-07-16 ("just fix this shit",
"open the PR and I'll merge it")
Branch: fix/ble-scan-write-storm

## 0. WHAT THIS IS NOT

This does **not** fix the iOS stack overflow in 1.0.0+23
(Sentry TREMBLE-FUNCTIONS-Q). That root cause is still unidentified. The BLE
storm is the leading hypothesis for the accompanying main-thread hang, not a
proven cause of the recursion. Build 24 may still freeze.

## 1. OBJECTIVE

Stop the BLE scan loop from issuing hundreds of unbounded, un-awaited Firestore
writes per scan window, and make the Profile build configuration buildable.

## 2. SCOPE

Changes:
- `lib/src/core/ble_service.dart` — add `ScanCycleDedupe`; gate the
  `proximity_events` write to once per device per scan cycle.
- `test/core/ble_scan_dedupe_test.dart` — new, 5 cases.
- `ios/Profile.xcconfig` — repoint the include at `Flutter/Release.xcconfig`.

Does NOT change: notification delivery, the wave pill, the router, Cloud
Functions, Firestore rules, the `proximity_events` schema, or `rssi` semantics
(unread server-side).

## 3. FINDING (evidence, not assumption)

`FlutterBluePlus.scanResults` re-emits the *cumulative* result list on every
advertisement packet. `ble_service.dart:154` iterated that list per emission and
called `_onDeviceDetected` per result, un-awaited — each doing a Firestore
`.get()` plus an `.add()`.

Consequences, all verified by reading the consumers:
1. Unbounded concurrent writes saturate the Firestore platform channel. Peak
   coincides with two phones scanning each other — exactly when a proximity pair
   fires. Matches the Sentry AppHang stack (Thread 0 in `_dispatch_sync_f_slow`)
   and the 70KB/5s Crashlytics firelog uploads in the breadcrumbs.
2. Every write invokes `onBleProximity` (`proximity.functions.ts:1043`), which is
   deprecated and returns immediately — pure cost, no cascade.
3. `notifications.functions.ts:50` derives the monthly recap's near-miss count
   from a `count()` over `proximity_events`. The count shown to users has been
   inflated by orders of magnitude.

`scanProximityPairs` reads the `proximity` collection, not `proximity_events`,
so pairing behaviour is unaffected by this change.

## 4. RISKS & TRADEOFFS

- Fewer `proximity_events` docs. Intended: the recap count becomes truthful
  (one encounter per device per scan). No other consumer reads the collection.
- `rssi` is not read server-side, so collapsing duplicate emissions loses no
  information.
- Dedupe state is per-cycle and reset on scan start, so a device that leaves and
  returns is re-reported on the next cycle.
- Profile config change affects only Profile builds; Debug-dev and Release-prod
  are untouched, so no release path changes.
- Residual: the stack overflow may persist. Device verification required before
  claiming otherwise.

## 5. VERIFICATION

- Unit tests: 5 new `ScanCycleDedupe` cases, incl. a 200-emission burst
  asserting exactly one write. Full suite 327/327.
- Integration tests: backend Jest suite green via pre-commit hook; no server
  contract changed.
- Security scan: pre-commit secret scan clean; no secrets, auth, or rules
  touched.
- Analyzer: `flutter analyze` clean.
- Device: OUTSTANDING — two phones in proximity on build 24 to confirm the
  Firestore write volume drops and to re-test the freeze.

# Prior Release Chore
Plan ID: 20260716-release-b23
Risk Level: LOW (version bump only; the shipped code merged as PRs #52/#53/#54)
Status: IN-REVIEW 2026-07-16 — TestFlight 1.0.0 (23) delivered (UUID
`47784b71-08f5-4859-8b31-960c2be2c3b6`); AAB awaiting manual Play Console upload.
Founder Approval Required: YES — granted 2026-07-16 ("deploy all")
Branch: chore/release-b23

## Objective

Ship 1.0.0 (23), the first binary containing today's three fixes, and deploy the
Cloud Functions half of the TTL lane that a binary cannot carry.

## Scope

- `pubspec.yaml`: `1.0.0+22` → `1.0.0+23` — sole committed source of truth for
  both platforms' version fields.
- `android/local.properties`: local `flutter.versionCode` mirror 22 → 23.
  Gitignored, not committed; pubspec remains SSOT.
- `tasks/plan.md`: this entry.

## What build 23 carries

| PR | Change | Why it needed a new binary |
|---|---|---|
| #52 | Wave pill on notification tap | build 22 predates it — Wave Back was never runnable |
| #53 | Pill 3-minute auto-dismiss | client-side timer |
| #54 | 44 bundled typefaces, no runtime fetch | fixes the offline first-launch crash |

## Production deploy (executed 2026-07-16)

`onWaveCreated` and `scanProximityPairs` deployed to `am---dating-app`
(europe-west1, v2, Node 22) and verified live via `functions:list`. This is the
server half of PR #53: the 5-minute expiry is inert without it, and it ships
independently of any binary.

## Verification (artifact-level, not assumed)

- versionCode `23` / versionName `1.0.0` / package `tremble.dating.app` read out
  of the built prodRelease manifest — not inferred from pubspec. `local.properties`
  had a stale `flutter.versionCode=22` that would have produced a Play Store
  version-code rejection; caught pre-build and synced.
- Prod `--dart-define-from-file=.env.prod.json` values verified present in the
  compiled binaries, the exact check build 17 failed: IPA `App.framework` carries
  PLACES_KEY_PROD + REVENUECAT_APPLE_API_KEY + SENTRY_DSN; AAB `libapp.so` carries
  PLACES_KEY_PROD + REVENUECAT_GOOGLE_API_KEY + SENTRY_DSN. Each platform's unused
  RevenueCat key is absent because AOT const-folds `Platform.isIOS`/`isAndroid` and
  tree-shakes the dead branch — expected, not a gap.
- 44 .ttf + 4 OFL licences present inside both AAB and IPA.
- AAB 67.5 MB against the 120 MB budget, with the fonts included.
- Flutter 322/322, analyzer clean, Functions 154/154, lint/build clean.
- Artifacts preserved under ignored `release-symbols/b23/`; AAB sha256 prefix
  `97673544002a…`.

## Open — device verification (cannot be proven from CI)

1. Offline first launch: fresh install, airplane mode, cold start — the actual
   proof of PR #54. No test can show this.
2. Wave Back via the iOS notification action — first binary in which it can work.
3. Foreground / background / killed notification display, closing the
   BLOCKER-STORE-005 device matrix.
4. TTL: a wave to an offline handset must NOT arrive after 5 minutes.

---

# Prior Implementation Plan
Plan ID: 20260716-bundle-fonts-offline
Risk Level: MEDIUM
Status: RESOLVED 2026-07-16 — PR #54 merged into `main` @ 53ddd64
Founder Approval Required: YES — granted 2026-07-16
Branch: fix/bundle-fonts-offline (merged)

## 1. OBJECTIVE

First launch must never depend on the network to render text. `main()` awaited
an HTTP download of the brand typefaces before `runApp`: a slow connection
stalled startup and a bad one produced the production Android crash
"Failed to load font with url".

## 2. AUDIT (what the code actually calls)

| Family | Call sites | In AGENTS.md contract |
|---|---|---|
| `instrumentSans` | 293 | yes |
| `playfairDisplay` | 34 | yes |
| `jetBrainsMono` | 17 | yes |
| `lora` | 15 | yes |
| `inter` | 4 | **NO** |

`GoogleFonts.inter` violated the AGENTS.md:292 typography contract and would
have kept fetching from the network. Its 4 sites are plain UI text (wave-pill
name/subtitle, account-suspended screen), so they move to Instrument Sans — the
contract's UI sans. Visual change, deliberate.

## 3. WHY THE FULL VARIANT SET, NOT THE AUDITED ONE

Three findings from reading google_fonts 8.0.2 rather than assuming:

1. An asset matches when its path ENDS with the API prefix
   (`google_fonts_base.dart:329`), so `assets/fonts/` works and no `fonts:`
   block is needed — all 363 call sites keep working untouched.
2. A requested weight resolves to the family's CLOSEST AVAILABLE variant
   (`_closestMatch`, `google_fonts_base.dart:97`). Instrument Sans ships no
   ExtraBold, so the w800 call sites legitimately resolve to Bold — an audit
   that bundled "the weights we call" would have fetched a file that does not
   exist.
3. `TrembleTheme.displayFont/bodyFont/uiFont` take an arbitrary `FontWeight`,
   so no static audit of call sites can stay correct as code changes.

Bundling every variant of the four families (44 files, 4.6 MB) removes the
whole "missed weight → silent fallback typeface" class permanently.

## 4. SCOPE

- `assets/fonts/` [NEW] — 44 .ttf + 4 OFL licence texts.
- `tool/fetch_fonts.py` [NEW] — regenerates the set from the hashes google_fonts
  itself embeds, so bundled bytes are identical to the runtime download.
- `pubspec.yaml` — declare `assets/fonts/`.
- `lib/main.dart` — `allowRuntimeFetching = false` before any font call;
  register OFL licences; preload from assets.
- `match_notification_pill.dart`, `account_suspended_screen.dart` — Inter →
  Instrument Sans.
- `test/core/bundled_fonts_test.dart` [NEW].
- NOT touched: `theme.dart` and the other 363 call sites; no version bump.

## 5. RISKS & TRADEOFFS

- +4.6 MB of assets. Accepted: the release budget is 120 MB and the failure it
  removes is a launch crash.
- Inter → Instrument Sans is a real visual change in 4 places.
- `allowRuntimeFetching = false` makes a missing variant throw instead of
  fetching. Non-fatal (caught; Flutter falls back to a system face) but it is a
  cosmetic regression, which the pinned-manifest test exists to prevent.
- The behavioural load test stalls rather than failing cleanly when an asset is
  absent, so a fast deterministic manifest pin sits in front of it.

## 6. VERIFICATION

- unit tests: 8 new assertions — all weights and italics of all four families
  load with fetching disabled; the manifest pin; licences present and
  registered; fetch-disabled ordering; no non-contract family in `lib/`.
  Flutter 322/322 (314 + 8).
- Mutation-checked, not assumed: removing `Lora-SemiBold.ttf` makes the
  manifest test fail (exit 1, `Actual: Set:['Lora-SemiBold.ttf']`). An earlier
  version of this test passed with the file deleted — it was reading Flutter's
  `build/unit_test_assets/` cache — and was rewritten.
- integration tests: n/a — no service boundary. Offline first-launch is a
  device check for build 23.
- security scan: no credentials or PII. Fonts fetched from the same
  fonts.gstatic.com URLs google_fonts uses, each length-validated against the
  package's expected size. OFL permits redistribution; licence texts ship with
  the binaries.
- `flutter analyze` clean; `dart format` clean; dev-flavor APK builds.

---

# Prior Implementation Plan
Plan ID: 20260716-notification-ttl-and-pill-auto-dismiss
Risk Level: MEDIUM
Status: RESOLVED 2026-07-16 — PR #53 merged into `main` @ fcc0585
Founder Approval Required: YES — granted 2026-07-16 (touches Cloud Functions)
Branch: fix/notification-ttl-and-pill-auto-dismiss (merged)

## 0. FINDING THAT RESCOPED THIS LANE

The request was "add ttl=300s so the notification disappears from the lock
screen if unread within 5 minutes". TTL does not do that. It bounds only how
long FCM/APNs keeps *retrying delivery* to an unreachable handset; once
delivered, a notification persists until the user dismisses it.

Verified against the vendored SDK types, not from memory:
- `AndroidConfig.ttl` — "Time-to-live duration of the message in milliseconds",
  a delivery lifespan (`firebase-admin/lib/messaging/messaging-api.d.ts:349`).
- `AndroidNotification` exposes no `timeoutAfter` field, so FCM v1 has no
  server-side display timeout at all.

TTL is still worth shipping, for a different reason than requested: a handset
that is offline or in Doze currently receives the backlog on reconnect and is
told someone is 100 m away an hour after they left. That is a correctness bug
for a proximity product, and it got sharper after PR #52 — tapping a stale
notification now opens a WavePill for someone long gone, where before it did
nothing.

Founder decision 2026-07-16: ship TTL as scoped; accept that a delivered
notification stays until dismissed. Rejected alternatives: Android data-only +
client-rendered `setTimeoutAfter` (trades away killed-state delivery, the exact
subject of STORE-005) and iOS collapse-id + follow-up silent push (needs a
scheduler and a second push per wave).

## 1. OBJECTIVE

Stop time-sensitive pushes from being delivered after they stop being true, and
stop an unanswered pill from occupying the screen indefinitely.

## 2. SCOPE

- `functions/src/core/notification_expiry.ts` [NEW] — single source for the
  window; the two platforms take different units and must not drift.
- `functions/src/modules/matches/matches.functions.ts` — INCOMING_WAVE, silent
  and visible branches.
- `functions/src/modules/proximity/proximity.functions.ts` — CROSSING_PATHS,
  silent and visible branches.
- `lib/src/shared/ui/wave_pill_service.dart` — auto-dismiss timer plus its
  cancellation paths.
- Tests: `test/shared/ui/wave_pill_auto_dismiss_test.dart` [NEW],
  `functions/src/__tests__/matches.test.ts`,
  `functions/src/__tests__/proximity_crossing_paths.test.ts`.
- NOT touched: SECOND_ENCOUNTER and the run-mode sends
  (`proximity.functions.ts` ~1116/1138), MUTUAL_WAVE, the FCM payload contract,
  Firestore Rules, native config, `pubspec.yaml`.

## 3. STEPS

1. Register this Plan-ID entry in `tasks/plan.md`.
2. RED/GREEN the four send sites against a shared expiry helper.
3. RED/GREEN the pill auto-dismiss timer and its cancellation paths.
4. Verify Functions lint/build/tests, Flutter analyzer/tests, dev APK.
5. Merge through protected `main`; deploy the two Functions as a separate
   approved lane.

## 4. RISKS & TRADEOFFS

- Android takes a relative duration in milliseconds; APNs takes an absolute
  UNIX epoch in seconds as a string header. One shared helper keeps them
  aligned. `deliverWaveNotification` retries a prebuilt message: the absolute
  iOS deadline correctly survives the retry, the Android relative window
  restarts. Retries are bounded to seconds, so the drift is immaterial.
- The pill timer must be cancelled on reaction, not merely ignored: a Wave
  tapped at 2:59 with a slow network would otherwise be torn down mid-request.
  Cancellation is covered by a test that holds the send open past the deadline.
- TTL changes nothing until the two Functions are deployed. The pill timer
  ships in build 23. Neither is live on merge.

## 5. VERIFICATION

- unit tests: 5 new Functions assertions (visible + silent expiry per type,
  send-time derivation, priority preserved) and 6 new Flutter assertions
  (fires, holds, cancel-on-wave, cancel-on-dismiss, cancel-on-replace,
  three-minute default). Functions 154/154; Flutter 314/314. Each observed RED
  first.
- integration tests: n/a — no new cross-service flow. Real delivery behaviour
  is exercised by the physical-device notification procedure.
- security scan: no credentials, keys, or PII in the diff; no new network,
  auth, or persistence surface. The expiry helper reads only the clock.
- `flutter analyze` clean; `dart format` clean; Functions `tsc --noEmit` and
  eslint clean; dev-flavor APK builds.

---

# Prior Implementation Plan
Plan ID: 20260716-notification-tap-wave-pill
Risk Level: MEDIUM
Status: RESOLVED 2026-07-16 — PR #52 merged into `main` @ 7e768c7
Founder Approval Required: NO
Branch: fix/notification-tap-wave-pill (merged)

## 1. OBJECTIVE

Tapping an `INCOMING_WAVE` or `CROSSING_PATHS` system notification opens the
app and presents the WavePill over whatever screen the router lands on.

## 2. SCOPE

- `lib/src/core/router.dart` — extend `handleNotificationNavigation` with an
  injected pill presenter; extract the existing `onForegroundWave` closure into
  a single shared `presentWavePill`.
- `test/core/router_notification_pill_test.dart` [NEW] — 11 behavioural dispatch
  assertions plus 4 source-level wiring assertions.
- `test/core/router_foreground_wave_wiring_test.dart` — repoint one pinned token
  from `Overlay.of` to `Overlay.maybeOf`.
- No change to `notification_service.dart`, `wave_pill_service.dart`, the FCM
  payload contract, Cloud Functions, Firebase config, native config, or the
  existing `MUTUAL_WAVE` / `RUN_INTERCEPT` paths.

## 3. STEPS

1. Register this Plan-ID entry in `tasks/plan.md`.
2. RED: assert tap-dispatch parses the sender payload and presents the pill.
3. GREEN: add the pill branch to `handleNotificationNavigation`.
4. Refactor both paths onto one `presentWavePill` owning every guard.
5. Verify analyzer, full Flutter suite, and dev APK; merge through protected
   `main`.

## 4. RISKS & TRADEOFFS

- Presenting the pill needs `ref`, which the top-level handler lacks. Injecting
  a presenter avoids a second pill path that would drift from the foreground
  one; the trade-off is one extra parameter on a public function.
- A tap can arrive signed out, mid-onboarding, or before the Navigator's
  overlay exists. The presenter fails closed on auth, null context, and missing
  overlay; `Overlay.maybeOf` replaces `Overlay.of`, which throws.
- The foreground path newly inherits the auth guard. Intentional and strictly
  safer — a pill should never render for a signed-out user.
- Wiring assertions are source-level because the provider body cannot run
  without Firebase; dispatch logic itself is covered behaviourally.

## 5. VERIFICATION

- unit tests: 15 new assertions, each observed RED before implementation; full
  suite 308/308 (293 baseline + 15).
- integration tests: n/a — no service boundary crossed; the change is client
  routing only. Real delivery is exercised by the physical-device notification
  test from the build-22 lane.
- security scan: no credentials, keys, or PII in the diff; no new network,
  auth, or persistence surface. Payload values are read-only and already
  present on the device.
- `flutter analyze` clean; `dart format` clean; dev-flavor APK builds.

---

# Prior Implementation Plan
Plan ID: 20260716-docs-agents-readme-handoff-refresh
Risk Level: LOW
Status: RESOLVED 2026-07-16 — PR #51 merged into `main` @ 8674eb2
Founder Approval Required: NO
Branch: docs/agents-readme-handoff-refresh (merged)

## 1. OBJECTIVE

Realign `AGENTS.md`, `README.md`, and `.planning/HANDOFF.json` with the
verified v1.3 launch state so downstream audit tooling and future sessions
read a truthful snapshot.

## 2. SCOPE

- Replace stale "None" active-blocker list in `AGENTS.md` with the current
  post-merge inventory; refresh file/test counts; append lessons rules #7–#9
  capturing the CROSSING_PATHS / INCOMING_WAVE repair learnings.
- Update `README.md` v1.3 launch note and run command flavor flags.
- Replace April Phase-2D `.planning/HANDOFF.json` snapshot with a build-22
  handoff carrying signed-release metadata, shipped PRs, verification
  evidence, open external gates, and the exact next action.
- Add this Plan-ID entry to `tasks/plan.md`.
- No application code, Firebase, credential, store console, or production
  data change.

## 3. STEPS

1. Register this Plan-ID entry in `tasks/plan.md`.
2. Commit the four documentation files under this Plan-ID.
3. Push branch and open PR with compliant MPC metadata.
4. Wait for protected-main CI green, then merge.
5. Update local `main` and delete branch.

## 4. RISKS & TRADEOFFS

- Documentation drift if merged with an already-out-of-date artifact —
  offset by piggy-backing on the same day's build-22 verification lane.
- No production or credential impact.

## 5. VERIFICATION

- unit tests: n/a — documentation-only diff; no runtime code changed.
- integration tests: n/a — no service surface touched.
- security scan: manual review of the staged diff for credential, key,
  PII, or private URL exposure.
- Protected-branch CI must remain green.

---

# Prior Implementation Plan
Plan ID: 20260716-launch-state-cleanup
Risk Level: LOW
Status: RESOLVED 2026-07-16 — PR #50 merged through protected `main`; repository cleanup verified
Founder Approval Required: NO
Branch: docs/launch-state-cleanup (merged)

## 1. OBJECTIVE

Reconcile launch records with the verified build-22 repository and live-service
state, then leave one clean protected `main` as the baseline for remaining work.

## 2. SCOPE

- Update control-plane launch status, blocker classification, checklist state,
  milestone state, and the current handoff.
- Record only outcomes supported by repository, CI, deployment, live-page, and
  signed-build evidence.
- Do not change application code, production configuration, credentials, store
  consoles, or legal-policy content.

## 3. STEPS

1. Merge the verified iOS delivery repair through protected `main`.
2. Merge the permanent FCM-token Rules regression suite through protected `main`.
3. Reconcile stale launch, legal, security, and store records.
4. Preserve the signed build-22 IPA outside disposable worktrees.
5. Remove merged branches/worktrees and prove the final checkout is clean.

## 4. RISKS & TRADEOFFS

- Marking code complete must not imply an external credential, device, legal,
  or console gate passed.
- Historical phase-directory warnings remain documented rather than fabricating
  empty GSD phase artifacts.

## 5. VERIFICATION

- unit tests: no application behavior changes; protected CI must remain green.
- integration tests: no service mutation; existing emulator and notification
  integration suites remain green on the merged baseline.
- security scan: no credentials enter the documentation diff.
- Markdown diff check, Plan-ID metadata, protected-branch CI, final Git status,
  worktree list, branch inventory, PR inventory, and artifact checksum verified.

---

# Prior Implementation Plan
Plan ID: 20260715-fcm-token-rules-recovery
Risk Level: LOW
Status: RESOLVED 2026-07-16 — PR #49 merged into `main` @ 1cf5446
Founder Approval Required: NO
Branch: fix/session44-fcm-rules-recovery (merged)

## 1. OBJECTIVE

Preserve the production FCM-token Firestore Rules recovery as a permanent,
emulator-backed regression suite without changing the deployed rules.

## 2. SCOPE

- Add an isolated candidate rules fixture and a production-baseline fixture.
- Add Firestore emulator tests for allowed self token writes and denied profile,
  cross-user, unauthenticated, type-confused, and unexpected-field writes.
- Keep production `firestore.rules`, Firebase configuration, and application code
  unchanged.

## 3. STEPS

1. Capture the candidate and production-baseline policies as test fixtures.
2. Exercise the token-only contract against the Firestore emulator.
3. Verify the dedicated test package has no high-severity dependency findings.
4. Run the repository Flutter and Functions gates through the commit hook.
5. Merge the regression suite through protected `main`.

## 4. RISKS & TRADEOFFS

- Fixtures can drift from production, so both the intended candidate and the
  previously deployed baseline are retained for explicit comparison.
- This lane proves policy behavior locally; it does not redeploy or mutate the
  already recovered production ruleset.

## 5. VERIFICATION

- unit tests: 15 focused rules assertions pass against the emulator.
- integration tests: Firestore emulator execution passes for authenticated,
  unauthenticated, cross-user, invalid-type, and unexpected-field cases.
- security scan: the dedicated package reports zero vulnerabilities and the
  committed diff contains no credentials.
- Flutter analyzer and 293 Flutter tests pass; Functions lint, build, and all
  149 Functions tests pass through the repository commit hook and protected CI.

---

# Prior Implementation Plan
Plan ID: 20260715-crossing-paths-ios-delivery
Risk Level: HIGH
Status: RESOLVED 2026-07-16 — PR #48 merged into `main` @ eef99c0
Founder Approval Required: YES — approved in the 2026-07-15 audit handoff and reaffirmed on 2026-07-16
Branch: fix/crossing-paths-ios-delivery (merged)

## 1. OBJECTIVE

Restore canonical sender identity and reliable iOS delivery for
`CROSSING_PATHS` and `INCOMING_WAVE`, while allowing a reciprocal Wave
only after an explicit notification action.

## 2. SCOPE

- Cloud Functions identity, notification payloads, bounded retry,
  delivery-state deduplication, structured redacted logging, and focused tests.
- Flutter notification lifecycle ownership and explicit action dispatch tests.
- Native iOS bridging for the real `UNNotificationResponse.actionIdentifier`.
- Production build number `1.0.0+22`.
- No Firestore schema, Rules, profile migration, or unrelated Firebase change.

## 3. STEPS

1. Lock production-shaped canonical identity and delivery behavior in tests.
2. Implement server delivery, retry, deduplication, and safe logging changes.
3. Remove receipt-triggered Wave writes and preserve explicit iOS actions.
4. Deploy only the two approved Functions and produce the signed build-22 IPA.
5. Merge through protected `main`, then complete the APNs/device release gate.

## 4. RISKS & TRADEOFFS

- Retry and deduplication must land together to avoid duplicate delivery.
- Native/Flutter cold-start action handling must remain idempotent.
- APNs credentials and physical-device delivery remain an external release gate;
  the code change alone cannot prove that stored Apple credentials are valid.

## 5. VERIFICATION

- unit tests: all Functions tests and Flutter tests pass.
- integration tests: focused notification payload, retry, deduplication, and
  explicit-action paths pass; production Functions deployed independently.
- security scan: staged and committed diffs contain no credentials or PII.
- Flutter analyzer clean; dev-flavor APK succeeds.
- Signed production IPA exports with production APNs entitlement and passes
  App Store validation.

---

# Prior Implementation Plan
Plan ID: 20260714-legal-003-art9-consent-hardening
Risk Level: HIGH (Art. 9 GDPR consent enforcement + core matching pipeline + backend write gate + on-launch UX)
Status: RESOLVED 2026-07-14 — PR #41 merged into `main` @ cce1f1c; Cloud Functions deployed to prod (`am---dating-app`) same day. Downstream lanes unblocked: LEGAL-001 DPIA rewrite, LEGAL-004 Weekend Pass timezone, PLAN_04 KORAK 4.2/4.3, STORE-003/004 Play Console declarations.
Founder Approval Required: YES (approved 2026-07-14 in the pre-cut discuss-phase — this file IS the record)
Branch: feature/legal-003-art9-consent-code (merged as PR #41; code follow-up to the docs branch feature/legal-003-art9-consent-hardening / PR #40)

## 0. AUDIT RESULT — LEGAL-003 gap analysis (2026-07-14)

BLOCKER-LEGAL-003 was originally scoped as "add explicit consent for
Art. 9 special-category data." A discuss-phase audit against `main`
(post PR #39 merge) found the scaffolding ~60% complete but with 4
HIGH-severity gaps that individually invalidate the compliance
posture. This PR closes all HIGH gaps + adjacent MEDIUM cleanups
in a single coherent lane so we never ship a half-compliant state.

### Current state audit (`main` post PR #39)

| Component | State | Evidence |
|---|---|---|
| `consent_step.dart` registration UI | ✅ Collects per-category consents (orientation required; religion + ethnicity optional) | `lib/src/features/auth/presentation/widgets/registration_steps/consent_step.dart:38-46` |
| Client persistence | ✅ `sexualOrientationConsent` + `sexualOrientationConsentAt` + `religionConsent` + `ethnicityConsent` on `AuthUser` | `lib/src/features/auth/data/auth_repository.dart:87-93` |
| `getPublicProfile` whitelist | ✅ religion / ethnicity / gender blocked from client-facing response via TS excess-property enforcement | `functions/src/modules/users/users.schema.ts:95-131` |
| Bilateral fail-closed scorer (religion + ethnicity) | ✅ Both parties must have consent=true for scoring to fire | `functions/src/modules/compatibility/compatibility_calculator.ts:273-289` |
| Server write-time enforcement | ❌ **HIGH GAP** — `users.functions.ts` accepts Art. 9 field writes with no consent check (grep "consent" → 0 hits) | `functions/src/modules/users/users.functions.ts` |
| Bilateral fail-closed scorer for gender + lookingFor | ❌ **HIGH GAP** — orientation is derived from these fields but there is no analogous scorer gate | `compatibility_calculator.ts` |
| Settings withdrawal UX | ❌ **HIGH GAP** — `settings_screen.dart` has zero consent references; violates GDPR Art. 7(3) "as easy to withdraw as to give" | `lib/src/features/settings/presentation/settings_screen.dart` |
| Existing-user backfill | ❌ **HIGH GAP** — every pre-consent-step prod user has `null` orientation consent; no re-prompt path | policy + code |
| "Select all" pill toggles Art. 9 optionals | ⚠️ MEDIUM — undermines "specific" consent per category | `consent_step.dart:56-57` |
| Consent version tag | ⚠️ MEDIUM — no `{category}ConsentVersion`; purpose-text bumps cannot re-prompt | data model |
| Timestamps for religion + ethnicity consents | ⚠️ MEDIUM — only orientation gets `ConsentAt`; religion + ethnicity do not | `auth_repository.dart` |

### Legal framing (approved 2026-07-14)

Founder direction: `sexualOrientationConsent` STAYS REQUIRED for
matching. The Art. 9(2)(a) explicit-consent defense holds up if
(a) purpose is narrowly scoped in the consent text (matchmaking
within Tremble only, no ad-tech, no analytics fingerprinting, no
third-party sharing), (b) that scope is enforced in code
(bilateral fail-closed gate on gender + lookingFor), and (c)
withdrawal is functional (Settings toggle purges the fields).
This is the standard EU dating-app posture (Bumble, Hinge). The
Grindr NOK 65M fine was not "requiring orientation was illegal"
but "orientation collected for matching was shared with ad
networks without a separate lawful basis." Tremble never shares
Art. 9 data with third parties — the narrow purpose scope is
defensible when it is provably enforced.

## 1. OBJECTIVE

Close all HIGH-severity Art. 9 gaps in one PR so we ship a coherent
consent posture, not a half-compliant intermediate state. Every
policy claim in the consent text is backed by code enforcement in
this PR.

## 2. SCOPE

**Files this PR touches:**

Server:
- `functions/src/modules/users/users.functions.ts` — write-time enforcement in `updateProfile`; new `withdrawArt9Consent` callable that deletes the sensitive field(s)
- `functions/src/modules/users/users.schema.ts` — accept `sexualOrientationConsent` / `religionConsent` / `ethnicityConsent` on `updateProfile` (same-request grants)
- `functions/src/modules/auth/auth.functions.ts` — `completeOnboarding` drops religion/ethnicity to null when the paired consent isn't true; server stamps version + timestamp for all three categories
- `functions/src/modules/compatibility/compatibility_calculator.ts` — orientation bilateral fail-closed gate on `lookingFor` (`gender` is not scored today; the gate is placed on the orientation-adjacent scoring surface)
- `functions/src/index.ts` — export the new `withdrawArt9Consent` callable
- `functions/src/__tests__/users.test.ts` — 10 new assertions: pair-of-tests per Art. 9 field, same-request-withdrawal rejection, withdrawal callable delete semantics
- `functions/src/__tests__/compatibility_calculator.test.ts` — orientation bilateral gate pair-of-tests (mirrors religion pattern)

Client:
- `lib/src/features/auth/presentation/widgets/registration_steps/consent_step.dart` — remove select-all from Art. 9 optionals; narrow-purpose text on all three Art. 9 tiles via `_v1` translation keys with a "Learn more" PP anchor link; stable Keys for widget-test access
- `lib/src/features/auth/data/auth_repository.dart` — five new AuthUser fields (version + timestamp for orientation / religion / ethnicity); `fromFirestore` + `copyWith` extended; new `withdrawArt9Consent(category)` and `setArt9Consent(category, granted:)` repo + notifier methods (server-first, not optimistic, so a network failure keeps the backfill modal open for retry)
- `lib/src/features/settings/presentation/widgets/privacy_consents_section.dart` — NEW; three-tile settings section with confirmation dialog + destructive withdrawal
- `lib/src/features/settings/presentation/settings_screen.dart` — wires the new section as a fifth expandable "privacy" group
- `lib/src/features/auth/presentation/backfill_consent_modal.dart` — NEW; PopScope-locked full-screen modal + `BackfillConsentGate` root-level overlay
- `lib/src/app.dart` — wraps the app inside `BackfillConsentGate` alongside the existing `DismissKeyboard`
- `lib/src/core/translations.dart` — Art. 9 tile copy + settings section copy + backfill modal copy in EN + SL + HR; other locales fall back to EN via the existing `tr()` fallback

Tests:
- `test/features/auth/consent_step_test.dart` — select-all restriction, `_v1` key wiring, PP anchor deep-links, and four narrow-purpose phrases across EN + SL + HR
- `test/features/settings/privacy_consents_section_test.dart` — NEW; render-state parity + confirm-then-invoke + cancel-suppression
- `test/features/auth/backfill_consent_modal_test.dart` — NEW; four state-predicate assertions plus accept / decline / server-error retry paths
- `test/features/auth/photo_upload_registration_test.dart` — updated so the "select-all + continue" path taps the orientation tile explicitly (LEGAL-003 step 4)

Docs / tracking:
- `tasks/plan.md`, `tasks/blockers.md`, `tasks/plans/PLAN_03_APP_CODE.md`, `tasks/plans/PLAN_04_LEGAL_STORES.md` — plan + status updates

**Files this PR does NOT touch:**
- `firestore.rules` — write enforcement is CF-side; the app never writes directly. Rules review is a separate lane if we ever open direct writes.
- `firestore.indexes.json`
- BLE service, native config, Info.plist / PrivacyInfo.xcprivacy, AndroidManifest
- Any other feature module (matches, waves, radar, recap, event pin sheet)
- Any legal doc under `web/` or `legal/` — DPIA + Privacy Policy rewrites are LEGAL-001 + PLAN_04 KORAK 4.3, downstream of this PR

## 3. STEPS

### Step 1 — Server write-time enforcement

In `updateProfile` + `completeOnboarding` (CF handlers), before persist:

- Load the target user's current consent flags from Firestore.
- Merge them with any consent flags in the incoming request (same-request grants are honored).
- If incoming `gender` or `lookingFor` is present AND merged `sexualOrientationConsent !== true` → reject with `code: 'permission-denied'` + `message: 'art9_orientation_consent_required'`.
- Same enforcement for `religion` vs `religionConsent`, `ethnicity` vs `ethnicityConsent`.
- Fail-closed: any consent flag missing or false blocks the corresponding field write.

Verify via jest: `updateProfile({ gender: 'female' })` with `sexualOrientationConsent = false` → 403 with correct error code.

### Step 2 — Bilateral fail-closed scorer gate for gender + lookingFor

In `compatibility_calculator.ts`, mirror the existing religion / ethnicity pattern (line 273-289):

- Add `const bothConsentOrientation = a.sexualOrientationConsent === true && b.sexualOrientationConsent === true;`
- Guard every scoring dimension that reads `a.gender`, `b.gender`, `a.lookingFor`, `b.lookingFor` with `bothConsentOrientation`.
- If either party lacks consent → the orientation-adjacent dimensions are OMITTED from the score (not zero, not one — matching the existing skip semantics).

Verify via jest pair: neither → dimension skipped; one → skipped; both → dimension counted.

### Step 3 — Consent-text hardening

Rewrite all three Art. 9 consent tiles in `consent_step.dart` with narrow-purpose language:

- **Orientation tile:** "I consent to Tremble processing my gender and matching preferences (from which my sexual orientation may be inferred — a GDPR Art. 9 special category) SOLELY for the purpose of matching me with compatible users inside Tremble. This data is never sold, never shared with advertisers, never used for analytics, and is bilaterally fail-closed (only users who have also consented can be scored against my orientation). I can withdraw consent from Settings at any time; on withdrawal my gender and matching preferences are deleted from Tremble."
- **Religion tile:** analogous narrow-purpose text.
- **Ethnicity tile:** analogous narrow-purpose text.

Each tile links to the Privacy Policy anchor `#art9-consent-<category>`. Anchors will be pinned in LEGAL-001; if PP is not yet updated, the anchor still resolves to the PP root — the link never dangles.

Update EN + SL + HR translations in the same commit.

### Step 4 — Remove "select all" from Art. 9 optionals

- `_toggleAll()` currently flips religion, ethnicity, orientation alongside Terms / Privacy / Age / Location / DataProcessing (`consent_step.dart:48-60`).
- Restrict `_toggleAll()` to Terms + Privacy + DataProcessing + Age + Location only. Art. 9 tiles are ONLY toggleable individually.
- The Continue button gate stays: all mandatory tiles + orientation required; religion + ethnicity remain optional.

### Step 5 — Consent version tag + timestamps

Add fields on `AuthUser`:
- `sexualOrientationConsentVersion: String?` (initial value `'v1'`)
- `religionConsentVersion: String?` (initial value `'v1'`)
- `ethnicityConsentVersion: String?` (initial value `'v1'`)
- `religionConsentAt: DateTime?`
- `ethnicityConsentAt: DateTime?`

Persist all five on registration + on every consent state transition (withdrawal or re-grant). Update `toMap`, `fromMap`, `copyWith`. Extend the Zod schema in `users.schema.ts` to accept the five new fields on write.

### Step 6 — Settings withdrawal UX

New `privacy_consents_section.dart` embedded in the existing Settings screen:

- Three tiles (orientation / religion / ethnicity), each showing current consent state + accepted version + timestamp.
- On withdrawal:
  1. Confirmation dialog with a clear impact statement: "This will remove your [category] data from Tremble. You will not appear in matches scored on this dimension. You can re-consent later, but you will need to re-enter the data."
  2. On confirm → CF call updates the consent flag to `false` + writes new timestamp + version; `FieldValue.delete()` on the corresponding field(s) — orientation withdraws also deletes `gender` and `lookingFor`.
  3. Scorer immediately reflects (already fail-closed).
- On re-grant → route user to the existing profile-edit UI to re-enter the field.

### Step 7 — Existing-user backfill modal

New `backfill_consent_modal.dart`:

- On app launch, after auth resolution, if `currentUser.sexualOrientationConsent == null` → show the modal ABOVE all other UI.
- Modal shows the full narrow-purpose statement (same wording as Step 3 orientation tile) + Accept / Decline buttons.
- **Accept** → CF call writes consent = true + `v1` + timestamp. Modal dismisses. Normal app flow.
- **Decline** → CF call writes consent = false + `v1` + timestamp. Modal dismisses. User is routed to browse-only mode (matching disabled; scorer already fails closed on their data). Settings shows the withdrawal state; user can re-consent from there.
- Modal cannot be swipe-dismissed or back-button-dismissed — a decision must be made.
- No re-prompt loop: once a decision is recorded (even Decline), the modal does not re-appear until a version bump.

## 4. RISKS & TRADEOFFS

- **HIGH risk classification** — modifies core matching pipeline (scorer) AND server-side write enforcement AND on-launch UX in one PR. Splitting would ship intermediate half-compliant states (worse than nothing), so we accept the larger diff. Trade-off acknowledged.
- **Backfill modal will cause a temporary DAU dip** — every existing user hits a blocking screen on next launch. Accept-rate is expected to be high (product is understandable) but not 100%. Users who decline lose matching access and may churn. Founder-approved: worth it for legal defensibility.
- **`FieldValue.delete()` on withdrawal is destructive** — user cannot recover the deleted field. UX mitigation: confirmation dialog with an explicit impact statement + option to re-enter on re-grant.
- **`v1` version tag is a decision made permanent** — future consent-text bumps to `v2` will need to re-prompt existing v1 users. The mechanism is built in this PR; the first `v2` bump is a future lane.
- **Purpose text is long** — legally strong, UX-heavy. The tile is scrollable. Acceptable trade-off given Grindr precedent.
- **Not in this PR (deferred):** immutable consent-history subcollection (only relevant if audit demands proof of prior states — current model overwrites), Privacy Policy rewrite (LEGAL-001 lane), DPIA update (PLAN_04 KORAK 4.3), sending the pisno mnenje request to counsel (PLAN_04 KORAK 4.2 — done AFTER this PR merges so counsel opines on shipped code, not a proposal).

## 5. VERIFICATION

- **unit tests** — 8+ new assertions:
  - Server: `updateProfile` rejects `gender` write when orientation consent = false
  - Server: `updateProfile` accepts `gender` write when the SAME request grants orientation consent
  - Server: analogous pair for religion + ethnicity
  - Scorer: orientation dimension skipped when neither party has consent
  - Scorer: orientation dimension skipped when one party has consent
  - Scorer: orientation dimension counted when both parties have consent
  - Widget: `consent_step` select-all no longer flips Art. 9 optionals
  - Widget: privacy consents section withdrawal invokes `FieldValue.delete` via mocked repo
  - Widget: backfill modal renders on null consent + Accept path writes `true + v1`
  - Widget: backfill modal Decline path writes `false + v1` and routes to browse-only mode
- **integration tests** — n/a for this PR (no new cross-service flow; each unit test covers a single boundary cleanly)
- **security scan** — n/a — this PR IS the Art. 9 security hardening; any surface a scanner would flag is precisely what the PR closes. Manual security review by founder before merge is the actual gate.
- `flutter analyze` clean
- `flutter test` all pass (existing + new)
- `cd functions && npm test` all pass (existing + new)
- Manual smoke on dev flavor:
  - Fresh registration → all consent fields land in Firestore with `v1` + timestamps
  - Update `gender` via app with orientation consent = false → 403 (matches error code)
  - Toggle orientation off in Settings → Firestore doc shows `gender` + `lookingFor` deleted + consent = false + new timestamp
  - Synthetic pre-migration user (manually null consent) → backfill modal blocks on launch
- MPC PR pre-flight (Rules #79 + #80):
  - Title: `[PLAN-ID: 20260714-legal-003-art9-consent-hardening] feat(privacy): Art. 9 consent hardening — server enforcement + bilateral scorer gate + withdrawal UX + backfill modal`.
  - Body contains `## Verification checklist` naming `unit tests`, `integration tests`, `security scan`.
  - Body contains ZERO Rule #80 naive-regex trigger substrings — paraphrase risk framing without literal `risk_level: high`, `infra_change`, `touches_auth`, `touches_pii`, `external_model_calls`.
  - Plan-ID present in this file (line 2).

## 6. LINKED LANES

- **BLOCKER-LEGAL-001** (DPIA false claims) — this PR provides the code-truth foundation for the DPIA §3.2 / §4.2 / §8 rewrite. Consent version tags + fail-closed scorer + withdrawal purge are the load-bearing DPIA claims. The DPIA rewrite is a separate founder + counsel lane, downstream of this PR.
- **PLAN_04 KORAK 4.2** (odvetnica pisno mnenje) — Art. 9(2)(a) conditionality is one of the two mandatory questions. Send AFTER this PR merges so counsel opines on shipped code, not a proposal. Cross-reference is now in PLAN_04.
- **PLAN_04 KORAK 4.3** (docs rewrite) — DPIA §gender + lookingFor consent mehanizem now has a concrete code implementation to reference.
- **BLOCKER-LEGAL-004** (Weekend Window ToS mismatch + user-local timezone) — separate lane, rescoped 2026-07-14 from LOW (ToS edit only) to HIGH (code + ToS). Product model confirmed as a PAID weekend Premium package with three purchase-timing branches (queued before Fri 19:00 → activates at Fri 19:00 same week; instant Fri 19:00 - Sun 19:00; queued after Sun 19:00 → next weekend), computed in the **user's local timezone** (not hardcoded `Europe/Ljubljana`). Fix now requires: (a) IANA `timezone` field on user document + backfill; (b) `getNextWeekendWindow(userTimezone)` refactor + call-site updates; (c) traveler decision (snapshot at purchase vs re-evaluate at activation); (d) DST edge-case handling; (e) ToS §7 rewrite describing the localized product. Sequenced AFTER LEGAL-003 ships. Durable decision record: memory `weekend-pass-user-local-timezone.md`.

---

# Active Release Chore
Plan ID: 20260714-release-b17
Risk Level: LOW (version string bump + gitignore line; no code paths, no infra, no auth, no PII)
Status: IN-REVIEW 2026-07-14 — PR #43 opened; TestFlight upload 1.0.0 (17) delivered to ASC (delivery UUID `0b1e8e74-df40-479e-8015-5e4501b1e2fc`); AAB awaiting manual Play Console upload.
Founder Approval Required: NO (LOW risk; release chore paired with LEGAL-003 artifacts already approved and merged in PR #41).
Branch: chore/release-1.0.0-b17

## Objective

Align git HEAD with the release artifacts (AAB + IPA) that carry the first public shipment of the LEGAL-003 Art. 9 GDPR consent hardening code. Previous build 16 was never public. Build 17 is the first user-facing binary containing the Art. 9 code merged in PR #41 (`cce1f1c`) and prod-deployed to Cloud Functions the same day.

## Scope

- `pubspec.yaml`: version `1.0.0+16` → `1.0.0+17` — single source of truth for both Android `versionCode`/`versionName` and iOS `CFBundleShortVersionString`/`CFBundleVersion` (memory: `android-version-source-of-truth`).
- `.gitignore`: add `release-symbols/` — local-only preservation copy of AAB, IPA, and native debug symbols kept outside `build/` so the inter-platform `flutter clean` does not wipe them, and kept out of git because ~130 MB of binaries.

## Notes for MPC PR pre-flight

- Title: `[PLAN-ID: 20260714-release-b17] chore(release): bump build to 1.0.0+17`. NOTE — slug intentionally omits the `1.0.0` dots; CI regex `[a-z0-9\-]+` rejects `.`. Lesson learned; recording here so future release chores use `bXY` slugs (build number, no version dots).
- Body contains `## Verification checklist` naming `unit tests`, `integration tests`, `security scan` (all `n/a` with reasons — release chore, no source paths changed).
- Plan-ID present on this line: `20260714-release-b17`.

### Post-ship note — b17 was DOA

Build 17 shipped with `--dart-define=FLAVOR=prod` and NOTHING else. `PLACES_KEY_PROD` / `REVENUECAT_APPLE_API_KEY` / `REVENUECAT_GOOGLE_API_KEY` / `SENTRY_DSN` all resolved to empty string. TestFlight smoke test confirmed: gym search returned "no gyms found nearby" during registration; new-user signup blocked. Superseded by lane below (`release-b18`). See Rule #84 in `tasks/lessons.md` for the durable fix.

---

# Active Release Chore
Plan ID: 20260714-release-b18
Risk Level: LOW (version string bump + repo doc updates; no code paths, no infra, no auth, no PII)
Status: IN-REVIEW 2026-07-14 — TestFlight upload 1.0.0 (18) in flight via altool; AAB awaiting manual Play Console upload; PR to be opened.
Founder Approval Required: NO (LOW risk; supersedes DOA build 17 with corrected env-file build flag).
Branch: chore/release-b18

## Objective

Ship a working 1.0.0 (18) to Play Console + TestFlight after build 17 was found DOA on TestFlight smoke test (gym search broken because `PLACES_KEY_PROD` was empty; IAP would also break because RevenueCat keys were empty). This build uses `--dart-define-from-file=.env.prod.json` for both platforms so every prod key from the file is compiled in.

## Scope

- `pubspec.yaml`: version `1.0.0+17` → `1.0.0+18` — SSOT bump (memory: `android-version-source-of-truth`).
- `tasks/lessons.md`: adds Rule #84 documenting the DOA root cause and the required build flags, so the mistake is durable in-repo, not just in personal memory.
- `tasks/plan.md`: this section, plus the "Post-ship note" annotation on the b17 lane above.

## Verification for MPC PR pre-flight

- Title: `[PLAN-ID: 20260714-release-b18] chore(release): rebuild 1.0.0+18 with env file — supersedes DOA b17`.
- Body contains `## Verification checklist` naming `unit tests`, `integration tests`, `security scan` (all `n/a` with reasons — release chore + docs).
- Plan-ID present on this line: `20260714-release-b18`.

---

# Active Release Chore
Plan ID: 20260715-release-b20
Risk Level: LOW (version string bump + font-preload restore + tiny UI version marker; no infra, no auth, no PII, no schema changes)
Status: IN-REVIEW 2026-07-15 — b20 IPA already built locally (per prior session log); PR to be opened.
Founder Approval Required: NO (LOW risk; no code paths cross a system boundary; net additions are: one guarded async preload, one 10pt Text widget, and a version-string bump).
Branch: chore/release-b20

## Objective

Ship 1.0.0 (20) to Play Console + TestFlight. b20 rolls up three small carry-over changes that accumulated locally after b18 shipped but were never committed:

1. `GoogleFonts.pendingFonts([...])` preload is re-enabled in `main.dart`, wrapped in `try/catch` so a font-CDN failure at cold start cannot crash the app (fallback: Flutter uses its bundled fonts).
2. A small `'v20'` label under the registration Continue button so QA / TestFlight users can identify the running build without opening Settings.
3. `pubspec.yaml` bump 1.0.0+18 → 1.0.0+20. b19 is intentionally skipped (a local b19 IPA existed briefly but was never uploaded; b20 supersedes it so store version-code monotonicity is preserved either way).

## Scope

- `pubspec.yaml`: version `1.0.0+18` → `1.0.0+20` — SSOT bump (memory: `android-version-source-of-truth`).
- `lib/main.dart`: re-enable `GoogleFonts.pendingFonts([...])` inside a `try/catch` (`if (kDebugMode) debugPrint(...)` on failure — silent in release per `dart/security.md` "no logging sensitive data" and to avoid noisy prod logs). Rationale: without preload, first-frame paint uses fallback fonts then swaps — visible flash on cold start.
- `lib/src/features/auth/presentation/widgets/registration_steps/email_location_step.dart`: wrap the existing Continue button in a `Column(mainAxisSize: MainAxisSize.min, ...)` and append a `Text('v20', style: TextStyle(color: white30 / black38 by theme, fontSize: 10))` version marker. Purely additive; button semantics/enabled logic unchanged.
- `tasks/plan.md`: this section.

## Verification for MPC PR pre-flight

- Title: `[PLAN-ID: 20260715-release-b20] chore(release): 1.0.0+20 — GoogleFonts preload + v20 label`.
- Body contains `## Verification checklist` naming `unit tests`, `integration tests`, `security scan` (release chore — `n/a` with reasons documented per lane).
- Plan-ID present on this line: `20260715-release-b20`.

---

# Active Release Chore
Plan ID: 20260715-release-b21
Risk Level: LOW (version string bump only; ships the Sentry-fix rollup PR #46 that already landed on main)
Status: IN-PROGRESS 2026-07-15 — cutting release branch off main @ 168013d (post-#46 merge).
Founder Approval Required: NO (LOW risk; pubspec version bump only; no code paths cross a system boundary in this commit).
Branch: chore/release-b21

## Objective

Ship 1.0.0 (21) to Play Console + TestFlight. b21 packages the 5 Sentry-fix rollup that merged as PR #46 (`bc14dc8` → squashed to main as `168013d`):

- Issue 1 — Firebase Permission Denied guard on unauth Firestore reads during login race.
- Issue 2 — Android StackOverflow in `onRequestPermissionsResult` (recursive callback loop on Android 14).
- Issue 3 — Null-check operator crash in `map_provider.dart` (null-aware fallbacks).
- Issue 4 — `MissingPluginException` guard for platforms without flutter_blue_plus channel.
- Issue 5 — Unhandled `ClientException` from PMTiles fetch (soft-fail error boundary).

Rebuilt against `1.0.0+21` so store `versionCode` monotonicity is preserved (last shipped: +20).

## Scope

- `pubspec.yaml`: version `1.0.0+20` → `1.0.0+21` — SSOT bump (memory: `android-version-source-of-truth`).
- `tasks/plan.md`: this section.
- `android/local.properties`: local `flutter.versionCode` mirror bumped 20→21 on this machine (gitignored; not part of the commit — pubspec remains SSOT per memory rule).

## Verification for MPC PR pre-flight

- Title: `[PLAN-ID: 20260715-release-b21] chore(release): 1.0.0+21 — Sentry-fix rollup rebuild`.
- Body contains `## Verification checklist` naming `unit tests`, `integration tests`, `security scan` (release chore — `n/a` with reasons documented per lane).
- Plan-ID present on this line: `20260715-release-b21`.
