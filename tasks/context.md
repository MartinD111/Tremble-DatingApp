## Session State — 2026-04-24
- Active Task: Korak 4 — iOS BLE Background State Restoration (ADR-001)
- Environment: Both (dev verified, prod deployed)
- Modified Files: functions/src/modules/proximity/proximity.functions.ts, firestore.rules
- Open Problems: ADR-001 (iOS BLE background), D-37 (map toggle test pending Martin)
- System Status: Build passing. 19/19 functions deployed to prod. Rules deployed dev + prod.

---

## Session Handoff — 2026-04-24

### What Was Done This Session
| Item | Fix | Status |
|------|-----|--------|
| SEC-002 | Removed lat/lng from proximity Firestore writes | ✅ Deployed dev + prod |
| BLOCKER-004 | Maps API keys confirmed both projects | ✅ Resolved |
| D-35 | Maps API keys confirmed both projects | ✅ Resolved |
| Prod rules | Full Firestore rules deployed to am---dating-app | ✅ Done |
| Prod backup | Point-in-time recovery + daily backup enabled | ✅ Done |
| Store plan | Store submission master plan created | ✅ tasks/store_submission_plan.md |

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
