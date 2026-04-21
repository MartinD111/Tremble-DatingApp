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
