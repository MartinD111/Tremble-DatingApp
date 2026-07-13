# Active Implementation Plan
Plan ID: 20260713-distance-remove-and-hardfilters-comingsoon
Risk Level: LOW
Founder Approval Required: NO
Branch: feat/tier-3-7c-5R-and-3-7c-2C

1. OBJECTIVE — Deliver KORAK 3.7c-5R + 3.7c-2C as a single Flutter-only
   PR that (a) retires the false-advertisement distance bullets from
   the paywall per ADR-007 Amendment §5, (b) soft-labels the paused
   hard-filters bullet with "coming soon" across all 8 supported
   locales per ADR-007 Amendment §6, and (c) sweeps the orphan
   `distance_help` translation key discovered during pre-flight (no
   caller anywhere in `lib/`; fossil from the never-built distance
   slider). Zero gate logic changes, copy-only.

2. SCOPE —
   - **Modified:**
     - `lib/src/features/settings/presentation/premium_screen.dart` —
       remove two distance bullet keys from the ordered arrays, delete
       the EN + SL translation entries for them, refresh the free-tier
       comment, update EN `premium_feature_hard_filters` with
       "(coming soon)" suffix, and add the same soft-labelled bullet
       to the 7 other locale blocks (sl, de, hr, it, es, fr, pt).
     - `lib/src/core/translations.dart` — delete the orphan
       `distance_help` entry (multi-line) from all 8 locale blocks
       (en, sl, de, it, fr, hr, sr, hu). Locale-block count must be
       identical before and after.
     - `test/features/settings/premium_screen_test.dart` — Premium
       ordered set 8→7, Free ordered set 7→6, add the two retired
       distance keys to the "retired paywall keys are fully removed"
       assertion, add "coming soon" contains checks (EN + SL).
     - `tasks/plan.md` — this file (Plan-ID rewrite).
     - `tasks/plans/PLAN_03_APP_CODE.md` — mark 3.7c-5R + 3.7c-2C
       as MERGED, update STATUS table, add prod-deploy dnevnik entry.
   - **Untouched:** all Cloud Functions, Firestore rules, CI config,
     ADR-007, all other Dart features. No gate logic added, no
     server contract changed.

3. STEPS —
   1. Delete `premium_feature_distance_100` from
      `premiumOnlyFeatureBullets` (premium_screen.dart:69).
   2. Delete `premium_free_distance_50` from
      `freeTierFeatureBullets` (premium_screen.dart:85). Refresh the
      preceding comment that says "distance-up-to-50km" so it stops
      claiming a bullet that no longer exists.
   3. Delete the four translation entries for those keys (EN 316 +
      334, SL 393 + 409).
   4. Update EN `premium_feature_hard_filters` (line 312-313) with
      the "(coming soon)" suffix per ADR-007 §6.
   5. Add localised `premium_feature_hard_filters` entries to sl, de,
      hr, it, es, fr, pt locale blocks per the exact phrasing in
      ADR-007 §6.
   6. Delete all 8 `distance_help` entries in translations.dart. Grep
      pre + post to confirm locale-block count unchanged.
   7. Update `premium_screen_test.dart`: shrink both ordered lists,
      add the two distance keys to the retired-keys sweep, add EN +
      SL "coming soon" contains assertions.
   8. `flutter analyze` — 0 issues. `flutter test` — all green.
   9. Rewrite this `tasks/plan.md`, then open PR complying with
      Rule #79 + Rule #80 pre-flight.

4. RISKS & TRADEOFFS —
   - **Copy-only, no gate change:** false-advertisement risk goes
     DOWN, not up. Nothing else in the app reads these bullet keys.
   - **Orphan `distance_help` deletion:** grep confirmed zero callers
     in `lib/`. If a future distance-slider PR ever lands, it can
     re-add its own key — the deletion here is honest cleanup, not
     future-blocking.
   - **Non-EN feature-bullet translations still fall back to EN**
     for every other Premium bullet — that is existing behaviour
     inherited from KORAK 3.7a and unchanged by this PR. Adding a
     full non-EN feature-bullet translation pass is a separate task
     tracked outside 3.7.

5. VERIFICATION —
   - `flutter analyze` — 0 issues.
   - `flutter test` — all suites green (unit + widget). Two new
     assertions in `premium_screen_test.dart`; count moves by test
     additions only, no test file removals.
   - unit tests — added (retired-keys sweep + coming-soon contains).
   - integration tests — none needed; no CF or Firestore path
     touched.
   - security scan — grep of branch diff shows only Dart copy files
     and docs; no secrets, no PII, no auth/billing/security-boundary
     change.
   - `git diff --stat origin/main...HEAD` — five files:
     `lib/src/features/settings/presentation/premium_screen.dart`,
     `lib/src/core/translations.dart`,
     `test/features/settings/premium_screen_test.dart`,
     `tasks/plan.md`,
     `tasks/plans/PLAN_03_APP_CODE.md`.
   - MPC PR-Metadata gate verification (Rule #79 + Rule #80
     pre-flight):
     - Title format present: `[PLAN-ID:
       20260713-distance-remove-and-hardfilters-comingsoon] …`.
     - Body contains: `Verification checklist`, `unit tests`,
       `integration tests`, `security scan`.
     - Body does NOT contain any literal risk-regex trigger
       substring (per Rule #80).
     - Plan-ID present in this `tasks/plan.md` file (line 2).
