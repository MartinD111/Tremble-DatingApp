- Active Task: Splash Screen Optimization & Onboarding Resilience
- Environment: Dev (Android)
- Modified Files: flutter_native_splash.yaml, flutter_launcher_icons.yaml, tremble_logo.dart, registration_flow.dart, intro_slide_step.dart
- Open Problems: ADR-001 (iOS BLE background)
- System Status: Splash regenerated, logo opacity improved, logout implemented in onboarding.

---

## Session Handoff — 2026-04-24

### What Was Done This Session
| Item | Fix | Status |
|------|-----|--------|
| UI-001 | Splash Screen Artifacts (White Square/Opacity) | ✅ Regenerated with icon_background_color and transparent PNG |
| UX-001 | Onboarding Logout / Cancel Registration | ✅ Implemented with translations for all languages |
| UI-002 | Logo Wave Visibility ("opacity za lines") | ✅ Increased base alpha to 0.30 |
| SEC-002 | Removed lat/lng from proximity Firestore writes | ✅ Deployed dev + prod |
| BLOCKER-004 | Maps API keys confirmed both projects | ✅ Resolved |

### Open Blockers
- ADR-001: iOS BLE background state restoration — not yet implemented
- BLOCKER-003: Legal/RevenueCat — Phase 8 on hold (AMS Solutions d.o.o. unregistered)
- D-37: Map toggle test — pending Martin on Samsung S25 Ultra

### Next Action
iOS BLE Background State Restoration (ADR-001).
Use Korak 4 prompt from tasks/store_submission_plan.md.
Risk level HIGH — requires native iOS config (Info.plist). Founder approval required before implementation.

### Resume Command
/gsd:resume-work

---

## Phase 1 & 2: Registration Resilience ✅ COMPLETE

| Item | Status |
|------|--------|
| Checkpoint | ✅ `onboardingCheckpoint` in Firestore |
| Auth Loop  | ✅ router.dart allows drafts to resume /onboarding |
| Signal Calibration | ✅ Hardware Rebrand, zero-writing policy, Signal Lock |
| Dedup (007) | ✅ Upstash Redis rate-limiting |

---

- **Security Update**: Phase 11 complete. Cloud Functions deployed to `tremble-dev`.
- **Infrastructure**: `.firebaserc` aliases `dev` and `prod` strictly mapped.
- **Privacy Fix**: SEC-002 resolved. lat/lng removed from proximity writes. Deployed dev + prod 2026-04-24.
- **Prod Firestore**: Full rules (users, drafts, matches, waves, proximity, proximity_events, rateLimits, idempotencyKeys, gdprRequests, default deny) deployed to am---dating-app 2026-04-24.
- **Prod Backup**: Point-in-time recovery (7 days) + daily backup (7 days expiry) enabled 2026-04-24.
