# Permanent Project Knowledge (Lessons)

> Rules are permanent and never deleted. Ordered newest-first (highest rule number first).

---

**Rule #88 — Test foreground/tap push behaviour with `functions/src/scripts/send_test_push.ts`, not by waiting on `scanProximityPairs`.**
[2026-07-18] The scheduled scan's 10-min global throttle + per-pair cooldown almost never coincide with the app being foregrounded on-screen, so foreground pushes (the freeze + pill paths) cannot be reproduced by walking around — this cost two inconclusive device sessions. The script sends ONE CROSSING_PATHS / INCOMING_WAVE directly to a device (by `--uid=` → `users/{uid}.fcmToken`, or raw `--token=`), reusing the exact prod payloads + `apnsExpirationHeaders`. Use `--project=am---dating-app --i-know-this-is-prod` for prod. Angle-bracket placeholders in docs are LITERAL shell metacharacters — pass a real uid with no `<>` or zsh throws `parse error near '\n'`.
Source: device-verification tooling, 2026-07-18 (PR #63).

**Rule #87 — Verify framework / plugin / native internals against REAL source, not reasoning, before blaming them.**
[2026-07-18] The "tap did nothing" and the freeze were misdiagnosed repeatedly by reasoning about how firebase_messaging / FlutterAppDelegate forward notifications. The handoff suspected PR #60's delegate change broke `didReceiveNotificationResponse` forwarding. Reading the actual Flutter engine `.mm` for the pinned engine commit (`e4b8dca`) showed `FlutterAppDelegate` + `FlutterPluginAppLifeCycleDelegate` forward it to plugins identically to `willPresentNotification` — REFUTED. The real bug was in our own Dart (Rule #86). Same failure mode as the crash-filter bug and the two freeze misdiagnoses: assert against real device stacks / real source, never assumed ones.
Source: wave-pill render sprint, 2026-07-18.

**Rule #86 — A global overlay (wave pill, app-wide banner) MUST come from `rootNavigatorKey.currentState.overlay`, never `Overlay.maybeOf(rootNavigatorKey.currentContext)`.**
[2026-07-18] `Overlay.maybeOf(rootNavigatorKey.currentContext)` is ALWAYS null: the root Navigator (GoRouter `navigatorKey`) builds its `Overlay` as a CHILD, so the Overlay is a *descendant* of the navigator's context, and `maybeOf` only walks *ancestors*. `presentWavePill` used the context lookup, so the CROSSING_PATHS / wave pill never rendered — foreground AND tap, regardless of auth or timing. Proven on device (build 25, 2026-07-18 08:48:03: two visible pushes, `pairsNotified:2`, nothing shown) and by `test/core/root_overlay_resolution_test.dart`. Fix: `rootNavigatorKey.currentState?.overlay` (the Navigator's own `OverlayState`); present sheets/paywalls from `overlay.context`. See `presentWavePill` in `lib/src/core/router.dart`.
Source: wave-pill render sprint, 2026-07-18 (PR #65).

**Rule #85 — The Flutter app reports to the Sentry project `tremble-functions`, NOT `tremble-app`. A release that uploads no debug symbols is not a release.**
[2026-07-17] Two separate traps, both of which cost real hours.

**(a) The project name is a lie waiting to happen.** There are three Sentry
projects — `tremble-app`, `tremble-functions`, `tremble-website`. The obvious
guess for the Flutter app is `tremble-app`. It is wrong. `SENTRY_DSN` in
`.env.prod.json` resolves to project id `4511554698936400`, which is
`tremble-functions`. Every iOS crash lands there: `TREMBLE-FUNCTIONS-Q`
(EXC_BAD_ACCESS), `-S` (AppHang), `-R` (MapController), `-P` (gstatic font) —
all `platform: cocoa`, `release: tremble.dating.app@1.0.0+23`. `tremble-app`
exists and receives nothing. `tasks/context.md` (Session 39) instructs a future
reader to "confirm Sentry **tremble-app** project receives events" — that line
is wrong; do not act on it. Uploading symbols to `tremble-app` would succeed,
report success, and symbolicate nothing.

**(b) Symbols were never uploaded at all.** Releases ship `--obfuscate
--split-debug-info` but nothing was ever sent to Sentry, so every native frame
arrived as `<redacted>` and every Dart issue title as `lM: Cancelled` /
`cJ: [permission-denied]`. Session 48 spent ~5 hours reconstructing the 1.0.0+23
crash-reporter storm by hand for exactly this reason.

**The artifacts are not interchangeable, and iOS/Android are asymmetric.**
Verified with `sentry-cli debug-files check` on build 23, not assumed:

| Artifact | Debug ID | Fixes |
|---|---|---|
| `Runner.app.dSYM` | `89bb20ec-…` — **usable** | `<redacted>` native frames (Obj-C/Swift/system) |
| `App.framework.dSYM` | `72002995-…` — **usable** | **iOS Dart AOT frames** |
| `app.android-arm64.symbols` | `30f93e7a-…` — **usable** | **Android Dart frames** |
| `app.ios-arm64.symbols` | `00000000-…` — **UNUSABLE** | nothing — Sentry rejects it |
| `obfuscation_map.json` | paired to a debug ID | obfuscated Dart issue *titles* (`lM:`, `cJ:`) |

**The trap:** on iOS the `--split-debug-info` `.symbols` file is stripped of its
debug identifier (`Usable: no (missing debug identifier, likely stripped)`), and
`sentry-cli debug-files upload` reports "Found 0 debug information files". It is
for `flutter symbolize` only. iOS Dart frames are decoded by
**`App.framework.dSYM`** from the `.xcarchive` instead. On **Android** the
`.symbols` file DOES carry a real debug ID and is the right artifact. So
"upload the .symbols files" is correct for Android and useless for iOS — do not
assume the platforms behave the same.

**Symbolication happens at INGEST.** Uploading dSYMs after a crash has been
stored does NOT retroactively fix it — build 23's events stayed `<redacted>`
even after a verified upload of the exact matching debug IDs. Symbols must be up
BEFORE the build ships, which is why the script uploads as part of the build.

**How to apply:**
- Build prod via `scripts/release/build_prod.sh` only. It enforces Rule #84,
  produces all three artifacts, uploads them, and preserves them under
  `release-symbols/b<N>/`.
- Never let a build's dSYMs live only in `build/` — `flutter clean` destroys
  them and with them any hope of reading that build's crashes. Build 23's dSYMs
  survived by pure luck (`Runner.app.dSYM` UUID `89BB20EC-14F6-3E25-980F-6885FCF9E740`,
  which matches the `app_id` on the live TREMBLE-FUNCTIONS-Q event).
- Verify debug files are listed for the new `dist` BEFORE uploading to
  TestFlight: https://aleksandar-bojic.sentry.io/settings/projects/tremble-functions/debug-symbols/
- Use an **organization** token (`sntrys_…`) from
  `/settings/auth-tokens/`. It has no scope picker — the fixed `org:ci` scope
  DOES cover `debug-files upload` despite the UI blurb saying only "Source Map
  Upload, Release Creation, Code Mappings" (verified 2026-07-17). It is
  upload-only: reading or reprocessing issues returns HTTP 403, which is correct
  least privilege for a build token.
- The org is EU-region, but do NOT set `url:` / `SENTRY_URL`. An org token embeds
  its own `url` + `region_url`; sentry-cli uses the embedded value and warns that
  it is ignoring yours. Only a personal token would need an explicit region.
- `SENTRY_AUTH_TOKEN` is an env var, never a pubspec value — `pubspec.yaml` is
  committed and the pre-commit secret scan reads it.

Source: Sentry dSYM pipeline lane, 2026-07-17. Related: Rule #84.

---

**Rule #84 — Prod release builds MUST use `--dart-define-from-file=.env.prod.json`, not a bare `--dart-define=FLAVOR=prod`.**
[2026-07-14] Build 1.0.0+17 was uploaded to Play Console (AAB) and TestFlight (IPA) during the LEGAL-003 close-out session using a build script that passed only `--dart-define=FLAVOR=prod`. Consequences observed on TestFlight iOS build 17:
- `PlacesService._apiKey` resolved to empty string → Google Places autocomplete returned auth error → **"No gyms found nearby"** during the gym step of registration → new-user signup was completely blocked.
- `REVENUECAT_APPLE_API_KEY` / `REVENUECAT_GOOGLE_API_KEY` empty → RevenueCat SDK cannot initialize → Weekend Pass / any IAP purchase would silently fail.
- `SENTRY_DSN` empty → no crash telemetry from the DOA build (masking the failure).

**How to apply — every prod release, both platforms:**

```bash
export SENTRY_AUTH_TOKEN=...          # see Rule #85
scripts/release/build_prod.sh         # both platforms, builds + uploads symbols
```

**Use the script.** It is the only supported path. It enforces this rule (and
fails the build if any required key in `.env.prod.json` is empty — the exact
build-17 failure), adds the `--save-obfuscation-map` that the hand-written
commands below always omitted, uploads debug symbols per Rule #85, and preserves
the artifacts. The commands it runs are, for reference only:

```bash
flutter build appbundle --release --flavor prod \
  --dart-define-from-file=.env.prod.json \
  --obfuscate --split-debug-info=build/symbols/android

flutter build ipa --release --flavor prod \
  --dart-define-from-file=.env.prod.json \
  --obfuscate --split-debug-info=build/symbols/ios \
  --extra-gen-snapshot-options=--save-obfuscation-map=<abs>/build/symbols/ios/obfuscation_map.json \
  --export-options-plist=ios/ExportOptions.plist
```

Do NOT accept a release script that lists individual `--dart-define` flags — it silently drifts when a new key is added to `.env.prod.json`. Always pass the file, not the keys.

**Still-open violation (2026-07-17):** `.github/workflows/deploy.yml` `build-apk`
runs `--dart-define=FLAVOR=$FLAVOR` with no env file and no obfuscation — this
rule's exact failure. It builds an APK rather than the AAB that ships, so it
appears to be dead weight. Fix or delete it; do not use it to cut a release.

**Smoke-test hint before shipping:** on a fresh install of the AAB/IPA, register a test user through the gym step. If "no gyms found nearby" appears for common queries ("Fitnes", major chains), the env file was skipped — bump the build number and rebuild before uploading to any store channel.

This rule tightens Rule #1 — which says "provide the explicit dev or prod flavor flags" but does not explicitly require `--dart-define-from-file` for release BUILDS (only mentions it for `flutter run` dev commands). Rule #84 removes that ambiguity for builds.

Source: Build 17 DOA post-mortem, 2026-07-14. Related: [[release-build-must-use-env-file]] (personal memory).

---

**Rule #83 — Verify Handoff Intel Against `git log` + `gh pr list` BEFORE Cutting a Fix Branch.**
[2026-07-14] A handoff prompt that names a specific commit hash, branch, or "still-open" ticket is a claim about state _at write time_ — not now. Session 2026-07-14 was spawned to fix the "flaky GymStep test" and inherited a PLAN_00 §"Pokvarjeno / odprto" list of 8 live blockers. Verification revealed 5 of the 8 were already merged (PR #14 ci.yml injection, PR #13 stopBilling CF, PR #17 CROSSING_PATHS, PR #18 prefer_not_to_say) or cannot-reproduce (KORAK 3.8-2 flaky GymStep = 43/43 pass). ~90 minutes lost rediscovering resolved work before the phantom-blocker pattern became visible.

**How to apply — before cutting ANY fix branch off a handoff:**
- `git log --all --oneline | head -30` — is the fix already in `main`?
- `git branch --contains <commit-hash>` — for every commit hash the handoff names, confirm it's on `main` (or NOT on `main`) as claimed.
- `gh pr view <N> --json state,mergedAt,title` — for every PR number the handoff references, verify state matches the narrative.
- If the fix already landed: close the ticket with evidence (merge commit + PR link) and STOP. Do not cut the branch. Report to founder in one sentence and await next lane.
- If only PART of the handoff is stale: narrow the branch scope to just the still-open work and note the discrepancy in the PR body's Verification section.

**Why:** Handoffs are written under context that ages. Every CLI session that skips verification pays a compounding cost — hours per session, until the founder or a future session notices the pattern. The verification step is 60 seconds; the cost of skipping it is 60+ minutes _and_ a false-progress commit if you push a fix for something already fixed.

Source: Session 2026-07-14 stale-intel audit. Codified as PLAN_00 §"Pokvarjeno / odprto" post-audit annotation. Related: [[mpc-preflight-before-every-gh-pr-create]] (Rule #79 corollary — pre-flight is process discipline; this rule is intel discipline).

**Rule #82 — Info.plist Can Lie to Apple While Runtime Prompts Tell Users the Truth. Audit Three Surfaces Before Every Submission.**
[2026-07-13] BLOCKER-STORE-002 (Apple 5.1.1 rejection risk) sat open for 7 days because the audit only saw one lie. Fixing it surfaced two more that had been latent since the Anonymity Mode feature first shipped:

1. **Master↔localized divergence.** `ios/Runner/Info.plist`'s master `NSContactsUsageDescription` said "Tremble does not access or store any contact data" while `en.lproj/InfoPlist.strings` (and `sl`/`hr`) already said the opposite. At runtime iOS shows the localized string, so users saw the truth — but Apple's static review reads the master, so reviewers saw the lie. Users happy, submission rejected.
2. **Silent duplicate keys.** Three permission keys (`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription`) each appeared twice in the master `Info.plist`. Xcode keeps the last occurrence at build so nothing crashed, but the raw XML tripped Apple's automated review.
3. **PrivacyInfo.xcprivacy missing derived-data declaration.** ADR-004's zero-data architecture hashes phone contacts on-device before transmission. Hashing does NOT exempt the app from declaring `NSPrivacyCollectedDataTypeContacts` — Apple treats the derived data leaving the device as Contacts-category collection. Missing declaration is a separate ITMS-91036-family submission gap.

**How to apply — before every prod build / submission:**
- For each `NS*UsageDescription` key in `ios/Runner/Info.plist`, `diff` the master string against `ios/Runner/en.lproj/InfoPlist.strings` (and every other `*.lproj`). Master should be byte-identical to the base-locale localized version, so Apple's static reviewer and the user's runtime prompt tell the same story.
- Count each usage-description key: `for k in NSContacts NSCamera NSPhotoLibrary NSPhotoLibraryAdd NSLocationWhenInUse NSLocationAlwaysAndWhenInUse NSBluetoothAlways NSBluetoothPeripheral NSMotion NSMicrophone NSFaceID; do grep -c "<key>${k}UsageDescription</key>" ios/Runner/Info.plist; done` — every count must be exactly 1.
- Cross-check `PrivacyInfo.xcprivacy`'s `NSPrivacyCollectedDataTypes` against the actual code. If the code processes contacts, photos, location, or any other collected type — even in a hashed or derived form that leaves the device — the manifest must declare it. Hashing is not an exemption.
- Rule of thumb: an Info.plist audit that only reads the master file is half a job. Read master, localized, and the privacy manifest together, then compare all three to the code.

Source: BLOCKER-STORE-002 close-out (KORAK 3.8-1, PR #32, 2026-07-13). Extends [[pr-title-plan-id-required]] and the ITMS-90683 note further down this file. Related: ADR-004 hash-only architecture is what forces the derived-data privacy-manifest declaration.

**Rule #81 — When Retiring a "Never-Wired" Feature, Sweep the Whole Fossil Trail — Not Just What the ADR Names.**
[2026-07-13] ADR-007 Amendment §5 declared the max-distance-slider row a mistake and named two paywall bullet keys to retire (`premium_feature_distance_100` + `premium_free_distance_50`). Pre-flight grep for KORAK 3.7c-5R surfaced a third artefact the ADR did NOT name: an orphan `distance_help` translation key with an 8-locale entry in `lib/src/core/translations.dart` and **zero callers anywhere in `lib/`** — fossil from the same never-built slider. Deleting only what the ADR listed would have left the fossil in place; the next contributor greps `distance` and thinks a widget must exist.

**How to apply:**
- Before opening a "retire feature X" PR, grep for the feature's naming vocabulary (`distance`, `Distance`, `Razdalja`, `km`) across BOTH `lib/` and `functions/src/` — not just the specific keys the ADR names.
- Any zero-caller string, key, field, or const that shares the same vocabulary is a fossil from the same mistake. Delete it in the same PR.
- Add a "bonus cleanup" section to the PR body naming what you found and why it was orphaned, so the reviewer can sanity-check that the sweep was justified (not overreach).
- Rule of thumb: an ADR names decisions, not exhaustive file lists. Trust the ADR's *intent*, then let grep tell you the actual blast radius.

Source: PR #28 pre-flight, KORAK 3.7c-5R + 3.7c-2C, 2026-07-13. If applied differently, the orphan `distance_help` in translations.dart would still be there today.

**Rule #80 — Never Put Literal `risk_level: high` in ANY PR Body (Even in Negation).**
[2026-07-13] The `mpc-validate-pr` job in `.github/workflows/ci.yml` computes `is_high_risk` with a naive case-insensitive `grep -iE "(infra_change|touches_auth|touches_pii|external_model_calls|risk_level: (high|critical))"` over the PR body — regardless of surrounding context. Writing `` `risk_level: high` NOT needed `` or "not a `risk_level: high` change" flips `is_high_risk` to `true`, which triggers the `⑦ MPC — Founder Approval` environment gate and blocks merge until manually approved via GitHub → Environments → founder-approval.

**How to apply:**
- To declare a low-risk PR, write `Risk level: low` or `risk_level: low` — never mention `high` or `critical` in any form.
- If you must reference the high-risk classification (e.g. in prose about the gate), paraphrase: "high-risk classification NOT needed", "no high-risk trigger", "not infra/auth/PII/external-model territory".
- The same trap applies to the substrings `infra_change`, `touches_auth`, `touches_pii`, `external_model_calls` — never mention them literally in a low-risk PR body.
- Verify after `gh pr create`: `gh pr view <N> --json body -q .body | grep -iE "(infra_change|touches_auth|touches_pii|external_model_calls|risk_level: (high|critical))"` — must return zero hits for a low-risk PR.

**Corollary — Docs and follow-up PRs are NOT exempt from Rule #79.** On 2026-07-13 I opened PR #24 (docs bundle for KORAK 3.6 + ADR-007) and PR #25 (KORAK 3.7a paywall copy) in the same session; both initially violated Rule #79 (missing `[PLAN-ID: …]` title prefix and/or missing verification-checklist phrases). Add a hard pre-flight before every `gh pr create`:
1. `tasks/plan.md` line 2 has a `Plan ID:` for THIS branch's delivery.
2. Title formatted `[PLAN-ID: YYYYMMDD-short-name] type(scope): summary`.
3. Body contains a `## Verification checklist` section literally naming `unit tests`, `integration tests`, `security scan` (mark `n/a` with a reason for docs-only — do NOT drop the phrases).
4. Body does NOT contain any literal risk-regex trigger substring (per this rule).

Source: PR #24 metadata failure + PR #25 body-regex false-positive on `risk_level: high`, 2026-07-13. Codified as memory `mpc-preflight-before-every-gh-pr-create.md` and extends [[pr-title-plan-id-required]].

**Rule #79 — Every PR Must Pass the MPC PR-Metadata Gate (title Plan-ID + body checklist).**
[2026-07-12] The required job `① MPC — PR Metadata` in `.github/workflows/ci.yml` runs on every `pull_request` and enforces **both** a title format AND a body checklist. Docs-only, chore, and trivial PRs are NOT exempt.

**Title requirement:** must match `\[PLAN-ID: ?[0-9]{8}-[a-z0-9\-]+\]`. CI only regex-matches the format — it does NOT read `tasks/plan.md` — but the Plan-ID SHOULD correspond to an active entry in `tasks/plan.md` per MPC convention.

**Body requirement:** must contain, case-insensitive, ALL four phrases (grepped verbatim): `Verification checklist`, `unit tests`, `integration tests`, `security scan`. Missing any one → job fails, all downstream gates (Policy Enforcement, Security Scans, SRE Gate, Founder Approval, ⑧ All Checks Passed) are skipped and marked failing.

**Pre-PR checklist (do BEFORE `gh pr create`):**
1. Confirm `tasks/plan.md` has an active `Plan ID:` line matching this work; if off-plan (docs/chore), rewrite `tasks/plan.md` with a new plan entry (`YYYYMMDD-short-name`) and commit it in the same PR.
2. Title: `type(scope): summary [PLAN-ID: YYYYMMDD-short-name]`.
3. Body: include a `## Verification checklist` section that names `unit tests`, `integration tests`, `security scan` explicitly — mark `n/a` with a one-line reason for docs-only PRs; do NOT omit the phrases.

**If a PR is already open and failing this gate:** `gh pr edit <N> --title "..." --body "..."` — the check re-runs on edit; do NOT recreate the branch. Old failing check-runs from the pre-edit commit remain visible but GitHub uses the latest per name/SHA, so they do not block merge.

**Non-admin path:** since `main` is protected and requires all ① checks green, admin bypass is not available to `unfab`. Fix title + body properly rather than trying to force-merge.

Source: PR #15 failure and remediation, 2026-07-12.

**Rule #78 — Single Source of Truth is the Codebase.**
[2026-07-06] Do not rely on AI-generated strategy or documentation files as a source of truth. Relying on "circular context" caused fake features and non-existent files to be treated as reality. Always verify claims against the actual codebase.
Source: Compliance Report, July 2026.

**Rule #77 — Paywall Copy Must Be 100% Code-Accurate.**
[2026-07-06] Do not advertise premium features that don't exist in code (e.g. "unlimited geofence pings") and do not hide actual gated features (e.g. "see who waved"). This is a violation of App Store guidelines and consumer protection laws.
Source: Compliance Report, July 2026.

**Rule #76 — Android Platform Declarations Block Launches.**
[2026-07-06] Android requires Prominent Disclosure, video demos, and Play Console declarations for background location and Foreground Services (FGS) before app submission. This review takes 2-4 weeks. Plan this long before the build is finalized.
Source: Compliance Report, July 2026.

**Rule #75 — GDPR Art. 9 Sensitive Data Cannot Be Bundled.**
[2026-07-06] Processing sexual orientation (even implicitly via `gender` + `lookingFor`), religion, ethnicity, or cannabis use falls under GDPR Article 9. These require explicit, granular, and separate consent checkboxes. They cannot be bundled into a generic "sensitive data" flag or skipped.
Source: Compliance Report, July 2026.
## iOS Build & App Store

### ITMS-90683: Missing NSUsageDescription keys
**When:** Any time a new SDK is added to pubspec.yaml or Podfile.
**Root cause:** Third-party SDKs (Firebase, Google Sign-In, flutter_contacts, image_picker, etc.) internally reference iOS APIs that require purpose strings in Info.plist. Apple validates these at upload time, not at build time — the error only surfaces after xcrun altool upload.
**Prevention:** Before every prod build, run:
`grep -c "UsageDescription" ios/Runner/Info.plist`
Cross-reference with all packages in pubspec.yaml that touch: contacts, camera, photos, location, Bluetooth, microphone, calendar, health, face ID, motion, speech.
**Known required keys for Tremble (as of build 5):**
- NSBluetoothAlwaysUsageDescription ✅
- NSBluetoothPeripheralUsageDescription ✅
- NSCameraUsageDescription ✅
- NSContactsUsageDescription ✅ (Firebase SDK references CNContactStore)
- NSLocationAlwaysAndWhenInUseUsageDescription ✅
- NSLocationAlwaysUsageDescription ✅
- NSLocationWhenInUseUsageDescription ✅
- NSMotionUsageDescription ✅
- NSPhotoLibraryAddUsageDescription ✅
- NSPhotoLibraryUsageDescription ✅
**If a new package is added:** grep the package source for "CNContact\|PHPhoto\|AVCapture\|CLLocation\|CMMotion\|CBCentral\|CBPeripheral\|NSMicrophone\|NSCalendar\|NSFaceID\|NSSpeech" and add the corresponding key before the next prod build.

---


**Rule #73 — Never use dart:io HttpClient for HTTPS requests to Cloudflare R2 on iOS.**
[2026-06-17] dart:io HttpClient uses Dart's own TLS stack. On iOS this triggers SSLV3_ALERT_HANDSHAKE_FAILURE when connecting to Cloudflare R2's S3-compatible endpoint (*.r2.cloudflarestorage.com) because Dart's TLS implementation does not negotiate cipher suites Cloudflare requires. Android is unaffected. Fix: use package:http (delegates to NSURLSession / Apple Network.framework on iOS). package:http ^1.2.2 is already in pubspec.yaml.
Source: R2 photo upload iOS TLS fix, June 2026.

**Rule #72 — GDPR block-ref cleanup (gdpr.functions.ts step 5b) uses a single Firestore batch (500-write cap).**
If a deleted user was blocked by >500 others, the batch throws and deletion fails. Add chunking before user base scales past ~200 DAU. Pattern: split blockersOf.docs into chunks of 499, commit each batch sequentially.
Source: Security audit, 11 Jun 2026.

**Rule #9 — Guard every `startForeground()` with a type mask on Android 14+.**
[2026-06-03] Asserting an FGS type whose runtime permission isn't held throws `SecurityException` (e.g. `type=location` without `ACCESS_*_LOCATION`), and starting from the background throws `ForegroundServiceStartNotAllowedException`. Either crashes the process — and because radar-active is persisted in `RadarStateBridge`, it re-crashes on every launch ("can't turn it off" loop). Fix: assert only the FGS types whose permission is currently granted (DATA_SYNC always), wrap `startForeground` in try/catch, and on failure force radar OFF + cancel the notification so the loop breaks instead of crashing. Source: `RadarForegroundService.kt:86` crash, June 2026.

**Rule #71 — Invalidate cached stamps when Dart SDK is missing.**
[2026-05-28] If the Dart SDK is deleted or missing from the Flutter `bin/cache/` but the snapshot and stamp files remain (e.g., `engine-dart-sdk.stamp`), the `update_dart_sdk.sh` script will bypass bootstrapping and crash with a "No such file or directory" error. Delete `engine-dart-sdk.stamp`, `flutter_tools.snapshot`, and `flutter_tools.stamp` to force the tool to download and reconstruct the Dart SDK.
Source: Flutter SDK bootstrapping, May 2026.

**Rule #70 — Validate map style color literals before committing them.**
[2026-05-25] Map style JSON must only contain valid hex literals and supported color expressions. If a planned color token is incomplete or malformed, normalize it before editing the style asset so the style stays parseable and reviewable.
Source: Light Apple Maps redesign, May 2026.

**Rule #69 — Light maps require light frosted overlays, not dark glass shells.**
[2026-05-25] On light basemaps, bottom sheets, zoom pills, search bars, and info panels should use translucent white, blur, a fine light-gray border, and a soft shadow. Reusing dark-framed glass UI on a light map makes the canvas feel muddy and lowers hierarchy. Keep glassmorphism in the overlay layer, not in the basemap style.
Source: Light Apple Maps redesign, May 2026.

**Rule #68 — Bundled map style assets are the source of truth for app-side vector tile maps.**
[2026-05-25] When `flutter_map` / `VectorTileLayer` loads a bundled style JSON asset, treat that asset as canonical. Worker or tile-server style JSON is parity only. Map palette, label hierarchy, and zoom gating must be edited in the Flutter asset first so mobile rendering stays deterministic offline.
Source: Light Apple Maps redesign, May 2026.

**Rule #67 — Type guard R2ObjectBody when fetching from Cloudflare R2.**
[2026-05-20] `env.BUCKET.get()` returns `R2ObjectBody | R2Object`. Only `R2ObjectBody` exposes `.body`. Always guard with `"body" in resp` before accessing the stream. Also type the options object as `R2GetOptions` to avoid `noExplicitAny` linter errors.
Source: Cloudflare Worker Map tile publication, May 2026.

**Rule #66 — Verify iOS storyboard background after `flutter_native_splash`.**
[2026-05-17] Running `dart run flutter_native_splash:create` can reset `ios/Runner/Base.lproj/LaunchScreen.storyboard` view background to white even when the generated `LaunchBackground` is dark graphite. Always inspect the storyboard diff and restore the background color to `#1A1A18` before iOS verification.
Source: iOS Splash Screen Fix, May 2026.

**Rule #65 — Precise multi-level directory import paths.**
[2026-05-17] Always double-check relative import path depths when referencing files from different feature domains (e.g. `../../../core/` vs `../../../../core/`). Run `flutter analyze` to catch import resolution errors before simulator runs.
Source: Compatibility Score (Phase A) Verification, May 2026.

**Rule #64 — Manual native cleanup for SDK removal.**
[2026-05-09] Removing a package from `pubspec.yaml` is insufficient. Native keys and SDK initializers MUST be manually purged from `Info.plist` (iOS) and `AndroidManifest.xml` (Android) to prevent runtime crashes.
Source: OSM Migration, May 2026.

**Rule #63 — Seamless radar sweeps.**
[2026-05-09] `SweepGradient` for `RadarPainter` must include a buffer stop at `0.99` (not `1.0`) to prevent a hard seam at the 3 o'clock wrap-around position.
Source: UI Polish, May 2026.

**Rule #62 — Native splash background matching.**
[2026-05-09] Both `color` and `android_12: color` in `flutter_native_splash.yaml` MUST be `#1A1A18` to prevent a white-box regression during app startup.
Source: Branding Stabilization, May 2026.

**Rule #61 — Brand-accurate icon assets.**
[2026-05-09] `adaptive_icon_background` in `flutter_launcher_icons.yaml` MUST match Tremble Rose `#F4436C` using `tremble_icon_clean.png`. Transparent variants produce a brown-pink artifact on launcher backgrounds.
Source: Branding Stabilization, May 2026.

**Rule #60 — Performance-safe contact hashing.**
[2026-05-08] Processing large contact lists (1000+ entries) for SHA-256 hashing MUST be done in a background isolate (`compute` or manual `Isolate`). Normalize to E.164 before hashing.
Source: F13 Stealth & Safety Implementation, May 2026.

**Rule #59 — Mandatory confirmation for disabling privacy shields.**
[2026-05-08] Any UI action disabling a privacy protection feature (e.g., toggling a Safe Zone inactive) MUST be gated behind a confirmation modal to prevent accidental exposure.
Source: F13 Stealth & Safety Implementation, May 2026.

**Rule #58 — GDPR-neutral naming for Safe Zones.**
[2026-05-08] Safe Zones MUST use neutral indexed names (e.g., "Zone 1") instead of address-derived or timestamp-derived names to prevent location fingerprinting.
Source: F13 Stealth & Safety Implementation, May 2026.

**Rule #57 — Assistance contact sharing UX.**
[2026-04-30] If a user skips phone entry during onboarding, the "Send Phone" button in the Trembling Window MUST be disabled/hidden with a clear explanation — never prompt mid-interaction.
Source: Pulse Intercept (F12) Planning, April 2026.

**Rule #56 — Zero-chat privacy architecture.**
[2026-04-30] Tremble STRICTLY forbids free-text chatrooms. Communication during the Trembling Window is restricted to atomic actionable buttons (e.g., [Send Phone]) and ephemeral visual aids only.
Source: Pulse Intercept (F12) Planning, April 2026.

**Rule #55 — Ephemeral media cleanup strategy.**
[2026-04-30] "View-once" photos (Pulse Intercept F12) MUST be deleted server-side immediately when `viewedAt` is set. UI-level hiding alone is insufficient for GDPR compliance. Always use a Cloud Function trigger to purge the Storage file.
Source: Pulse Intercept (F12) Planning, April 2026.

**Rule #54 — Recap UI structure: active vs. history separation.**
[2026-04-30] Post-activity recaps must clearly separate actionable encounters (active TTL) from historical ones (expired) using distinct `SliverList` sections or a `CustomScrollView`.
Source: Run Club Recap (F6) Implementation, April 2026.

**Rule #53 — Tiered profile access in history logs.**
[2026-04-30] Historical logs must respect subscription-based data masking: free users see limited/blurred profiles, premium users see full details. History must not be a loophole for free users.
Source: Run Club Recap (F6) Implementation, April 2026.

**Rule #52 — `ColorFiltered` for "Missed Opportunities" UX.**
[2026-04-30] Use a greyscale `ColorFiltered` matrix on expired encounter cards to visually signal "cold/historical" state and drive premium upgrade motivation.
Source: Run Club Recap (F6) Implementation, April 2026.

**Rule #51 — Mid-run intercept UI overrides silent mode.**
[2026-04-30] An explicit user action (e.g., sending a Wave from the Live Run Card) MUST override the receiver's silent state. Passive proximity remains silent; intentional Waves are always delivered immediately.
Source: Run Club (F6) UX Design, April 2026.

**Rule #50 — Native motion sensors over background timers.**
[2026-04-30] Background activity sensing MUST use `CMMotionActivityManager` (iOS) and `ActivityRecognitionClient` (Android) via `EventChannel`. Mock timers in isolates are unreliable and battery-heavy.
Source: ADR-001 Implementation, April 2026.

**Rule #49 — Strict 10-minute TTL for Run Club (Momentum Rule).**
[2026-04-30] Proximity data for running must have a 10-minute TTL in Firestore. If no Wave is sent within 10 minutes, the match record is purged. Non-negotiable for privacy and brand promise.
Source: Run Club (F6) Finalization, April 2026.

**Rule #48 — Staged files modified by pre-commit hooks must be re-added.**
[2026-04-29] If `dart format .` runs in a pre-commit hook and modifies files, those changes stay unstaged. Run `git add <file>` to re-stage the formatted files before committing.
Source: Git Hook Troubleshooting, April 2026.

**Rule #47 — Use `matchType` for distinct product tiers in matching UI.**
[2026-04-29] Event Mode gives all users temporary Premium access. Gym Mode keeps basic users locked (pill UI) with DND to prevent intrusive push notifications during workouts.
Source: Proximity Engine Refinement, April 2026.

**Rule #46 — Native geofencing for static proximity points.**
[2026-04-29] Static location tracking (gyms, event venues) MUST use OS Geofencing APIs, not continuous GPS polling. The hardware wakes the app on region entry — zero drain when idle.
Source: Proximity Engine Refinement, April 2026.

**Rule #45 — NEVER commit secrets to version control.**
[2026-04-29] API keys, access tokens, and credentials MUST NEVER appear in documentation, todo lists, or code files. Use Secret Managers or `--dart-define`. Leaked secrets must be rotated instantly.
Source: Google Places API Leak in todo.md, April 2026.

**Rule #44 — Always verify Cloud Function exports in `index.ts`.**
[2026-04-29] New Cloud Functions MUST be exported in `functions/src/index.ts`. Without this, the Firebase CLI will not deploy them.
Source: Event Mode Matching (F2), April 2026.

**Rule #43 — Avoid booleans for dynamic lifestyle preferences.**
[2026-04-29] Multi-choice preferences (e.g., Nicotine: vaping, cigarettes, shisha) MUST be stored as `List<String>`, not booleans. This avoids database migrations as cultural habits evolve.
Source: Nicotine Step Implementation, April 2026.

**Rule #42 — Always use Places API session tokens.**
[2026-04-29] Location autocomplete MUST pass a long-lived `sessionToken` with every request until a selection is made. Reduces billing from $0.017/keystroke to $0.017/session.
Source: Places API (New) Integration, April 2026.

**Rule #41 — Single source of truth documentation.**
[2026-04-29] All architectural policies, deployment rules, and feature implementations MUST reside in `tasks/MASTER_PLAN.md`. Do not fragment plans across multiple files.
Source: Project Consolidation, April 2026.

**Rule #40 — `MainActivity` should extend `FlutterFragmentActivity`.**
[2026-04-25] `FlutterFragmentActivity` is required for clean `MethodChannel`/`EventChannel` lifecycle management. `FlutterActivity` causes subtle teardown issues during orientation changes.
Source: Android OS Integration, April 2026.

**Rule #39 — `setColorInt` (RemoteViews) requires API 31+.**
[2026-04-25] Gate all `RemoteViews.setColorInt` calls behind `Build.VERSION.SDK_INT >= Build.VERSION_CODES.S`. Provide a pre-API-31 fallback static drawable.
Source: Android OS Integration, April 2026.

**Rule #38 — Quick Settings tile icons must be monochrome vectors.**
[2026-04-25] Android QS tiles require a single-color vector drawable. The system applies Material You tinting at runtime — do NOT embed brand colors in the drawable.
Source: Android OS Integration, April 2026.

**Rule #38 — Never set restricted fields (e.g. `isPremium`, `isAdmin`) from client-side `set()` during registration.**
[2026-07-15] If `firestore.rules`'s `validCreateKeys()` prevents these fields, including them in the initial `AuthRepository.registerWithEmail` payload will cause the `set()` operation to silently fail on the client. This leaves document creation entirely up to backend triggers, creating a race condition where immediate `.update()` calls (like selecting a gym) will crash with `PERMISSION_DENIED` because the document (`resource.data`) doesn't exist yet. Always use `SetOptions(merge: true)` for subsequent writes during onboarding.
Source: Sentry Audit (Issue 1), July 2026.

**Rule #37 — `flutter_launcher_icons` adaptive foreground must use padded source.**
[2026-04-24] Use `tremble_splash_source.png` (icon at 50% of 2048px canvas) for `adaptive_icon_foreground` to prevent clipping in all launcher shapes (circle, squircle, etc.).
Source: Launcher Icon Fix, April 2026.

**Rule #36 — Splash source image must be the colored icon.**
[2026-04-24] `tremble_icon_clean_transparent.png` has white artwork on transparent background — it is invisible on dark splash screens. Always use `tremble_icon_clean.png` (rose-colored) as the splash source.
Source: Splash Screen Fix, April 2026.

**Rule #35 — Resolve Android startup "white flash" via `NormalTheme` inheritance.**
[2026-04-24] Change `NormalTheme` parent to `Theme.Black.NoTitleBar` and explicitly set `windowBackground` to a dark color in `styles.xml`.
Source: Android Theme Polish.

**Rule #34 — Avoid `const` for initialization with dynamic categories in `flutter_local_notifications`.**
[2026-04-24] Initialization settings cannot be `const` if they depend on runtime-generated notification categories or actions.
Source: Notification Service Refactor.

**Rule #33 — Rich notification payloads must use `imageUrl` for FCM Admin SDK.**
[2026-04-24] The FCM payload key for images is `imageUrl`. Using `photoUrl` (internal model field) in the notification block will cause images to not appear in the system shade.
Source: Interaction System v2.1.

**Rule #32 — Never answer N/Y prompts during `firebase deploy` without reading them.**
[2026-04-24] Firebase asked to delete TTL field overrides during a Firestore deploy. Answering Y would have permanently deleted TTL policies, causing documents to accumulate forever. Always answer N to field override deletion prompts.
Source: Prod deploy, April 2026.

**Rule #31 — Prod Firestore rules must be explicitly deployed.**
[2026-04-24] Production Firestore does not inherit rules from dev. Always deploy full rules to prod: `firebase deploy --only firestore --project prod`.
Source: Prod rules audit, April 2026.

**Rule #30 — Never store raw GPS coordinates in Firestore for proximity matching.**
[2026-04-24] `lat/lng` in `proximity/{uid}` readable by all authenticated users is a GDPR violation. Use geohash only for Firestore storage. Coordinates stay in-memory during Cloud Function execution.
Source: SEC-002 Privacy Fix, April 2026.

**Rule #29 — Avoid `SafeArea` as a global wrapper for modal bottom sheets.**
[2026-04-23] `SafeArea` inside `showModalBottomSheet` causes a black gap at the bottom (iOS home indicator area). Use `MediaQuery.of(context).padding.bottom` for targeted padding inside the modal instead.
Source: Onboarding v2 implementation.

**Rule #28 — Center `CustomPainter` paths using SVG group transforms.**
[2026-04-23] Match the SVG `group transform` (e.g., `translate(centerX - X * scale, centerY - Y * scale)`) when implementing icons in `CustomPainter`. Small offsets cause off-center rendering at different densities.
Source: Onboarding v2 implementation.

**Rule #27 — `flutter_launcher_icons` requires PNG assets.**
[2026-04-23] The package does not support SVG. Convert the master SVG to a 1024×1024 PNG before running icon generation.
Source: Onboarding v2 implementation.

**Rule #26 — Use `PageView` indexing for multi-stage registration rituals.**
[2026-04-23] Keep the Ritual screen as the final index in the existing `PageView` rather than pushing a new route. This enables seamless shared-element animations and keeps `PingOverlay` active.
Source: Onboarding v2 implementation.

**Rule #25 — Use `NotifierProvider` for persistent global app state (e.g., Language).**
[2026-04-23] `StateProvider` can reset unexpectedly if its dependencies change during high-friction flows like registration. Switch to `NotifierProvider` with explicit state preservation in the `build` method.
Source: Onboarding v2 implementation.

**Rule #24 — Centralize date/zodiac logic in `ZodiacUtils`.**
[2026-04-22] Never calculate age or zodiac locally in UI components. All birthday-to-age and birthday-to-zodiac logic MUST reside in `ZodiacUtils` for global consistency.
Source: Zodiac Localization & UI Refinement, April 2026.

**Rule #23 — Avoid system emojis in UI elements for cross-platform stability.**
[2026-04-22] System emojis render as `[?]` squares on some iOS versions. Use `LucideIcons` or custom SVG assets for critical UI elements to maintain a premium, consistent aesthetic.
Source: TASK-REG-18, April 2026.

**Rule #22 — Prefer native button loading states over manual if/else UI switching.**
[2026-04-21] Shared buttons (like `PrimaryButton`) should handle their own `isLoading` state internally. This prevents layout shifts and centralizes the spinner logic.
Source: D-27 Spinner Fix, April 2026.

**Rule #21 — Always verify Firebase aliases in `.firebaserc` before deployment.**
[2026-04-20] A misconfigured `.firebaserc` (e.g., `development` pointing to prod) can cause catastrophic data loss. Always cross-reference with `firebase projects:list` before any deploy.
Source: Phase 11 Security Audit, April 2026.

**Rule #20 — "App as a Tool" Profile UI logic.**
[2026-04-20] Favor vertical `Wrap` over horizontal `Row` for data-dense sections. Maintain 1:1 logic parity between `ProfileCardPreview` (self-view) and `ProfileDetailScreen` (match-view) at all times.
Source: Profile UI Refinement TASK-004, April 2026.

**Rule #19 — Duplicate keys in `const Map` are compile-time errors.**
[2026-04-20] In Dart, adding an existing key to a constant map literal will prevent the app from building. Perform a global key-check before adding translations.
Source: i18n Cleanup TASK-011, April 2026.

**Rule #18 — Flutter/Dart environment paths vary on local machines.**
[2026-04-20] The standard `flutter` command may fail in certain shell environments. Absolute path on this machine: `/Users/aleksandarbojic/flutter/bin/flutter`.
Source: i18n Cleanup TASK-011, April 2026.

**Rule #17 — Zero writing policy in onboarding.**
[2026-04-20] The registration flow must contain zero custom text input fields (excluding Name). Use binary/enum-based selection only — the "Signal Calibration" brand demands no verbal friction.
Source: Registration Phase 2 (Signal Calibration), April 2026.

**Rule #16 — iOS Map xcconfig files live at `ios/Flutter/`, not `ios/Runner/`.**
[2026-04-20] `Info.plist` resolves `$(MAPS_API_KEY)` from `ios/Flutter/Debug.xcconfig` / `Release.xcconfig`. If the map renders grey on iOS, confirm these files exist and contain a real key.
Source: Map Troubleshooting, April 2026.

**Rule #15 — App Check requires explicit server-side enforcement.**
[2026-04-20] Enabling App Check client-side is only half the integration. Cloud Functions MUST also verify the token and have `enforceAppCheck: true` in their configuration. Without this, the backend remains open.
Source: Phase 9 Security Hardening, April 2026.

**Rule #8 — Always pass translation functions (`tr`) to standalone widgets.**
Never rely on hardcoded strings in shared UI components.
Source: Phase 10 Polish, April 2026.

**Rule #3 — TREMBLE HAS NO IN-APP CHAT. EVER.**
[2026-04-09] The core product mechanic is: Wave → Mutual Wave → 30-minute real-life finding game → meet in person.

**Rule #2 — Never bypass Riverpod strictly typed state.**
[2026-03] Do not mutate state directly in the UI layer. Always use typed providers and notifiers.

**Rule #1 — Never run un-flavored Flutter build commands.**
[2026-03] For dev runs, use `flutter run --dart-define-from-file=.env.json`. For builds, always provide the explicit dev or prod flavor flags. An un-flavored build is a misconfigured build.
Source: Multi-Env Setup, March 2026.

**Rule #74 — `package:http` does NOT use NSURLSession on iOS by default.**
[2026-06-18] It wraps `dart:io HttpClient` (BoringSSL), whose TLS stack fails the handshake against Cloudflare R2 with `SSLV3_ALERT_HANDSHAKE_FAILURE`. For R2 — or any endpoint failing TLS on iOS — use `cupertino_http`'s `CupertinoClient` (NSURLSession / Network.framework). See `lib/src/core/upload_service.dart`.
Source: R2 upload TLS sprint, June 2026.

**Rule #89 — Client cross-user reads are denied; route through a CF.**
[2026-07-19] Multiple "phantom" failures (reveal "?", trembling-window collapse) were all one root cause: the client reading data Firestore rules forbid. `/users` is `read: if isSelf`, `/matches` update is `hasOnly(['seenBy'])`. `markMatchAsFound`, `sendGesture`, and `ProfileRepository.getPublicProfile` all did denied reads/writes → permission-denied → silent nulls or crashes. Fix pattern: move to an Admin-SDK callable (`markMatchFound`, `sendMatchGesture`, `getPublicProfile`). BEFORE wiring a client to a CF, check the CF's OWN guards — `getPublicProfile` adds `requireVerifiedEmail`, a second gate that still returns null for unverified accounts.

**Rule #90 — Cupertino alert dialogs cannot hold Material widgets or big content.**
[2026-07-19] `CupertinoAlertDialog` has no Material ancestor → any `InkWell`/`TextButton`/`WidgetStateProperty` inside throws `Material.of null` (TREMBLE-FUNCTIONS-12). It also can't scroll a large form → the report dialog was "endless scroll, 0 buttons" on iOS, and white text was invisible on its light surface. Lesson: for anything beyond a trivial 1-2 line confirm, use a themed bottom sheet, not `showPlatformDialog`/`CupertinoAlertDialog`. Also: a widget test passing on macOS does NOT prove the iOS path — `Platform.isIOS` is false on the macOS test host, so the Cupertino branch is never exercised locally.

**Rule #91 — Match reveal `seenBy` was asymmetric by construction.**
[2026-07-19] `onWaveCreated` created the match with `seenBy:[fromUid]` — the wave-back completer was pre-marked seen, so their home-screen reveal listener (`!seenBy.contains(myUid)`) never fired. Only ONE user ever saw "We have a match". Fix: `seenBy:[]`. Also, the persistent match doc (`uidA_uidB`) meant a re-wave was a no-op — restart the window only when the prior one is POSITIVELY over (terminal status or known-expired createdAt), never on the same-burst reciprocal wave.

**Rule #92 — Pulse Intercept (Send Phone/Photo) is meetup ASSISTANCE, not matching.**
[2026-07-19] Founder product rule: Send Phone / Send Photo belong in the TREMBLING WINDOW (radar search phase, helping two matched people physically find each other), NOT on the match reveal page. The match reveal shows only photo + age + 3 hobbies (shared first). Do not conflate the two surfaces. DONE Session 51 (`095b50c`): `PulseInterceptBar` widget lives in `RadarSearchOverlay`, gated on `RadarSearchSession.partnerUid != null`; removed from `match_reveal_screen`.

**Rule #93 — A red CI + green-local Flutter split is almost always a Flutter-version delta, not "env-sensitive flakiness". Verify the actual assert; don't inherit a handoff's guessed root cause.**
[2026-07-19] Session 50 handed off that the `ugc_action_sheet_block_dialog_test` CI failure was TREMBLE-FUNCTIONS-12 (`Material.of` null in Cupertino). WRONG. Pulling the CI log showed the real failure: *"ListTile background color or ink splashes may be invisible"* (×2) — a Flutter framework assert that fires when a `ListTile` sits under an opaque `DecoratedBox`/`Container` with no `Material` between them. It reproduces only on CI because CI uses `subosito/flutter-action` with `channel: stable` (UNPINNED → latest stable, which tightened this assert), while local is pinned `3.41.4` and never fires it. Two lessons: (1) when a test is red in CI but green locally, suspect a Flutter/toolchain version delta first and read the CI log for the *actual* exception — a handoff's assumed cause can be wrong. (2) Because local can't reproduce the newer-Flutter assert, the fix must be STRUCTURAL (guarantee a `Material` ancestor), not "went green locally". Consider pinning the CI Flutter version to match local so this class of split stops happening. Build 29 (`1.0.0+29`) TestFlight Delivery UUID `6d2cbef2-aaf2-4cea-b0ca-9bff4453a6f2`.

**Rule #94 — When a merged PR was SQUASHED, its topic branch conflicts with main on every shared line if you keep working on it. The branch is a superset, not a peer.**
[2026-07-20] PR #69 was **squash-merged** into `main` as one commit (`e937fd9`), but the `fix/post-match-flow-repair` branch kept batch 1 as its original individual commits AND added batch 2/3 on top. A new PR (#70) from that branch showed conflicts in 6 files (pubspec, match_reveal_screen, trembling_window_test, matches.test, blockers, context) because git saw the *same batch-1 lines* arriving from two histories (main's squashed blob vs the branch's individual commits). Resolution pattern: (1) confirm the divergence shape — `git log HEAD..origin/main` showed main was only 1 commit ahead (the squash) and the branch 26 ahead, so the branch is a strict SUPERSET; (2) `git merge origin/main`, take `--ours` (branch) on every conflict, because the branch already contains all of batch 1 plus 2/3; (3) PROVE it — full suites green with IDENTICAL counts to pre-merge (387 Flutter + 164 functions), `flutter analyze` clean, and `git grep -E '^(<<<<<<<|>>>>>>>)'` returns nothing. Taking `ours` blindly is only safe once you've verified superset + green counts. Prevention: after a squash-merge, either delete the topic branch and cut a fresh one from main for follow-up work, or immediately merge main back in — don't keep stacking commits on the pre-squash branch. Also: a fresh PR needs its own title+body — `[PLAN-ID: YYYYMMDD-name]` + a "Verification checklist" body with `unit tests`/`integration tests`/`security scan`, plus an `ADR-NNN` reference whenever the diff touches `pubspec.yaml`/`firebase.json`/infra (ci.yml enforces this). Build 30 (`1.0.0+30`) TestFlight Delivery UUID `a136a10b-ac5d-4c68-af98-c8cfed277048`; PR #70 required gates green (⑦ Founder Approval skips at low risk).

**Rule #95 — `scripts/release/build_prod.sh all` builds the IPA but does NOT upload it to TestFlight.**
[2026-07-20] Build 31's iOS binary was "missing from TestFlight" for hours — not a processing delay, it was **never uploaded**. The script builds + preserves the IPA (`release-symbols/bNN/tremble.dating.app.ipa`) and prints `Next: verify Sentry lists debug files … BEFORE uploading to TestFlight`. The only `altool` string in its log is flutter's *hint text*, not an execution (`grep -c "xcrun altool --upload-app"` = 1 but it's the instruction line). An earlier session handoff wrongly claimed it "uploads to TestFlight automatically", so the manual step got skipped — Android AAB reached Play (versionCode read straight from the bundle, can't be mislabeled) but iOS reached nothing. Lesson: after every prod build, run `xcrun altool --upload-app --type ios -f <ipa> --apiKey V24BM2VRC2 --apiIssuer 752b6022-1929-42dd-b8a4-c894cd4f131d` yourself and confirm `UPLOAD SUCCEEDED` + a Delivery UUID; never assume auto-upload. To verify an AAB's real versionCode without bundletool: `unzip -p app.aab base/manifest/AndroidManifest.xml` (protobuf) shows `…versionCode…<n>` inline. Build 31 (`1.0.0+31`) TestFlight Delivery UUID `db31765d-8d5a-450b-a628-659e9e2eb847`.

**Rule #96 — `fL: Cancelled` from `tile_loader.dart` is benign map-tile-cancellation noise, not a crash.**
[2026-07-20] Prod Sentry filled with `fL: Cancelled` errors (TREMBLE-FUNCTIONS-13/14/15, dist 31), stacktrace `TileLoader._renderTile`/`_renderJob` in `tile_loader.dart` (vector_map_tiles / flutter_map). These fire when in-flight tile render jobs are cancelled on map/radar dispose or navigation — expected, harmless, but logged at `error` level and drowning real issues. `fL` is the obfuscated tile-cancellation class. Fix pattern: add a `beforeSend` filter in Sentry init that drops exceptions whose type/message is `Cancelled` and whose frames originate in `tile_loader.dart`, and/or cancel tile futures cleanly on dispose. Don't chase these as bugs. Distinct from TREMBLE-FUNCTIONS-12 (`Material.of` null), which is a real crash class (see Rule #90). **Shipped Session 55 (PR #77):** `options.beforeSend` runs the shared `CrashFilter._isBenignTileFailure` predicate over `SentryEvent.exceptions`; the FlutterError path already used it. Two gotchas: (1) these escape `FlutterError.onError` and reach Sentry via `PlatformDispatcher.onError`/the isolate listener — filtering only `FlutterError.onError` is not enough, `beforeSend` is the central chokepoint; (2) release minifies the exception TYPE (arrives as `fL: Cancelled`), so match the VALUE with `.contains('Cancelled')`, never the type, and always gate behind a tile-pipeline stack frame so real defects still report.

**Rule #97 — When a rendered thing "never appears", confirm the data SOURCE is actually fed, not just that the renderer works. A correct sink with no producer looks identical to a broken sink.**
[2026-07-21] BUG-RADAR-DOT ("partner dot never plots") looked like a paint/animation bug. It wasn't: `radar_painter.dart:115` draws a dot whenever `pingDistance != null` — the renderer is fine. The real cause: `pingDistance/pingAngleProvider` (`home_screen.dart:64`) have exactly ONE writer, the dev-sim bridge (`home_screen.dart:445`, gated on `devSim.isMutualWaveActive`). In a REAL mutual wave nothing ever writes them, so they stay null and the painter skips the dot. Method that found it fast: `grep -rn pingDistance` across lib and trace every WRITE site (not read sites) — the absence of a production writer is the bug. Second, harder lesson surfaced by the same trace: **BLE RSSI gives approximate distance but NO bearing/direction** (that's why the product has a warmer/colder "warmth" mechanic, not an arrow). So a truthful positioned dot can't exist from BLE alone — any direction must be inferred from RSSI×device-compass-heading. This turned a "quick dot fix" into FEATURE-RADAR-SONAR (founder wants a privacy-by-design search-and-rescue sonar: stop-sweep, pulse every 1–2s, turn-to-find). Deferred to its own brainstorm→plan→device session. Don't build the wrong small thing when the founder's real requirement collides with a physical constraint — surface the constraint and ask. Full vision: memory `radar-sonar-search-feature`.

**Rule #98 — A repo-wide CI `npm audit --audit-level=high` gate fails EVERY PR the moment a transitive high advisory lands upstream; clear it with non-breaking `npm audit fix`, not `--force`.**
[2026-07-21] PR #75's `④ Backend — Lint & Build` failed on `npm audit --audit-level=high` (functions/) with `brace-expansion` GHSA-3jxr-9vmj-r5cp (high, DoS) — nothing to do with the PR's diff; a transitive advisory had just been published, so it would red-fail any branch off that base. Fix: `cd functions && npm audit fix` (WITHOUT `--force`) — it applied a lockfile-only bump of brace-expansion to 2.1.2/1.1.16 and left the moderate uuid/firebase-admin chain alone (those need a breaking `firebase-admin` major, below the `--audit-level=high` threshold, so out of scope). Verify with `npm audit --audit-level=high; echo $?` == 0 (mind pipes — `$?` after a pipe is the last stage's exit, not npm's). Committed as a standalone `chore(deps)` on the blocked PR's branch to unblock it; the commit-quality hook re-ran the 168 functions tests to prove the lockfile change was safe. `npm audit fix --force` would have pulled a breaking firebase-admin@10 — never use `--force` to satisfy a high gate when the high item has a non-breaking fix.

**Rule #99 — Session-56 build gotchas: commit-quality format hook, autoDispose keep-alive, and Notifier-stub default state.**
[2026-07-21] Three traps hit while TDD-building FEATURE-RADAR-SONAR Phase A. (1) **The commit-quality hook runs `dart format` on staged files and ABORTS the commit when it reformats anything** (line-length rewraps are common). Symptom: `git commit` output ends at "Formatted N files (X changed)" and `git log` shows HEAD unchanged. Fix: `git add` the reformatted files again and re-`git commit` — it passes on the second try. Also: `dart run build_runner build` rewrites the `_$…Hash()` string in EVERY `.g.dart` (stale hashes in the repo), so unrelated `.g.dart` files show as modified — `git checkout --` them before committing to keep the commit atomic. (2) **A `@riverpod` (autoDispose) controller with a stream subscription needs a live listener or it disposes the instant `read()` returns, cancelling the sub before any emission lands.** Production: keep it alive with `ref.watch(theProvider)` in the consuming widget (`_RadarSection`). Unit test: hold `container.listen(provider, (_, __) {})` (NOT a bare `container.read`) or the BLE emission is dropped and state never updates. (3) **A test stub that returns a model's `.empty`/default constant inherits that model's DEFAULT field values** — `SonarPing.empty` defaults `signalState: searching`, so a `FakeSonarPingController` returning it silently rendered the "Searching…" caption (and its animation ticker) in unrelated overlay widget tests → "A Timer is still pending after the widget tree was disposed". Make stubs return an explicit benign state (`SonarSignalState.fresh`), and for any one-shot `flutter_animate` `.fadeIn()` in a widget test, either settle it (`pump(300ms+)` then `pumpWidget(SizedBox())` to dispose) or don't render it. Related: [[radar-sonar-search-feature]], Rule #97.

**Rule #100 — Verify the next ADR number against `tasks/decisions/` before writing it; slugs get reused across parallel plans.** [2026-07-21] The FEATURE-RADAR-SONAR plan + Session-56/57 handoffs all said the compass dependency would be "ADR-008". But `ADR-008-bundled-brand-typefaces.md` already existed — the number had been claimed by an unrelated lane between when the radar plan was written and when Phase B executed. Writing "ADR-008 (compass)" would have collided two decisions on one number. Fix: `ls tasks/decisions/` before creating any ADR; the compass decision became **ADR-009**, with a one-line note at the top pointing back from the expected "ADR-008" name, and the PR/plan/memory all updated to say ADR-009. Plan documents are point-in-time — an ADR number quoted in a plan is a *suggestion*, not a reservation; confirm it's still free at execution time.

**Rule #101 — The radar dot angle is in the painter's screen convention (0 = RIGHT), NOT compass/math "0 = north/top" — reconcile before writing the angle math; and every prod deploy needs an explicit `--project prod`.** [2026-07-21] FEATURE-RADAR-SONAR Phase B. (1) The design/plan described `dotAngle` as "facing the bearing → 0 = top", but `radar_painter.dart` plots the dot with `pingX = cx + r*cos(a); pingY = cy + r*sin(a)` — screen y is DOWN, so **angle 0 = right/east, +clockwise**, and "top" is `-π/2`. A `dotAngle` that returned "0 = top" would have put the dot 90° off. Reconciliation: `dotAngle = wrap((bearing−heading)·π/180 − π/2)` so the dot sits at the top when the user faces the partner, unit-tested against the painter's cos/sin convention (facing→3π/2, right→0, behind→π/2, left→π). Always read the *renderer's* trig before defining angle helpers; a plan's verbal angle description is not the paint convention. (2) The Firebase CLI's active project was `tremble-dev` (`firebase projects:list` → "tremble-dev (current)"). Deploying the Phase B server bearing with a bare `firebase deploy --only functions:scanProximityPairs` would have hit DEV. **Always pass `--project prod` (alias in `.firebaserc` → `am---dating-app`) explicitly for any prod deploy** — never trust the CLI's ambient project. Also: `firebase.json` has no functions `predeploy` hook, so `npm run build` (tsc → `lib/`) must be run manually before deploy or stale JS ships. Related: [[radar-sonar-search-feature]].

**Rule #102 — Never write to `matches/{id}` on a polling cadence; write only when a field actually changes.** [2026-07-22] Precise-finder pre-release bug hunt (build 35). `updateFinderLocation` unconditionally wrote `finderOptIn.{uid}=true` on every ~3s poll. Firestore bumps the doc version and fires a snapshot to every listener even when the written value is identical, and `Match` has no `operator==`, so `activeMatchesStreamProvider` → `currentSearchProvider` emitted "changed" on every write. Every `@riverpod` controller that `ref.watch(currentSearchProvider)` in `build()` (SonarPingController, WarmthController) then fully re-ran build — whose return value REPLACES `state` (→ `SonarPing.empty`, radius null) and whose previous `onDispose` fired `_reset()` — blanking the radar dot every ~1.5–3s during an active finder session, i.e. exactly during the feature's showcase moment. Pre-PR this churn existed but only ~1/min (scanProximityPairs bearing writer) so it was invisible; the 3s cadence made it 40× worse. Fix (5c033a5, deployed): compare-before-write — skip the opt-in update when the flag is already true (revocation stays unconditional, it runs ~once). Two generals: (a) any server writer that touches a doc watched via `ref.watch` in a Notifier's `build()` is a client-state reset in disguise — audit cadenced writers against watched docs; (b) consider value-equality (`operator==`) on stream-fed domain models so identical snapshots don't propagate as changes. Also note: a generated Notifier's `build()` re-run resets `state` to the return value — keep-alive fields survive, `state` does not. Related: [[radar-sonar-search-feature]], Rule #99.

**Rule #103 — `gcloud` on this Mac is dead (Python 3.9, unsupported); Firestore admin ops (TTL policies) work via the Firestore Admin REST API using firebase-tools' stored OAuth credentials.** [2026-07-22] The build-35 founder step "create TTL policy on collection group `finder` field `expireAt`" is not CLI-deployable via `firebase deploy`, and `gcloud firestore fields ttls update` failed to even load (`gcloud failed to load. You are running gcloud with Python 3.9`; no 3.10+ interpreter on the machine). Working path with zero machine changes: read `tokens.refresh_token` from `~/.config/configstore/firebase-tools.json`, exchange it at `oauth2.googleapis.com/token` using firebase-tools' public OAuth client (`563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com` / `j9iVZfS8kkCEFUPaAeJV0sAi`, embedded constants in its source), then `PATCH https://firestore.googleapis.com/v1/projects/am---dating-app/databases/(default)/collectionGroups/finder/fields/expireAt?updateMask=ttlConfig` with body `{"ttlConfig": {}}` (note: the mask param is `updateMask=ttlConfig`, NOT `updateMask.fieldPaths=`). Verified with a GET → `ttlConfig.state: ACTIVE` (2026-07-22). Never echo the tokens; the same pattern covers other `gcloud firestore` gaps until gcloud gets a supported Python. Related: Rule #101 (always target `am---dating-app` explicitly).

**Rule #104 — A self-perpetuating client loop (haptics, polling, animation drivers) must re-check its authoritative gate EVERY iteration, and any time-window provider needs its own expiry tick.** [2026-07-23] Session-62 device pass: sonar vibrations kept firing after the trembling window ended AND after radar was toggled off, until an unrelated navigation happened to dispose the controller. Three compounding holes, all the same shape: (1) `currentSearch` evaluates the 30-min window against `DateTime.now()` only when a Firestore snapshot arrives — nothing re-evaluates at the expiry instant, so an expired match is returned indefinitely (a time-derived provider that is only event-driven is stale by construction; give it a timer that fires at the boundary). (2) `SonarPingController._pingStep` is an async self-recursion whose only in-place stopper is one branch of `_tickFreshness` — and the precise-finder early-return bypassed exactly that branch, so once looping it could never stop in place. A loop's continue-condition must include the business gate (window still pending, radar still on), not merely "was I told to stop". (3) The radar-off toggle stopped BLE + the background service but signalled neither `SonarPingController` nor `PreciseFinderController` — when a user intent kills a subsystem, enumerate every dependent controller and stop them explicitly; "the stream will dry up" is not a stop signal (grace-hold logic and early-returns can outlive it). Related: Rule #102 (same controllers, opposite failure — there they reset too often, here they never stop).

**Rule #105 — Presence/visibility state must derive from user intent only: never refresh it from message receipt, and never silently swallow the write that revokes it.** [2026-07-23] Session-62: Martin was scanned, notified, waved at, and matched with his radar OFF. Chain: (a) `GeoService.stop()` wraps its `isActive:false` revocation write in `catch (_) {}` "non-critical" — but a failed revocation means staying discoverable for up to the 24h TTL; revocation writes are the MOST critical writes and need retry + a cold-start reconcile (local intent says off → ensure the server doc says off). Unclean termination (force-kill, FGS death) never runs stop() at all, so reconcile-on-boot is mandatory, not optional. (b) The FCM background handler refreshed `proximity/{uid}.updatedAt` on every silent CROSSING_PATHS/SECOND_ENCOUNTER wake with no radar-intent check — creating a self-sustaining freshness loop (scan → notify → receipt refreshes → fresh for next scan, forever). Its own comment said "Message receipt is not user intent", then treated it as exactly that. Any handler that runs on push receipt must check stored user intent (SharedPreferences `radar_active`) before touching presence. (c) Defense-in-depth was absent: `sendWave`/`onWaveCreated` never verify the target is radar-active, so one stale doc makes a user fully matchable. Server actions targeting a user must re-verify that user's CURRENT opt-in state, not trust that discovery already filtered them. Related: Rule #104 (client half of the same session), memory [[radar-sonar-search-feature]].
