- Active Task: Rich Proximity Notifications (Interaction System v2.1) & UI Polish
- Environment: Dev (Android/iOS)
- Modified Files: proximity.functions.ts, notification_service.dart, translations.dart, router.dart, permission_gate_screen.dart, tremble_logo.dart, styles.xml, lessons.md, CLAUDE.md
- Open Problems: ADR-001 (iOS BLE background)
- System Status: Interaction System v2.1 pushed to main and deployed to dev functions. Lessons synced to CLAUDE.md.

---

## Session Handoff — 2026-04-24 (Update)

### What Was Done This Session
| Item | Fix | Status |
|------|-----|--------|
| NOT-001 | Interaction System v2.1 | ✅ Rich notifications with sender identity (Name, Age, Photo) |
| NOT-002 | Background Wave Action | ✅ Background interaction handling for "Wave" button |
| UI-003 | Android White Square | ✅ NormalTheme fixed with Black parent and dark background |
| UI-004 | Permission Gate Overflow | ✅ Wrapped in ScrollView for small devices |
| UI-005 | Logo Opacity | ✅ Increased base opacity for "lines" per founder request |
| LOC-001 | Translations v2.1 | ✅ Identity-based notification strings added to all languages |

### Open Blockers
- ADR-001: iOS BLE background state restoration — not yet implemented
- BLOCKER-003: Legal/RevenueCat — Phase 8 on hold (AMS Solutions d.o.o. unregistered)
- D-37: Map toggle test — pending Martin on Samsung S25 Ultra

### Next Action
iOS BLE Background State Restoration (ADR-001).
Requires native iOS config (Info.plist) and background state preservation logic.
Risk level HIGH — Founder approval required.

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
