# Roadmap: Tremble

## Overview

Tremble is a proximity-based dating app built on Flutter + Firebase. The core mechanic: BLE detects when two users are physically near each other, either can send a wave, a mutual wave creates a match, and both users have 30 minutes to find each other physically. **There is no in-app chat — ever.** Phases 1–7 have shipped the full foundation plus wave mechanic and push notifications. Phases 8–10 complete the product: monetization, security hardening, and store launch.

## Milestones

- ✅ **v1.0 Foundation** — Phases 1–5 (shipped 2026-04-08) — [archive](milestones/v1.1-ROADMAP.md)
- ✅ **v1.1 Core Product** — Phases 6–7 (brand alignment + wave mechanic + push notifications, shipped 2026-04-09) — [archive](milestones/v1.1-ROADMAP.md)
- [ ] **v1.2 Monetization & Security** — Phases 8–9 (paywall + hardening)
- [ ] **v1.3 Launch** — Phase 10 (store submission + landing page)

## Phases

<details>
<summary>✅ v1.0 Foundation (Phases 1–5) — SHIPPED 2026-04-08</summary>

### Phase 1: Foundation
**Goal**: Flutter 3 + Riverpod 2 + GoRouter architecture is live with Firebase Auth, multi-environment config, and CI/CD
**Requirements**: FOUND-01, FOUND-02, FOUND-03, FOUND-04, FOUND-05, FOUND-06
**Plans**: Complete

### Phase 2: Core UX
**Goal**: Users can create profiles, see the radar dashboard, and the matching UI is in place
**Requirements**: PROF-01, PROF-02, PROF-03, BLE-05
**Plans**: Complete

### Phase 3: Proximity Engine
**Goal**: BLE scanning detects nearby Tremble users in the background and logs proximity events to Firestore
**Requirements**: BLE-01, BLE-02, BLE-03, BLE-04
**Plans**: Complete

### Phase 4: Infrastructure
**Goal**: Cloud infrastructure is production-ready — R2 media storage, 21 Cloud Functions, Redis rate limiting, and multi-env separation enforced
**Requirements**: INFRA-01, INFRA-02, INFRA-03, INFRA-04
**Plans**: Complete

### Phase 5: Auth & Routing
**Goal**: Auth redirect loop is resolved, email verification UI is live, and Maps API key injection is wired
**Requirements**: FOUND-04 (routing fix), INFRA-04 (Maps key mechanism), PROF-02 (email verification banner)
**Plans**: Complete

</details>

<details>
<summary>✅ v1.1 Core Product (Phases 6–7) — SHIPPED 2026-04-09</summary>

### Phase 6: Brand Alignment ✅
**Goal**: The app looks and feels like Tremble — correct colors, fonts, copy, and Maps API key wired
**Depends on**: Phase 5
**Requirements**: BRAND-01, BRAND-02, BRAND-03, BRAND-04, BRAND-05
**Plans**: 3/3 complete

### Phase 7: Wave Mechanic + Push Notifications ✅
**Goal**: Users can send waves, mutual waves create matches, match reveal works, and push notifications fire correctly
**Depends on**: Phase 6
**Requirements**: WAVE-01–06, PUSH-01–02, PUSH-04–05
**Note**: PUSH-03 closed N/A (chat mechanic removed per Rule #3). Tremble has no in-app chat.
**Plans**: Complete (Interaction System v2.1 + iOS Notification Service Extension)

</details>

---

### v1.2 Monetization & Security

**Milestone Goal:** Revenue layer is live and the app meets production security and compliance requirements.

#### Phase 8: Paywall / Tremble Pro
**Goal**: The freemium wave limit and Tremble Pro subscription are live and purchasable on both platforms
**Depends on**: Phase 7
**Requirements**: WAVE-07, PAY-01, PAY-02, PAY-03, PAY-04, PAY-05, PAY-06
**Success Criteria** (what must be TRUE):
  1. Free tier users are blocked from sending a 6th wave in a calendar month with a clear paywall prompt
  2. Paywall appears after the first proximity event — not at onboarding or app open
  3. User can subscribe to Tremble Pro (~€9.99/month) via App Store (StoreKit) and Play Store (Play Billing) through RevenueCat
  4. Pro subscription state is synced to Firestore and respected by wave-limit enforcement
  5. When a Pro subscription lapses, the user gracefully reverts to free tier limits without data loss or crash
**Note**: Both founders must be present for Phase 8 kickoff.
**Plans**: TBD

#### Phase 9: Security Hardening & GDPR
**Goal**: The app is production-security-ready — App Check enforced, Firestore rules hardened, and GDPR deletion pipeline validated end-to-end
**Depends on**: Phase 8
**Requirements**: SEC-01, SEC-02, SEC-03, SEC-04, SEC-05, SEC-06
**Success Criteria** (what must be TRUE):
  1. Firebase App Check is enforced in all Cloud Functions — unauthenticated requests are rejected (SEC-001 blocker resolved)
  2. Firestore Security Rules are deny-by-default; each document type permits only its owner to read/write
  3. GDPR deletion pipeline runs end-to-end: deleting a user cascades across Firestore, Cloudflare R2, and Firebase Auth within 72 hours
  4. PII fields (email, date of birth) are encrypted at rest and verified
  5. Proximity data (RSSI/BLE) is confirmed to exist only in RAM — no persistence to disk or Firestore verified by audit
**Sub-tasks complete**: 10-01 GDPR deletion pipeline fix — deployed to tremble-dev 2026-04-09
**Plans**: 10-01-PLAN.md ✅ (tremble-dev), prod deploy pending

---

### v1.3 Launch

**Milestone Goal:** Tremble is live on both stores with a functional marketing landing page.

#### Phase 10: Launch Polish & Store Deploy
**Goal**: Tremble is submitted to and approved by the App Store and Play Store, with a live marketing landing page at trembledating.com
**Depends on**: Phase 9
**Requirements**: LAUNCH-01, LAUNCH-02, LAUNCH-03, LAUNCH-04, LAUNCH-05, LAUNCH-06, LAUNCH-07
**Success Criteria** (what must be TRUE):
  1. App Store Connect listing is complete — metadata, keywords, screenshots, and preview video uploaded
  2. Google Play Console listing is complete — same assets as iOS adapted to Play requirements
  3. TestFlight internal beta is live and at least one external beta tester has installed the app
  4. Google Play Internal Testing track has an approved build
  5. trembledating.com shows a live landing page with hero section, proximity demo animation, and working waitlist or store redirect
  6. App Store Review submission has been accepted (or is in review)
  7. Play Store Review submission has been accepted (or is in review)
**Plans**:
  - [x] TASK-10-01: Identity Injection (Icons & Splash)
  - [x] TASK-10-02: Ghost State UX (System Nominal)
  - [ ] TASK-10-03: Framing & Metadata
  - [ ] TASK-10-04: TestFlight / Internal Beta
  - [ ] TASK-10-05: Landing Page (trembledating.com)

**UI hint**: yes

---

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v1.0 | - | ✅ Complete | 2026-04-08 |
| 2. Core UX | v1.0 | - | ✅ Complete | 2026-04-08 |
| 3. Proximity Engine | v1.0 | - | ✅ Complete | 2026-04-08 |
| 4. Infrastructure | v1.0 | - | ✅ Complete | 2026-04-08 |
| 5. Auth & Routing | v1.0 | - | ✅ Complete | 2026-04-08 |
| 6. Brand Alignment | v1.1 | 3/3 | ✅ Complete | 2026-04-09 |
| 7. Wave Mechanic + Push Notifications | v1.1 | - | ✅ Complete | 2026-04-09 |
| 8. Paywall / Tremble Pro | v1.2 | 0/TBD | ⏳ Not started | - |
| 9. Security Hardening & GDPR | v1.2 | 1/TBD | 🟡 In progress | - |
| 10. Launch Polish & Store Deploy | v1.3 | 2/5 | 🟡 In progress | - |
| 11. SECURITY-01: Technical Security Audit & Hardening | v1.2 | 0/TBD | ⏳ Not started | - |

---

#### Phase 11: SECURITY-01: Technical Security Audit & Hardening
**Goal**: Cloud Functions have App Check enforced, Firestore rules are deny-by-default with validated write schemas, secrets are confirmed env-only, and the Flutter client uses the correct App Check providers per flavor
**Depends on**: Phase 9
**Requirements**: SECURITY-01 through SECURITY-04
**Success Criteria** (what must be TRUE):
  1. Every `onCall` Cloud Function has `{ enforceAppCheck: true }` — unauthenticated requests return UNAUTHENTICATED
  2. No `.passthrough()` in any Zod schema; all inputs have strict type and length constraints
  3. PII (uid, email) masked or removed from all `console.log` statements in Cloud Functions
  4. `proximity_events` Firestore write rule validates `from`, `toDeviceId`, `rssi` (int), `timestamp`, and `ttl` presence and types
  5. `idempotencyKeys` and `rateLimits` collections are `allow read, write: if false`
  6. Global deny rule `match /{document=**} { allow read, write: if false; }` is the last rule in `firestore.rules`
  7. `functions/.env.example` contains no real secrets; `redis.ts` and `email.functions.ts` read exclusively from `process.env`
  8. `main.dart` activates `AndroidDebugProvider`/`AppleDebugProvider` on dev flavor; real providers on prod
**Plans**: TBD

---

*Roadmap created: 2026-04-08*
*Updated: 2026-04-18 — v1.1 archived. Both completed milestones collapsed into details blocks.*
*Brownfield project — Phases 1–5 inferred from codebase, session history, and context.md*
