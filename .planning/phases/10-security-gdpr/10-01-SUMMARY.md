# Summary: GDPR Deletion Pipeline Fix

```
Plan ID: 20260409-gdpr-deletion-fix
Executed: 2026-04-09
Branch: feature/gdpr-deletion-fix
Commit: 0da9f6a
```

## Outcome

GDPR `deleteUserAccount` and `exportUserData` functions corrected.
All 4 unit tests pass. Full suite (12/12) passes. tsc: 0 errors.

## Founder Decision

**reports collection: Option B** (anonymise `reportedId` → `"[deleted]"`, retain document for GDPR Art. 17(3)(e) legal defence).

## What Changed

### `gdpr.functions.ts`

- Added `deleteBatch(refs: DocumentReference[])` helper — paginated 500-doc Firestore batches
- Replaced single unbounded `db.batch()` in `deleteUserAccount` with sequential `deleteBatch` calls
- Added missing collections to deletion pipeline:
  - `waves` (fromUid + toUid queries)
  - `proximity_events` (field `from == uid`)
  - `proximity_notifications` (`users array-contains uid`)
  - `idempotencyKeys` (`__name__` range `{uid}:*`)
  - `reports` (hard delete where `reporterId == uid`; anonymise where `reportedId == uid`)
- Updated `exportUserData`: replaced `greetingsSent`/`greetingsReceived` (stale collection) with `wavesSent`/`wavesReceived`

### `gdpr.test.ts` (new file)

4 unit tests:
1. Unauthenticated request rejected
2. All expected collections queried + auth.deleteUser called
3. 501 docs triggers ≥2 batch commits
4. Export returns `wavesSent`/`wavesReceived`, not `greetings` keys

## Verification Gates Passed

| Gate | Result |
|------|--------|
| Unit tests 4/4 | ✅ |
| Full suite 12/12 | ✅ |
| tsc --noEmit | ✅ 0 errors |
| npm run build | ✅ exit 0 |
| pre-commit (dart format + analyze) | ✅ |

## Remaining

- Push branch → CI
- `firebase deploy --only functions --project tremble-dev`
- Visual verify in Firebase console (tremble-dev only, NOT am---dating-app)
