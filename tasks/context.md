## Session State — 2026-04-08
- Session ID: MPC-BugFix-Auth-Map-Email-2026-04-08
- Active Task: Production bug fixes — auth redirect loop, Google Maps API, email verification
- Environment: Dev (tremble-dev)
- Branch: main
- Modified Files:
    - lib/src/core/router.dart (Fixed redirect loop: !isOnboarded now goes directly to /onboarding)
    - android/app/build.gradle.kts (Added MAPS_API_KEY reading from local.properties)
    - android/app/src/main/AndroidManifest.xml (Added com.google.android.geo.API_KEY meta-data)
    - android/local.properties (Added MAPS_API_KEY placeholder — fill with real key)
    - ios/Runner/AppDelegate.swift (Added GMSServices.provideAPIKey() reading from Info.plist)
    - ios/Runner/Info.plist (Added MAPS_API_KEY entry reading from xcconfig)
    - ios/Flutter/Debug.xcconfig (Added MAPS_API_KEY placeholder — fill with real key)
    - lib/src/features/auth/presentation/registration_flow.dart (Added email verification banner on name page)
    - lib/src/core/translations.dart (Added verify_email_title + resend keys in EN/SL/DE)
- System Status:
    - flutter analyze: 0 new issues (1 pre-existing unused_element warning)

## Session Handoff (For Aleksandar)
- Completed:
    - **Bug Fix 1 — Auth Router Loop:** `router.dart` `!isOnboarded` block sent logged-in users to `/login` which then bounced to `/onboarding`. Fixed: now goes directly to `/onboarding`.
    - **Bug Fix 2 — Google Maps API Key:** Key was completely absent from both platforms. Set up injection mechanism: Android reads from `android/local.properties`, iOS reads xcconfig → Info.plist → AppDelegate.
    - **Bug Fix 3 — Email Verification:** Added a visible rose-tinted banner on the name page (page 6) for email users with unverified emails. Includes email address + Resend button.
- Blocked:
    - **ACTION REQUIRED:** Fill in actual Google Maps API keys:
      - Android: `android/local.properties` → replace `YOUR_MAPS_API_KEY_HERE`
      - iOS: `ios/Flutter/Debug.xcconfig` → replace `YOUR_MAPS_API_KEY_HERE`
      - For CI/CD: add `MAPS_API_KEY` as a secret injected into both platform configs
- Next Action (Priority Order):
    1. **URGENT:** Add real Maps API key to local.properties (Android) and Debug.xcconfig (iOS)
    2. **TASK C (15 min):** Update onboarding copy in `lib/src/core/translations.dart`.
    3. **TASK D (5 min):** Fix Registration CTA copy in `translations.dart`.
    4. **TASK B (1-2h):** Color token swap teal (#00D9A6) → rose (#F4436C) — see `ADR-003-brand-alignment.md`.
    5. **TASK A (2-3h):** Update font system (Playfair Display / Lora / Instrument Sans).

## Staleness Rule: If this block is >48h old, re-sync with main before executing.
