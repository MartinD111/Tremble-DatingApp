---
name: firebase-security
description: Use this skill when writing or reviewing Firestore Security Rules, Cloud Functions auth/App Check middleware, or before any Firebase production deployment. Covers Tremble-specific data model security patterns, TTL field verification, and pre-deploy checklists. Always use this skill before any deploy to tremble-dev or am---dating-app, and before writing any new onCall or scheduled Cloud Function.
origin: Tremble
---

# Firebase Security Skill

Tremble-specific Firebase security patterns for Firestore Rules, Cloud Functions middleware, and App Check enforcement.

**Last verified:** 6 Jun 2026

## When to Activate

- Writing or modifying Firestore Security Rules
- Adding new Cloud Functions (onCall or scheduled triggers)
- Implementing or changing authentication flows
- Before deploying to `tremble-dev` or `am---dating-app`
- After any schema change to user/match/proximity documents
- Reviewing App Check enforcement status
- Any question about TTL fields — check `references/ttl-field-map.md` first

---

## 1. Firestore Security Rules

### Core Principle

Every rule must answer: **"Can this authenticated user access this specific document?"**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

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

    // Users — authenticated read, owner write
    match /users/{userId} {
      allow read: if isAuthenticated();

      allow create: if isOwner(userId)
        && isValidString(request.resource.data.displayName, 50)
        && isValidAge(request.resource.data.age)
        && request.resource.data.keys().hasAll(['displayName', 'age', 'geohash']);

      allow update: if isOwner(userId)
        && request.resource.data.uid == resource.data.uid
        && request.resource.data.createdAt == resource.data.createdAt;

      allow delete: if isOwner(userId);
    }

    // Proximity — users write their own location only
    match /proximity/{userId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId);
    }

    // Matches — both participants read, Cloud Functions write only
    match /matches/{matchId} {
      allow read: if isAuthenticated()
        && (resource.data.user1 == request.auth.uid
            || resource.data.user2 == request.auth.uid);
      allow write: if false; // Admin SDK only
    }

    // Greetings (Waves) — sender creates, recipient updates status
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
        && request.resource.data.senderId == resource.data.senderId;

      allow delete: if false;
    }

    // Blocks — owner manages their list
    match /blocks/{blockId} {
      allow read: if isAuthenticated()
        && resource.data.blockerId == request.auth.uid;
      allow create: if isAuthenticated()
        && request.resource.data.blockerId == request.auth.uid;
      allow delete: if isAuthenticated()
        && resource.data.blockerId == request.auth.uid;
    }

    // Reports — write-only, no client read
    match /reports/{reportId} {
      allow create: if isAuthenticated()
        && request.resource.data.reporterId == request.auth.uid;
      allow read: if false;
      allow update, delete: if false;
    }
  }
}
```

### Rules Checklist

- [ ] Every collection has explicit allow/deny
- [ ] No `allow read, write: if true` anywhere
- [ ] User docs enforce `request.auth.uid == userId`
- [ ] Immutable fields (uid, createdAt) blocked from update
- [ ] Matches: write: if false (Admin SDK only)
- [ ] Reports: read: if false
- [ ] Field-level validation on create (type, length, range)

---

## 2. Cloud Functions Auth Middleware

### Required Pattern — All onCall Functions

Order is mandatory: AppCheck → Auth → Zod validation → business logic.

```typescript
import { requireAppCheck } from '../middleware/appCheck';
import { requireAuth } from '../middleware/authGuard';

export const myFunction = onCall(async (request) => {
  requireAppCheck(request);          // 1. Block non-app clients
  const uid = requireAuth(request);  // 2. Ensure logged in
  const data = MySchema.parse(request.data); // 3. Zod validation
  // 4. Business logic
});
```

### requireAppCheck

```typescript
// functions/src/middleware/appCheck.ts
export function requireAppCheck(request: CallableRequest): void {
  if (request.app == undefined) {
    throw new HttpsError(
      'failed-precondition',
      'The function must be called from an App Check verified app.'
    );
  }
}
```

### Scheduled Functions (NO App Check)

`scanProximityPairs` and all scheduled CFs run server-side — no `request.app`:

```typescript
// DO NOT call requireAppCheck() on scheduled functions
export const scanProximityPairs = onSchedule('every 1 minutes', async () => {
  // No AppCheck, no requireAuth — server-side only
  // Reads proximity collection, finds geohash pairs, writes proximity_events
});
```

**Current scheduled functions in prod:**
- `scanProximityPairs` — 1-min interval, geohash pair detection
- No `onBleProximity` or `onRunEncounter` — both deleted Jun 2026

---

## 3. TTL Fields

**Always check `references/ttl-field-map.md` before writing any CF that touches proximity_events, run_encounters, rateLimits, or gdprRequests.**

Quick lookup:

| Collection | TTL field | ❌ Wrong field |
|---|---|---|
| proximity_events | `expiresAt` | `ttl` (caused prod bug) |
| run_encounters | `expiresAt` | `ttl` (caused prod bug) |
| rateLimits | `ttl` | — |
| gdprRequests | `ttl` | — |
| proximity (geohash) | `geoHashExpiresAt` | — |

Verify TTL policies active on prod:

```bash
gcloud firestore fields ttls list --database="(default)" --project=am---dating-app
```

---

## 4. App Check

| Mode | Behavior |
|---|---|
| Monitoring | Logs unverified requests, allows them |
| Enforced | Blocks all unverified requests |

- `tremble-dev`: monitoring mode acceptable
- `am---dating-app`: **enforced before launch, no exceptions**

Debug token workflow:
```
1. Flutter debug build → prints token to console
2. Firebase Console → App Check → app → Manage debug tokens → Add
3. Debug builds can now call enforced functions
```

---

## 5. Sensitive Data Rules

```typescript
// NEVER log:
console.log(request.auth?.uid)         // truncate if needed
console.log(request.data?.phoneNumber) // PII
console.log(request.data?.location)    // location data

// CORRECT:
console.info('[updateProfile] success', { uid: uid.substring(0, 8) + '...' });
console.error('[findNearby] failed', { error: e.message });
```

---

## 6. Pre-Deployment Checklist

### Deploy to tremble-dev

- [ ] `npm run build` — 0 TypeScript errors
- [ ] All new `onCall` functions: `requireAppCheck()` + `requireAuth()`
- [ ] No hardcoded UIDs, emails, or tokens
- [ ] Zod schema on all `request.data` fields
- [ ] No PII in `console.log`
- [ ] TTL fields match `references/ttl-field-map.md`

### Deploy to am---dating-app (production)

Run tremble-dev checklist first, then:

- [ ] App Check enforced — iOS + Android (Firebase Console)
- [ ] Firestore Rules reviewed + deployed
- [ ] Anonymous auth disabled if unused
- [ ] Debug tokens audited
- [ ] Deploy command: `firebase deploy --only functions,firestore --project am---dating-app`
- [ ] Smoke test: login, updateProfile, findNearby → all 200
- [ ] Monitor Functions → Logs for 10 min post-deploy

**Never:** `--only hosting` on a functions deploy. Never cross-deploy between tremble-dev and am---dating-app configs.

---

## Composability

**This skill is called by:**
- `tremble:deploy-workflow` — uses Section 6 checklist as the gate
- `tremble:compliance-checker` — uses Section 5 (PII rules) for CF code review
- `flutter-ble-proximity` — when BLE changes touch CF or Firestore rules

**This skill calls:**
- `references/ttl-field-map.md` — for any TTL field question
- `security-reviewer` agent — for full OWASP audit before prod launch

**Agent support:**
- `security-reviewer` — full OWASP-style audit before launch
- `architect` — when redesigning Firestore data model
