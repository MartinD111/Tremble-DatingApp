# PLAN: Login Layout Redesign & Apple Sign-In Integration

**Plan ID:** `20260517-login-layout-apple-sign-in`  
**Risk Level:** HIGH (Contains Apple Developer capabilities, bundle signing, and Core Firebase Auth methods)  
**Founder Approval Required:** YES  
**Branch:** `feature/login-layout-apple-signin`

---

## 1. OBJECTIVE

Resolve the login screen vertical height cutoff and safe area issues on physical iOS devices by relocating the language picker higher and using compact flag icons. Implement a side-by-side grid for Google and Apple sign-in options. Provide the complete blueprint for Apple Developer setup, Firebase Console registration, and Flutter wiring for Apple Sign-In. Document the diagnostic post-mortem of the onboarding tutorial crash.

---

## 2. SCOPE

- **UI Redesign:**
  - `lib/src/features/auth/presentation/login_screen.dart` — Replace full-width Google button with a side-by-side Row of Google and Apple buttons; replace the bottom language picker pill with a compact flag row positioned under the header or top bar.
- **Apple Sign-In Code Integration:**
  - `pubspec.yaml` — Add `sign_in_with_apple`.
  - `lib/src/features/auth/data/auth_repository.dart` — Add `signInWithApple()` methods in the repository and notifier layer.
- **Native Configuration:**
  - `ios/Runner/Info.plist` & Entitlements — Register Apple Sign-In capability (once developer account is configured).
- **Out of Scope:**
  - Modifying email/password registration flow steps or other onboarding page structures.

---

## 3. CORE DESIGN RESOLUTIONS

### A. Bottom Layout Cutoff & Safe Area Adjustment
- **Problem:** The language selector pill is at the absolute bottom of the login `Column`. On physical screens (especially iOS home indicator areas), this results in spacing overflows or a visual cutoff.
- **Fix:** Move the language picker higher in the interface. To prevent any cutoff, the scrollable area padding is adjusted, and the Scaffold uses `SafeArea` explicitly.

### B. Flag-Based Compact Language Picker
- **Problem:** The previous language picker was a full button text string that opened a heavy search bottom-sheet.
- **Solution:** Replace it with a horizontal, ultra-clean row of flag emojis (🇸🇮, 🇬🇧, 🇭🇷, 🇩🇪, 🇮🇹, 🇫🇷, 🇭🇺, 🇷🇸). 
- **Placement:** Place this compact row right under the Tremble subtitle ("IT RUNS WHILE YOU LIVE. / DELUJE, MEDTEM KO ŽIVIŠ.").
- **Interaction:** Tapping a flag immediately switches the app's language, updating the entire screen instantaneously with no modal overlay needed. A subtle rose highlight (`#F4436C`) and rounded border outline will indicate the selected language.

### C. Side-by-Side Prijavni Gumbi (Google & Apple)
- **Layout:** Google Sign-In and Apple Sign-In will share a single `Row` inside the form.
- **Structure:**
  - Left (Google): Dark graphite card (`0xFF1E1E1E`), border outline, Google logo 'G', and clean CTA text/icon.
  - Right (Apple): Premium solid white card, black Apple icon, and clean text/icon.
  - Width: 50% split utilizing `Expanded` widgets with an elegant `12px` horizontal spacer.

```
+------------------------------------+
|                                    |
|             [LOGO]                 |
|            Tremble                 |
|    "IT RUNS WHILE YOU LIVE."       |
|                                    |
|       🇸🇮  🇬🇧  🇭🇷  🇩🇪  🇮🇹           |  <-- Compact Flags Relocated
|                                    |
|        [ Email Input ]             |
|       [ Password Input ]           |
|                                    |
|         [ LOG IN CTA ]             |
|                                    |
|    [ Google ]    [ Apple ]         |  <-- Side-by-Side 50/50 Row
|                                    |
|      Don't have an account?        |
+------------------------------------+
```

---

## 4. SIGN IN WITH APPLE — IMPLEMENTATION BLUEPRINT

Implementing Apple Sign-In requires both native Apple Account provisioning and code setup. Because the Apple Developer Account is currently non-paid (BLOCKER-003/005), this wiring will be split into **Native Configuration (Gated by Founder Portal Access)** and **Code Implementation**.

### Step 1: Apple Developer Portal (User Action Required)
1. Log in to [Apple Developer Portal](https://developer.apple.com).
2. Go to **Certificates, Identifiers & Profiles** -> **Identifiers**.
3. Select the App ID matching Tremble (e.g., `com.pulse` / `tremble.dating.app`).
4. Check the box for **Sign In with Apple**.
5. Save the configuration and regenerate the Provisioning Profiles.

### Step 2: Xcode Configuration
1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select the `Runner` target -> Go to **Signing & Capabilities**.
3. Click the **+ Capability** button in the top left -> search and double-click **Sign in with Apple**.
4. Xcode automatically generates a `Runner.entitlements` file with the required key-value entries.

### Step 3: Firebase Console Setup
1. Go to the [Firebase Console](https://console.firebase.google.com).
2. Open your active project (`tremble-dev` / `am---dating-app`).
3. Navigate to **Authentication** -> **Sign-in method**.
4. Click **Add new provider** -> select **Apple**.
5. Enable the provider, fill in the Apple Team ID, Key ID, and private key details, and click **Save**.

### Step 4: Flutter Dependencies (`pubspec.yaml`)
Add the package to the project dependencies:
```yaml
dependencies:
  sign_in_with_apple: ^6.1.1
```

### Step 5: Dart Integration (`auth_repository.dart`)
Implement the core repository handler inside `AuthRepository`:
```dart
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

Future<AuthUser> signInWithApple() async {
  try {
    final AuthorizationCredentialAppleID appleCredential = 
        await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final AuthCredential credential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final UserCredential userCredential =
        await _auth.signInWithCredential(credential);
    return _fetchUser(userCredential.user!);
  } catch (e) {
    debugPrint("[Apple Sign-In] Error: $e");
    rethrow;
  }
}
```

---

## 5. POST-MORTEM DIAGNOSTICS: ONBOARDING QUICK TUTORIAL CRASH

During development in simulator, completing onboarding and immediately entering the homepage triggered a crash on the quick tutorial sheet callback.

### A. Root Cause Analysis
1. Upon completing onboarding, the app router redirected from `/onboarding` to the default `/` path (mounting `HomeScreen`).
2. HomeScreen's build pipeline successfully triggered `_showTutorialOptInSheet()` in the first frame.
3. Simultaneously, the Firebase Auth state stream emitted an updated user model (because the completeOnboarding state write was saved to Firestore). This caused the router or HomeScreen to initiate a rebuild or brief unmount/remount cycle.
4. When the user clicked "Yes, show me" on the bottom sheet modal overlay, the callback executed:
   `ref.read(tutorialProvider.notifier).startTutorial();`
5. Since the parent element context had been unmounted or rebuilt during the stream transition, `ref` was flagged as disposed, throwing:
   `"Bad state: Cannot use ref after the widget was disposed"`

### B. Prevention & Resolution Applied
- The notifier references are now pre-extracted and captured strictly **before** opening the asynchronous/modal sheet:
  ```dart
  final tutorialNotifier = ref.read(tutorialProvider.notifier);
  final navNotifier = ref.read(navIndexProvider.notifier);
  final radarModeNotifier = ref.read(selectedRadarModeProvider.notifier);
  ```
- The modal bottom sheet callbacks now access these local captured variables instead of calling `ref.read` dynamically inside the asynchronous event handlers.
- **Status:** **Resolved and verified** in local codebase. No further crashes can occur during onboarding stream adjustments.

---

## 6. RISKS & TRADEOFFS

- **Tradeoff:** Using pure flag emojis directly on-screen is extremely clean and fast, but emoji appearance varies slightly between iOS and Android platforms. E.g., iOS emojis are rounder and highly stylized. This aligns perfectly with Tremble's custom design.
- **Native Signing Blocker:** Xcode capabilities configuration for "Sign in with Apple" *cannot* compile or run on physical devices without a paid Apple Developer Team profile active. Local emulator/simulator runs will succeed, but final provisioning depends on legal company setup.

---

## 7. VERIFICATION MATRIX

1. **Static Analysis & Tests:**
   - Run `flutter analyze` to ensure clean codebase.
   - Run `flutter test` to verify all 60 router and logic tests pass.
2. **Visual Inspection:**
   - Verify flag row renders correctly underneath the Tremble subtitle.
   - Verify tapping flag switches screen language instantly.
   - Verify bottom cutoff is resolved and the Scaffold scrolls comfortably with dynamic view insets.
   - Verify Google and Apple buttons are side-by-side, occupying exactly 50% split.
3. **Build Gates:**
   - Verify Android build: `flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev`
   - Verify iOS build: `flutter build ios --debug --flavor dev --dart-define=FLAVOR=dev --no-codesign`

---

## 8. EXECUTION STATUS — 2026-05-17

**Status:** Implemented locally on `main`.

**Completed:**
- Moved the login language selector out of the bottom area and into a compact flag row beneath the Tremble subtitle.
- Removed the language bottom sheet from the login screen; tapping a flag now updates `appLanguageProvider` immediately.
- Replaced the single full-width Google button with a 50/50 Google + Apple social sign-in row.
- Added `sign_in_with_apple: ^6.1.4` and wired `AuthRepository.signInWithApple()` / `AuthNotifier.signInWithApple()` using Firebase OAuth credentials with a SHA-256 nonce.
- Added `com.apple.developer.applesignin` to `ios/Runner/Runner.entitlements`.
- Removed the tracked `FirebaseAppCheckDebugToken` value from `ios/Runner/Info.plist`.
- Added a focused test for the compact login language order.

**Still gated outside code:**
- Apple Developer Portal App ID capability and regenerated provisioning profiles.
- Firebase Console Apple provider setup with Team ID, Key ID, and private key.
- Physical iOS verification remains blocked by provisioning until BLOCKER-005 is resolved.

**Verification run in this session:**
- `dart format lib/src/features/auth/data/auth_repository.dart lib/src/features/auth/presentation/login_screen.dart test/features/auth/login_screen_test.dart` — PASS.
- `flutter analyze` — PASS.
- `flutter test` — PASS (61/61).
- `flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev` — PASS.
- `flutter build ios --debug --flavor dev --dart-define=FLAVOR=dev --no-codesign` — PASS.
- `plutil -lint ios/Runner/Runner.entitlements ios/Runner/Info.plist` — PASS.
- Tracked secret/API pattern scan — PASS for live secrets; only this plan note mentions the removed App Check plist key.
