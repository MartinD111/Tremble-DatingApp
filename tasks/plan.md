# Active Implementation Plan
Plan ID: 20260713-plan-03-ship-pivot-docs
Risk Level: LOW
Founder Approval Required: NO
Branch: docs/plan-03-ship-pivot

1. OBJECTIVE — Reflect the KORAK 3.7 substantial completion in
   `tasks/plans/PLAN_03_APP_CODE.md` and pivot the "naslednji korak"
   guidance from tier-matrix polish to ship-critical work (KORAK 3.8
   drobci → PLAN_04 Legal + Play Console → PLAN_05 final build + BLE
   matrix + submission). Founder's stated goal 2026-07-13: ship the
   app. Remaining 3.7c-* work (4a heatmap chip, 4b + 3.7c-3-B
   per-filter subset, 6..11 pair-of-tests batch, 3.7z integration
   matrix) is deferrable and does not block launch.

2. SCOPE —
   - **Modified:**
     - `tasks/plans/PLAN_03_APP_CODE.md` — mark 3.7c-3-A as MERGED,
       update STATUS row to SHIP-READY, rewrite "Naslednji korak"
       block, add "SHIP PIVOT" entry to prod deploy dnevnik.
     - `tasks/plan.md` — this file (Plan-ID rewrite).
   - **Untouched:** all runtime code, tests, CI config, Firestore
     rules, ADR-007. This is a docs-only pivot recording.

3. STEPS —
   1. Update PLAN_03_APP_CODE.md status table + naslednji-korak
      guidance to reflect the ship pivot.
   2. Add SHIP PIVOT entry to the prod deploy dnevnik.
   3. Rewrite this `tasks/plan.md`, open PR per Rule #79 + #80.

4. RISKS & TRADEOFFS —
   - **Docs-only, zero code change.** No functional risk.
   - **The pivot is a founder decision recorded here, not a
     unilateral CLI shift.** Rooted in founder's stated 2026-07-13
     ship goal.

5. VERIFICATION —
   - `flutter analyze` — 0 issues (no runtime code touched).
   - `flutter test` — 263 tests green (unchanged; no test files
     touched).
   - unit tests — none added or modified (n/a for docs).
   - integration tests — n/a; no CF or Firestore path touched.
   - security scan — grep of branch diff shows only `tasks/**`
     changes; no secrets, no PII, no auth/billing/security-boundary
     change.
   - `git diff --stat origin/main...HEAD` — two files:
     `tasks/plans/PLAN_03_APP_CODE.md`, `tasks/plan.md`.
   - MPC PR-Metadata gate verification (Rule #79 + Rule #80
     pre-flight):
     - Title format: `[PLAN-ID:
       20260713-plan-03-ship-pivot-docs] …`.
     - Body contains: `Verification checklist`, `unit tests`,
       `integration tests`, `security scan`.
     - Body does NOT contain any literal risk-regex trigger
       substring (per Rule #80).
     - Plan-ID present in this `tasks/plan.md` file (line 2).
