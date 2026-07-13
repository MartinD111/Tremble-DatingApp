# Blockers & Investigation Findings

---

## CRITICAL — Store Blockers (Pred Submissionom)

### BLOCKER-STORE-001 — iOS Privacy Manifest & Encryption Declaration
**Date:** 2026-07-06
**Status:** OPEN
**Impact:** App Store will automatically reject the build starting from iOS 17.4 without a privacy manifest. Missing encryption declaration will cause App Store Connect rejection.
**Action:** Add `PrivacyInfo.xcprivacy` and add encryption declaration to `Info.plist`. (Task 6h3grHhjVXFhMRJP, 6h3grHqC22mCcccP)

### BLOCKER-STORE-002 — iOS Info.plist Contacts Contradiction
**Date:** 2026-07-06
**Status:** RESOLVED 2026-07-13 — code side reconciled
**Impact:** `Info.plist` stated contacts are not accessed, but Privacy Policy §2.5 says they are. Apple 5.1.1 rejection risk.
**Resolution (PR fix/info-plist-contacts-reconcile, KORAK 3.8-1):**
- Master `NSContactsUsageDescription` rewritten to match localized `en.lproj/InfoPlist.strings` verbatim (describes Anonymity Mode / ADR-004).
- Three duplicate permission keys removed from Info.plist (NSCameraUsageDescription, NSPhotoLibraryUsageDescription, NSPhotoLibraryAddUsageDescription). Founder decision 2026-07-13: kept the L46/L48 wording that covers Pulse Intercept (v1 feature); L50-51 replaced with the Apple-preferred explicit-consent NSPhotoLibraryAdd variant.
- `PrivacyInfo.xcprivacy` now declares `NSPrivacyCollectedDataTypeContacts` (Linked=false per ADR-004 hash-only transmission; Tracking=false; Purpose=AppFunctionality).
**Still-owed (founder, PLAN_04 KORAK 4.2):** align `trembledating.com/privacy` §2.5 web copy with Anonymity Mode + hashed transmission. Required before actual App Store submission.
(Task 6h3p8gWpxpq7rWXw)

### BLOCKER-STORE-003 — Android Background Location Declaration
**Date:** 2026-07-06 (updated 2026-07-07)
**Status:** OPEN — code side done, Play Console side pending
**Impact:** Requires Prominent Disclosure, a demo video, and a special declaration in Google Play Console. This review process takes 2-4 weeks and blocks Android launch.
**Progress (2026-07-07, PR #7 / commit a3f793b, Session 42):**
- ✅ Standalone Prominent Disclosure screen added at `lib/src/features/auth/presentation/prominent_disclosure_screen.dart` — shown between foreground grant and OS background prompt on both Android and iOS.
- ✅ Consent flow refactored so the OS `ACCESS_BACKGROUND_LOCATION` prompt only fires after the disclosure's primary CTA is tapped. "Not now" completes onboarding with foreground-only location.
- ✅ Android is now a first-class background-location caller (previously the manifest permission was silently dormant).
- ⏳ Copy in EN + SL is spec-verbatim and **must go through `brand-voice-agent` review** before ship.
- ⏳ EN + SL screenshots of the new screen must be captured on an emulator/device for the Play submission package.
- ⏳ Play Console declaration + demo video still need to be submitted.
**Action:** Run copy through brand-voice-agent, capture screenshots, record demo video, submit Play declaration. (Task 6h3p8gWG7WHWV7JP)

### BLOCKER-STORE-004 — Android Foreground Services Declaration
**Date:** 2026-07-06
**Status:** OPEN
**Impact:** FGS types (location, connectedDevice, dataSync) require Google Play declaration.
**Action:** Submit FGS declaration to Google Play. (Task 6h3p8gc78572RF9P)

---

## CRITICAL — Legal Blockers (Pred Submissionom)

### BLOCKER-LEGAL-001 — DPIA False Claims
**Date:** 2026-07-06
**Status:** OPEN
**Impact:** DPIA falsely claims `getPublicProfile` doesn't leak sensitive data, and lists incorrect TTLs (24h vs 2h). Evidence of discrepancy during an audit is an aggravating factor.
**Action:** Fix DPIA to match codebase reality. (Task 6h3jFhxVHpRmph9P)

### BLOCKER-LEGAL-002 — Cannabis Legal Classification
**Date:** 2026-07-06
**Status:** OPEN
**Impact:** `nicotineUse` bundles cannabis with vape. In some jurisdictions, cannabis data is "criminal offense data" (Art. 10 GDPR), meaning consent cannot legitimize it.
**Action:** Separate cannabis into its own field pending legal review. (Task 6h3jHjr7Hf58G8pw)

### BLOCKER-LEGAL-003 — Sexual Orientation (GDPR Art. 9) Missing Consent
**Date:** 2026-07-06
**Status:** OPEN
**Impact:** The combination of `gender` + `lookingFor` implicitly reveals sexual orientation. As an Art. 9 category, processing without explicit consent is a massive GDPR violation (Grindr fined NOK 65M for this).
**Action:** Add an explicit consent gate for processing these fields. (Task 6h3j9q65vh3mG64P)

### BLOCKER-LEGAL-004 — Weekend Window ToS Mismatch
**Date:** 2026-07-06
**Status:** OPEN
**Impact:** ToS §7 promises an automatic weekend window (Fri 19h - Sun 19h), but code doesn't enforce this. This is an unfair business practice / consumer deception.
**Action:** Align code enforcement with ToS, or amend ToS. (Task 6h332RFRW946QWXw)

### BLOCKER-LEGAL-005 — Paywall False Advertising
**Date:** 2026-07-06
**Status:** OPEN
**Impact:** Paywall advertises features that don't exist in code ("unlimited geofence pings") and hides features that are actually gated ("see who waved"). Violates Apple 3.1.2 and consumer protection laws.
**Action:** Sync `premium_screen.dart` with actual backend gate logic. (Task 6h3pmrF84Cf6JVQP)

---

## ARCHIVED BLOCKERS (Resolved)

> **B001 / ADR-001** (iOS BLE Background State) ✅ RESOLVED 2026-04-29
> **B002 / D-37** (3-State Map Toggle) ✅ RESOLVED 2026-04-29
> **B003** (Company Setup / RevenueCat) ✅ RESOLVED 2026-05-07
> **B004 / F5** (Strava/Health Integration) ✅ REMOVED 2026-04-30
> **B005** (iOS Dev Provisioning for com.pulse) ✅ RESOLVED
> **B006** (Photo Upload / Onboarding E2E) ✅ RESOLVED
> **B007** (Legal Web Pages Live) ✅ RESOLVED 2026-05-26
