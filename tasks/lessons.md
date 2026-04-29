# Permanent Project Knowledge (Lessons)

**Rule #41 — Single Source of Truth Documentation (MASTER_PLAN.md).**
[2026-04-29] Do not fragment implementation plans, UI specs, or store submission strategies across multiple files. All architectural policies, deployment rules, and feature implementations MUST reside in `tasks/MASTER_PLAN.md` to ensure context is never dropped across agent sessions.
Source: Project Consolidation, April 2026.

**Rule #42 — Always use Places API Session Tokens.**
[2026-04-29] To avoid astronomical GCP billing costs (reducing from $0.017/keystroke to $0.017/session), location autocomplete implementations MUST pass a unique, long-lived `sessionToken` with every search request until a location is explicitly selected.
Source: Places API (New) Integration, April 2026.

**Rule #43 — Avoid booleans for dynamic lifestyle preferences.**
[2026-04-29] User preferences that span multiple choices (e.g., Nicotine covering vaping, cigarettes, shisha, ZYN) should be stored as multi-select lists (`List<String>`) rather than simple true/false switches. This supports evolving cultural habits without frequent database migrations.
Source: Nicotine Step Implementation, April 2026.

Rule #1
[2026-03-31] Never run un-flavored `flutter build` or `flutter run`. Must provide `--flavor dev --dart-define=FLAVOR=dev` or prod equivalents.
Source: Multi-Env Setup March 2026.

Rule #2
[2026-03] Do not bypass Riverpod strictly typed state. Avoid mutating state directly in UI.

**Rule #3 — TREMBLE HAS NO IN-APP CHAT. EVER.**
[2026-04-09] The core product mechanic is: Wave → Mutual Wave → 30-minute real-life finding game → meet in person.

**Rule #15 — App Check requires explicit server-side enforcement.**
[2026-04-20] Enabling App Check on the client (`FirebaseAppCheck.activate`) is only half the integration. Cloud Functions must also be updated to verify the token in the middleware (`request.appToken`) and have `enforceAppCheck: true` in their configuration. Without this, the backend remains open to unauthorized clients even if the mobile app is sending valid tokens.
Source: Phase 9 Security Hardening, April 2026.

**Rule #16 — iOS Map xcconfig files live at `ios/Flutter/`, not `ios/Runner/`.**
[2026-04-20] `ios/Runner/Info.plist` resolves `$(MAPS_API_KEY)` from `ios/Flutter/Debug.xcconfig` and `ios/Flutter/Release.xcconfig` (not `ios/Runner/*.xcconfig`). The Xcode project (`project.pbxproj`) points `baseConfigurationReference` to `Flutter/Debug.xcconfig`. If the map renders as a grey screen on iOS, confirm these two files exist and contain a real key (not placeholder). Android Maps key lives separately in `android/local.properties`.
Source: Map Troubleshooting, April 2026.

**Rule #17 — Zero Writing Policy in Onboarding.**
[2026-04-20] The registration flow must contain zero custom text input fields (excluding Name). The brand identity ("Stoic, Solid") demands binary/enum-based selection only to maintain a technical "Signal Calibration" theme. Any request for "Custom" free-text fields (eg: custom pet, custom job) must be rejected to ensure zero verbal friction.
Source: Registration Phase 2 (Signal Calibration), April 2026.

**Rule #18 — Flutter/Dart Environment Paths are variable on local machines.**
[2026-04-20] The standard `flutter` command may fail in certain shell environments if not properly sourced. Always verify the absolute path (on this machine: `/Users/aleksandarbojic/flutter/bin/flutter`) when standard commands fail.
Source: i18n Cleanup TASK-011, April 2026.

**Rule #19 — Duplicate keys in `const Map` are compile-time errors.**
[2026-04-20] In Dart, adding a key that already exists to a constant map literal will prevent the app from building. When extracting strings to `translations.dart`, first perform a global key-check to avoid silent build failures in the IDE.
Source: i18n Cleanup TASK-011, April 2026.

**Rule #20 — "App as a Tool" Profile UI Logic.**
[2026-04-20] Favor vertical `Wrap` over horizontal scrolling `Row` for data-dense sections (e.g., Hobbies). This improves transparency (everything visible at once) and reduces interaction friction. Additionally, always maintain 1:1 logic parity between `ProfileCardPreview` (self-view) and `ProfileDetailScreen` (match-view) to ensure the technical brand experience is consistent across all surfaces. Simplify complex visualizations (e.g., spectrum sliders) into direct data points (pills) for non-personality traits (e.g., politics) to avoid "designer-y" distractions.
Source: Profile UI Refinement TASK-004, April 2026.
**Rule #21 — Always verify Firebase aliases in `.firebaserc` before deployment.**
[2026-04-20] Never assume project aliases like `development` or `staging` point to the correct project. A misconfigured `.firebaserc` (e.g., `development` pointing to a production project ID) can lead to catastrophic data loss or policy violations. Always cross-reference the project ID in `firebase.json` or `.firebaserc` with the official project list (`firebase projects:list`) before executing any deployment command.
Source: Phase 11 Security Audit, April 2026.

**Rule #22 — Prefer native button loading states over manual if/else UI switching.**
[2026-04-21] To avoid layout shifts and maintain a premium look, shared buttons (like `PrimaryButton`) should handle their own `isLoading` state. This centralizes the spinner logic (SVG/CircularProgressIndicator) and ensures the page layout remains stable while the backend call is in progress.
Source: D-27 Spinner Fix, April 2021.

**Rule #23 — Avoid system emojis in UI elements for cross-platform stability.**
[2026-04-22] System emojis often render as generic square blocks `[?]` on iOS if the font fallback is not perfectly configured or if the OS version differs. Always prefer `LucideIcons` or custom SVG assets for critical UI feedback (e.g., chips, status indicators, onboarding steps) to maintain a premium, technical aesthetic.
Source: TASK-REG-18, April 2026.

**Rule #24 — Centralize date/zodiac logic in `ZodiacUtils`.**
[2026-04-22] Never implement age or zodiac calculations locally in UI components. All birthday-to-age and birthday-to-zodiac logic must reside in `ZodiacUtils` to ensure consistent data across Registration, Profile Editing, and Profile Detail screens. This avoids "logic drift" and ensures that if we update the calculation (e.g., Leap year edge cases), it propagates globally.
Source: Zodiac Localization & UI Refinement, April 2026.
+
+**Rule #25 — Use `NotifierProvider` for persistent global app state (e.g., Language).**
+[2026-04-23] Standard `StateProvider` can reset unexpectedly if its dependencies (like `authStateProvider`) change while the user has no defined profile state. Switching to `NotifierProvider` with explicit state preservation (reading `ref.state` in the build method) ensures the UI language remains stable during high-friction flows like registration.
+Source: Onboarding v2 implementation.
+
+**Rule #26 — Use PageView indexing for multi-stage registration rituals.**
+[2026-04-23] For high-fidelity visual transitions (like the Ritual screen), keep the widget as a final index in the existing `PageView` rather than pushing a new route. This allows for seamless shared-element animations and ensures the `PingOverlay` logic remains active across the entire activation sequence.
+Source: Onboarding v2 implementation.
+
+**Rule #27 — `flutter_launcher_icons` requires PNG assets.**
+[2026-04-23] The automated icon generation package (`flutter_launcher_icons`) does not support SVG files directly. To automate icon updates, always convert the master SVG to a high-resolution PNG (1024x1024) first. This ensures the pixel data is correctly extracted for various device resolutions.
+
+**Rule #28 — Center `CustomPainter` paths using SVG group transforms.**
+[2026-04-23] When implementing complex icons (like the Tremble logo) in a `CustomPainter`, matching the source design exactly requires translating the coordinate system to match the SVG's `group transform` (e.g., `translate(centerX - (X * scale), centerY - (Y * scale))`). Small deviations in these offsets cause the logo to look "broken" or uncentered on different screen densities.
+
+**Rule #29 — Avoid `SafeArea` as a global wrapper for modal bottom sheets.**
+[2026-04-23] Wrapping a `showModalBottomSheet` builder in `SafeArea` can cause a "black gap" or "cutoff" at the bottom of the screen (behind the iOS home indicator) because the `SafeArea` prevents the background color from extending into the system area. Instead, use `MediaQuery.of(context).padding.bottom` to add targeted padding inside the modal's background-colored container.
**Rule #8** — Always pass translation functions (`tr`) to standalone widgets and bottom sheet utilities. Never rely on hardcoded strings in shared UI components. Source: Phase 10 Polish, April 2026.

**Rule #30 — Never store raw GPS coordinates in Firestore for proximity matching.**
[2026-04-24] updateLocation was writing lat/lng to proximity/{uid} with a rule allowing all authenticated users to read. This is a GDPR violation and contradicts "privacy by architecture" — the core brand promise. Use geohash only for Firestore storage. Coordinates are used in-memory during Cloud Function execution and never persisted.
Source: SEC-002 Privacy Fix, April 2026.

**Rule #31 — Prod Firestore rules must be explicitly deployed — they do not inherit from dev.**
[2026-04-24] Production Firestore (am---dating-app) had only waitlist rules. All other collections (users, matches, waves, proximity, etc.) were relying on default deny — which works but is not explicit and creates risk. Always deploy full rules to prod. Use: firebase deploy --only firestore --project prod
Source: Prod rules audit, April 2026.

**Rule #32 — Never answer N/Y prompts during firebase deploy without reading them.**
[2026-04-24] During firestore deploy to prod, Firebase asked to delete TTL field overrides (gdprRequests.ttl, proximity.ttl, proximity_events.ttl). Answering Y would have permanently deleted TTL policies — documents would accumulate forever. Always answer N to field override deletion prompts unless you explicitly created those overrides and want them gone.
Source: Prod deploy, April 2026.
Rule #33 — Rich notification payloads must use `imageUrl` for FCM Admin SDK.
[2026-04-24] While the client uses `photoUrl` for internal models, the Firebase Cloud Messaging payload key for images in the data/notification block must be `imageUrl` (or matching the `NotificationService` wrapper) to ensure images appear correctly in the system notification shade.
Source: Interaction System v2.1.

Rule #34 — Avoid `const` for initialization with dynamic categories in `flutter_local_notifications`.
[2026-04-24] Initialization settings for both Darwin (iOS) and Android cannot be declared as `const` if they depend on runtime-generated notification categories or actions. Attempting to use `const` will cause a compile-time error when categories are passed as a variable.
Source: Notification Service Refactor.

Rule #35 — Resolve Android startup "white flash" via `NormalTheme` inheritance.
[2026-04-24] The common white flash during app initialization on Android is often caused by the `NormalTheme` inheriting from a `Light` parent in `styles.xml`. Changing the parent to `Theme.Black.NoTitleBar` (or a Material3 dark equivalent) and explicitly setting `windowBackground` to a dark color resolves this.
Source: Android Theme Polish.

**Rule #36 — Splash source image must be the COLORED icon, not the transparent variant.**
[2026-04-24] `tremble_icon_clean_transparent.png` has WHITE artwork on transparent background. On a dark `#1A1A18` splash background, this renders as white/monochrome. Always use `tremble_icon_clean.png` (rose-colored full icon) as the splash/launcher source. For proper sizing, create `tremble_splash_source.png` — the rose icon at 50% of a 2048×2048 transparent canvas — to prevent zoom-in and cut-off on device.
Source: Splash Screen Fix, April 2026.

**Rule #38 — Quick Settings tile icons must be monochrome vectors.**
[2026-04-25] Android Quick Settings tiles require a single-color vector drawable (`ic_tremble_qs_tile.xml`). The system tints the icon with the device accent colour (Material You) at runtime — do NOT embed brand colours in the drawable. Using a coloured PNG or a vector with hard-coded fillColor produces a flat white square on most OEM launchers and fails Play Store review.
Source: Android OS Integration, April 2026.

**Rule #39 — `setColorInt` (RemoteViews) requires API 31+ for icon tinting in widgets.**
[2026-04-25] `RemoteViews.setColorInt` is only available from Android 12 (API 31). Always gate calls to this method behind `Build.VERSION.SDK_INT >= Build.VERSION_CODES.S` and provide a pre-12 fallback (static drawable with brand border) so older devices do not crash.
Source: Android OS Integration, April 2026.

**Rule #40 — `MainActivity` should extend `FlutterFragmentActivity`, not `FlutterActivity`.**
[2026-04-25] `FlutterFragmentActivity` is the modern embedding base and is required for clean `MethodChannel`/`EventChannel` lifecycle management when adding custom native code alongside Flutter. `FlutterActivity` works but causes subtle issues with channel teardown during orientation changes.
Source: Android OS Integration, April 2026.

**Rule #37 — flutter_launcher_icons adaptive foreground must use padded source.**
[2026-04-24] For Android adaptive icons, the foreground image should have ~25% padding on all sides (safe zone is 66% of the 108dp canvas). Use `tremble_splash_source.png` (icon at 50% of 2048px canvas) as `adaptive_icon_foreground` to ensure the rose icon is fully visible in all launcher shapes (circle, squircle, etc.) without clipping.
Source: Launcher Icon Fix, April 2026.

**Rule #38 — AnimatedSwitcher ScaleTransition causes perceived lag on tab switches.**
[2026-04-24] A ScaleTransition(0.98→1.0) on NavigationBar tab switches creates a subtle but noticeable "pop" effect — the content appears to breathe in before settling, which reads as sluggishness. Use FadeTransition only for tab-level AnimatedSwitcher; keep duration ≤200 ms. Reserve scale transitions for explicit "open detail" navigations (e.g., GoRouter push to profile screen).
Source: UI-Icon-Stability polish, April 2026.

**Rule #39 — RadarPainter maxRadius must match the outermost grid circle.**
[2026-04-24] If `maxRadius` is smaller than the canvas boundary where the last concentric ring is drawn, the radar pulse stops short of the outermost circle and the scan line appears clipped. `maxRadius` drives both the grid rings AND the scan geometry — if you change one, the other must match. Set `size.width * 0.5` as the canonical value.
Source: UI-Icon-Stability polish, April 2026.


## 🧠 Learning Log — Tremble Development

### 1. Flutter + Google Maps: Safe API Key Injection (2026-04-08)
- **Problem:** Storing API keys in `AndroidManifest.xml` or `AppDelegate.swift` leaks them to version control.
- **Solution:** Multi-layered injection using platform configuration files that are excluded from `.gitignore`.
- **Pattern (Android):**
    1. `android/local.properties` -> `MAPS_API_KEY=your_key`
    2. `android/app/build.gradle.kts` -> Load properties, add to `manifestPlaceholders`.
    3. `AndroidManifest.xml` -> `<meta-data android:name="..." android:value="${MAPS_API_KEY}" />`
- **Pattern (iOS):**
    1. `ios/Flutter/Debug.xcconfig` -> `MAPS_API_KEY=your_key`
    2. `ios/Runner/Info.plist` -> Add `MAPS_API_KEY` key with value `$(MAPS_API_KEY)`.
    3. `ios/Runner/AppDelegate.swift` -> `GMSServices.provideAPIKey(Bundle.main.object(forInfoDictionaryKey: "MAPS_API_KEY") as? String ?? "")`

### 2. Auth Redirect Loops (2026-04-08)
- **Problem:** `GoRouter` redirecting `!isOnboarded` to `/login` which then logic-bounced to `/onboarding`.
- **Solution:** Always jump directly to the target state (e.g., `/onboarding`) if the user is already authenticated but data-incomplete. Avoid redundant hops through auth screens after session is established.

### 3. iOS Notification Service Extension: Rich Push (2026-04-10)
- **Problem:** iOS does not display images in push notifications by default (unlike Android).
- **Solution:** Implement a `UNNotificationServiceExtension`. It intercepted the notification, extracted the image URL from the FCM payload, downloaded it to a temporary file, and attached it to the notice content.
- **Key Caveat:** The extension runs as a separate process; any shared logic (e.g., App Groups) requires manual target configuration in Xcode.

### 4. Node.js 22 Runtime Migration (2026-04-10)
- **Problem:** Cloud Functions on older Node.js versions (20) have limited lifetime support and miss modern performance optimizations.
- **Solution:** Upgrade to Node.js 22 in `package.json`.
- **Insight:** Changing the engine version requires an `npm install` to update the `package-lock.json` metadata, ensuring the Firebase CLI correctly detects the environment upon deployment.


# Repository Review Findings

## 1. Review Summary
The repository review was conducted on 2026-03-14 according to the user's 8-step request.

| Step | Task | Status | Findings |
|---|---|---|---|
| 1 | MPC Documentation | [x] | Analyzed `MPC workflow.md`. Ready for strict integration. |
| 2 | ECC Documentation | [!] | **Missing.** No file or reference found in the repository codebase. |
| 3 | Project Context | [x] | Reviewed `tasks/context.md`. Current Phase: 5 (Production). |
| 4 | Handoff Documentation | [x] | Reviewed `tasks/handoff.md`. Environment setup is complete. |
| 5 | Manual Legal Tasks | [x] | Reviewed `MANUAL_LEGAL_TASKS.md`. GDPR/ZVOP-2 tasks identified. |
| 6 | Setup Instructions | [x] | Reviewed `SETUP.md` and `BOOTSTRAP.md`. |
| 7 | Martin Setup Guide | [!] | **Missing.** Referenced in `context.md` but file `martin_setup_guide.md` does not exist. |
| 8 | Environment Agnostic | [x] | **Confirmed.** Uses Flutter flavors and Firebase Secret Manager. |

## 2. Technical Evidence: Environment Agnosticism
- **Frontend:** uses `String.fromEnvironment('FLAVOR')` in `lib/main.dart` to switch `FirebaseOptions`.
- **Backend:** `functions/src/config/env.ts` loads secrets from `process.env` (Firebase Secret Manager).
- **CI/CD:** `.github/workflows/` scripts handle secret injection and SDK management.

## 3. Notable Gaps
- **ECC:** The term "ECC" does not appear in documentation. It may refer to "Elliptic Curve Cryptography" (standard in Firebase/SSL) or a missing specific document.
- **Martin Setup Guide:** The log states this was created, but it is not in the filesystem. It should be regenerated to support the Windows/Android (S25 Ultra) environment.

## 4. Next Steps
- Strictly follow the MPC "Orchestral Loop".
- Update `tasks/context.md` to the MPC format.
- Propose regeneration of `martin_setup_guide.md`.
