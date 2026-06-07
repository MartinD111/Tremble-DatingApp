---
name: tremble-deploy-workflow
description: Use this skill for any Firebase deployment task — deploying Cloud Functions, Firestore rules, indexes, or preparing a production deploy for Tremble. Covers the full deploy pipeline from pre-flight checks to post-deploy smoke test for both tremble-dev and am---dating-app. Always use before running any firebase deploy command, and always use when the user asks about deploying, releasing, or pushing to Firebase.
origin: Tremble
---

# Tremble Deploy Workflow

End-to-end deploy pipeline for tremble-dev and am---dating-app.

**Last verified:** 6 Jun 2026

## CRITICAL RULES — read before anything else

- **Never cross-deploy** — tremble-dev config ≠ am---dating-app config. Separate `.env.json` files.
- **Never deploy to prod autonomously** — prod deploy requires founder confirmation.
- **Never push directly to main** — feature branch → PR → merge → deploy.
- **Never modify AndroidManifest.xml, Info.plist, google-services.json** without founder approval.
- `am---dating-app` is the production project identifier. Not "prod", not "production" — use exact string.

---

## 1. Pre-Flight (both environments)

Run these before any deploy. All must pass.

```bash
# 1. TypeScript build — zero errors required
cd functions
npm run build

# 2. Flutter analyze — zero errors required
cd ..
flutter analyze

# 3. Tests — all 148 must pass
flutter test

# 4. Lint functions
cd functions
npm run lint
```

If any step fails: stop, fix, re-run from step 1. Do not deploy with warnings.

---

## 2. Deploy to tremble-dev

```bash
firebase deploy --only functions,firestore --project tremble-dev
```

**What this deploys:**
- All Cloud Functions (europe-west1, Node.js v22)
- Firestore rules
- Firestore indexes

**Post-deploy verification (tremble-dev):**
```bash
# Check functions deployed without errors
firebase functions:log --project tremble-dev --limit 20

# Expected: no ERROR lines in first 2 minutes
```

**Smoke test (tremble-dev):**
```bash
flutter run --dart-define-from-file=.env.json --flavor dev --dart-define=FLAVOR=dev
```
Verify: login flow, updateProfile, findNearby all return 200 in Firebase Console → Functions → Logs.

---

## 3. Deploy indexes only

```bash
firebase deploy --only firestore:indexes --project tremble-dev
# or
firebase deploy --only firestore:indexes --project am---dating-app
```

Use when: adding new composite index, changing collection group query.

---

## 4. Deploy to am---dating-app (PRODUCTION)

**Gate:** tremble-dev deploy + smoke test must pass first. No exceptions.

**Pre-prod checklist** (from `firebase-security` skill):

- [ ] App Check enforced — iOS + Android (Firebase Console → App Check)
- [ ] Firestore Rules reviewed — no `allow read, write: if true`
- [ ] TTL fields verified — see `references/ttl-field-map.md`
- [ ] All new `onCall` functions: `requireAppCheck()` + `requireAuth()`
- [ ] No hardcoded UIDs, emails, or tokens
- [ ] No PII in `console.log`
- [ ] Anonymous auth disabled if unused
- [ ] Debug tokens audited in Firebase Console

**Deploy command:**
```bash
firebase deploy --only functions,firestore --project am---dating-app
```

**Post-deploy — monitor for 10 minutes:**
```bash
firebase functions:log --project am---dating-app --limit 50
```

**Prod smoke test:**
- Login flow → 200
- `updateProfile` → 200
- `findNearby` → 200
- `scanProximityPairs` scheduled — verify in Firebase Console → Functions → Scheduler

---

## 5. Pending prod deploys (as of 6 Jun 2026)

These are staged on tremble-dev, waiting for device test + founder sign-off:

| Change | Status | Gate |
|---|---|---|
| Silent notifs (CROSSING_PATHS + INCOMING_WAVE) | ✅ dev | Device test BLE E2E |
| nicotineFilter schema + Premium gate | ✅ dev | Device test |
| scanProximityPairs bothPremium hard filter | ✅ dev | Device test |
| GDPR BUG-001 fix | ✅ dev | — |
| Firestore indexes | 🔴 prod pending | `firebase deploy --only firestore:indexes --project am---dating-app` |
| prod TTL: proximity → geoHashExpiresAt | 🔴 prod pending | Firebase Console, manual — add when collection exists |

---

## 6. Rollback

Cloud Functions:
```bash
# List previous versions
firebase functions:list --project am---dating-app

# Redeploy previous version by checking out previous commit + redeploy
git checkout <previous-commit>
npm run build
firebase deploy --only functions --project am---dating-app
```

Firestore rules rollback:
```bash
# Get current rules via REST (Firebase CLI 15.18.0 doesn't support firestore:rules:get)
curl -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  "https://firestore.googleapis.com/v1/projects/am---dating-app/databases/(default)/documents"
```

---

## Composability

**This skill calls:**
- `firebase-security` — for pre-deploy security checklist (Section 6)
- `flutter-ble-proximity` — for verifying BLE-related CF changes before deploy
- `references/ttl-field-map.md` — TTL field verification

**This skill is called by:**
- `tremble:session-closer` — to verify what was deployed in a session
- `tremble:compliance-checker` — as final gate before prod deploy recommendation
