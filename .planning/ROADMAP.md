# Roadmap: Tremble

## Overview

Tremble is a proximity-based dating app built on Flutter + Firebase. The core mechanic: BLE detects when two users are physically near each other, either can send a wave, a mutual wave creates a match, and a match unlocks chat. Phases 1–5 have shipped the full foundation — architecture, BLE engine, profile flow, cloud infrastructure, and auth routing. Phases 6–10 complete the product: brand alignment, wave mechanic, messaging, monetization, security hardening, and store launch.

## Milestones

- [x] **v1.0 Foundation** - Phases 1–5 (shipped 2026-04-08)
- [ ] **v1.1 Core Product** - Phases 6–8 (brand + wave + messaging)
- [ ] **v1.2 Monetization & Security** - Phases 9–10 (paywall + hardening)
- [ ] **v1.3 Launch** - Phase 11 (store submission + landing page)

## Phases

<details>
<summary>✅ v1.0 Foundation (Phases 1–5) — SHIPPED 2026-04-08</summary>

### Phase 1: Foundation
**Goal**: Flutter 3 + Riverpod 2 + GoRouter architecture is live with Firebase Auth, multi-environment config, and CI/CD
**Requirements**: FOUND-01, FOUND-02, FOUND-03, FOUND-04, FOUND-05, FOUND-06
**Success Criteria** (what must be TRUE):
  1. App runs on dev flavor without un-flavored builds
  2. Firebase Auth (email + Google Sign-In) works in dev environment
  3. Auth routing sends new users to onboarding, returning users to dashboard
  4. GlassCard dark-first UI renders without overflow errors
  5. GitHub Actions CI passes on every push
**Plans**: Complete

### Phase 2: Core UX
**Goal**: Users can create profiles, see the radar dashboard, and the matching UI is in place
**Requirements**: PROF-01, PROF-02, PROF-03, BLE-05
**Success Criteria** (what must be TRUE):
  1. User can complete the full registration flow (email → name → age → gender → interests → photos)
  2. Radar dashboard renders with pulse animation at ≥60 FPS
  3. Profile bio (max 160 chars) and interests list are saved and displayed
  4. Email verification banner shows for unverified users
**Plans**: Complete

### Phase 3: Proximity Engine
**Goal**: BLE scanning detects nearby Tremble users in the background and logs proximity events to Firestore
**Requirements**: BLE-01, BLE-02, BLE-03, BLE-04
**Success Criteria** (what must be TRUE):
  1. BLE scanning runs in background on both iOS and Android with foreground notification
  2. Session UUID (not user ID) is broadcast — privacy by architecture enforced
  3. RSSI → distance mapped with exponential smoothing; false triggers filtered
  4. Proximity events are written to Firestore when threshold is crossed
**Plans**: Complete

### Phase 4: Infrastructure
**Goal**: Cloud infrastructure is production-ready — R2 media storage, 21 Cloud Functions, Redis rate limiting, and multi-env separation enforced
**Requirements**: INFRA-01, INFRA-02, INFRA-03, INFRA-04
**Success Criteria** (what must be TRUE):
  1. Cloudflare R2 serves media via media.trembledating.com in both environments
  2. 21 Cloud Functions deployed to europe-west1 with no cross-environment contamination
  3. Upstash Redis rate limiting active on all write endpoints
  4. Google Maps API key injection mechanism works on both platforms
**Plans**: Complete

### Phase 5: Auth & Routing
**Goal**: Auth redirect loop is resolved, email verification UI is live, and Maps API key injection is wired
**Requirements**: FOUND-04 (routing fix), INFRA-04 (Maps key mechanism), PROF-02 (email verification banner)
**Success Criteria** (what must be TRUE):
  1. New users land on onboarding after login — no redirect loop
  2. Returning users land on dashboard without intermediate screens
  3. Email verification banner appears on registration for unverified email users
  4. Maps API key placeholder exists in both Android local.properties and iOS Debug.xcconfig
**Plans**: Complete

</details>

---

### v1.1 Core Product

**Milestone Goal:** The app is visually brand-aligned and the full wave → match → chat loop works end-to-end.

#### Phase 6: Brand Alignment
**Goal**: The app looks and feels like Tremble — correct colors, fonts, copy, and Maps API key wired
**Depends on**: Phase 5
**Requirements**: BRAND-01, BRAND-02, BRAND-03, BRAND-04, BRAND-05
**Success Criteria** (what must be TRUE):
  1. No teal (#00D9A6) exists anywhere in the UI — Tremble Rose (#F4436C) is the primary CTA color throughout
  2. All four fonts render correctly: Playfair Display 900 on display/H1, Lora on body, Instrument Sans on UI elements, JetBrains Mono on telemetry readouts
  3. Onboarding and registration copy is updated to brand voice — short, direct, confident
  4. Real Google Maps API key is wired on both platforms (Android + iOS)
  5. flutter analyze runs clean — zero new warnings
**Plans**: 3 plans
Plans:
- [x] 06-01-PLAN.md — Color token audit + JetBrains Mono on radar telemetry text (BRAND-01, BRAND-02)
- [x] 06-02-PLAN.md — Onboarding copy rewrite + greeting_sent → wave_sent rename in all 8 languages (BRAND-03, BRAND-04)
- [ ] 06-03-PLAN.md — Maps API key wired to iOS Release.xcconfig + human verification checkpoint (BRAND-05)
**UI hint**: yes

#### Phase 7: Wave Mechanic
**Goal**: Users can send waves, mutual waves create matches, and the match reveal + profile unlock work end-to-end
**Depends on**: Phase 6
**Requirements**: WAVE-01, WAVE-02, WAVE-03, WAVE-04, WAVE-05, WAVE-06
**Success Criteria** (what must be TRUE):
  1. User can send a wave from the dashboard with one tap — no confirmation dialog
  2. One-sided waves are never visible to the recipient until mutual interest is confirmed
  3. A mutual wave creates a match in Firestore and triggers the match reveal screen with brand animation
  4. After match, both users can see each other's full profile (name, photo, bio, interests)
  5. Wave state is persisted correctly — no duplicate waves, no race conditions
**Plans**: TBD
**UI hint**: yes

#### Phase 8: Messaging & Push Notifications
**Goal**: Matched users can chat in real time and the three approved notification types fire at the right moments
**Depends on**: Phase 7
**Requirements**: MSG-01, MSG-02, MSG-03, MSG-04, PUSH-01, PUSH-02, PUSH-03, PUSH-04, PUSH-05
**Success Criteria** (what must be TRUE):
  1. User can send and receive messages in real time after a mutual wave match
  2. Read receipts are visible to both parties
  3. Chat persists in Firestore with TTL policy applied; unmatching deletes chat and match record
  4. Proximity event notification fires with "Someone nearby." — no names, no photos, no location data
  5. Mutual wave notification fires and the profile unlock is triggered
  6. 24h inactivity reminder fires when a match exists but no chat has started
  7. No other notification types exist in the codebase — marketing and gamification notifications are absent
**Plans**: TBD
**UI hint**: yes

---

### v1.2 Monetization & Security

**Milestone Goal:** Revenue layer is live and the app meets production security and compliance requirements.

#### Phase 9: Paywall / Tremble Pro
**Goal**: The freemium wave limit and Tremble Pro subscription are live and purchasable on both platforms
**Depends on**: Phase 8
**Requirements**: WAVE-07, PAY-01, PAY-02, PAY-03, PAY-04, PAY-05, PAY-06
**Success Criteria** (what must be TRUE):
  1. Free tier users are blocked from sending a 6th wave in a calendar month with a clear paywall prompt
  2. Paywall appears after the first proximity event — not at onboarding or app open
  3. User can subscribe to Tremble Pro (~€9.99/month) via App Store (StoreKit) and Play Store (Play Billing) through RevenueCat
  4. Pro subscription state is synced to Firestore and respected by wave-limit enforcement
  5. When a Pro subscription lapses, the user gracefully reverts to free tier limits without data loss or crash
**Plans**: TBD

#### Phase 10: Security Hardening & GDPR
**Goal**: The app is production-security-ready — App Check enforced, Firestore rules hardened, and GDPR deletion pipeline validated end-to-end
**Depends on**: Phase 9
**Requirements**: SEC-01, SEC-02, SEC-03, SEC-04, SEC-05, SEC-06
**Success Criteria** (what must be TRUE):
  1. Firebase App Check is enforced in all 21 Cloud Functions — unauthenticated requests are rejected (SEC-001 blocker resolved)
  2. Firestore Security Rules are deny-by-default; each document type permits only its owner to read/write
  3. GDPR deletion pipeline runs end-to-end: deleting a user cascades across Firestore, Cloudflare R2, and Firebase Auth within 72 hours
  4. PII fields (email, date of birth) are encrypted at rest and verified
  5. Proximity data (RSSI/BLE) is confirmed to exist only in RAM — no persistence to disk or Firestore verified by audit
**Plans**: TBD

---

### v1.3 Launch

**Milestone Goal:** Tremble is live on both stores with a functional marketing landing page.

#### Phase 11: Launch Polish & Store Deploy
**Goal**: Tremble is submitted to and approved by the App Store and Play Store, with a live marketing landing page at trembledating.com
**Depends on**: Phase 10
**Requirements**: LAUNCH-01, LAUNCH-02, LAUNCH-03, LAUNCH-04, LAUNCH-05, LAUNCH-06, LAUNCH-07
**Success Criteria** (what must be TRUE):
  1. App Store Connect listing is complete — metadata, keywords, screenshots, and preview video uploaded
  2. Google Play Console listing is complete — same assets as iOS adapted to Play requirements
  3. TestFlight internal beta is live and at least one external beta tester has installed the app
  4. Google Play Internal Testing track has an approved build
  5. trembledating.com shows a live landing page with hero section, proximity demo animation, and working waitlist or store redirect
  6. App Store Review submission has been accepted (or is in review)
  7. Play Store Review submission has been accepted (or is in review)
**Plans**: TBD
**UI hint**: yes

---

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v1.0 | - | Complete | 2026-04-08 |
| 2. Core UX | v1.0 | - | Complete | 2026-04-08 |
| 3. Proximity Engine | v1.0 | - | Complete | 2026-04-08 |
| 4. Infrastructure | v1.0 | - | Complete | 2026-04-08 |
| 5. Auth & Routing | v1.0 | - | Complete | 2026-04-08 |
| 6. Brand Alignment | v1.1 | 0/3 | Not started | - |
| 7. Messaging & Push Notifications | v1.1 | 0/TBD | Not started | - |
| 8. Paywall / Tremble Pro | v1.2 | 0/TBD | Not started | - |
| 9. Security Hardening & GDPR | v1.2 | 0/TBD | Not started | - |
| 10. Launch Polish & Store Deploy | v1.3 | 0/TBD | Not started | - |

---

## Coverage

**v1 requirements mapped:** 37/37

| Requirement | Phase | Status |
|-------------|-------|--------|
| BRAND-01 | Phase 6 | Pending |
| BRAND-02 | Phase 6 | Pending |
| BRAND-03 | Phase 6 | Pending |
| BRAND-04 | Phase 6 | Pending |
| BRAND-05 | Phase 6 | Pending |
| WAVE-01 | Phase 6 | Pending |
| WAVE-02 | Phase 6 | Pending |
| WAVE-03 | Phase 6 | Pending |
| WAVE-04 | Phase 6 | Pending |
| WAVE-05 | Phase 6 | Pending |
| WAVE-06 | Phase 6 | Pending |
| WAVE-07 | Phase 8 | Pending |
| MSG-01 | Phase 7 | Pending |
| MSG-02 | Phase 7 | Pending |
| MSG-03 | Phase 7 | Pending |
| MSG-04 | Phase 7 | Pending |
| PUSH-01 | Phase 7 | Pending |
| PUSH-02 | Phase 7 | Pending |
| PUSH-03 | Phase 7 | Pending |
| PUSH-04 | Phase 7 | Pending |
| PUSH-05 | Phase 7 | Pending |
| PAY-01 | Phase 8 | Pending |
| PAY-02 | Phase 8 | Pending |
| PAY-03 | Phase 8 | Pending |
| PAY-04 | Phase 8 | Pending |
| PAY-05 | Phase 8 | Pending |
| PAY-06 | Phase 8 | Pending |
| SEC-01 | Phase 9 | Pending |
| SEC-02 | Phase 9 | Pending |
| SEC-03 | Phase 9 | Pending |
| SEC-04 | Phase 9 | Pending |
| SEC-05 | Phase 9 | Pending |
| SEC-06 | Phase 9 | Pending |
| LAUNCH-01 | Phase 10 | Pending |
| LAUNCH-02 | Phase 10 | Pending |
| LAUNCH-03 | Phase 10 | Pending |
| LAUNCH-04 | Phase 10 | Pending |
| LAUNCH-05 | Phase 10 | Pending |
| LAUNCH-06 | Phase 10 | Pending |
| LAUNCH-07 | Phase 10 | Pending |

---

*Roadmap created: 2026-04-08*
*Brownfield project — Phases 1–5 inferred from codebase, session history, and context.md*
