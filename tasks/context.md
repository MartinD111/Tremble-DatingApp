## Session State — 2026-04-04
- Session ID: D09-D13-Fix-2026-04-04
- Active Task: COMPLETE — D-09 and D-13 resolved
- Environment: Prod (am---dating-app)
- Branch: main
- Modified Files:
    - functions/src/modules/auth/auth.functions.ts (onUserDocCreated → europe-west1)
    - functions/src/modules/proximity/proximity.functions.ts (onBleProximity → europe-west1)
    - functions/src/modules/email/email.functions.ts (resendVerificationEmail → europe-west1)
    - functions/.env (added GOOGLE_WEB_CLIENT_ID)
    - functions/.env.example (documented GOOGLE_WEB_CLIENT_ID)
    - tasks/debt.md (D-09, D-13 marked resolved)
- Open Problems:
    - D-03: Consent screen reimplementation (consent_service.dart + permission_gate_screen.dart missing)
    - D-11: Deprecated androidProvider/appleProvider in main.dart
    - D-12: Firestore TTL policies unconfirmed in Firebase Console
- System Status: flutter analyze 2 info warnings only (D-11, pre-existing). 0 errors. All 21 functions in europe-west1.
- Last Release: Phase 5 AppCheck Complete

## Session Handoff (For Aleksandar)
- Completed:
    - D-13 RESOLVED: GOOGLE_WEB_CLIENT_ID added to functions/.env. verifyGoogleToken now functional.
    - D-09 RESOLVED: onBleProximity, onUserDocCreated, resendVerificationEmail migrated to europe-west1. Old us-central1 instances deleted. All 21 functions now unified in europe-west1.
- Blocked:
    - D-12 (Medium/Phase 5): TTL policies not confirmed active in Firebase Console
    - D-03 (Medium/Phase 6): consent_service.dart + permission_gate_screen.dart need reimplementation
- Next Action: Confirm D-12 TTL policies in Firebase Console (proximity_events, proximity, gdprRequests collections — field: ttl). Manual step in Firebase Console.
- Staleness Rule: If this block is >48h old, re-validate before executing.
