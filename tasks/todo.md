# Tremble - Project TODOs

## Active Focus: Bug Fixes (Wave & Profile Persistence) 🚀

### 1. Fix Wave Logic (BUG-001)
- [ ] Replace `sendGreeting` call in `match_repository.dart` with `WaveRepository.sendWave()`.
- [ ] Verify Firestore write for `waves` collection.

### 2. Fix Profile Persistence (BUG-002)
- [ ] Update `updateProfileSchema` in `functions/src/modules/users/users.schema.ts`.
- [ ] Verify image and hobby saving logic.

### 3. Continue Background Service Hardening
- [ ] **Step 3:** Enforce Firebase App Check (`enforceAppCheck: true`) on all 21 Cloud Functions.


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
