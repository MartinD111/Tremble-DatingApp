# Active Implementation Plan
Plan ID: 20260714-adr007-pair-of-tests-hardening
Risk Level: MEDIUM (billing-adjacent test surface — tests only, no runtime code change)
Founder Approval Required: YES (approved 2026-07-14 in the pre-cut coverage-matrix review)
Branch: test/adr007-pair-of-tests-hardening

## 0. AUDIT RESULT — ADR-007 §4 pair-of-tests coverage matrix (2026-07-14)

Ship-side PR #37 (LEGAL-005 close) recorded the "pair-of-tests per
gate" mandate as a MEDIUM test-hardening follow-up lane. This PR
executes that lane against the seven Premium bullets in
`premium_screen.dart` `premiumOnlyFeatureBullets`.

### Coverage matrix as of `main @ 1301d54`

| # | Paywall bullet | Gate location | (a) Free hits | (b) Premium bypasses | Verdict |
|---|---|---|---|---|---|
| 1 | `premium_feature_radar_extended` | `lib/src/core/geo_service.dart:257` (`radiusTier = _isPremium ? 'pro' : 'free'`) → CFs read tier | MISSING | MISSING | **GAP — filled this PR** |
| 2 | `premium_feature_mutual_waves_20` | Client `AuthUser.hasReachedWaveLimit`; server `matches.functions.ts:38-56, 256-260` | Client PRESENT (`auth_user_wave_limit_test.dart:6,49,82`); server PARTIAL (helper `mutualWaveLimitForUser` returns 5 — `matches.test.ts:397` — but no `count >= limit` rejection pair) | Client PRESENT (line 16, 60, 82); server PARTIAL | **PARTIAL server side — filled this PR** |
| 3 | `premium_feature_open_profile_cards` | `matches_screen.dart:143` compound `isPremium && hasMutualWave` | PRESENT (`matches_three_state_test.dart:25`) | PRESENT (`:64` + 4-cell truth-table at `:118`) | COVERED |
| 4 | `premium_feature_recap_full` | `run_recap_screen.dart:498` + `matches_screen.dart:467` | PRESENT (`viewed_recaps_test.dart:6, 28`) + wiring pin | PRESENT (`viewed_recaps_test.dart:50`) + wiring pin | COVERED |
| 5 | `premium_feature_near_miss_history` | `matches_screen.dart:40, 54` | PRESENT (`near_miss_locked_state_test.dart:41`) | PRESENT (`:49`) | COVERED |
| 6 | `premium_feature_hard_filters` | Soft-labelled "coming soon" — no behavioural gate (Amendment §2 paused) | n/a | n/a | SKIP per ADR-007 Amendment §2 |
| 7 | `premium_feature_event_insights` | `event_pin_sheet.dart:138, 154, 171` | PRESENT (`event_pin_sheet_tier_gates_test.dart:38, 85`) | PRESENT (`:59, 104`) | COVERED (PR #30) |

### What this PR ships

Two gaps closed, ~50 LoC added, zero runtime code change:

1. **Gate 1 (radar_extended)** — new
   `test/core/geo_service_radar_tier_test.dart`. Source-scan pair
   pinning the Free tuple (100 m + −75 dBm), the Premium tuple (250 m
   + −85 dBm), the shared `_isPremium ? 'pro' : 'free'` ternary that
   writes both branches, and the `updatePremiumTier` runtime hook.
   Behavioural render is untestable in isolation without dwarfing
   the assertion signal (Firestore + Battery + Geolocator mocking);
   source-scan mirrors the pattern already used by
   `recap_ui_wiring_test.dart` and `near_miss_locked_state_test.dart:146`.
2. **Gate 2 (mutual_waves_20 — server side)** — two additional
   assertions in `functions/src/__tests__/matches.test.ts` under the
   existing `mutual wave monthly counters` block. Uses the exported
   `mutualWaveLimitForUser` + `mutualWaveCountForUser` helpers to
   verify that the `count >= limit` comparison at
   `matches.functions.ts:256` correctly rejects at Free-tier=5,
   accepts Premium at 5, and rejects Premium at 20.

Everything else stays untouched. Gates 3, 5, 7 have widget-level
behavioural pairs; Gate 4 is behaviourally covered on the
viewedRecaps surface and wiring-pinned on the read-only render
surface. Gate 6 is skipped per ADR-007 Amendment §2.

## 1. OBJECTIVE
Close the ADR-007 §4 pair-of-tests deferred lane recorded in PR #37
LEGAL-005 close-out. Every gated feature now has an (a) Free hits
gate + (b) Premium bypasses gate assertion so a future refactor
cannot silently un-gate a Premium-only bullet without a CI failure.

## 2. SCOPE

**Files this PR touches:**
- `test/core/geo_service_radar_tier_test.dart` — NEW (Gate 1 pair).
- `functions/src/__tests__/matches.test.ts` — extend existing
  `describe("mutual wave monthly counters")` block with Gate 2 pair.
- `tasks/plan.md` — this file; Plan-ID rewrite + coverage matrix.
- `tasks/blockers.md` — append pair-of-tests close-out note under
  BLOCKER-LEGAL-005 (deferred lane resolved).
- `tasks/plans/PLAN_03_APP_CODE.md` — append KORAK 3.9-3-followup
  Output block under KORAK 3.9.

**Files this PR does NOT touch:** anything under `lib/`,
`functions/src/modules/`, `functions/src/middleware/`, `ios/`,
`android/`, `.github/`, `firebase.json`, `firestore.rules`,
`firestore.indexes.json`, `PrivacyInfo.xcprivacy`. Zero runtime code
path modified; zero CF handler modified; zero native config; zero
CI change; zero test assertion that already passes gets rewritten
(only extension).

## 3. NEXT LANES — durable index of deferred work

After this PR merges, remaining ship-side blockers indexed here for
future sessions (unchanged from PR #38 §3):

### Ship-critical blockers

- **BLOCKER-STORE-003** — Play Console submission for background
  location. Copy review DONE (KORAK 3.9-4, PR #36). Still owed: EN +
  SL screenshots on a real device, demo video, Play Console
  declaration form. Task `6h3p8gWG7WHWV7JP`.
- **BLOCKER-STORE-004** — Android Foreground Services declaration on
  Play Console (types: location, connectedDevice, dataSync). Task
  `6h3p8gc78572RF9P`.

### Legal blockers (unfab + counsel)

- **BLOCKER-LEGAL-001** — DPIA false claims (`getPublicProfile` leak
  claim + TTLs mismatch). Task `6h3jFhxVHpRmph9P`.
- **BLOCKER-LEGAL-003** — `gender` + `lookingFor` = implicit Art. 9
  sexual-orientation category; explicit consent gate missing. Task
  `6h3j9q65vh3mG64P`.
- **BLOCKER-LEGAL-004** — ToS §7 promises automatic weekend window;
  code enforces user-triggered activation. Sync ToS to code or code
  to ToS. Task `6h332RFRW946QWXw`.

## 4. RISKS & TRADEOFFS

- **Zero runtime change.** Both files are test-only additions; the
  handlers, providers, and UI paths compile and behave identically
  before and after.
- **Billing-adjacent test surface** — mutual-wave enforcement is the
  RevenueCat entitlement contract. Extending the server helper pair
  with a threshold-rejection assertion tightens the safety net
  around a Free→Premium boundary without touching the boundary
  itself.
- **Source-scan wiring pattern (Gate 1)** — pins string literals
  in `geo_service.dart`. If a future refactor renames the tier
  strings or moves the ternary, the wiring test needs a coordinated
  update — same maintenance shape as `recap_ui_wiring_test.dart`.
  Accepted trade-off.

## 5. VERIFICATION

- **unit tests** — 2 new Dart assertions (`test/core/geo_service_radar_tier_test.dart`) + 2 new server assertions (`functions/src/__tests__/matches.test.ts`).
- **integration tests** — n/a (test-only PR; no new runtime paths to exercise).
- **security scan** — n/a. Test files only; no auth/PII/billing runtime code path modified.
- `flutter analyze` → 0 issues.
- `flutter test` → 265/265 pass (263 baseline + 2 new).
- `cd functions && npm test` → 119/119 pass (117 baseline + 2 new).
- MPC PR pre-flight (Rules #79 + #80):
  - Title: `[PLAN-ID: 20260714-adr007-pair-of-tests-hardening] test(gates): ADR-007 §4 pair-of-tests coverage for 2 Premium gates`.
  - Body contains `## Verification checklist` naming `unit tests`,
    `integration tests`, `security scan`.
  - Body contains zero Rule #80 naive-regex trigger substrings.
  - Plan-ID present in this file (line 2).
