# Requirements: Tremble

**Defined:** 2026-04-08
**Core Value:** The proximity event — the moment two Tremble users are physically near each other — must work reliably, silently, and privately. If BLE detection fails, nothing else matters.

---

## Already Shipped (Validated in Codebase)

These exist and are verified. They do not need re-implementation but some need polish/fixes.

### Foundation
- ✓ **FOUND-01**: Flutter 3 + Riverpod 2 + GoRouter architecture established
- ✓ **FOUND-02**: Multi-environment (tremble-dev / am---dating-app prod) with flavor system
- ✓ **FOUND-03**: Firebase Auth with email + Google Sign-In
- ✓ **FOUND-04**: Auth routing: login → onboarding for new users, login → dashboard for returning users
- ✓ **FOUND-05**: Glassmorphic dark-first UI with GlassCard component
- ✓ **FOUND-06**: GitHub Actions CI/CD with Base64 secret injection

### Proximity Engine
- ✓ **BLE-01**: flutter_blue_plus BLE scanning with Tremble session UUID
- ✓ **BLE-02**: Background service with foreground notification (Android + iOS)
- ✓ **BLE-03**: RSSI → distance mapping with exponential smoothing
- ✓ **BLE-04**: Proximity events written to Firestore (threshold-gated)
- ✓ **BLE-05**: Radar dashboard with pulse animation

### Profile & Onboarding
- ✓ **PROF-01**: Registration flow: email/Google → name → age → gender → interests → photos
- ✓ **PROF-02**: Email verification banner shown to unverified email users
- ✓ **PROF-03**: Profile bio (max 160 chars), interests list

### Infrastructure
- ✓ **INFRA-01**: Cloudflare R2 media storage with CDN (media.trembledating.com)
- ✓ **INFRA-02**: 21 deployed Cloud Functions in europe-west1
- ✓ **INFRA-03**: Upstash Redis for rate limiting
- ✓ **INFRA-04**: Google Maps API key injection mechanism (Android + iOS)

---

## v1 Requirements (Remaining Work — In Roadmap)

### Brand Alignment

- [ ] **BRAND-01**: Color token swap — all teal (#00D9A6) replaced with Tremble Rose (#F4436C). Signal Yellow (#F5C842), Deep Graphite (#1A1A18), Warm Cream (#FAFAF7), Confirm Green (#2D9B6F) applied correctly per context
- [ ] **BRAND-02**: Font system installed in Flutter — Playfair Display 900 (display/H1), Lora 400/500 (body text), Instrument Sans 500–700 (UI/nav/buttons), JetBrains Mono (telemetry/radar readouts)
- [ ] **BRAND-03**: Onboarding copy updated to brand voice — short, direct, confident. No filler phrases.
- [ ] **BRAND-04**: Registration CTA copy updated to brand voice
- [ ] **BRAND-05**: Google Maps API key filled in (Android local.properties + iOS Debug.xcconfig)

### Wave & Match Mechanic

- [ ] **WAVE-01**: User can send a wave from dashboard when proximity event is recorded
- [ ] **WAVE-02**: Wave is one-tap action — no confirmation dialogs
- [ ] **WAVE-03**: Unidirectional interest is never shown to the other party (hidden until mutual)
- [ ] **WAVE-04**: Mutual wave → match is created in Firestore
- [ ] **WAVE-05**: Profile unlocks after mutual wave — name, photo, bio, interests visible
- [ ] **WAVE-06**: Match reveal screen with brand-aligned animation (not generic Material dialog)
- [ ] **WAVE-07**: Freemium limit: 5 outgoing waves/month on free tier

### Push Notifications

- [ ] **PUSH-01**: Proximity event notification — "Someone nearby." — no names, no photos, no location
- [ ] **PUSH-02**: Mutual wave notification — profile unlock triggered
- [ ] **PUSH-03**: 24h inactivity reminder if match exists but no chat started
- [ ] **PUSH-04**: No other notification types — no marketing, no gamification, no "see who liked you"
- [ ] **PUSH-05**: FCM configured for Android, APNs for iOS

### Messaging

- [ ] **MSG-01**: Real-time chat available after mutual wave match
- [ ] **MSG-02**: Message delivery confirmed (read receipts)
- [ ] **MSG-03**: Chat persists in Firestore with TTL policy
- [ ] **MSG-04**: User can unmatch (deletes chat + match record)

### Paywall / Tremble Pro

- [ ] **PAY-01**: Free tier allows 5 outgoing waves/month
- [ ] **PAY-02**: Paywall appears after first proximity event (value proven before ask)
- [ ] **PAY-03**: Tremble Pro (~€9.99/month) unlocks: unlimited waves + priority match visibility
- [ ] **PAY-04**: RevenueCat integration for cross-platform subscription management
- [ ] **PAY-05**: Subscription state synced to Firestore user record
- [ ] **PAY-06**: Graceful downgrade when Pro subscription lapses

### Security & Compliance

- [ ] **SEC-01**: Firebase App Check enforced in all Cloud Functions (currently configured but not enforced)
- [ ] **SEC-02**: Firestore Security Rules audit — deny-by-default, user-specific read/write per document
- [ ] **SEC-03**: GDPR deletion pipeline validated end-to-end (cascading delete: Firestore + R2 + Auth)
- [ ] **SEC-04**: 72h deletion SLA documented and tested
- [ ] **SEC-05**: PII encryption at rest verified (email, date of birth)
- [ ] **SEC-06**: Proximity data confirmed never written to persistent storage (RAM-only verified)

### Launch

- [ ] **LAUNCH-01**: App Store Connect listing — metadata, keywords, screenshots, preview video
- [ ] **LAUNCH-02**: Google Play Console listing — same as above
- [ ] **LAUNCH-03**: TestFlight internal beta distribution
- [ ] **LAUNCH-04**: Google Play Internal Testing track
- [ ] **LAUNCH-05**: trembledating.com landing page — hero + proximity demo animation + waitlist/store redirect
- [ ] **LAUNCH-06**: App Store Review submission (iOS)
- [ ] **LAUNCH-07**: Play Store Review submission (Android)

---

## v2 Requirements (Post-Launch)

### B2B Events API
- **B2B-01**: Tremble Events API for conference/festival organizers
- **B2B-02**: Geo-fenced proximity zones for events
- **B2B-03**: Whitelabel integration for partners with existing Tremble user base

### Extended Profile
- **PROF-04**: Second and third profile photos
- **PROF-05**: Verified identity badge (ID verification)

### Platform Analytics
- **ANAL-01**: Proximity event heatmaps (anonymized, no PII) for urban planning/retail B2B data layer
- **ANAL-02**: Match rate and real-world meeting conversion tracking (opt-in)

### Community Features
- **COMM-01**: Niche vertical apps (hikers, musicians, digital nomads) using same BLE engine
- **COMM-02**: Whitelabel licensing of proximity engine

---

## Out of Scope (v1)

| Feature | Reason |
|---------|--------|
| Swipe mechanic | Explicitly anti-Tinder by design — not a feature regression, a product decision |
| Video or audio profiles | Profile must be fast to read; complexity vs signal not justified for v1 |
| In-app social feed | Coordination tool, not engagement platform |
| Web app | BLE requires native; web cannot do background proximity scanning |
| Matching algorithm / ML scoring | Proximity is the algorithm; preference-based ranking deferred |
| "See who liked you" | Violates unidirectional hidden interest design principle |
| Marketing push notifications | Explicitly excluded in strategic doc |
| Audio/video calling | Post-match IRL meeting is the goal; in-app calling reduces motivation to meet |

---

## Traceability

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
| PUSH-01 | Phase 7 | Pending |
| PUSH-02 | Phase 7 | Pending |
| PUSH-03 | Phase 7 | Pending |
| PUSH-04 | Phase 7 | Pending |
| PUSH-05 | Phase 7 | Pending |
| MSG-01 | Phase 7 | Pending |
| MSG-02 | Phase 7 | Pending |
| MSG-03 | Phase 7 | Pending |
| MSG-04 | Phase 7 | Pending |
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

**Coverage:**
- v1 requirements (remaining): 37 total
- Mapped to phases: 37
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-08*
*Last updated: 2026-04-08 after initial GSD initialization — brownfield project*
