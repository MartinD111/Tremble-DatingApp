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
