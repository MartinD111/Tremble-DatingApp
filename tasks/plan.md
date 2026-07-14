# Active Implementation Plan
Plan ID: 20260714-paywall-audit-legal-005-close
Risk Level: LOW
Founder Approval Required: NO
Branch: docs/paywall-audit-legal-005-close-20260714

## 0. AUDIT RESULT — KORAK 3.9-3 paywall accuracy sync

**Overall verdict: LEGAL-005 already substantively closed by the KORAK
3.7 series (2026-07-13). Audit confirms every current bullet maps to
a real, implemented code gate. Docs-only close, no runtime edit.**

KORAK 3.9-3 was originally scoped as "sync `premium_screen.dart` with
actual backend gate logic (compound gates from KORAK 3.7c-1:
`hasMutualWave`, `effectiveIsPremium`, weekend pass window, itd.)."
The 2026-07-14 audit found nothing to sync — the sync already
happened during the ADR-007 rewrite in KORAK 3.7a → 3.7c-5R. Pivot to
docs-only close with audit evidence.

### Bullet ↔ gate mapping (all Premium-only bullets)

| Bullet key | Gate location | Verified |
|---|---|---|
| `premium_feature_radar_extended` | `lib/src/core/geo_service.dart:20-21` (100/250 m + −75/−85 dBm) | ✅ |
| `premium_feature_mutual_waves_20` | `functions/src/modules/matches/matches.functions.ts:38-56` (monthly cap 5/20, Europe/Ljubljana counter) | ✅ |
| `premium_feature_open_profile_cards` | `matches_screen.dart:143` (compound `isPremium && hasMutualWave`) + `match_repository.dart:70` (`hasMutualWave` field) | ✅ |
| `premium_feature_recap_full` | `recap_ttl_provider.dart` (600 s TTL) + `run_recap_screen.dart:498-503` (`isReadOnly = !isPremium \|\| isHistory \|\| isExpired`) | ✅ |
| `premium_feature_near_miss_history` | `matches_screen.dart:40,54` (upsell banner Free, tab visible Premium) | ✅ |
| `premium_feature_hard_filters` | Soft-labelled "coming soon" per ADR-007 Amendment §2/§6; locale coverage locked by `premium_screen_test.dart:99-153` | ✅ (honest) |
| `premium_feature_event_insights` | `event_pin_sheet.dart:138,154,171` (`effectiveIsPremium` gate on count + heatmap chip) | ✅ |

### Free-tier bullets (verified as-truthfully-free)

| Bullet key | Reality |
|---|---|
| `premium_free_proximity` | Proximity detection + push notifications work for both tiers |
| `premium_free_pulse_intercept` | Send Phone + Send Photo free for both tiers per ADR-007 |
| `premium_free_active_radar` | 30-min active radar inside every Trembling Window for both tiers |
| `premium_free_mutual_waves_5` | Free monthly cap = 5 (`MUTUAL_WAVE_FREE_LIMIT`) |
| `premium_free_event_pins` | Event pins on map visible; heatmap circle *outline only* per ADR-007 §3 |
| `premium_free_nicotine_filter` | Nicotine exclusion filter works for both tiers |

### Retired keys (LEGAL-005's original complaints)

Test-locked as removed in `test/features/settings/premium_screen_test.dart:75-97`:
`premium_feature_unlimited_geofence`, `premium_feature_wider_radar`,
`premium_feature_custom_themes`, `premium_feature_advanced_filters`,
`premium_free_gym_mode`, `premium_free_local_radar`,
`premium_free_wave_limit`, `premium_feature_distance_100`,
`premium_free_distance_50`.

### Copy-rule enforcement

`premium_screen_test.dart:155-189` scans user-facing strings for
banned phrases (`revolutionary`, `seamless`, `game-changing`, `find
love today`, `find your person`, `swipe`, `match queue`, `chat`) per
ADR-007 §3. Currently passes.

## 1. OBJECTIVE
Close BLOCKER-LEGAL-005 with concrete audit evidence so future
sessions don't re-open the phantom-blocker cycle Rule #83 warned
against. Preserve the audit's bullet↔gate mapping in a durable
location (blockers.md + this plan) as a source-of-truth for the next
copy-review cycle.

## 2. SCOPE
- `tasks/blockers.md` — BLOCKER-LEGAL-005 → RESOLVED with the
  full bullet↔gate mapping table + deferred pair-of-tests note.
- `tasks/plan.md` — this file; Plan-ID + §0 audit evidence + §3
  durable index of remaining ship-side blockers.
- `tasks/plans/PLAN_03_APP_CODE.md` — KORAK 3.9-3 Output block filled
  with the pivot note (fix → docs close).

**Not touched:** any code under `lib/`, `functions/`, `test/`,
`ios/`, `android/`, `.github/`, `firebase.json`. Zero runtime code,
zero test change, zero native config, zero CI. Copy did not need to
change; every current bullet already matches a real gate.

## 3. NEXT LANES — durable index of deferred work

The user asked to store the following for later. They remain tracked
in `tasks/blockers.md` with Todoist task IDs; surfaced here so any
future session sees them at bootstrap.

### Ship-critical blockers (unfab-owned or unfab+Martin)

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
- **BLOCKER-LEGAL-002** — Cannabis in `nicotineUse` = Art. 10 GDPR
  in some jurisdictions. Task `6h3jHjr7Hf58G8pw`.
- **BLOCKER-LEGAL-003** — `gender` + `lookingFor` = implicit Art. 9
  sexual-orientation category; explicit consent gate missing (Grindr
  precedent: NOK 65M fine). Task `6h3j9q65vh3mG64P`.
- **BLOCKER-LEGAL-004** — ToS §7 promises automatic weekend window
  (Fri 19h – Sun 19h), code enforces user-triggered activation
  (Rule: single write path via `activateWeekendPass`). Sync ToS to
  code or code to ToS. Task `6h332RFRW946QWXw`.

### Test-hardening lane (deferred from this PR)

- **KORAK 3.9-3 follow-up — ADR-007 §4 pair-of-tests per gate.** For
  every gated feature, add a pair of tests: (a) Free user hits gate
  → correct behaviour (limit / locked / grey / hidden); (b) Premium
  user does not hit gate → correct behaviour. Partial coverage in
  `matches_three_state_test.dart`, `revenuecat_subscription_test.dart`,
  `test/features/recap/`. Not systematically per-bullet. Risk MEDIUM
  (billing-adjacent test surface). Founder approval required to
  start. Not gating LEGAL-005 closure.

## 4. RISKS & TRADEOFFS
- Zero runtime change; zero submission risk introduced by this PR.
- Docs-only audit close means the paywall stays exactly as-is on
  main. That is by design — the audit found the copy is already
  correct.
- The pair-of-tests hardening lane is real work worth doing before
  App Store 3.1.2 review, but it is a test-quality investment, not a
  compliance blocker. Deferred cleanly here rather than force-bundled
  into this docs PR.

## 5. VERIFICATION
- `git diff --stat` on branch → 3 files under `tasks/**`.
- `flutter analyze` → 0 issues (pre-commit hook re-verifies; no Dart
  touched).
- `flutter test` → 263-baseline preserved.
- unit tests — n/a (docs-only, no runtime code).
- integration tests — n/a (docs-only).
- security scan — branch diff limited to `tasks/**`. Zero secrets,
  zero PII, zero auth/billing/security-boundary change.
- MPC PR pre-flight (Rules #79 + #80):
  - Title: `[PLAN-ID: 20260714-paywall-audit-legal-005-close] docs(blockers+plan): close BLOCKER-LEGAL-005 — paywall bullet↔gate audit CLEAN`.
  - Body contains `## Verification checklist` naming `unit tests`,
    `integration tests`, `security scan`.
  - Body contains zero Rule #80 naive-regex trigger substrings.
  - Plan-ID present in this file (line 2).
