# Session Handoff — 2026-04-11 (Auth-to-Firestore Routing Guard)

## 1. What Was Built

The Auth→Firestore routing guard was fully re-architected. The app now has a strict 4-state machine that prevents any user from seeing the Home/Radar screen unless their Firestore document confirms `isOnboarded: true`.

### Files changed
| File | Change |
|------|--------|
| `lib/src/features/auth/data/auth_repository.dart` | Added `ProfileStatus` sealed class + `profileStatusProvider` StreamProvider |
| `lib/src/core/router.dart` | Extracted `computeRedirect` pure function, updated `_RouterNotifier`, added `_SplashLoadingScreen` |
| `test/features/auth/profile_status_test.dart` | New — 11 unit tests |
| `test/core/router_redirect_test.dart` | New — 16 unit tests |

### What the routing guard now does
```
Auth not initialized         → hold (show splash)
Not logged in                → /login
Logged in, Firestore loading → hold (show full-screen spinner — never Radar)
Logged in, doc missing       → /onboarding
Logged in, isOnboarded=false → /onboarding
Logged in, isOnboarded=true, no GDPR consent → /permission-gate
Logged in, isOnboarded=true, consent given   → / (Home/Radar)
```

`profileStatusProvider` is now a **real-time Firestore stream** (`snapshots()`), not a one-shot future. It reacts automatically when the Cloud Function writes `isOnboarded: true` after `completeOnboarding` — no manual cache invalidation needed.

---

## 2. Open Issue — Action Required

### Problem: `isOnboarded: false` data corruption in Firestore

After deploying this fix, testing revealed that **some accounts (including the dev test account) have `isOnboarded: false` in Firestore even though the user completed registration.** The old code had a "self-healing" heuristic that silently detected profile fields and overrode `isOnboarded` to `true`. That heuristic has been removed — the router now reads the Firestore value strictly.

**Root cause:** During dev testing, `completeOnboarding` Cloud Function failed (e.g. App Check not enforced, network timeout), the debug fallback ran `markOnboardedDirectly`, but that Firestore write also failed silently. Local state showed `isOnboarded: true`, Firestore stored `false`. On every cold start, the stream reads Firestore → `false` → router sends to `/onboarding`.

### How to identify affected accounts

Open **Firebase Console → Firestore → `users` collection** and look for documents where:
- `isOnboarded: false`
- But `name`, `gender`, `birthDate`, or `photoUrls` are present (profile was filled)

### Fix option A — Manual (dev accounts only)
In Firebase Console → `users/{uid}` → edit field `isOnboarded` → set to `true`.

### Fix option B — One-time migration script (recommended for any affected prod users)

Run this from the Firebase Admin SDK or Cloud Functions shell:

```typescript
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

const db = getFirestore();

async function fixOnboardingFlags() {
  const snapshot = await db.collection('users')
    .where('isOnboarded', '==', false)
    .get();

  let fixed = 0;
  for (const doc of snapshot.docs) {
    const data = doc.data();
    const hasProfile =
      (data.name && data.name.trim().length > 0) ||
      data.gender != null ||
      data.birthDate != null ||
      (Array.isArray(data.photoUrls) && data.photoUrls.length > 0);

    if (hasProfile) {
      await doc.ref.update({
        isOnboarded: true,
        updatedAt: FieldValue.serverTimestamp(),
      });
      console.log(`Fixed: ${doc.id}`);
      fixed++;
    }
  }
  console.log(`Done — fixed ${fixed} accounts`);
}

fixOnboardingFlags();
```

Run once against **dev**, verify, then run against **prod**.

### Fix option C — Harden `completeOnboarding` (prevents future corruption)

In `AuthNotifier.completeOnboarding` (`auth_repository.dart`), the `markOnboardedDirectly` fallback should retry on failure and not update local state if Firestore write fails:

```dart
// Current code updates local state even if markOnboardedDirectly fails
state = user.copyWith(isOnboarded: true); // ← moves even on write failure

// Safer: only update local state if Firestore confirmed
```

This is a follow-up hardening task, not blocking for the data fix.

---

## 3. Verification Steps

After fixing the Firestore data:

1. Fresh login (no cached session) on physical Android device → must land on `/onboarding`
2. Returning user with `isOnboarded: true` → must land on `/` (Radar)
3. Navigate directly to `/settings` URL while `isOnboarded: false` → must redirect to `/onboarding`
4. `flutter analyze` → 0 issues
5. `flutter test` → 27/27 passing

---

## 4. What Is NOT Affected

- Registration flow itself — unchanged
- GDPR consent gate — unchanged, still works after onboarding
- Notification deep links — unchanged
- Match reveal screen — unchanged
- Google Sign-In — unchanged

---

*Prepared by Martin — Session 2026-04-11*
