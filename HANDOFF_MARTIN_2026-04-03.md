# Tremble — Martin Handoff
**Date:** 2026-04-03
**From:** Aleksandar (Technical Co-Founder)
**For:** Martin Dumanić (Android / Windows)
**Project:** `am---dating-app` (prod) / `tremble-dev` (dev)

---

## 1. Project State

### What is production-ready

| Area | Status | Notes |
|------|--------|-------|
| Cloud Functions | ✅ Deployed | All 18 onCall functions in `europe-west1` |
| Firestore Security Rules | ✅ Deployed | All collections covered, `proximity_events` write rule added today |
| Firebase AppCheck | ✅ Enforced on prod | All onCall functions protected |
| BLE Service (`ble_service.dart`) | ✅ Real implementation | `flutter_blue_plus` — not mock |
| Auth flow (login + onboarding) | ✅ Working | Google Sign-In + email |
| Matching + Greetings | ✅ Working | Cloud Functions handle all writes |
| Media uploads | ✅ Working | Cloudflare R2 via signed URLs |
| Production secrets (R2, Resend) | ✅ Set | Firebase Secret Manager |
| Multi-environment flavors | ✅ Working | Dev: `com.pulse` / Prod: `tremble.dating.app` |

### What is broken / pending

| ID | Issue | Severity |
|----|-------|----------|
| D-09 | Firestore triggers (`onBleProximity`, `onUserDocCreated`) still in `us-central1` — not yet migrated | Medium |
| D-12 | Firestore TTL policies not confirmed active in Firebase Console (see Section 3) | Medium |
| D-13 | `GOOGLE_WEB_CLIENT_ID` not confirmed set in prod Cloud Functions config — Aleksandar verifying | High |
| D-03 | GDPR consent screen (`consent_service.dart`, `permission_gate_screen.dart`) missing from `main` — in branch only | Medium |
| D-11 | `androidProvider`/`appleProvider` deprecated in `main.dart` — cosmetic, pre-launch cleanup | Low |

### Active branch

`feature/gdpr-permission-gate` — not merged, see Section 4.

---

## 2. Martin's Hardware Tasks (Samsung S25 Ultra)

### 2.1 Run the dev build

**Prerequisites:** Android Studio installed, USB debugging enabled on S25 Ultra, device connected.

```bash
# From repo root
flutter run --flavor dev --dart-define=FLAVOR=dev
```

Do not run `flutter run` without `--flavor dev`. This is a hard rule (Lessons Rule #1) — the app will fail to connect to Firebase without the correct flavor.

**Expected result:** App opens on the S25 Ultra, login screen appears with the Tremble dark theme.

---

### 2.2 BLE proximity test

**Goal:** Confirm that BLE scanning and `proximity_events` write reach the `onBleProximity` Cloud Function.

**What you need:**
- Two Android devices (S25 Ultra + any second Android with Tremble dev installed)
- Both logged in with different dev accounts

**Steps:**

1. Open Tremble on both devices — log in.
2. Activate radar on Device 1 (tap radar / start proximity session).
3. Activate radar on Device 2.
4. Hold devices within 5 metres of each other for at least 30 seconds.
5. Open Firebase Console → `tremble-dev` → Firestore → `proximity_events` collection.
6. Confirm new documents appear with both device UIDs.
7. Open Firebase Console → `tremble-dev` → Functions → Logs → filter `onBleProximity`.
8. Confirm the function triggered and returned success (no errors).

**Pass criteria:** Document written to `proximity_events`, `onBleProximity` triggered, no Firestore permission errors in logs.

**If permission denied errors appear in logs:** The prod rules are correct (`am---dating-app`). If you are testing dev (`tremble-dev`), the rules may not be in sync — let Aleksandar know.

---

### 2.3 Auth flow test

1. Sign out of the app.
2. Sign in with Google on the S25 Ultra.
3. Complete onboarding (all steps).
4. Confirm profile appears in Firestore `users/{uid}` in `tremble-dev`.

---

## 3. Martin's Firebase Tasks

### 3.1 Register Android SHA-256 fingerprint (AppCheck)

AppCheck on Android requires your device's SHA-256 signing certificate registered in Firebase.

**Step 1 — Get your debug keystore fingerprint:**

```bash
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android \
  -keypass android
```

Look for the line:
```
SHA256: XX:XX:XX:XX:...
```

Copy the full SHA-256 value.

**Step 2 — Register in Firebase Console:**

1. Go to [Firebase Console](https://console.firebase.google.com/) → project `tremble-dev`
2. Project Settings → Your Apps → Android app (`com.pulse`)
3. Scroll to **SHA certificate fingerprints**
4. Click **Add fingerprint** → paste your SHA-256 → Save

Repeat for `am---dating-app` if you also test the prod flavor (app ID: `tremble.dating.app`).

---

### 3.2 Register AppCheck debug token (Android)

When running a debug build, AppCheck requires a debug token so Cloud Functions do not reject requests.

**Step 1 — Find your debug token:**

Run the dev build on the S25 Ultra. In the Android Studio logcat, filter for `AppCheck` or `DebugAppCheckProvider`. You will see a line similar to:

```
D/FirebaseAppCheck: Enter this debug secret into the allow list in the Firebase Console for your project: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
```

Copy the UUID.

**Step 2 — Register in Firebase Console:**

1. Firebase Console → `tremble-dev` → App Check
2. Click your Android app
3. Scroll to **Debug tokens** → **Add debug token**
4. Paste the UUID → give it a name (e.g. `Martin-S25-Ultra`) → Save

**Step 3 — Verify:**

Re-run the dev build. BLE functions and Cloud Function calls should no longer return `AppCheck token is invalid` errors.

---

### 3.3 Confirm Firestore TTL policies (D-12)

Three collections must have TTL policies active to auto-delete expired documents. These were defined in code but need to be confirmed active in the Firebase Console.

**Check in Firebase Console → `am---dating-app` → Firestore → TTL:**

| Collection | Field | Expected TTL |
|------------|-------|-------------|
| `proximity_events` | `expiresAt` | 24 hours |
| `proximity` | `expiresAt` | 2 hours |
| `gdprRequests` | `expiresAt` | 30 days |

**How to verify:**

1. Firebase Console → `am---dating-app` → Firestore Database
2. Left sidebar → **TTL policies**
3. Confirm all three collection/field pairs appear with status `Active`

If any are missing or show `Processing`, report back to Aleksandar — do not create them yourself without a call.

---

## 4. Branches to Review

### `feature/gdpr-permission-gate`

**What it contains (1 commit):**
- `lib/src/core/consent_service.dart` — new file, GDPR consent service
- `lib/src/features/auth/presentation/permission_gate_screen.dart` — new screen, BLE/location permission gate
- `lib/src/core/router.dart` — updated to add `permission_gate` route
- `lib/src/core/background_service.dart` — gated on consent before BLE starts

**What to review (Android-specific):**

1. Checkout the branch locally:
   ```bash
   git checkout feature/gdpr-permission-gate
   flutter run --flavor dev --dart-define=FLAVOR=dev
   ```

2. Check the permission gate screen on S25 Ultra:
   - Does it appear after login, before BLE starts?
   - Do the BLE and Location permission dialogs fire correctly?
   - After granting permissions, does the radar screen load?

3. Check that BLE does **not** start if the user denies permissions — this is the critical gate.

4. Report findings to Aleksandar. **Do not merge this branch** — merge decision is Aleksandar's.

---

## 5. Do Not Touch

The following must not be modified without a call with Aleksandar:

| What | Why |
|------|-----|
| `GoogleService-Info.plist` / `google-services.json` | Prod Firebase config — wrong change breaks all auth |
| `android/app/build.gradle` (signing config) | Prod release signing — only Aleksandar has the keystore |
| `firestore.rules` (prod, `am---dating-app`) | Rules are live — a bad deploy breaks all clients |
| `functions/` — any Cloud Function | All Functions deployed to prod — wrong change breaks BLE + matching |
| `lib/src/core/firebase_options_prod.dart` | Prod Firebase config — do not edit |
| `Info.plist` (iOS, both targets) | iOS permissions and bundle IDs — only touch if Aleksandar approves |
| Any merge to `main` | Main is the deploy branch — Aleksandar merges |

---

## 6. How to Start a Claude Code Session

If you open the project with Claude Code (CLI), run this as your first command every session:

```
/gsd:resume-work
```

This restores full project context: current phase, open debt items, last session handoff, next action. Do not start writing or modifying code before running this.

**Quick session template:**

```
/gsd:resume-work
# Read the status output
# Ask Claude to fix the specific debt item or task
# At end of session: Claude updates context.md automatically
```

Claude Code is configured via `CLAUDE.md` in the repo root — it knows the architecture, flavors, rules, and agent routing. Trust it, but do not let it touch Firebase config, signing, or Cloud Functions without checking with Aleksandar.

---

*Questions: WhatsApp Aleksandar or open a GitHub Issue tagged `[martin-question]`.*
