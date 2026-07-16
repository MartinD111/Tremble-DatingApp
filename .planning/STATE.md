---
gsd_state_version: 1.0
milestone: v1.3 Launch
milestone_name: Store Submission
status: in_progress
last_updated: "2026-07-16T09:00:00.000+02:00"
progress:
  total_phases: 11
  completed_phases: 10
  total_plans: 17
  completed_plans: 17
---

# Project State: Tremble

## Current Focus

Prepare signed production build `1.0.0+22` for App Store submission after the
remaining external credential, device, legal, and store-console gates pass.

## Verified Release State

- Apple Developer membership and production signing are active.
- Production bundle ID is `tremble.dating.app`; Firebase production project is
  `am---dating-app`.
- Build 22 archives, exports as an App Store IPA, carries the production APNs
  entitlement, and passes App Store validation.
- RevenueCat purchase/restore/customer-info paths are real SDK integrations;
  products and offerings still need store-dashboard configuration and sandbox
  verification.
- Privacy Policy, Terms, erasure, and support/bug pages are live. Slovenian ToS
  and the DSA contact page remain publication gaps.
- Firestore token-write recovery is active in production and protected by a
  focused emulator regression suite.

## Phase Progress

| Phase | Name | Status |
|-------|------|--------|
| 1–7 | Foundation through Wave Mechanic | ✅ Complete |
| 8 | Paywall / Tremble Pro | ✅ Application code complete; store config pending |
| 9 | Security Hardening & GDPR | ✅ Complete |
| 10 | Launch Polish & Store Deploy | 🟡 In progress |
| 11 | Technical Security Audit & Hardening | ✅ Complete |

## Open Release Gates

| Gate | Required outcome |
|------|------------------|
| APNs / device | Inspect the Firebase-stored APNs credential and pass build-22 foreground/background/killed plus explicit Wave Back tests on a physical iPhone |
| Legal | Reconcile the DPIA; correct Weekend Getaway timezone behavior and ToS; publish `/sl/tos` and `/dsa-contact` |
| App Store Connect | Complete metadata, privacy labels, IAP products, RevenueCat offerings, reviewer account, screenshots, age rating/EULA, and review notes |
| Play Console | Submit background-location and foreground-service declarations, Data Safety form, screenshots, and demo video |

## Next Action

Use the clean `main` baseline for a dedicated APNs credential/device-verification
lane, then execute the remaining legal and store-console gates without mixing
them into application-source PRs.
