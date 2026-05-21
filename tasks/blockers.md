# Blockers & Investigation Findings

---

## BLOCKER-001 / ADR-001 — iOS BLE Background State Restoration
**Date:** 2026-04-29
**Status:** ✅ RESOLVED
**Impact:** `flutter_blue_plus` is now integrated via NativeMotionService EventChannel, successfully enabling background state restoration.
**Action:** None.

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

## BLOCKER-004 — F5 (Strava/Health) Integration
**Date:** 2026-04-30
**Status:** ✅ RESOLVED (REMOVED)
**Impact:** Feature permanently removed to align with privacy-first philosophy.
**Action:** Cleanup code leftovers (D-43) — COMPLETED 2026-04-30.

## BLOCKER-005 — iOS Dev Provisioning for `com.pulse`
**Date:** 2026-05-17
**Status:** 🟡 OPEN
**Impact:** Physical iPhone deploy for dev flavor cannot complete because Xcode cannot register or find an iOS App Development provisioning profile for bundle identifier `com.pulse` under team `K9VCTUX87F`.
**Evidence:** `flutter run -d 00008120-001618402604201E --flavor dev --dart-define=FLAVOR=dev` fails at signing with “Failed Registering Bundle Identifier” and “No profiles for 'com.pulse' were found.”
**Action:** In Apple Developer/Xcode, create or select a valid development profile for `com.pulse`, or explicitly approve a local-only dev bundle identifier change before physical-device verification.

## BLOCKER-006 — Photo Upload / Onboarding E2E Not Verified
**Date:** 2026-05-21
**Status:** 🔴 OPEN
**Impact:** Registration can still be broken after the photo step if the R2 upload, `completeOnboarding`, and Firestore profile write do not succeed end to end on `tremble-dev`.
**Evidence:** `generateUploadUrl` is deployed on `tremble-dev`, but no authenticated app run has verified picker → presigned URL → R2 PUT → `photoUrls` → `completeOnboarding`. Code audit found Flutter sends `interestedIn` as `List<String>` while backend schemas expected a single enum string; fixed and deployed to `tremble-dev` on 2026-05-21 with regression tests.
**Action:** Run a physical/simulator registration with a real image and confirm `photoUrls` persists in Firestore. Requires App Check debug token to be registered first.

## BLOCKER-007 — Legal Web Pages Not Confirmed Live
**Date:** 2026-05-21
**Status:** 🟡 OPEN
**Impact:** App Store / Play Store review can fail if Privacy Policy, Terms, and Erasure pages are not live and linked on `trembledating.com`.
**Evidence:** Website sources exist under `../Website/Izvedba/tremble-website/app/privacy` and `app/erasure`, but this mobile repo has no proof that final Privacy Policy, ToS, and Erasure Form are published live.
**Action:** Verify live URLs on `trembledating.com`, add missing ToS if absent, and link them from store metadata and app settings.

---

*(Historical resolved blockers (SEC-001, FUNCTIONS-DEPLOY, SEC-002, F5, etc.) have been archived to `MASTER_PLAN.md` and `lessons.md` to keep this file actionable).*
