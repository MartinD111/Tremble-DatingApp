# Active Implementation Plan
Plan ID: 20260714-stale-intel-audit-docs
Risk Level: LOW
Founder Approval Required: NO
Branch: docs/stale-intel-audit-20260714

## 0. AUDIT FINDINGS — 2026-07-14 session

This session was spawned to work KORAK 3.8-2 (flaky GymStep test).
Investigation cascaded into a broader intel audit because every
handoff-flagged blocker turned out to already be resolved. Concrete
evidence for each:

### A. KORAK 3.8-2 — flaky GymStep test — CANNOT REPRODUCE
- 30/30 isolated runs → 30 pass, 0 fail.
- 10/10 whole-file runs → 10 pass, 0 fail.
- 3/3 full-suite runs → 3 pass, 0 fail.
- Total: **43/43 local passes on `main` @ `f0def1e`.**
- CI history: last 100 runs = 70 success / 25 cancelled / 5 failure.
  Grep of the 5 failure logs for
  `gymstep|photo_upload_registration|your gyms|inline error` → 0 hits.
  Single most-recent failure was a GitHub Actions
  `Service Unavailable` infra outage on `Build Dev APK`.
- Todoist `6h4rqCpQ3jjg9vjw` closed with evidence.

### B. ADR-001 (BLE wire-up) — RESOLVED 2026-05-25
- `tasks/decisions/ADR-001-ble-proximity-engine.md` line 4:
  `Status: Implemented / Resolved`. Line 17 states the "mock timer"
  problem the ADR describes is historical Context, not current state.
- `lib/src/core/ble_service.dart` — real `flutter_blue_plus.startScan`
  on the Tremble UUID, real `flutter_ble_peripheral.start`, writes
  `proximity_events` with `fromUid`/`geohash`/`rssi`/`expiresAt`.
- `ios/Runner/BleRestoreBridge.swift` — real native CBCentralManager
  with `CBCentralManagerOptionRestoreIdentifierKey`
  (`app.tremble.ble.central`), survives force-quit.
  EventChannel `app.tremble/ble/restore/events` → Dart writer.
- `lib/src/core/ble_restore_service.dart` — real Dart bridge, wired
  at `home_screen.dart:166`.
- Android BLE permissions declared in AndroidManifest.xml L14–L21.
- **CLAUDE.md's active-blocker note is factually stale (~2 months).**

### C. CI shell-injection fix — MERGED via PR #14
- Commit `6923a42` is in `main` — verified via `git branch --contains`.
- Merge commit `b0ee5ab` (`Merge pull request #14`).
- Current `main` `.github/workflows/ci.yml` L45–L100 already has all
  four `env:` blocks (`TITLE`, `BODY`, `BASE_REF`, `BODY` again)
  neutralising the interpolation vector.
- Todoist `6h4xVHjRqhp56VQP` closed with evidence.

### D. stopBilling €10 CF — MERGED via PR #13
- Merged 2026-07-12, commit `e0108ff`.
- Todoist `6h4rx2R9CC3WvxGw` closed with evidence.

### E. CROSSING_PATHS visible notification — MERGED via PR #17
- Merged 2026-07-12, commit `7df1159`. PLAN_03 KORAK 3.1 ✅.
- Todoist `6h4rx2JH52hFHxQw` closed with evidence.

### F. prefer_not_to_say translation — MERGED via PR #18
- Merged 2026-07-12.
- Todoist `6h4rx2VJmmW7XjHP` closed with evidence.

## 1. OBJECTIVE
Reset the plan of record so future sessions (and the founder) don't
re-discover these five stale entries. Options for the next PR live in
§3 — founder picks one.

## 2. SCOPE
Docs-only PR on branch `docs/stale-intel-audit-20260714`. Files:
- `tasks/plans/PLAN_00_MASTER_INDEX.md` — remove 4 merged entries from
  §"Pokvarjeno / odprto" + 5 closed tasks from §"Todoist živi taski"
  (annotated with audit note so the delta is auditable).
- `tasks/lessons.md` — add Rule #83 (verify handoff intel before
  cutting a fix branch).
- `tasks/plans/PLAN_03_APP_CODE.md` — add KORAK 3.9 (this section)
  + 3.9-2/3/4 next-lane specs as durable plan of record.
- `tasks/plan.md` — this file, Plan-ID + branch line updated.
- `~/.claude/CLAUDE.md` — DIFF PROPOSED in PR body (§"Founder
  follow-up"); founder applies manually to the global file.

**Not touched:** any file under `lib/`, `functions/`, `ios/`,
`android/`, `test/`, `.github/`, `firebase.json`, `AndroidManifest.xml`,
`Info.plist`. Zero runtime code, zero CI, zero native config.

## 3. NEXT-LANE OPTIONS (founder picks)

### Option 3a — Stale-intel audit docs PR (RECOMMENDED)
Small, safe, docs-only. Prevents phantom-blocker rediscovery.
- Update `tasks/plans/PLAN_00_MASTER_INDEX.md` §"Pokvarjeno /
  odprto" and §"Todoist živi taski" to remove 5 completed items.
- Add Rule #83 to `tasks/lessons.md`: verify handoff intel against
  `git log`/`gh pr list` BEFORE cutting a fix branch.
- Update `~/.claude/CLAUDE.md` active-blocker section (founder-owned
  file — I can propose the diff; founder applies).
- Plan-ID: `20260714-stale-intel-audit-docs`.
- Risk: LOW. No runtime code changed.

### Option 3b — BLOCKER-STORE-001 iOS submission-readiness audit
Rule #82 3-surface audit against the current tree post PR #32:
- Master Info.plist vs `en.lproj/InfoPlist.strings` divergence
- Duplicate permission-key sweep
- PrivacyInfo.xcprivacy derived-data declaration completeness
Docs-only unless a gap is found; likely mixes some Info.plist edits
that need founder approval (native file, PLAN_00 rule).

### Option 3c — BLOCKER-LEGAL-005 paywall accuracy sync
`lib/src/features/settings/presentation/premium_screen.dart` vs
actual backend gate logic. Fix false claims / hidden gates. This is
an App Store 3.1.2 blocker per `tasks/blockers.md`.
- Requires reading every gate the premium screen advertises against
  the CF/Firestore logic that actually enforces it.
- Medium-risk (paywall is user-facing, billing-adjacent) — HIGH per
  MPC if we touch RevenueCat entitlement mapping.

### Option 3d — BLOCKER-STORE-003 brand-voice review of disclosure
Run the EN + SL Prominent Disclosure copy through brand-voice-agent.
Docs-only. Founder ships to Play Console with the revised copy.

## 4. RISKS & TRADEOFFS
- Option 3a is highest leverage for the token cost — every future
  session pays a compounding cost until the stale docs are corrected.
- Options 3b/3c/3d are all legit ship-critical lanes; picking one is
  a founder-strategy call I don't have context for (dependency on
  Play/App Store submission windows, Martin's availability, etc.).

## 5. VERIFICATION
- `git diff --stat` on branch → 4 files under `tasks/**`.
- `flutter analyze` → 0 issues (no Dart touched; pre-commit hook runs).
- `flutter test` → 263 tests green baseline preserved.
- unit tests — n/a (docs-only, no runtime code).
- integration tests — n/a (docs-only).
- security scan — branch diff limited to `tasks/**`. Zero secrets,
  zero PII, zero auth/billing/security-boundary change.
- MPC PR pre-flight (Rules #79 + #80):
  - Title: `[PLAN-ID: 20260714-stale-intel-audit-docs] docs(plan+lessons): remove 5 merged tasks from PLAN_00 + Rule #83 verify-intel`.
  - Body includes `## Verification checklist` naming `unit tests`,
    `integration tests`, `security scan` (each marked n/a with a
    one-line docs-only reason).
  - Body contains zero Rule #80 naive-regex trigger substrings.
  - Plan-ID present in this file (line 2).
