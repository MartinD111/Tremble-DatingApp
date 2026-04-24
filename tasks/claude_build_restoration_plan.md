# Plan ID: 20260424-Stability-Restoration-V2
**Risk Level:** MEDIUM (Touches Auth, Firestore, and Maps)
**Founder Approval:** REQUIRED for Maps SHA-1 verification
**Branch:** `fix/regressions-and-polish`

## 1. OBJECTIVE
Resolve all functional regressions introduced by recent merges: fix Maps authorization, restore Profile saving, fix Firestore proximity permissions, and polish the Radar UI to remove jitters and overflows.

---

## 2. SCOPE
### Files Affected:
- **UI/Polish:** `lib/src/shared/widgets/tremble_logo.dart`, `lib/src/features/profile/screens/edit_profile_screen.dart`, `lib/src/features/dashboard/widgets/profile_card.dart`
- **Logic/Auth:** `lib/src/features/profile/repositories/profile_repository.dart`, `lib/src/core/notification_service.dart`, `lib/src/core/router.dart`
- **Backend:** `functions/src/modules/proximity/proximity.functions.ts`
- **Config:** `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`

### What Does NOT Change:
- Core BLE scanning algorithms.
- Matching logic.
- Navigation structure.

---

## 3. DETAILED STEPS

### Phase 1: Build & Logic Restoration (Critical)
1.  **Notification Service Fix:**
    -   Remove `const` from `DarwinInitializationSettings` in `notification_service.dart` because it contains dynamic categories.
    -   Remove `const` from `InitializationSettings`.
2.  **Cloud Functions Fix:**
    -   Update `proximity.functions.ts`: Change `image` key to `imageUrl` in FCM payload to match Admin SDK expectations.
    -   Remove unused `haversineDistance` to satisfy strict compiler.
3.  **Auth Resilience in Router:**
    -   In `router.dart`, wrap `NEARBY_WAVE_ACTION` logic in a `StreamSubscription` to `FirebaseAuth.instance.authStateChanges()` or a retry loop to ensure `currentUser` is populated during cold starts from notification taps.

### Phase 2: Profile & Permission Fixes
1.  **Schema Alignment (The "Photo Save" Fix):**
    -   The backend now enforces strict fields: `location`, `hasChildren`, `interestedIn` (as string, not array), etc.
    -   Update `ProfileModel.toJson()` to ensure all mandatory fields are present.
    -   Ensure `photoUrl` is correctly passed if a new image was uploaded to Cloudflare R2.
2.  **Firestore Permission Audit:**
    -   The log shows `PERMISSION_DENIED` on `proximity/{uid}`.
    -   Verify `firestore.rules`. If the rule is `allow read, write: if false` (as per SEC-002), ensure the Flutter app is NOT trying to write directly to this collection. It should be handled via the `updateLocation` Cloud Function.
    -   Redirect any direct Firestore writes for location to the `updateLocation` function.

### Phase 3: UI Polish & Layout
1.  **Radar (Logo) Jitter & Pulse:**
    -   Audit `tremble_logo.dart`. 
    -   Ensure the pulse animation uses a `Tween` that reaches the edge of the circular container without clipping.
    -   Check for overlapping `Stack` children that might create the "double line" effect.
    -   Wrap the pulse painter in a `RepaintBoundary`.
2.  **Profile Card Overflows:**
    -   In `edit_profile_screen.dart`, wrap Gender and Preferences sections in a `Wrap` widget or a scrollable list to handle smaller screens.
    -   Adjust the "Info" button positioning in the dashboard profile card. Move it to a `Positioned(top: 8, right: 8)` and ensure it doesn't overlap the name/age title.
3.  **Your People Section:**
    -   Adjust layout constraints to prevent the info button from floating over text.

### Phase 4: Maps Restoration (High Risk)
1.  **Package Name & SHA-1 Sync:**
    -   Verify `com.pulse` package name in `android/app/build.gradle`.
    -   Run `cd android && ./gradlew signingReport` to extract the SHA-1 of the `dev` debug key.
    -   **ACTION FOR USER:** Verify that this SHA-1 is added to the Google Cloud Console "API & Services > Credentials" for the Maps API key, restricted to the `com.pulse` package.
2.  **API Key Verification:**
    -   Ensure the flavor-specific `google_maps_api_key` is being correctly injected into `AndroidManifest.xml`.

---

## 4. RISKS & TRADEOFFS
- **Strict Validation:** Updating the Profile model to match the backend might break compatibility with any older user documents that lack these new fields. Migration logic might be needed in the repository.
- **Maps Delay:** If the SHA-1 mismatch is in the Cloud Console, only the user (Founder) can fix it, as I don't have access to the GCP UI.

---

## 5. VERIFICATION PROTOCOL
1.  **Automated:**
    -   `flutter analyze` (Zero errors).
    -   `cd functions && npm run build` (Zero errors).
2.  **Manual (Device Test):**
    -   Verify Radar animation is smooth.
    -   Attempt to save a profile photo; verify no 400 errors in console.
    -   Open Map view; verify it doesn't show "Google Maps for this app is not authorized".
    -   Check for pixel overflows in Onboarding/Profile Edit.
