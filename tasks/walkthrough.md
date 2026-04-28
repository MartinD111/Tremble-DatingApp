# Walkthrough — Production Stabilization & Consolidation

We have stabilized the Tremble platform and streamlined all documentation into a single Source of Truth.

## 1. Documentation Consolidation (2026-04-29)
**Problem**: The project suffered from severe fragmentation with 10+ disjointed markdown files (F1-F11 plans, yaml policies, store submission checklists). This confused agent execution and caused logic drift.
**Solution**:
- Aggregated all architectural policies, F1-F11 execution plans, and routing strategies into a single `tasks/MASTER_PLAN.md`.
- Purged all legacy `.md` and `.yaml` policy files.
- Updated `context.md`, `todo.md`, `blockers.md`, and `lessons.md` to align with the new structure.
- **Outcome**: A clean `tasks/` directory focused purely on current state and immediate next actions.

## 2. Authentication Redirect Loop (D-14)
**Problem**: Authenticated users who had not yet completed onboarding were being bounced from `/login` back to `/onboarding`, creating a loop or poor UX.
**Solution**: Refactored `router.dart` so that if a user is authenticated but not yet onboarded, they land directly on `/onboarding`, skipping the redundant login screen entirely.

## 3. Google Maps Infrastructure (D-15)
**Problem**: Maps were not integrated at the platform level.
**Solution**: Created a secure, injection-based pattern for API keys:
- **Android**: Updated `build.gradle.kts` to pull `MAPS_API_KEY` from `local.properties`.
- **iOS**: Updated `AppDelegate.swift` and `Info.plist` to pull from `Debug.xcconfig`.
- **Status**: The developer has now added a valid API key to both local configuration files.

## 4. Email Verification UI
**Problem**: Users didn't know their verification status during registration.
**Solution**: Added a persistent banner on the Name page (the first step of onboarding after account creation) that warns the user if their email is unverified and provides a "Resend" button.

## 5. Maintenance
- ✅ Fixed `Flutter analyze` warning regarding unused `_prevPage` in `registration_flow.dart`.
- ✅ Resolved all "undefined lang" errors in Dashboard, Matches, and Edit Profile screens.
- ✅ Cleaned up all redundant duplicate keys in `translations.dart` (Zero analysis issues).
- ✅ Ran project-wide `dart format .` on 108 files.
- ✅ All MPC documents (`context.md`, `debt.md`, `lessons.md`, `MASTER_PLAN.md`) are up-to-date and consolidated.

## 6. Systematic i18n Cleanup (TASK-011)
**Problem**: Residual hardcoded Slovenian strings were present in key features (Matches, Profile, Home), and the translation system had accumulated duplicate keys causing static analysis errors.
**Solution**:
- Extracted ~60+ strings into `translations.dart`.
- Refactored the Hobby system to use technical keys for localization while preserving legacy data compatibility.
- Automated cleanup of `translations.dart` to ensure unique keys in constant maps.
- Verified with `flutter analyze` and `dart format`.

## 7. Scalable Notification Deduplication (TASK-007)
**Problem**: Proximity notifications and wave alerts were prone to "spamming" (redundant pings) in high-density areas, causing notification fatigue and hitting Firestore read/write limits.
**Solution**:
- **Redis Infrastructure**: Integrated **Upstash Redis** (REST-based) for high-performance, low-latency state checks.
- **Improved Cooldowns**: Increased proximity alert cooldown from 15 → 30 minutes (aligning with radar lock heartbeat).
- **Global Throttling**: Implemented a global guard preventing any recipient from receiving >3 proximity pings per 10-minute window across all nearby users.
- **Wave Dedup**: Added a 5-minute Redis-backed deduplication for "Waves" to prevent accidental double-tap notifications.
- **Haptic Polish**: Added client-side throttling to ensure vibrates don't "machine-gun" if messages arrive near-simultaneously.
- **Security**: Verified App Check enforcement on all related Cloud Functions.

---
*Aesthetics reminder: The new notification logic preserves the "Stoic/Solid" brand identity by staying silent in over-crowded environments.*
