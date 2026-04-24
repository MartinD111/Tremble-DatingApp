# Plan ID: 20260424-Build-Restoration
**Risk Level:** LOW (Fixing syntax errors)
**Founder Approval:** GRANTED (Via delegation to Claude CLI)
**Branch:** `feature/build-restoration`

## 1. OBJECTIVE
Restore the Flutter and Firebase builds that were broken by hasty implementation. Fix `const` initialization errors in Dart, resolve strict TypeScript compiler errors in Cloud Functions, and ensure Firebase Auth is safely read when processing notification actions.

## 2. SCOPE
**Files Affected:**
- `lib/src/core/notification_service.dart`
- `functions/src/modules/proximity/proximity.functions.ts`
- `lib/src/core/router.dart`

**What Does NOT Change:**
- Proximity scanning logic.
- UI components (PermissionGateScreen, TrembleLogo).
- Native Android/iOS configuration.

## 3. STEPS FOR CLAUDE CLI

### Step 1: Fix Flutter Syntax Errors
**Target:** `lib/src/core/notification_service.dart`
**Action:**
1. Locate the `iosSettings` declaration around line 124.
2. Remove the `const` keyword from `const DarwinInitializationSettings(...)` because the `categories` argument passed to it is dynamic.
3. Locate `_notifications.initialize(...)` around line 132.
4. Remove the `const` keyword from `const InitializationSettings(...)`.
**Verification:** `flutter analyze` must no longer flag `const_initialized_with_non_constant_value`.

### Step 2: Fix Cloud Functions TypeScript Errors
**Target:** `functions/src/modules/proximity/proximity.functions.ts`
**Action:**
1. Locate the FCM `notification` payload object around line 385.
2. Change the property name `image: photoUrl` to `imageUrl: photoUrl` (this is the correct key for the Firebase Admin SDK).
3. Locate the `haversineDistance` function around line 96.
4. Delete the entire `haversineDistance` function block, as it is unused and violates strict `noUnusedLocals` TypeScript settings.
**Verification:** Run `cd functions && npm run build`. It must exit with code `0`.

### Step 3: Secure Background/Foreground Auth State
**Target:** `lib/src/core/router.dart` (Inside `handleNotificationNavigation`)
**Action:**
1. Locate the `NEARBY_WAVE_ACTION` block.
2. The current implementation relies on `FirebaseAuth.instance.currentUser?.uid`. If the app was completely terminated (cold start), Firebase Auth might take a few milliseconds to restore the user session.
3. Wrap the UID retrieval in a short retry mechanism (e.g., waiting up to 1 second for `currentUser` to become non-null) or explicitly await the auth state change stream for the first non-null emission before executing the Firestore write.
**Verification:** Ensure the code compiles.

## 4. RISKS & TRADEOFFS
- **Auth State Timing:** Waiting for Auth state in `router.dart` might delay the wave execution by a few hundred milliseconds, but it prevents silent failures.

## 5. VERIFICATION PROTOCOL
Claude must run the following commands sequentially and verify they all pass before marking this complete:
```bash
flutter analyze
cd functions && npm run build
```
No warnings, no errors.
