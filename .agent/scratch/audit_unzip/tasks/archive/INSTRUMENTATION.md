# Auth Loop Bug — Instrumentation Guide

## Setup

The codebase now has detailed logging added at 3 levels:

### 1. Registration Flow (`_registerUser`)
```
[TREMBLE_AUTH_FLOW] _registerUser() called
[TREMBLE_AUTH_FLOW] Register succeeded. Firebase currentUser=...
[TREMBLE_AUTH_FLOW] Advancing page from X to Y
```

### 2. Router (`computeRedirect`)
```
[TREMBLE_ROUTER] computeRedirect() called: currentPath=..., authUser=..., profileLoading=...
[TREMBLE_ROUTER] Profile status: ..., needsOnboarding=...
[TREMBLE_ROUTER] Needs onboarding, redirecting to: /onboarding
```

### 3. Router Notifier (`_RouterNotifier`)
```
[ROUTER] authStateProvider → user: ...
[ROUTER] profileStatusProvider → ... authStreamFired=...
[ROUTER] redirect /path → /newpath ...
```

## Reproduction Steps

1. **Build and run the app in dev mode**
   ```bash
   flutter run --flavor dev --dart-define=FLAVOR=dev
   ```

2. **Navigate to registration**
   - Open app
   - Tap "Are you new?" (or navigate to `/onboarding`)

3. **Progress through steps**
   - Complete intro slides
   - Set birthday

4. **On Email/Location step (page 5)**
   - Enter email: `test@example.com`
   - Enter password: `Password123!`
   - Enter location: `City, Country`
   - Tap "Continue"

5. **Observe the bug**
   - Expected: Page advances to Name step
   - Actual: User gets redirected back to an earlier page or sees a loop

6. **Capture logs**
   - Open DevTools (Chrome `localhost:9100` for Flutter)
   - Scroll through the console output
   - Look for the sequence of `[TREMBLE_AUTH_FLOW]`, `[TREMBLE_ROUTER]`, and `[ROUTER]` messages

## Log Analysis — What to Look For

### Scenario A: Router Redirect Interrupts Page Advance
```
[TREMBLE_AUTH_FLOW] _registerUser() called. currentUser=null, currentPage=5
[TREMBLE_AUTH_FLOW] Calling authStateProvider.notifier.register()
[ROUTER] authStateProvider → user: <UID>
[TREMBLE_ROUTER] computeRedirect() called: currentPath=/onboarding, authUser=test@example.com, profileLoading=true
[TREMBLE_ROUTER] Profile loading, holding...
[TREMBLE_ROUTER] redirect /onboarding → (stay)  ...
[TREMBLE_AUTH_FLOW] Register succeeded. Firebase currentUser=test@example.com
[TREMBLE_AUTH_FLOW] Advancing page from 5 to 6
[ROUTER] profileStatusProvider → Loaded(notFound) authStreamFired=true
[TREMBLE_ROUTER] computeRedirect() called: currentPath=/onboarding, authUser=test@example.com, profileLoading=false
[TREMBLE_ROUTER] Profile status: notFound, needsOnboarding=true
[TREMBLE_ROUTER] Needs onboarding, redirecting to: /onboarding
[TREMBLE_ROUTER] redirect /onboarding → /onboarding ...
```

**→ Result:** Page advances to 6, but immediately the router sees `needsOnboarding=true` and redirects to `/onboarding`, which RECREATES the RegistrationFlow widget, resetting the PageController to page 0. User sees a jump backward.

### Scenario B: Race Where Profile Is Cached (Second Attempt)
On the second attempt, the profile document might exist in Firestore (from the first partial registration), so:
```
[ROUTER] profileStatusProvider → Loaded(ready: isOnboarded=false) authStreamFired=true
[TREMBLE_ROUTER] computeRedirect() called: ..., profileLoading=false
[TREMBLE_ROUTER] Profile status: Ready(isOnboarded=false), needsOnboarding=true
[TREMBLE_ROUTER] Needs onboarding, redirecting to: /onboarding
```

**→ Result:** Same as Scenario A. However, if the profile already has `isOnboarded=true` from the previous attempt, the redirect won't fire, and the page advances normally.

---

## Hypothesis Summary

**Root Cause:** When `_registerUser()` creates a Firebase account, the auth state changes and triggers the router's `_RouterNotifier` listener. At that moment:
- `authUser` is not null (newly created)
- `profileStatus` is loading or notFound (Firestore profile hasn't been created yet)
- `needsOnboarding = true` (profile is missing or not onboarded)

The router then calls `computeRedirect()` → returns `/onboarding` → redirects the entire navigation stack. This causes a new `RegistrationFlow` instance to be created, resetting the PageController to page 0.

**The Page Advance Is Lost:** Even though `_registerUser()` advances the PageController from page 5 to page 6, the router redirect interrupts this and recreates the screen, causing the PageController to reset.

---

## Next Steps

1. Run the app with the instrumentation enabled
2. Capture the full log sequence from email/password entry → expected page 6 advance
3. Paste the log output here or to the issue tracker
4. Confirm which scenario matches (A or B above)
5. Implement the fix based on the root cause

---

## Possible Fixes (Do Not Implement Yet)

Once the root cause is confirmed, fixes will fall into one of these categories:

### Fix Option 1: Suppress Router Redirect During Registration
- Once the registration flow starts, set a flag: `isRegistrationInProgress = true`
- In `computeRedirect()`, if `isRegistrationInProgress && currentPath == '/onboarding'`, return `null` (stay)
- Clear the flag once `_completeRegistration()` writes the profile to Firestore

### Fix Option 2: Create Profile Eagerly on Email Registration
- In `_registerUser()`, immediately write a skeleton profile to Firestore with `isOnboarded=false`
- This prevents `needsOnboarding=true` from triggering a redirect
- Fill in the rest of the profile as the user completes each step

### Fix Option 3: Defer Router Redirect Until Profile Is Fully Created
- Modify `computeRedirect()` to check: if `authUser.isOnboarded=false` AND `currentPath=='/onboarding'`, stay (don't redirect)
- Only redirect when profile is missing entirely, not when it exists but isn't onboarded

---

## Debugging Commands

**View debug logs in console:**
```bash
# In Flutter DevTools, search for [TREMBLE_AUTH_FLOW], [TREMBLE_ROUTER], [ROUTER]
```

**Simulate the flow programmatically:**
```dart
// In registration_flow.dart, add a button to manually test:
TextButton(
  onPressed: () {
    debugPrint('[TEST] Current Firebase user: ${FirebaseAuth.instance.currentUser?.email}');
    debugPrint('[TEST] Current PageController page: $_currentPage');
  },
  child: const Text('Debug Auth State'),
),
```

**Check Firestore state after registration attempt:**
```bash
# In Firebase Console:
# Cloud Firestore → users → [userID]
# Check if profile document exists and what fields are set
```
