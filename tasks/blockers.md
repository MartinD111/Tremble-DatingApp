# Blockers & Investigation Findings

---

## BLOCKER-001 / ADR-001 — iOS BLE Background State Restoration
**Date:** 2026-04-29
**Status:** 🔴 OPEN
**Impact:** `flutter_blue_plus` is not wired correctly in `background_service.dart`, which still relies on a mock timer. This prevents background scanning for devices, acting as a critical functional blocker for TestFlight.
**Action:** Requires manual Flutter/Native communication channel implementation that bypasses standard background service limits.

## BLOCKER-002 / D-37 — 3-State Map Toggle Untested on Physical Device
**Date:** 2026-04-29
**Status:** ✅ RESOLVED
**Impact:** The 3-state map toggle logic was implemented and has been verified by Martin on a physical Samsung S25 Ultra.
**Action:** None.

## BLOCKER-003 — Legal/Legislative (RevenueCat)
**Date:** 2026-04-18
**Status:** 🔴 OPEN
**Impact:** Phase 8 (Paywall) is on hold until company registration and legal entities are established.
**Action:** Move to Phase 9 (Security Hardening) and Phase C (UI Polish) instead (now complete). Resume when company entity is confirmed.

---

*(Historical resolved blockers (SEC-001, FUNCTIONS-DEPLOY, SEC-002, etc.) have been archived to `MASTER_PLAN.md` and `lessons.md` to keep this file actionable).*
