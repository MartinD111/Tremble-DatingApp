---
gsd_state_version: 1.0
milestone: Beta Ready
milestone_name: Beta Ready (pending Apple Dev Account)
status: pending_release
last_updated: "2026-05-28T12:00:00.000Z"
progress:
  total_phases: 11
  completed_phases: 10
  total_plans: 15
  completed_plans: 15
---

# Project State: Tremble

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-18 after v1.1)

**Core value:** The proximity event must work reliably, silently, and privately. If BLE fails, nothing else matters.
**Current focus:** Beta Ready — pending Apple Dev Account approval.

## Shipped Milestones

| Milestone | Name | Phases | Shipped |
|-----------|------|--------|---------|
| v1.0 | Foundation | 1–5 | 2026-04-08 |
| v1.1 | Core Product | 6–7 | 2026-04-09 |
| v1.2 | Monetization & Security | 8-9, 11 | 2026-05-28 |

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
| 8 | Paywall / Tremble Pro | ✅ Complete (Mock RevenueCat wired, design refactored to solid brand cards) |
| 9 | Security Hardening & GDPR | ✅ Complete (GDPR deletion pipeline validated) |
| 10 | Launch Polish & Store Deploy | 🟡 In progress |
| 11 | Technical Security Audit & Hardening | ✅ Complete (All findings resolved) |

## Completed Features (Since April 2026)

* **Weekend Getaway**: Weekend-specific premium plan/window matching features.
* **LiquidNavBar**: Custom bottom bar with dynamic icon spotlighting and route overlay.
* **WavePillService**: Foreground wave notification banner with entrance & success animations and haptics.
* **Tutorial Overlay**: Multi-step walkthrough with page navigation locks.
* **5-Card Premium Carousel**: Solid Graphite (`#1A1A18`) 3D cards with solid plan borders and exact typography (Playfair Display / Instrument Sans).
* **HR Translations Parity**: 100% parity across Croatian translations with 608/608 keys localized.
* **FCM Notification Wiring**: Foreground listeners connected in `HomeScreen` for matched wave payloads.
* **Rate Limiting**: Added `checkRateLimit` (Firestore TTL & Upstash Redis) to 13 key Cloud Functions.
* **Firestore Security Rules**: Hardened Rules (6 findings resolved including `active_run_crosses` and `proximity/{userId}` write whitelists).

## Open Blockers

| ID | Issue | Impact |
|----|-------|--------|
| BLOCKER-REV | Apple Developer Program membership pending approval ($99 fee and registration processing) | Gating TestFlight and physical iOS provisioning |
| BLOCKER-MAP | Planet map tiles (`planet.pmtiles`) upload and CDN setup by Martin | Protomaps basemap asset check |

## Known Tech Debt

| ID | Debt | Status |
|----|------|--------|
| D-29 | Map tile device test deferred | Open |
| D-33 | `migrateMatchTypes` legacy function pending removal from production Cloud Functions export | Open |
| D-34 | App Check debug token setup via `--dart-define` pending cleanup and configuration | Open |

## Next Action

Awaiting Apple Developer Account approval to resolve the physical iOS device provisioning blockers and run the first TestFlight beta deployment.
