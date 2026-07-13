# Active Implementation Plan
Plan ID: 20260713-tier-matrix-audit
Risk Level: LOW
Founder Approval Required: NO
Branch: research/tier-matrix-audit-3-7b

1. OBJECTIVE — Produce the KORAK 3.7b deliverable: a grep-driven audit
   of every ADR-007 (`tasks/decisions/ADR-007-tier-matrix.md`) row
   against the actual codebase, with per-row verdicts (OK / PARTIAL /
   MISSING / N/A) and an ordered fix list that feeds sub-KORAK-i
   3.7c-3.7n. Zero runtime code changed; result is a single new
   document at `tasks/AUDIT_TIER_MATRIX_20260713.md`.

2. SCOPE —
   - **Added:**
     - `tasks/AUDIT_TIER_MATRIX_20260713.md` — the audit report.
   - **Modified:**
     - `tasks/plan.md` — this file; carries the Plan-ID so the MPC
       PR-Metadata gate passes.
   - **Untouched:** all runtime code, tests, CI config, Firestore
     rules, ADR-007 itself. This PR ships zero executable changes and
     zero ADR revisions.

3. STEPS —
   1. Grep each ADR-007 row against the codebase (server + client)
      and record file:line references for the actual gate (if any).
   2. Verdict-tag each row: ✅ OK / ⚠️ PARTIAL / ❌ MISSING / 🟦 N/A.
   3. For ⚠️ and ❌ rows, name the fix action and its estimated blast
      radius (one-file gate flip vs multi-file new build).
   4. Assemble the ordered fix list (Priority 1: ambiguity resolution,
      Priority 2: quick unambiguous gate additions, Priority 3:
      consistency test coverage, Priority 4: deferred behind ADR-001)
      that becomes the roadmap for sub-KORAK-i 3.7c-3.7n.
   5. Record assumptions + blind spots so the next session can decide
      whether to trust the audit or re-grep specific rows.
   6. Rewrite this `tasks/plan.md` with the Plan-ID and open a PR that
      complies with Rule #79 + Rule #80.

4. RISKS & TRADEOFFS —
   - **Grep-only method (LOW):** the audit does not run the app or
     toggle actual RevenueCat entitlements. A gate that reads
     `isPremium` under a different name (`isPro`, `hasEntitlement`)
     would be invisible. Reasonable confidence given the codebase's
     naming consistency, but flagged in the report.
   - **Ambiguity rows deliberately deferred (LOW):** three rows are
     tagged for founder clarification before 3.7c-3.7n begins. This
     is by design — kicking off a large PR before scope is clear
     wastes effort.
   - **No behaviour change:** audit is research-only; if any verdict
     turns out wrong, the fix lands in 3.7c-3.7n, not here.

5. VERIFICATION —
   - `flutter analyze` — 0 issues (no runtime code touched).
   - `flutter test` — 247 tests green on branch base (unchanged; no
     test files touched).
   - unit tests — none added or modified.
   - integration tests — none needed; no CF or Firestore path touched.
   - security scan — grep of branch diff shows only `tasks/**`
     changes; no secrets, no PII, no auth/billing/security-boundary
     change.
   - `git diff --stat origin/main...HEAD` — two files:
     `tasks/AUDIT_TIER_MATRIX_20260713.md` (new),
     `tasks/plan.md` (Plan-ID rewrite).
   - MPC PR-Metadata gate verification (Rule #79 + Rule #80 preflight):
     - Title format present: `[PLAN-ID: 20260713-tier-matrix-audit] …`.
     - Body contains: `Verification checklist`, `unit tests`,
       `integration tests`, `security scan`.
     - Body does NOT contain any literal risk-regex trigger substring
       (per Rule #80).
     - Plan-ID `20260713-tier-matrix-audit` present in this
       `tasks/plan.md` file (line 2).
