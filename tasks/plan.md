# Active Implementation Plan
Plan ID: 20260712-lessons-rule-79-expand
Risk Level: LOW
Founder Approval Required: NO
Branch: docs/lessons-rule-79-expand

1. OBJECTIVE — Expand Rule #79 in `tasks/lessons.md` with the full MPC PR-metadata gate contract (title Plan-ID regex + four body checklist phrases + retitle re-runs CI + non-admin path), so future PRs pass the `① MPC — PR Metadata` job on the first push.

2. SCOPE — Documentation only. Modified: `tasks/lessons.md`, `tasks/plan.md`. Does NOT touch: Flutter app code, Cloud Functions, Firestore Rules, `.github/workflows/`, native manifests, secrets, or `pubspec.yaml`.

3. STEPS —
   (a) Replace Rule #79 body with a two-part contract (title + body) that names the four required phrases (`Verification checklist`, `unit tests`, `integration tests`, `security scan`) and clarifies CI only regex-matches the title (does not read `tasks/plan.md`).
   (b) Document that `gh pr edit <N> --title --body` re-runs the check and that stale FAILURE conclusions do not block once the latest run passes.
   (c) Update `tasks/plan.md` (this file) with this PR's Plan-ID.

4. RISKS & TRADEOFFS —
   - No runtime risk: documentation-only change.
   - Rule #79 grows in length; kept inline in lessons.md rather than split into a separate doc so the source stays single-file per MPC convention.

5. VERIFICATION —
   - **Verification checklist:**
   - [x] unit tests — n/a for docs; no code touched.
   - [x] integration tests — n/a for docs; no runtime path touched.
   - [x] security scan — n/a for docs; no dependency, secret, permission, or workflow change.
   - [x] `flutter analyze` clean and `flutter test` green via pre-commit hook.
   - [x] Diff scoped entirely under `tasks/` — verified via `git diff --stat origin/main...HEAD`.
