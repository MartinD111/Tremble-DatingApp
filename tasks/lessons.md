# Permanent Project Knowledge (Lessons)

> Rules are permanent and never deleted. Ordered newest-first (highest rule number first).

---

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
