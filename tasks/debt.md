# Technical Debt Register

| ID   | Description                                    | Risk   | Due       | Status |
|------|------------------------------------------------|--------|-----------|--------|
| D-01 | BLE implementation uses mock background logic  | High   | Phase 3   | ✅ RESOLVED — Verified by Claude Code 2026-04-02 — implementation already shipped in ble_service.dart |
| D-02 | Production Secrets missing in Cloud Functions  | High   | Phase 5   | 🔴 OPEN — requires manual founder action |
| D-03 | Missing explicit GDPR prompt for Location/BLE  | Medium | Phase 6   | 🔴 OPEN — 2026-04-03 audit: consent_service.dart and permission_gate_screen.dart do not exist in filesystem. D-03 was incorrectly marked resolved. Requires full reimplementation. |
| D-04 | plan.md was out of sync with shipped work      | Low    | Immediate | ✅ RESOLVED — 2026-04-02 |
| D-05 | background_service.dart BLE mock not replaced despite ble_service.dart being real | High | Phase 3 | ✅ RESOLVED — Verified by Claude Code 2026-04-02 — implementation already shipped in ble_service.dart |
| D-06 | .agent/skills/flutter-ble/SKILL.md contains firebase-security content — mislabeled, needs replacement | Low | Immediate | ✅ RESOLVED — 2026-04-02: replaced with real flutter_blue_plus patterns |
| D-07 | Cloud Functions deployed to prod (am---dating-app) in us-central1 instead of europe-west1. | High | Phase 5 | ✅ RESOLVED — 2026-04-03: Cloud Functions migrated to europe-west1. 15 us-central1 onCall functions deleted. |
| D-08 | Flutter SDK Path mismatch in .vscode/settings.json | Low | Immediate | ✅ RESOLVED — 2026-04-03: manually pointed to system SDK |
| D-09 | Firestore trigger functions onBleProximity and onUserDocCreated still in us-central1 — require separate migration | Medium | Phase 5 | ✅ RESOLVED — 2026-04-04: onBleProximity, onUserDocCreated, and resendVerificationEmail migrated to europe-west1. Old us-central1 instances deleted. All 21 functions now in europe-west1. |
| D-10 | proximity_events collection has no Firestore write rule — BLE proximity detection silently fails in prod, onBleProximity Cloud Function never triggers | High   | Immediate | ✅ RESOLVED — 2026-04-03: write rule added (auth required), read denied. Deployed to am---dating-app. |
| D-11 | androidProvider/appleProvider deprecated in main.dart — replace with providerAndroid/providerApple before launch | Low    | Phase 6   | 🔴 OPEN |
| D-12 | Firestore TTL policies for proximity_events, proximity, gdprRequests not confirmed active in Firebase Console | Medium | Phase 5   | 🔴 OPEN |
| D-13 | GOOGLE_WEB_CLIENT_ID not confirmed set in prod Cloud Functions environment config | High   | Phase 5   | ✅ RESOLVED — 2026-04-04: added to functions/.env (value sourced from functions.config().auth.google_client_id). All 21 functions redeployed to am---dating-app. |
| D-14 | api_client.dart used FirebaseFunctions.instance (us-central1 default) — all onCall functions were migrated to europe-west1 on 2026-04-03 but client was not updated, causing NOT_FOUND on every Cloud Function call | High | Immediate | ✅ RESOLVED — 2026-04-03: changed to FirebaseFunctions.instanceFor(region: 'europe-west1') in lib/src/core/api_client.dart |
