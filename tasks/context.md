## Session State — 2026-04-03
- Session ID: D14-Fix-2026-04-03
- Active Task: D-14 resolved — api_client.dart region fix (us-central1 → europe-west1)
- Environment: Dev (tremble-dev)
- Modified Files:
    - lib/src/core/api_client.dart
    - tasks/debt.md
    - tasks/context.md
- Open Problems:
    - D-03: Consent screen reimplementation (consent_service.dart + permission_gate_screen.dart missing)
    - D-09: Firestore triggers (onBleProximity, onUserDocCreated) still in us-central1
    - D-11: Deprecated androidProvider/appleProvider in main.dart
    - D-12: Firestore TTL policies unconfirmed in Firebase Console
    - D-13: GOOGLE_WEB_CLIENT_ID unconfirmed in prod Functions config
- System Status: flutter analyze 2 info warnings only (D-11, pre-existing). 0 errors.
- Last Release: Phase 5 AppCheck Complete

## Session Handoff (For Aleksandar)
- Completed:
    - D-14 RESOLVED: api_client.dart was calling FirebaseFunctions.instance (defaults to us-central1). All 18 onCall functions are in europe-west1 since D-07 migration on 2026-04-03. Changed to FirebaseFunctions.instanceFor(region: 'europe-west1'). This was the root cause of "Registration failed: NOT_FOUND" on Martin's device.
    - registration_flow.dart snackbar fixed: '\$e' → '$e' (was printing literal "$e" instead of exception).
- Blocked:
    - D-13 (HIGH/Phase 5): GOOGLE_WEB_CLIENT_ID not confirmed in prod Functions config
    - D-09 (Medium/Phase 5): Firestore triggers still in us-central1
    - D-12 (Medium/Phase 5): TTL policies not confirmed active
    - D-03 (Medium/Phase 6): consent_service.dart + permission_gate_screen.dart need reimplementation
- Next Action: Martin to run `flutter run --flavor dev --dart-define=FLAVOR=dev` and verify completeOnboarding succeeds. Then proceed with BLE test (Section 2.2 of handoff).
- Staleness Rule: If this block is >48h old, re-validate before executing.
