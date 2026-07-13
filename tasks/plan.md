# Active Implementation Plan
Plan ID: 20260713-adr-007-and-korak-3-6-docs
Risk Level: LOW
Founder Approval Required: NO
Branch: docs/plan-03-korak-3-6-merged

1. OBJECTIVE — Bundle the KORAK 3.6 post-merge documentation update
   with ADR-007 (tier-matrix lock) and the KORAK 3.7 restructure into
   a single docs-only PR against main. Two separate purposes served
   in one branch:
   (a) Backfill the KORAK 3.6 Output block in
       `tasks/plans/PLAN_03_APP_CODE.md` now that PR #23 is merged.
   (b) Lock the founder-provided Free/Premium tier matrix as
       `tasks/decisions/ADR-007-tier-matrix.md` and rewrite KORAK 3.7
       in PLAN_03 from a one-shot copy-fix into an umbrella covering
       sub-KORAK-i 3.7a-3.7z (paywall copy, feature-parity audit,
       per-gate PRs, integration tests).

2. SCOPE —
   - **Modified:**
     - `tasks/plans/PLAN_03_APP_CODE.md` — KORAK 3.6 heading marked
       ✅, Output block filled (merge coordinates, Places API grep
       report, test-count evidence, backward-compat note), STATUS
       table bumped, prod-deploy dnevnik entry appended for 3.6.
       Separately: KORAK 3.7 rewritten to reference ADR-007 with an
       audit-snapshot table and an ordered 3.7a-3.7z breakdown.
     - `tasks/plan.md` — this file; carries the new Plan-ID so the
       MPC PR-Metadata gate passes on the docs branch.
   - **Added:**
     - `tasks/decisions/ADR-007-tier-matrix.md` — Free/Premium tier
       matrix locked as source of truth. Includes cross-cutting rules
       (server is tier truth, no grandfathering, copy rules,
       consistency test pair requirement, RevenueCat entitlement key
       unchanged), consequences, non-goals, and cross-refs to the
       affected code.
   - **Untouched:** all runtime code, tests, CI config, Firestore
     rules. This PR ships zero executable changes.

3. STEPS —
   1. Fill the KORAK 3.6 Output block in PLAN_03_APP_CODE.md from the
      merged PR #23 metadata (merge commit ee48c69, tests 242/114
      green).
   2. Write `tasks/decisions/ADR-007-tier-matrix.md` from the
      founder's matrix, adding the cross-cutting rules that make the
      ADR actionable for KORAK 3.7 and future gate work.
   3. Rewrite PLAN_03 §3.7 to reference ADR-007, include the current-
      state audit snapshot table, and break down into ordered
      sub-KORAK-i so future sessions can pick up any one slice
      independently.
   4. Rewrite this `tasks/plan.md` with a Plan-ID that reflects the
      docs+ADR bundle so the MPC PR-Metadata gate passes.
   5. Retitle PR #24 with the required `[PLAN-ID: …]` prefix and
      rewrite its body to include the four MPC gate phrases
      (`Verification checklist`, `unit tests`, `integration tests`,
      `security scan`).

4. RISKS & TRADEOFFS —
   - **Bundled scope (LOW):** two logical changes (KORAK 3.6 backfill
     + ADR-007 lock) share one PR. Alternative was two separate
     PRs, but both change only `.md` files under `tasks/` with no
     overlap on the same file — combining reduces review overhead and
     lands the ADR before KORAK 3.7a (PR #25) needs it.
   - **Repeated MPC-gate mistake (SURFACED):** the initial PR #24
     shipped without the `[PLAN-ID: …]` title prefix or the four
     required body phrases, ignoring the memory note
     `pr-title-plan-id-required.md`. This plan file adds those
     bookkeeping steps to the checklist and the retitle-and-rebody is
     step 5. Future docs-only PRs must apply the same gate treatment.
   - **No runtime impact (VERIFIED):** grep for `\.dart`, `\.ts`,
     `\.yaml`, `firestore.rules` on the branch diff → 0 hits; only
     `.md` files touched.

5. VERIFICATION —
   - `flutter analyze` — 0 issues (no runtime code touched; kept as a
     safety net).
   - `flutter test` — 242 tests green on this branch's base
     (unchanged; no test files touched).
   - unit tests — none added or modified.
   - integration tests — none needed; no CF or Firestore path
     touched.
   - security scan — no secrets, no PII, no auth/billing logic
     change; grep of the branch diff shows only `tasks/**` changes.
   - Grep evidence:
     - `git diff --stat origin/main...HEAD` shows only
       `tasks/decisions/ADR-007-tier-matrix.md` (added),
       `tasks/plans/PLAN_03_APP_CODE.md` (modified), and
       `tasks/plan.md` (modified after this step).
   - MPC PR-Metadata verification:
     - PR title format: `[PLAN-ID: 20260713-adr-007-and-korak-3-6-
       docs] docs(plan): KORAK 3.6 backfill + ADR-007 tier matrix +
       KORAK 3.7 restructure`.
     - PR body must contain literal phrases: `Verification
       checklist`, `unit tests`, `integration tests`, `security scan`.
     - Plan-ID `20260713-adr-007-and-korak-3-6-docs` present in this
       `tasks/plan.md` file (line 2).
