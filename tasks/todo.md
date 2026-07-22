# Tremble - Project TODOs (V5)

## Active Focus: Compliance & Launch Readiness

Based on the 06-JUL-2026 Master Compliance Report, the focus is strictly on unblocking the App Store/Play Store submissions and resolving critical GDPR/Legal risks.

### CRITICAL (Pred Submissionom)

- [x] **BLOCKER-STORE-001:** Add `PrivacyInfo.xcprivacy` to iOS project. (Task 6h3grHhjVXFhMRJP)
- [x] **BLOCKER-STORE-001:** Add `ITSAppUsesNonExemptEncryption` to `Info.plist`. (Task 6h3grHqC22mCcccP)
- [x] **BLOCKER-STORE-002:** Reconcile Contacts permission copy and live Privacy Policy. (Task 6h3p8gWpxpq7rWXw)
- [ ] **BLOCKER-STORE-003:** Submit Android Background Location declaration. (Task 6h3p8gWG7WHWV7JP)
- [ ] **BLOCKER-STORE-004:** Submit Android FGS declarations. (Task 6h3p8gc78572RF9P)
- [ ] **BLOCKER-LEGAL-001:** Fix DPIA to reflect actual code architecture. (Task 6h3jFhxVHpRmph9P)
- [x] **BLOCKER-LEGAL-002:** Remove cannabis collection from registration, schema, display, and production data. (Task 6h3jHjr7Hf58G8pw)
- [x] **BLOCKER-LEGAL-003:** Implement explicit GDPR Art. 9 consent for sexual orientation (`gender` + `lookingFor`). (Task 6h3j9q65vh3mG64P)
- [ ] **BLOCKER-LEGAL-004:** Fix backend/ToS mismatch for the "Weekend Getaway" free window. (Task 6h332RFRW946QWXw)
- [x] **BLOCKER-LEGAL-005:** Sync Paywall copy with actual RevenueCat gates. (Task 6h3pmrF84Cf6JVQP)
- [ ] **BLOCKER-STORE-005:** Verify the Firebase-stored APNs credential and complete build-22 physical-iPhone notification/action tests.

### ACTIVE (Build 35 — Precise Finder)

- [ ] **DEVICE-PASS-B35:** Two-phone device pass on build 35 (TestFlight) — reciprocal opt-in → arrow + distance 60→10m; one declines → fallback only; background → sharing stops. Script in `blockers.md` FEATURE-RADAR-SONAR. Closes the radar-sonar feature.
- [ ] **PLAY-B35:** Upload `release-symbols/b35/app-prod-release.aab` to Play Console (versionCode 35).
- [x] **FINDER-BACKEND:** rules + `updateFinderLocation`/`markMatchFound` deployed to prod; TTL on `finder.expireAt` ACTIVE (2026-07-22).

### REQUIRED (Pred Javno Objavo)

- [ ] **Legal:** Configure Cookie/Consent banner (e.g., Usercentrics) for web and app. (Task 6h3pmrHxhCHX7q8P)
- [ ] **App Store:** Provide EULA link and Age Rating declaration.
- [ ] **App Store:** Complete App Store Connect metadata, privacy labels, IAP products, reviewer account, screenshots, and review notes.
- [ ] **Legal web:** Publish `/sl/tos` and `/dsa-contact`; correct the Weekend Getaway ToS language.
- [ ] **Data Safety:** Complete Play Console Data Safety form accurately.
- [ ] **Android:** Provide video demonstrating background location usage.

### RECOMMENDED (Po Launchu)

- [x] Implement robust Account Deletion (GDPR Right to Erasure) automation in Cloud Functions.
- [ ] Enhance rate limiting for F12 interactions.
- [ ] Move any remaining non-critical legal docs to a CMS for easier updates.

---
*Last Updated: 2026-07-22*
