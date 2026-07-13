# Active Implementation Plan
Plan ID: 20260713-plan-03-lesson-82-postmerge
Risk Level: LOW
Founder Approval Required: NO
Branch: docs/plan-03-lesson-82-postmerge

1. OBJECTIVE — Close the docs loop after KORAK 3.8-1 merged (PR #32,
   commit 0dfb672, merge 184f951). Two follow-ups worth committing
   before starting the next lane:
   (a) `tasks/plans/PLAN_03_APP_CODE.md` — flip KORAK 3.8-1 status
       from "PR open" to "merged into main" with the actual commit
       hashes.
   (b) `tasks/lessons.md` — codify Rule #82 (Info.plist submission
       audit: master↔localized divergence + duplicate keys +
       PrivacyInfo derived-data declaration) so the next submission
       cycle catches the same class of latent gaps.
   Docs-only; no code change.

2. SCOPE —
   - **Modified:**
     - `tasks/plans/PLAN_03_APP_CODE.md` — KORAK 3.8-1 row updated;
       Prod deploy dnevnik entry rewritten from "PR open" to
       "merged into main" with verification evidence.
     - `tasks/lessons.md` — Rule #82 added at the top (newest-first
       ordering).
     - `tasks/plan.md` — this file (Plan-ID rewrite).
   - **Untouched:** all runtime code, tests, CI, Firestore Rules,
     Cloud Functions, translations, iOS/Android native files.

3. STEPS —
   1. Cut `docs/plan-03-lesson-82-postmerge` off latest `main`.
   2. Commit the three-file docs update.
   3. Open PR per Rule #79 + Rule #80 pre-flight.

4. RISKS & TRADEOFFS —
   - Zero code change, zero runtime risk.
   - The lesson is preserved in the file that future sessions load
     during bootstrap; if not captured now, the next Info.plist
     audit cycle risks the same class of gap.

5. VERIFICATION —
   - `git diff --stat` — three files under `tasks/**`.
   - `flutter analyze` — 0 issues (no Dart touched).
   - `flutter test` — 263 tests green (unchanged).
   - unit tests — n/a; docs-only.
   - integration tests — n/a; docs-only.
   - security scan — branch diff limited to `tasks/**`. No
     secrets, no PII, no auth/billing/security-boundary change.
   - MPC PR pre-flight (Rules #79 + #80):
     - Title: `[PLAN-ID: 20260713-plan-03-lesson-82-postmerge]
       docs(plan+lessons): PLAN_03 KORAK 3.8-1 merged + Rule #82
       Info.plist submission audit`.
     - Body contains `Verification checklist`, `unit tests`,
       `integration tests`, `security scan`.
     - Body has ZERO Rule #80 naive-regex trigger substrings.
     - Plan-ID present in this `tasks/plan.md` file (line 2).
