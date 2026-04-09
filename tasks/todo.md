# Tremble - Project TODOs

## Active Focus: Phase 8 & 9 🚀

### 1. Phase 9: Security Hardening (Current)
- [ ] **Step 3:** Enforce Firebase App Check (`enforceAppCheck: true`) on all 21 Cloud Functions.
- [ ] **Step 4:** Security audit of Firestore rules for `proximity_events` collection.
- [ ] **Step 5:** Final GDPR deletion pipeline verification with production-like data sets.

### 2. Phase 8: Paywall & RevenueCat
- [ ] Initialize RevenueCat SDK in `subscription_service.dart`.
- [ ] Implement `isProProvider` and sync with Firestore `isPremium` field.
- [ ] Build Glassmorphic `PaywallScreen`.
- [ ] Implement Wave limits (5/day) for free users in `WaveRepository`.

---

## Technical Debt Cleaning (D-24/D-25)
- [ ] Complete Phase 2D: Extract remaining registration pages:
    - [ ] `languages_step.dart`
    - [ ] `dating_preferences_step.dart`
    - [ ] `what_to_meet_step.dart`
- [ ] Phase 2C Cleanup: Move 40+ Slovenian strings to `translations.dart`.
- [ ] Fix `CircularProgressIndicator` forever spinner in Forgot Password screen.

---

## Infrastructure & Store Prep
- [ ] Prepare Production release checklist.
- [ ] **FOUNDER:** Final review of TestFlight build with Rich Push.
- [ ] Update landing page for Privacy Policy on `trembledating.com`.

---
*Last Updated: 2026-04-10*
