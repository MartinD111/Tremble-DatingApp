# Active Implementation Plan
Plan ID: 20260713-event-pin-sheet-tier-gate-tests
Risk Level: LOW
Founder Approval Required: NO
Branch: feat/tier-3-7c-3-event-pin-sheet-tests

1. OBJECTIVE — Close KORAK 3.7c-3 (Event pin sheet gate trace) per
   ADR-007 Amendment §3 and the audit report's "verify existing gates
   for participant count + heatmap indicator" scope. Confirmed by
   read: both gates in `event_pin_sheet.dart` already match §3
   (Free → `_LockedFeatureRow` for both rows, Premium → `_PeopleCountRow`
   + `_HeatmapActiveRow`). This PR lands the pair-of-tests required by
   ADR-007 §4 so any future drift of the `effectiveIsPremium` ternary
   trips a red test. Zero behaviour change; regression net only.

   Slice B — "potential-matches count for Premium" (subset of
   participants that fit the caller's filter prefs) — is deferred to
   bundle with 3.7c-4b, which owns the per-filter subset CF endpoint
   (design pending per audit report §Priority 1). Founder decision
   2026-07-13.

2. SCOPE —
   - **Added:**
     - `test/features/map/event_pin_sheet_tier_gates_test.dart` — new
       widget test file. Four pair-of-tests: (Free, Premium) × (people
       count, heatmap indicator). Free → locked row visible;
       Premium → active/count row visible.
   - **Modified:**
     - `tasks/plan.md` — this file (Plan-ID rewrite).
     - `tasks/plans/PLAN_03_APP_CODE.md` — mark 3.7c-3 as MERGED once
       PR lands, add prod-deploy dnevnik entry.
   - **Untouched:** all runtime code (widget, model, Cloud Functions,
     Firestore rules). This is a regression-net PR; zero behavioural
     change. Slice B (potential-matches count) does not appear here.

3. STEPS —
   1. Create `test/features/map/event_pin_sheet_tier_gates_test.dart`.
   2. Assert Free path: pumping `EventPinSheet(effectiveIsPremium:
      false, …)` renders `pro_feature_locked` translation and does NOT
      render the raw participant count nor "LIVE" heatmap pill.
   3. Assert Premium path: pumping `EventPinSheet(effectiveIsPremium:
      true, …)` renders the participant count formatted via
      `pulsing_here` translation and the "LIVE" heatmap pill; does NOT
      render `pro_feature_locked` or `heatmap_locked`.
   4. Constrain flavor to non-dev (`FLAVOR=prod`) via widget test
      harness so `_DevGeofenceControls` does not render and pollute
      finder queries.
   5. `flutter analyze` + `flutter test` all green.
   6. Rewrite this `tasks/plan.md`, open PR per Rule #79 + Rule #80
      pre-flight.

4. RISKS & TRADEOFFS —
   - **Copy assertions coupled to translations.dart (LOW):** the tests
     look up EN/SL strings via `t()` at runtime, matching the widget's
     own lookup. If a future copy PR changes the EN wording, this file
     rebuilds against the new string automatically (no hard-coded
     literal). Safe.
   - **`_DevGeofenceControls` renders only when FLAVOR==dev.** Widget
     tests do NOT pass `--dart-define=FLAVOR=dev`, so the widget's
     `const String.fromEnvironment('FLAVOR', defaultValue: 'dev')`
     defaults to `dev` and the dev controls DO render. Compensated by
     scoping finder queries to non-dev widgets only (or by explicitly
     asserting the absence of locked/active markers without touching
     the dev block).
   - **Slice B deferred, not skipped.** ADR-007 §3's "potential matches
     count for Premium" still needs to land. Tracked as 3.7c-3-Slice-B
     in PLAN_03 status; will be bundled with 3.7c-4b when the per-filter
     subset CF design is finalised.

5. VERIFICATION —
   - `flutter analyze` — 0 issues.
   - `flutter test` — all suites green (unit + widget). New file
     `event_pin_sheet_tier_gates_test.dart` adds 4 tests.
   - unit tests — added (pair-of-tests for each of the two gates).
   - integration tests — n/a; no CF or Firestore path touched.
   - security scan — branch diff shows only Dart test additions + two
     docs files. No secrets, no PII, no auth/billing/security-boundary
     change.
   - `git diff --stat origin/main...HEAD` — expected files:
     `test/features/map/event_pin_sheet_tier_gates_test.dart`,
     `tasks/plan.md`,
     `tasks/plans/PLAN_03_APP_CODE.md`.
   - MPC PR-Metadata gate verification (Rule #79 + Rule #80
     pre-flight):
     - Title format: `[PLAN-ID:
       20260713-event-pin-sheet-tier-gate-tests] …`.
     - Body contains: `Verification checklist`, `unit tests`,
       `integration tests`, `security scan`.
     - Body does NOT contain any literal risk-regex trigger substring
       (per Rule #80).
     - Plan-ID present in this `tasks/plan.md` file (line 2).
