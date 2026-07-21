# Precise Turn-to-Find — Implementation Plan (build 35)

> **For the implementer (Codex):** implement task-by-task, TDD (write the failing test first, then the minimal code). Read the full contract first: `docs/superpowers/specs/2026-07-22-precise-finder-design.md` and `tasks/decisions/ADR-010-precise-window-location.md`. Steps use `- [ ]` for tracking.

**Goal:** Give two matched users an accurate, live turn-to-find arrow + distance during the trembling window, with raw coordinates never leaving the server.

**Architecture:** Per-window reciprocal opt-in. Each phone POSTs its coordinate to a callable every ~3s; the callable stores it in a Firestore-rules-locked, TTL-purged server-only path, reads the partner's latest, and returns ONLY bearing + distance. Client renders the radar dot from that (compass still rotates it); falls back to the coarse geohash arrow + BLE warmth when precise mode is off.

**Tech Stack:** Cloud Functions v2 (TypeScript, europe-west1), Firestore + rules + TTL, Flutter + Riverpod, geolocator, flutter_compass_v2, cloud_functions callable.

## Global Constraints (verbatim)
- Deploy functions/rules ONLY with `--project prod`. Firestore TTL policy on `finder.expireAt` is a **manual founder step** (console/gcloud) — not CLI-deployable; document it, don't fake it.
- Raw coordinates: server-only in `matches/{matchId}/finder/{uid}`; rules deny ALL client access; never logged; purged on `markMatchFound` + ~2-min TTL.
- Callable returns ONLY `{partnerSharing, bearing?, distanceM?, reason?}` — never coordinates.
- Free for all users. No premium gate on precise finding.
- Dart: `dart format .` clean, `flutter analyze` clean, `flutter test` green. Functions: `npm --prefix functions run build` + `npm --prefix functions test` + eslint clean.
- Branch from latest `main` AFTER PR #86 (this spec) is merged. Feature branch: `feat/precise-finder`.
- PR title needs `[PLAN-ID: 20260722-precise-finder]`; body needs a Verification checklist (unit tests / integration tests / security scan). HIGH-risk (rules + functions + location) → founder approval before merge.
- Release: bump `pubspec.yaml` ONLY to build 35, AFTER build 34 (C/D/E) is on main.

---

### Task 1: Extract pure haversine into `bearing.ts`

**Files:**
- Modify: `functions/src/modules/proximity/bearing.ts` (add `haversineMeters`)
- Modify: `functions/src/modules/proximity/proximity.functions.ts` (import it, drop the local copy)
- Test: `functions/src/__tests__/bearing.test.ts` (extend)

**Interfaces — Produces:** `export function haversineMeters(aLat:number,aLng:number,bLat:number,bLng:number): number`

- [ ] Write failing test: `haversineMeters` for a known pair (e.g. two points ~100m apart) is within ±1m; identical points → 0.
- [ ] Run → fails (not exported).
- [ ] Move the existing `haversineMeters` body from `proximity.functions.ts` into `bearing.ts`, export it, import it back in `proximity.functions.ts` (delete the local dup — keep `updateActiveMatchBearing` working).
- [ ] Run functions build + tests → green.
- [ ] Commit: `refactor(functions): extract haversineMeters into bearing.ts`

### Task 2: `updateFinderLocation` callable

**Files:**
- Create: `functions/src/modules/matches/finder.functions.ts`
- Modify: `functions/src/index.ts` (export `updateFinderLocation`)
- Test: `functions/src/__tests__/finder.test.ts`

**Interfaces — Consumes:** `computeBearing`, `haversineMeters` (bearing.ts); `loadParticipantMatch` pattern (matches.functions.ts). **Produces:** callable `updateFinderLocation`.

Contract:
- Input zod schema: `{ matchId:string, lat:number(-90..90), lng:number(-180..180), accuracy:number>=0, optIn:boolean }`.
- `requireAuth` + App Check (`enforceAppCheck: ENFORCE_APP_CHECK`) + participant check (caller ∈ match.userIds, else `permission-denied`).
- If `optIn` → merge `finderOptIn.{callerUid}=true` on the match doc.
- Write `matches/{matchId}/finder/{callerUid}` = `{lat,lng,accuracy,updatedAt:serverTimestamp, expireAt:now+120s}`.
- Read partner's `finder/{partnerUid}`. Compute `partnerUid` via `userIds.find(!==caller)`.
- Gate: return `{partnerSharing:false, reason}` when — match not `pending` or expired (`window_over`); partner not in `finderOptIn` (`partner_not_opted`); partner doc missing or `updatedAt` older than 10s (`partner_stale`). Else `{partnerSharing:true, bearing: round(computeBearing(caller,partner)), distanceM: round(haversineMeters(...))}`.
- Never log lat/lng.

- [ ] Write failing tests (mock Firestore) for each branch: both-opted+fresh → bearing/distance returned; partner_not_opted; partner_stale (>10s); window_over (status found / expired); non-participant → permission-denied; verify response NEVER contains lat/lng; verify `expireAt ≈ now+120s`.
- [ ] Run → fail.
- [ ] Implement the callable.
- [ ] Run functions build + tests → green.
- [ ] Commit: `feat(finder): updateFinderLocation callable — server-only coords, returns bearing+distance`

### Task 3: Purge on `markMatchFound`

**Files:**
- Modify: `functions/src/modules/matches/matches.functions.ts` (`markMatchFound`)
- Test: `functions/src/__tests__/` (existing markMatchFound test file or new)

- [ ] Write failing test: after `markMatchFound`, all `matches/{id}/finder/*` docs are deleted and `finderOptIn` is cleared (FieldValue.delete).
- [ ] Run → fail.
- [ ] In `markMatchFound`, after the status update, delete the `finder` subcollection docs and `finderOptIn`.
- [ ] Run → green.
- [ ] Commit: `feat(finder): purge finder coords + opt-in on markMatchFound`

### Task 4: Firestore rules lock + opt-in read

**Files:**
- Modify: `firestore.rules`
- Test: `functions/src/__tests__/` rules test (use `@firebase/rules-unit-testing` if present; else document manual verification)

Rules:
- `match /matches/{matchId}/finder/{uid}` → `allow read, write: if false;` (Admin SDK only).
- Ensure `finderOptIn` on the match doc is readable by participants (it rides on the existing match-doc read rule — confirm participants can read the match doc; clients still cannot write `finderOptIn`, matching the existing "only seenBy is client-writable" rule).

- [ ] Write failing rules test: participant read of `finder/{uid}` denied; non-participant denied; participant read of match doc (incl. `finderOptIn`) allowed; client write to `finder/**` denied; client write to `finderOptIn` denied.
- [ ] Run → fail.
- [ ] Add the rule; keep the existing match rules intact.
- [ ] Run → green.
- [ ] Commit: `feat(finder): lock finder subcollection in firestore.rules`

### Task 5: `bearingIsMeaningful` + coarse-arrow fallback (was old Prompt B)

**Files:**
- Modify: `lib/src/features/dashboard/domain/sonar_math.dart`
- Modify: `lib/src/features/dashboard/application/proximity_ping_controller.dart` (`_currentAngle`)
- Test: `test/features/dashboard/sonar_math_test.dart`, `..._ping_controller_test.dart`

**Produces:** `bool bearingIsMeaningful(String? distanceBucket)` → true for `'~150m' | 'far'`.

- [ ] Write failing tests: `bearingIsMeaningful('far')`/`'~150m'`==true; `'close'`/`'~50m'`/`null`==false. Controller: meaningful bucket + bearing + heading → dotAngle; `'close'` bucket → orbit (ignores bearing).
- [ ] Run → fail.
- [ ] Add helper; gate `_currentAngle()` to use `dotAngle` only when `bearingIsMeaningful(_distanceBucket)` (else orbit).
- [ ] Run → green.
- [ ] Commit: `feat(radar): coarse-arrow fallback only at approach range`

### Task 6: Finder repository + `PreciseFinderController`

**Files:**
- Create: `lib/src/features/dashboard/data/finder_repository.dart` (callable wrapper)
- Create: `lib/src/features/dashboard/application/precise_finder_controller.dart` (+ generated `.g.dart`)
- Test: `test/features/dashboard/precise_finder_controller_test.dart`

**Interfaces — Produces:** `FinderReading { bool partnerSharing; double? bearing; double? distanceM; String? reason }`; controller states `idle | waiting | active | fallback | stopped`; `optInAndStart(matchId)`, `stop()`.

Behaviour: on `optInAndStart` → start geolocator high-accuracy stream (foreground only), push to `updateFinderLocation` every ~3s with a distance filter; map response to state (`partnerSharing:true` → active with bearing/distance; false → waiting/fallback by reason). Stop + `stop()` on found/expiry/background/toggle-off. Never expose coordinates outside the repository.

- [ ] Write failing tests (fake repository): idle→waiting (opted, partner not) → active (both) → fallback (partner_stale) → stopped (stop()); stop clears the location stream; controller never surfaces lat/lng.
- [ ] Run → fail.
- [ ] Implement repository + controller.
- [ ] Run `dart format`, `flutter analyze`, `flutter test` → green.
- [ ] Commit: `feat(finder): PreciseFinderController + callable repository`

### Task 7: Radar UI — opt-in button, states, wire to dot + distance label

**Files:**
- Modify: `lib/src/features/dashboard/presentation/widgets/radar_search_overlay.dart` (button + states + distance label + microcopy)
- Modify: `lib/src/features/dashboard/presentation/home_screen.dart` (feed `pingAngleProvider`/`pingDistanceProvider` from precise reading when active; label)
- Modify: i18n arb/maps (en + sl): `finder_cta` ("Help us find each other"), `finder_waiting` ("Waiting for {name}…"), `finder_look_around` ("They're close — look around").
- Test: widget test for the overlay states.

Behaviour: precise `active` → dot uses precise bearing (via compass `dotAngle`) + solid style + "NN m" label; `waiting`/`fallback` → coarse/warmth + microcopy. Button hidden once `active` or after found.

- [ ] Write failing widget test: button shown in idle; tapping calls `optInAndStart`; active state shows distance label; fallback shows look-around copy.
- [ ] Run → fail.
- [ ] Implement UI + wiring + i18n.
- [ ] Run `dart format`, `flutter analyze`, `flutter test` → green.
- [ ] Commit: `feat(finder): radar opt-in button, precise arrow + distance, fallback copy`

### Task 8: Release — build 35

**Files:** Modify `pubspec.yaml` (version → `1.0.0+35`, only after build 34 is on main).

- [ ] Bump pubspec ONLY. Commit: `chore(release): bump to build 35 (1.0.0+35)`.

## Founder / manual steps (document in PR)
1. Create Firestore **TTL policy**: collection group `finder`, field `expireAt`, `--project prod` (console → Firestore → TTL, or `gcloud firestore fields ttls update`). Without it, abandoned coords rely only on `markMatchFound` purge.
2. Deploy: `firebase deploy --only firestore:rules --project prod` then `firebase deploy --only functions:updateFinderLocation,functions:markMatchFound --project prod`.
3. Build 35 via `build_prod.sh` + `--dart-define-from-file=.env.prod.json`; iOS `xcrun altool` (key V24BM2VRC2); founder uploads AAB.

## Self-review
- Spec coverage: activation (T6/T7), arrow+distance-only (T2), free (no gate anywhere), transport callable (T2/T6), privacy rules+TTL+purge (T2/T3/T4 + manual TTL), fallback (T5), testing (each task) — all mapped.
- No placeholders; interfaces named consistently (`FinderReading`, `updateFinderLocation`, `finderOptIn`, `bearingIsMeaningful`).
