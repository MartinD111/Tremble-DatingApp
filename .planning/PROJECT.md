# Tremble — Proximity Dating App

## What This Is

Tremble is a Flutter mobile app (iOS + Android) for proximity-based dating. It uses Bluetooth Low Energy to passively detect when two users are physically near each other, then lets each send a "wave." A mutual wave creates a match — both users have 30 minutes to find each other in the real world. **There is no in-app chat, ever.** The match reveal screen is the final in-app step. The app runs in the background — users live their lives, Tremble works quietly. It is the anti-Tinder: zero swiping, zero scrolling, one tap to act.

## Core Value

The proximity event — the moment two Tremble users are physically near each other — must work reliably, silently, and privately. If BLE detection fails, nothing else matters.

## Requirements

### Validated

- ✓ Flutter 3 + Riverpod 2 + GoRouter architecture — Phase 1
- ✓ Firebase Auth (email + Google Sign-In) — Phase 1
- ✓ Multi-environment setup (tremble-dev / am---dating-app prod) — Phase 1
- ✓ Dark-first UI with glassmorphic GlassCard component — Phase 1
- ✓ BLE scanning via flutter_blue_plus (CoreBluetooth/BluetoothLE) — Phase 3
- ✓ Background service with foreground notification (iOS/Android) — Phase 3
- ✓ Profile creation flow (name, age, gender, interests, photos) — Phase 2
- ✓ Radar dashboard screen with pulse animation — Phase 2
- ✓ Firestore proximity event logging — Phase 3
- ✓ CI/CD via GitHub Actions (Base64 secret injection, flutter stable) — Phase 5
- ✓ Cloudflare R2 media storage (tremble-avatars / tremble-avatars-dev) — Phase 5
- ✓ 21 deployed Cloud Functions (europe-west1) — Phase 5
- ✓ Auth redirect loop fixed (login → onboarding routing) — Phase 5
- ✓ Google Maps API key injection mechanism (Android + iOS) — Phase 5
- ✓ Email verification banner in registration flow — Phase 5
- ✓ Brand color tokens — Tremble Rose (#F4436C), Signal Yellow, Deep Graphite, Warm Cream — Phase 6 (v1.1)
- ✓ Font system — Playfair Display 900, Lora, Instrument Sans, JetBrains Mono — Phase 6 (v1.1)
- ✓ Brand-voice onboarding copy in 8 languages — Phase 6 (v1.1)
- ✓ Maps API key via CI secret injection on all platforms — Phase 6 (v1.1)
- ✓ Wave mechanic — one-tap send, unidirectional hidden, server-side mutual detection — Phase 7 (v1.1)
- ✓ Match created in Firestore on mutual wave — Phase 7 (v1.1)
- ✓ Profile unlock after mutual wave (name, photo, bio) — Phase 7 (v1.1)
- ✓ Match reveal screen with brand-aligned glassmorphic animation — Phase 7 (v1.1)
- ✓ 30-minute match session constraint — Phase 7 (v1.1)
- ✓ Push notifications: CROSSING_PATHS (anonymous), INCOMING_WAVE, MUTUAL_WAVE — Phase 7 (v1.1)
- ✓ WAVE_BACK_ACTION — send wave-back from notification without opening app — Phase 7 (v1.1)
- ✓ FCM (Android) + APNs (iOS) configured — Phase 7 (v1.1)

### Active

#### Paywall / Tremble Pro (Phase 8)
- [ ] **WAVE-07**: Freemium limit: 5 outgoing waves/month on free tier
- [ ] **PAY-01**: Free tier allows 5 outgoing waves/month
- [ ] **PAY-02**: Paywall appears after first proximity event (value proven before ask)
- [ ] **PAY-03**: Tremble Pro (~€9.99/month): unlimited waves + priority match visibility
- [ ] **PAY-04**: RevenueCat integration for cross-platform subscription management
- [ ] **PAY-05**: Subscription state synced to Firestore user record
- [ ] **PAY-06**: Graceful downgrade when Pro subscription lapses

#### Security & Compliance (Phase 9)
- [ ] **SEC-01**: Firebase App Check enforced in all Cloud Functions (currently configured but not enforced)
- [ ] **SEC-02**: Firestore Security Rules audit — deny-by-default, user-specific read/write per document
- [ ] **SEC-03**: GDPR deletion pipeline validated end-to-end (cascading delete: Firestore + R2 + Auth)
- [ ] **SEC-04**: 72h deletion SLA documented and tested
- [ ] **SEC-05**: PII encryption at rest verified (email, date of birth)
- [ ] **SEC-06**: Proximity data confirmed never written to persistent storage (RAM-only verified)

#### Launch (Phase 10)
- [ ] **LAUNCH-01**: App Store Connect listing — metadata, keywords, screenshots, preview video
- [ ] **LAUNCH-02**: Google Play Console listing
- [ ] **LAUNCH-03**: TestFlight internal beta distribution
- [ ] **LAUNCH-04**: Google Play Internal Testing track
- [ ] **LAUNCH-05**: trembledating.com landing page — hero + proximity demo animation + waitlist/store redirect
- [ ] **LAUNCH-06**: App Store Review submission (iOS)
- [ ] **LAUNCH-07**: Play Store Review submission (Android)

### Out of Scope

- **In-app chat** — explicitly removed. Tremble has no chat. After match, users have 30 min to meet IRL. Rule #3.
- **Swipe mechanic** — explicitly anti-Tinder by design; not a feature regression, a product decision
- **Video profiles or audio notes** — complexity vs signal ratio; profile must be fast to read
- **In-app social feed** — coordination tool, not engagement platform
- **Web app** — BLE requires native; web cannot do background proximity scanning
- **Matching algorithm / ML scoring** — proximity is the algorithm; preference-based ranking deferred post-launch
- **"See who liked you"** — violates unidirectional hidden interest design principle
- **Marketing push notifications** — explicitly excluded; PUSH-04 enforces this
- **Audio/video calling** — post-match IRL meeting is the goal; in-app calling reduces motivation to meet
- **PUSH-03 (24h inactivity reminder)** — closed N/A; references "no chat started" which is always true

## Context

### Current State (after v1.1)

- **Shipped milestones:** v1.0 Foundation (2026-04-08) + v1.1 Core Product (2026-04-09)
- **Codebase:** ~25,000 Dart LOC + TypeScript Cloud Functions
- **Stack:** Flutter 3 + Riverpod 2 + GoRouter | Firebase (Auth, Firestore, Functions, europe-west1) | Cloudflare R2 | Upstash Redis | Resend
- **Environments:** `tremble-dev` (dev) | `am---dating-app` (prod) — strict separation enforced
- **Bundle IDs:** `com.pulse` (dev) | `tremble.dating.app` (prod)
- **Run command always:** `--flavor dev --dart-define=FLAVOR=dev`
- **Secrets:** 40 items in Secret Manager — never hardcoded

### Brand Contract (enforced at code review)

- **Colors:** Rose `#F4436C` (primary CTA), Signal Yellow `#F5C842` (accents/badges only), Deep Graphite `#1A1A18` (text/dark bg), Warm Cream `#FAFAF7` (light bg), Confirm Green `#2D9B6F` (success states)
- **Typography:** Playfair Display 900 (display/H1), Lora 400/500 (body), Instrument Sans 500–700 (UI/buttons/nav), JetBrains Mono (telemetry/tech UI)
- **App:** dark-first | **Website:** light-first
- **GlassCard only:** glassmorphism applied only through GlassCard widget — never globally
- **Animations:** radar pulse + match reveal only — functional, never decorative

### Active Blockers

| ID | Issue | Impact |
|----|-------|--------|
| SEC-001 | Firebase App Check configured but not enforced in Cloud Functions | Prod security gap — Phase 9 |
| FUNCTIONS-DEPLOY | Cloud Functions build not deployed to tremble-dev since 2026-04-18 | Dev environment stale |

### Known Tech Debt

| ID | Debt | Severity |
|----|------|----------|
| D-25 | 40+ hardcoded Slovenian strings bypassing i18n system (home_screen, matches_screen, etc.) | Medium |
| D-26 | `ugc_action_sheet.dart` white background on dark gradient app | Medium |
| D-27 | Forgot password spinner doesn't stop after email sent | Medium |
| D-28 | 17-item registration UI fix plan (2026-04-13) — pending founder approval | Medium |
| D-29 | Map screen tile render test on physical device deferred (from 06-03) | Low |
| D-30 | Phase 7 executed outside GSD framework — no PLAN files, SUMMARY reconstructed retroactively | Low |

## Constraints

- **Platform:** iOS + Android only — BLE requires native; no web fallback
- **Privacy by architecture:** Proximity data (RSSI/BLE) lives in RAM only — never written to disk or Firestore. Non-negotiable.
- **Environment separation:** Dev and prod Firebase projects must never cross-contaminate
- **Performance:** ≥60 FPS on radar screen, BLE battery use <2%/hour, app bundle ≤120MB
- **GDPR:** europe-west1 data residency enforced. Deletion SLA 72h per Article 17.
- **No un-flavored builds:** Always `--flavor dev` or `--flavor prod`. Never bare flutter run/build.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| flutter_blue_plus for BLE | Direct access to CoreBluetooth (iOS) and BluetoothLE (Android); most maintained library | ✓ Good |
| Session-bound BLE UUID (not permanent user ID) | Prevents tracking across proximity events — privacy by architecture | ✓ Good |
| RSSI → distance with exponential smoothing | Filters signal noise, prevents false proximity triggers | ✓ Good |
| Cloudflare R2 for media | Reduces Firebase Storage cost, global CDN via media.trembledating.com | ✓ Good |
| Upstash Redis for rate limiting | Serverless Redis — no infrastructure to manage | ✓ Good |
| No in-app chat — ever | Post-match IRL meeting is the product. Chat reduces motivation to actually meet. Rule #3. | ✓ Good — v1.1 |
| `TrembleTheme.telemetryTextStyle()` pattern | Canonical entry point for all JetBrains Mono telemetry text — prevents drift | ✓ Good — v1.1 |
| `{name}` removed from wave_sent toast | Privacy: unidirectional mechanic — sender should not know recipient identity | ✓ Good — v1.1 |
| PUSH-03 closed N/A | "No chat started" condition always true; requirement is vestigial post chat removal | ✓ Good — v1.1 |
| Paywall after first proximity event | Value proven before monetization ask — higher conversion intent | — Pending v1.2 |
| RevenueCat for subscriptions | Cross-platform subscription management; avoids StoreKit/Play Billing complexity | — Pending v1.2 |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-18 after v1.1 milestone — Core Product shipped. Wave mechanic live. No chat, ever.*
