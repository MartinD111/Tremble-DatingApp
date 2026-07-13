# Active Implementation Plan
Plan ID: 20260713-matches-three-state-mutual-wave
Risk Level: MEDIUM
Founder Approval Required: NO
Branch: feat/tier-3-7c-1-matches-three-state

1. OBJECTIVE — Land ADR-007 Amendment §1 (Matches shape + mutual-wave
   predicate) as KORAK 3.7c-1. Introduce a compound gate
   `isPremium && hasMutualWave` on the Matches list render, and a
   three-state pipeline: (a) no mutual wave → greyscaled photo +
   name + age only, (b) mutual wave + Free → colour + name + age +
   3 shared hobbies, (c) mutual wave + Premium → colour + full
   profile card openable. Both tiers fall back to (a) when there is
   no mutual wave.

2. SCOPE —
   - **Modified:**
     - `functions/src/modules/matches/matches.functions.ts` —
       `getMatches` response gains a `hasMutualWave: boolean` field
       per profile, computed from `matchData.gestures` (mutual when
       `Object.keys(gestures ?? {}).length >= 2`).
     - `functions/src/__tests__/matches.test.ts` — new assertions on
       the `getMatches` mutual-wave contract (mutual + non-mutual
       pair-of-tests per ADR-007 §4).
     - `lib/src/features/matches/data/match_repository.dart` —
       `MatchProfile` gains `final bool hasMutualWave` (default
       `false`, backward-compatible with mock data + direct
       constructor callers); `MatchProfile.fromApi` reads
       `data['hasMutualWave'] as bool? ?? false`.
     - `lib/src/features/matches/presentation/matches_screen.dart` —
       three-state render pipeline replaces the existing
       `isLocked` placeholder for non-mutual matches. Tap gate on
       `_openProfile` becomes `isPremium && hasMutualWave`. Greyscale
       via `ColorFilter.matrix` around the photo.
     - `lib/src/core/dev_mock_users.dart` — set explicit
       `hasMutualWave` on the 3 mock users so dev-mode Admin Bypass
       renders all three states visibly.
     - `test/features/matches/matches_three_state_test.dart` — new
       widget test file covering the three states (pair-of-tests
       per ADR-007 §4: Free-non-mutual, Free-mutual, Premium-mutual,
       Premium-non-mutual).
     - `tasks/plan.md` — this file (Plan-ID rewrite).
     - `tasks/plans/PLAN_03_APP_CODE.md` — mark 3.7c-1 as MERGED
       once PR lands, add prod-deploy dnevnik entry.
   - **Untouched:** Firestore rules (read gates unchanged; write
     paths unchanged), all other features, Recap and Near-Miss
     card surfaces (those are 3.7c-10 / 3.7c-11 scoped separately).

3. STEPS —
   1. `getMatches` (functions/src/modules/matches/matches.functions.ts)
      — compute `hasMutualWave` server-side from
      `matchData.gestures`. Emit on the returned profile.
   2. `MatchProfile` DTO gains the field (default `false`).
   3. `matches_screen.dart` — replace `isLocked`-based render with
      three-state pipeline. Non-mutual = greyscaled photo + name +
      age, no tap-open. Mutual + Free = colour + 3 hobbies, no
      tap-open. Mutual + Premium = colour + full card, tap-open.
   4. `dev_mock_users.dart` — Nika = mutual (State C/B by tier),
      Luka = non-mutual (State A both tiers), Sara = mutual.
   5. Widget test suite: assert render for each of the 4 tier ×
      mutual permutations.
   6. CF test: `getMatches` returns `hasMutualWave: true` when both
      users are in `gestures`; `false` when only one is present or
      the map is empty.
   7. `flutter analyze` + `flutter test` + `npm test` (CF) all
      green.
   8. Rewrite this `tasks/plan.md`, open PR per Rule #79 + Rule #80
      pre-flight.

4. RISKS & TRADEOFFS —
   - **UX shift for Free-they-waved-me-didn't (MEDIUM):** today
     Free tier sees "Someone sent you a wave" placeholder when they
     received a wave and haven't replied. Under §1 they see the
     sender's real name + age + greyscaled photo. Confirmed by
     founder 2026-07-13 — ADR §1 wins (both tiers see the same
     greyed shape).
   - **CF deploy required (LOW):** `getMatches` shape change is
     additive. Clients that predate the field default to `false`
     and simply render everything as non-mutual → safe. Backwards-
     compatible for older APK builds during rollout.
   - **DTO default = false (LOW):** older mock data + widget tests
     that build `MatchProfile` directly continue to compile;
     they land in State A by default, which is intentional.
   - **Server truth vs client wave state:** we compute mutual on
     the server from the `matches/{matchId}.gestures` map, which
     is written client-side by `wave_repository.sendGesture`. If
     a client races two waves onto the same doc, Firestore's
     last-write-wins already resolves it; no new race introduced.
   - **Scope confined to Matches list.** Recap card and Near-Miss
     card still use the OLD render — three-state migration for
     those surfaces lives in 3.7c-10 / 3.7c-11.

5. VERIFICATION —
   - `flutter analyze` — 0 issues.
   - `flutter test` — all suites green (unit + widget). New file
     `matches_three_state_test.dart` adds coverage for the four
     tier × mutual permutations.
   - `cd functions && npm run build && npm run lint && npm test`
     — all green. New assertions in `matches.test.ts` cover the
     `hasMutualWave` contract in `getMatches`.
   - unit tests — added (CF `hasMutualWave` computation +
     widget three-state render).
   - integration tests — n/a; the mutual-wave predicate is a
     read-derived boolean, not a new write path. No Firestore
     rules touched.
   - security scan — branch diff shows only CF getMatches shape
     addition (additive, no auth logic), Dart DTO + widget +
     mock + tests, and docs. No secrets, no PII change, no
     credential surface.
   - `git diff --stat origin/main...HEAD` — expected files:
     `functions/src/modules/matches/matches.functions.ts`,
     `functions/src/__tests__/matches.test.ts`,
     `lib/src/features/matches/data/match_repository.dart`,
     `lib/src/features/matches/presentation/matches_screen.dart`,
     `lib/src/core/dev_mock_users.dart`,
     `test/features/matches/matches_three_state_test.dart`,
     `tasks/plan.md`,
     `tasks/plans/PLAN_03_APP_CODE.md`.
   - MPC PR-Metadata gate verification (Rule #79 + Rule #80
     pre-flight):
     - Title format: `[PLAN-ID:
       20260713-matches-three-state-mutual-wave] …`.
     - Body contains: `Verification checklist`, `unit tests`,
       `integration tests`, `security scan`.
     - Body does NOT contain any literal risk-regex trigger
       substring (per Rule #80).
     - Plan-ID present in this `tasks/plan.md` file (line 2).
