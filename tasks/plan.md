# Active Implementation Plan
Plan ID: 20260712-split-plan-set
Risk Level: LOW
Founder Approval Required: NO
Branch: docs/split-plan-set

1. OBJECTIVE — Land the split TREMBLE plan set (`tasks/plans/PLAN_00`–`PLAN_05`), the appended plan steps in `tasks/TREMBLE_IMPLEMENTATION_PLAN.md`, and Rule #79 in `tasks/lessons.md` so future PRs never re-hit the PLAN-ID CI gate.

2. SCOPE — Documentation only under `tasks/`. New: `tasks/plans/PLAN_00_MASTER_INDEX.md`, `PLAN_01_GIT_CI_SECURITY.md`, `PLAN_02_INFRA_OPS.md`, `PLAN_03_APP_CODE.md`, `PLAN_04_LEGAL_STORES.md`, `PLAN_05_LAUNCH.md`. Modified: `tasks/TREMBLE_IMPLEMENTATION_PLAN.md`, `tasks/lessons.md`. Does NOT touch: Flutter app code, Cloud Functions, Firestore Rules, CI workflows, native manifests, secrets, or `pubspec.yaml`.

3. STEPS —
   (a) Add the six-file split plan set under `tasks/plans/` and extend `TREMBLE_IMPLEMENTATION_PLAN.md` with the new plan steps.
   (b) Codify Rule #79 in `tasks/lessons.md` — every PR title must carry `[PLAN-ID: YYYYMMDD-short-name]`, docs-only PRs included.
   (c) Update `tasks/plan.md` (this file) so the active Plan-ID matches this PR's title.
   (d) Retitle PR #15 with `[PLAN-ID: 20260712-split-plan-set]` and update the body to satisfy the MPC PR-metadata gate.

4. RISKS & TRADEOFFS —
   - No runtime risk: documentation-only, no code, config, workflow, or dependency change.
   - Superseding the previous active plan (`20260711-fix-stop-billing-cloudevent`) is safe — that work already merged via PR #13.

5. VERIFICATION —
   - **Verification checklist:**
   - [x] unit tests — n/a for docs; existing test suite unchanged (pre-commit hook ran and passed: 10 suites / 95 tests).
   - [x] integration tests — n/a for docs; no touched service, function, or workflow.
   - [x] security scan — n/a for docs; no dependency, secret, permission, or manifest change. No security-sensitive surface introduced.
   - [x] `flutter analyze` clean and `flutter test` green on pre-commit hook.
   - [x] Diff scoped entirely under `tasks/` — verified with `git diff --stat origin/main...HEAD`.
