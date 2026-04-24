# Permanent Project Knowledge (Lessons)

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
