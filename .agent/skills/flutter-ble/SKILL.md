---
name: firebase-security
description: Use this skill when writing or reviewing Firestore Security Rules, Cloud Functions auth/App Check middleware, or before any Firebase production deployment. Covers Tremble-specific data model security patterns.
origin: Tremble
---

# Firebase Security Skill

Tremble-specific Firebase security patterns for Firestore Rules, Cloud Functions middleware, and App Check enforcement.

## When to Activate

- Writing or modifying Firestore Security Rules
- Adding new Cloud Functions (onCall or triggers)
- Implementing or changing authentication flows
- Before deploying to `am---dating-app` (production)
- After any schema change to user/match/proximity documents
- Reviewing App Check enforcement status

---

## 1. Firestore Security Rules

### Core Principles

Every rule must answer: **"Can this authenticated user access this specific document?"**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(uid) {
      return request.auth.uid == uid;
    }

    function isValidString(val, maxLen) {
      return val is string && val.size() > 0 && val.size() <= maxLen;
    }

    function isValidAge(age) {
      return age is int && age >= 18 && age <= 100;
    }

    // Users collection
    match /users/{userId} {
      // Anyone authenticated can read public profiles
      allow read: if isAuthenticated();

      // Only owner can write their own document
      allow create: if isOwner(userId)
        && isValidString(request.resource.data.displayName, 50)
        && isValidAge(request.resource.data.age)
        && request.resource.data.keys().hasAll(['displayName', 'age', 'geohash']);

      allow update: if isOwner(userId)
        // Prevent changing immutable fields
        && request.resource.data.uid == resource.data.uid
        && request.resource.data.createdAt == resource.data.createdAt;

      allow delete: if isOwner(userId);
    }

    // Proximity/radar — users write their own location only
    match /proximity/{userId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId);
    }

    // Matches — both participants can read, Cloud Functions write
    match /matches/{matchId} {
      allow read: if isAuthenticated()
        && (resource.data.user1 == request.auth.uid
            || resource.data.user2 == request.auth.uid);

      // Only Cloud Functions create/update matches (via Admin SDK)
      allow write: if false;
    }

    // Greetings — sender can create, recipient can update (accept/reject)
    match /greetings/{greetingId} {
      allow read: if isAuthenticated()
        && (resource.data.senderId == request.auth.uid
            || resource.data.recipientId == request.auth.uid);

      allow create: if isAuthenticated()
        && request.resource.data.senderId == request.auth.uid
        && request.resource.data.status == 'pending';

      allow update: if isAuthenticated()
        && resource.data.recipientId == request.auth.uid
        && request.resource.data.status in ['accepted', 'rejected']
        // Prevent changing core fields
        && request.resource.data.senderId == resource.data.senderId;

      allow delete: if false;
    }

    // Blocks — owner manages their own block list
    match /blocks/{blockId} {
      allow read: if isAuthenticated()
        && resource.data.blockerId == request.auth.uid;
      allow create: if isAuthenticated()
        && request.resource.data.blockerId == request.auth.uid;
      allow delete: if isAuthenticated()
        && resource.data.blockerId == request.auth.uid;
    }

    // Reports — write-only for authenticated users, no read
    match /reports/{reportId} {
      allow create: if isAuthenticated()
        && request.resource.data.reporterId == request.auth.uid;
      allow read: if false; // Admin only via Admin SDK
      allow update, delete: if false;
    }
  }
}
```

### Rules Verification Steps

```bash
# Run Firebase emulator rules tests
firebase emulators:start --only firestore
npm run test:rules   # if you have rules test suite

# Manually test a rule
firebase firestore:rules --check-rule "get /databases/(default)/documents/users/uid123"
```

### Rules Checklist

- [ ] Every collection has explicit allow/deny rules
- [ ] No `allow read, write: if true` anywhere
- [ ] User documents enforce `request.auth.uid == userId`
- [ ] Immutable fields (uid, createdAt) cannot be changed via rules
- [ ] Matches collection: only Admin SDK can write (Cloud Functions)
- [ ] Reports: write-only for users (no read)
- [ ] Field-level validation in create rules (type, length, range)

---

## 2. Cloud Functions Auth Middleware

### Required Pattern for All onCall Functions

Every `onCall` function in Tremble must call these in order:

```typescript
import { requireAppCheck } from '../middleware/appCheck';
import { requireAuth } from '../middleware/authGuard';

export const myFunction = onCall(async (request) => {
  // 1. App Check FIRST — blocks non-app clients
  requireAppCheck(request);

  // 2. Auth SECOND — ensures user is logged in
  const uid = requireAuth(request);

  // 3. Input validation THIRD — Zod schema
  const data = MySchema.parse(request.data);

  // 4. Business logic
  ...
});
```

### requireAppCheck implementation

```typescript
// functions/src/middleware/appCheck.ts
import { CallableRequest, HttpsError } from 'firebase-functions/v2/https';

export function requireAppCheck(request: CallableRequest): void {
  if (request.app == undefined) {
    console.warn('[AppCheck] Unverified request blocked', {
      uid: request.auth?.uid ?? 'unauthenticated',
    });
    throw new HttpsError(
      'failed-precondition',
      'The function must be called from an App Check verified app.'
    );
  }
}
```

### Trigger Functions (NO App Check)

Firestore triggers run server-side — they have no `request.app`:

```typescript
// DO NOT call requireAppCheck() on triggers
export const onUserDocCreated = onDocumentCreated(
  'users/{userId}',
  async (event) => {
    // No App Check, no requireAuth — this is server-side only
    const uid = event.params.userId;
    ...
  }
);
```

---

## 3. App Check Status

### Check Enforcement Status

```bash
# Firebase Console → App Check → Each app → Check "Enforced" toggle
# tremble-dev: can be in "monitoring" mode
# am---dating-app (production): must be "enforced" before launch
```

### Monitoring vs Enforcement

| Mode | What it does |
|------|-------------|
| Monitoring | Logs unverified requests but allows them |
| Enforced | Blocks all unverified requests |

**Never launch to production without enforcement enabled.**

### Debug Token Workflow

```
1. Flutter debug build runs → prints token to console
2. Copy token from Xcode/Android Studio logs: "[AppCheck] debug token: xxxx"
3. Firebase Console → App Check → <your app> → Manage debug tokens → Add token
4. Now debug builds can call enforced functions
```

---

## 4. Pre-Deployment Checklist (Firebase)

### Before deploying to tremble-dev

- [ ] `npm run build` passes with 0 TypeScript errors
- [ ] All new `onCall` functions have `requireAppCheck()` + `requireAuth()`
- [ ] No hardcoded UIDs, emails, or tokens in Functions code
- [ ] Zod schema validates all `request.data` fields
- [ ] No `console.log` with PII (emails, phone numbers, full UIDs in logs)

### Before deploying to production (am---dating-app)

- [ ] App Check enforcement enabled in Firebase Console for both iOS and Android
- [ ] Firestore Rules reviewed and deployed
- [ ] Firebase Auth — anonymous auth disabled if not used
- [ ] All debug tokens removed from Firebase Console (or at least audited)
- [ ] `firebase deploy --only functions,firestore:rules` (not `--only hosting`)
- [ ] Smoke test: login flow, updateProfile, findNearby all return 200
- [ ] Check Firebase Console → Functions → Logs for errors in first 10 minutes

---

## 5. Sensitive Data Rules

```typescript
// NEVER log in Cloud Functions:
console.log(request.auth?.uid)          // log uid only in errors, not routinely
console.log(request.data?.phoneNumber)  // PII
console.log(request.data?.location)     // location data

// CORRECT logging pattern:
console.info('[updateProfile] success', { uid: uid.substring(0, 8) + '...' });
console.error('[findNearby] failed', { error: e.message });
// Never log full UID in info logs — truncate or hash
```

## Agent Support

- Use **security-reviewer** agent for full OWASP-style audit before launch
- Use **architect** agent when redesigning Firestore data model (security implications)
