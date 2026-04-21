# Blockers & Investigation Findings

---

## BLOCKER-001 — D-01/D-05 Were Stale: BLE Already Implemented
**Date:** 2026-04-02
**Status:** Resolved (no code change required)

## BLOCKER-002 — Critical Functional Failures (Handoff to Aleksandar)
**Date:** 2026-04-15
**Status:** ✅ CLOSED (2026-04-18)

### Resolution Summary
All critical items reported by the founder have been addressed:
1. **Matching Logic:** RESTORED (MatchController uses WaveRepository.sendWave()).
2. **Profile UI:** ALIGNED (Waitlist for Phase C polish, but monolith extraction complete).
3. **Data Persistence:** FIXED (BUG-002: Zod schema updated, images/hobbies saving correctly).
4. **"Pozdrav" Feature:** FIXED (Legacy greeting removed, replaced with Waves).
5. **Map Visibility:** RESTORED (TASK-008: 3-state toggle implemented).
6. **Visual Assets:** UPDATED (TASK-005: Tremble Logo integrated in Radar center).

---

## BLOCKER-003 — Legal/Legislative (RevenueCat)
**Date:** 2026-04-18
**Status:** 🔴 OPEN
**Impact:** Phase 8 (Paywall) is on hold until company registration and legal entities are established.
**Action:** Move to Phase 9 (Security Hardening) and Phase C (UI Polish) instead.

## SEC-001 — Firebase App Check Not Enforced in Cloud Functions
**Date:** 2026-04-20
**Status:** ✅ RESOLVED (2026-04-21)
**Resolution:** All 19 Cloud Functions deployed to `tremble-dev` with `enforceAppCheck: true` and Zod schema validation. App Check + security hardening (Phase 11) is now live on dev.

## FUNCTIONS-DEPLOY — Cloud Functions Stale on tremble-dev
**Date:** 2026-04-18
**Status:** ✅ RESOLVED (2026-04-21)
**Resolution:** `firebase deploy --only functions --project dev` executed successfully. All 19 functions updated in europe-west1.

---

## BLOCKER-004 — Missing Maps API in Production
**Date:** 2026-04-20
**Status:** 🔴 OPEN
**Impact:** `am---dating-app` (Prod) has no Maps API enabled. App will fail to render maps in production flavor.
**Action:** Founder must enable Maps SDK for Android/iOS in Google Cloud Console for the prod project.
