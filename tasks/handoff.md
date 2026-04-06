# Founder Handoff: Registration Stabilization & UI Audit (2026-04-06)

Aleksandar, the registration flow has been stabilized. While we successfully restored the mandatory data collection steps, we have identified configuration issues with Google Sign-In and Light Mode accessibility that require attention before launch.

## 1. 🚀 Critical Action Items (Require Founder Attention)
- [ ] **Google Sign-In / Forgot Password (D-02):**
    - Both are currently reported as non-functional. 
    - **Action:** Ensure the Android SHA-1 and SHA-256 fingerprints from your local dev machine (and production keystore) are added to the Firebase Console settings.
    - **Action:** Verify `google-services.json` and `GoogleService-Info.plist` are up to date and correctly placed in the project.
- [ ] **Production Secrets (D-02):** Still need `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, and `RESEND_API_KEY` set in Firebase Functions configuration.
- [ ] **GDPR Region Migration (D-07):** Verify the move of Cloud Functions and data storage to `europe-west1` for compliance.

## 2. ✅ Latest Accomplishments (Restored registration flow)
- **Flow Restoration:** Page 5 ("Basic information") is no longer skipped for social users. This ensures location and other mandatory bio fields are collected for everyone.
- **Logic Stabilization:** Fixed a critical bug in `AuthRepository.registerWithEmail` where the `uid` was being passed improperly.
- **Loading UX:** Implemented `_isRegistering` state on the registration button to prevent multiple form submissions/race conditions.
- **Naming Alignment:** Page title updated from "Confirm details" to "Basic information" to better reflect the required user action.

## 3. ⚠️ Current Known Issues (Pending Polish)
- **Accessibility (Contrast):** 
    - "Tremble Rose" color on light backgrounds has insufficient contrast in Light Mode.
    - Selectable "pills" in registration are difficult to read in some lighting conditions.
- **Theme Persistence:** The "Enable Radar" screen sometimes ignores the previously selected Dark Mode preference.
- **Responsive Text:** The word "Introvertiranost" (and similar Slovenian labels) causes overflow/bad wrapping on smaller device screens.
- **Age Slider:** Age values are not visible immediately on launch; the user must often scroll or interact before the numerical indicators appear.

## 4. 📝 Next Development Steps
- [ ] **Configuration Fix:** Resolve the SHA/Keystore mismatch causing Google Sign-In failures.
- [ ] **Light Mode Audit:** Refactor the theme system to ensure "Tremble Rose" and UI components are WCAG compliant in light mode.
- [ ] **BLE Background Test:** Conduct a 30-minute stationary radar test to verify background persistence on Android.

---
*Prepared by Antigravity AI — Handoff for Aleksandar.*
