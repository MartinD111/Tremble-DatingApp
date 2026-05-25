---
gsd_state_version: 1.0
milestone: v1.2
milestone_name: Monetization & Security
status: in_progress
last_updated: "2026-05-25T00:00:00.000Z"
progress:
  total_phases: 2
  completed_phases: 1
  total_plans: 3
  completed_plans: 3
---

# Project State: Tremble

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-18 after v1.1)

**Core value:** The proximity event must work reliably, silently, and privately. If BLE fails, nothing else matters.
**Current focus:** v1.2 in progress — Monetization & Security

## Shipped Milestones

| Milestone | Name | Phases | Shipped |
|-----------|------|--------|---------|
| v1.0 | Foundation | 1–5 | 2026-04-08 |
| v1.1 | Core Product | 6–7 | 2026-04-09 |

## Phase Progress

| Phase | Name | Status |
|-------|------|--------|
| 1 | Foundation | ✅ Complete |
| 2 | Core UX | ✅ Complete |
| 3 | Proximity Engine | ✅ Complete |
| 4 | Infrastructure | ✅ Complete |
| 5 | Auth & Routing | ✅ Complete |
| 6 | Brand Alignment | ✅ Complete |
| 7 | Wave Mechanic + Push Notifications | ✅ Complete |
| 8 | Paywall / Tremble Pro | 🟡 In progress — billing mock, RevenueCat dependency missing |
| 9 | Security Hardening & GDPR | 🟡 In progress (10-01 GDPR fix deployed to tremble-dev) |
| 10 | Launch Polish & Store Deploy | 🟡 In progress — TASK-10-01 (icons + splash) ✅, TASK-10-02 (ghost state UX) ✅ |
| 11 | Technical Security Audit & Hardening | ✅ Complete (2026-04-20) |

## Open Blockers

| ID | Issue | Phase Impacted |
|----|-------|----------------|
| BLOCKER-003 | Legal/RevenueCat — Phase 8 on hold | Phase 8 |
| BLOCKER-005 | iOS dev provisioning for `com.pulse` — physical-device `flutter run` fails | Launch / QA |
| BLOCKER-006 | Photo upload E2E not verified on `tremble-dev` | Onboarding / Launch |
| BLOCKER-007 | `purchases_flutter` is not in `pubspec.yaml`; RevenueCat flow is `_simulateUpgrade()` mock | Phase 8 |
| BLOCKER-008 | `active_run_crosses` Firestore rule missing; production still returns `PERMISSION_DENIED` because rules were deployed to `tremble-dev` only | Proximity / Prod rules |
| BLOCKER-009 | `WavePillService` is not wired from FCM foreground messages to `HomeScreen` via `onForegroundWave` callback | Wave UX |
| BLOCKER-010 | Privacy Policy and Terms of Service are not confirmed live on `trembledating.com` | Store review |
| ~~BLOCKER-004~~ | ✅ RESOLVED 2026-04-24 — Maps API keys confirmed in tremble-dev and am---dating-app (iOS xcconfig + Android local.properties) |

## Resolved Blockers (2026-04-21)

| ID | Resolution |
|----|------------|
| ~~SEC-001~~ | ✅ All 19 Cloud Functions deployed to tremble-dev with App Check enforced |
| ~~FUNCTIONS-DEPLOY~~ | ✅ `firebase deploy --only functions --project dev` — all 19 functions live |

## Known Tech Debt

| ID | Debt | Status |
|----|------|--------|
| ~~D-25~~ | i18n defensive `tr()` + raw keys | ✅ Fixed 2026-04-21 |
| ~~D-26~~ | `ugc_action_sheet.dart` white background on dark gradient app | ✅ Fixed 2026-04-21 |
| ~~D-27~~ | Forgot password spinner does not stop after email sent | ✅ Fixed 2026-04-21 |
| ~~D-28~~ | Registration UI repair plan | ✅ Complete 2026-04-21 |
| D-29 | Map tile device test deferred | Open |
| D-30 | Phase 7 GSD tracking gap | Open |
| D-31 | `.planning/` docs are one month behind actual codebase | Open |
| D-32 | `MainApplication` extends deprecated `io.flutter.app.FlutterApplication`; migrate to `android.app.Application` | Open |

## Accumulated Context

### Roadmap Evolution

- Phase 11 added: SECURITY-01: Technical Security Audit & Hardening

### Decisions

- **11-PLAN-01**: Mask UIDs to 8-char prefix in all Cloud Function logs; remove email addresses from log statements entirely. Extended masking to fromUid/toUid in proximity BLE logs (Rule 2 — missing PII coverage). Commit: 6e03f0c.

## Next Action

Continue v1.2 Phase 8 with explicit mock billing status: the Premium screen exists, but RevenueCat is not integrated because `purchases_flutter` is absent from `pubspec.yaml`.

Next: wire `WavePillService` foreground FCM callback in `HomeScreen`, verify photo upload E2E on `tremble-dev`, and unblock live legal pages before store review.

Open debt: D-31 (`.planning/` stale docs), D-32 (deprecated Android application class).
Open blockers: BLOCKER-005 through BLOCKER-010 plus BLOCKER-003 legal/RevenueCat.

---
*Last updated: 2026-05-25 — synchronized with actual v1.2 app state. Planning docs are the only files changed.*
