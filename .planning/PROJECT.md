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
- ✓ Cloud Functions source organized across 11 `*.functions.ts` files (europe-west1) — Phase 5
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
- ✓ Weekend Getaway plan defined — €2,99/vikend, Friday 19:00 to Sunday 19:00, Signal Yellow accent — Phase 8 (v1.2)
- ✓ Premium screen: 5-card carousel for Signal Prime (€7,99/mo), Weekend Getaway (€2,99/vikend), Yearly (€59,99/yr), Lifetime (€149,99), and Free Tier — Phase 8 (v1.2)
- ✓ Premium carousel uses 3D perspective PageView, haptic feedback, infinite scroll, and dots indicator — Phase 8 (v1.2)
- ✓ `LiquidNavBar` modular `itemWrapper` support for tutorial spotlight targeting — Phase 10 (v1.2)
- ✓ `WavePillService` OverlayEntry pill for foreground waves — FCM wiring still pending — Phase 7 follow-up (v1.2)
- ✓ 6-step tutorial spotlight overlay with opt-in first-launch flow and SharedPreferences persistence — Phase 10 (v1.2)
- ✓ Places API session tokens wired to reduce autocomplete cost — Infrastructure (v1.2)
- ✓ Croatian translations complete: 608/608 strings — Localization (v1.2)
- ✓ `vector_map_tiles` and `vector_map_tiles_pmtiles` added for F1 Protomaps dependency path — Maps (v1.2)

### Active

#### Paywall / Tremble Pro (Phase 8)
- [ ] **WAVE-07**: Freemium limit: 5 outgoing waves/month on free tier
- [ ] **PAY-01**: Free tier allows 5 outgoing waves/month
- [ ] **PAY-02**: Paywall appears after first proximity event (value proven before ask)
- [ ] **PAY-03**: Tremble Pro (~€9.99/month): unlimited waves + priority match visibility
- [ ] **PAY-04**: RevenueCat integration for cross-platform subscription management (`purchases_flutter` not yet in `pubspec.yaml`; current upgrade flow is `_simulateUpgrade()` mock)
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

### Current State (May 2026)

- **Shipped milestones:** v1.0 Foundation (2026-04-08) + v1.1 Core Product (2026-04-09)
- **Current milestone:** v1.2 Monetization & Security in progress
- **Codebase stats:** 157 Dart files in `lib/`, 13 Dart test files, 11 Cloud Functions source files matching `functions/src/**/*.functions.ts`
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
| BLOCKER-005 | iOS dev provisioning for `com.pulse`; physical-device `flutter run` fails | iOS QA blocked |
| BLOCKER-006 | Photo upload E2E not verified on `tremble-dev` | Onboarding launch risk |
| BLOCKER-007 | `purchases_flutter` not in `pubspec.yaml`; RevenueCat is `_simulateUpgrade()` mock | Phase 8 billing blocked |
| BLOCKER-008 | `active_run_crosses` Firestore rule missing; prod still returns `PERMISSION_DENIED` because rules were deployed to `tremble-dev` only | Production proximity rule gap |
| BLOCKER-009 | `WavePillService` → `HomeScreen` wiring missing for FCM foreground `onForegroundWave` callback | Foreground wave UX incomplete |
| BLOCKER-010 | Privacy Policy and Terms of Service are not confirmed live on `trembledating.com` | Store review risk |

### Known Tech Debt

| ID | Debt | Severity |
|----|------|----------|
| D-29 | Map screen tile render test on physical device deferred (from 06-03) | Low |
| D-30 | Phase 7 executed outside GSD framework — no PLAN files, SUMMARY reconstructed retroactively | Low |
| D-31 | `.planning/` docs are one month behind actual codebase | Medium |
| D-32 | `MainApplication` extends deprecated `io.flutter.app.FlutterApplication`; migrate to `android.app.Application` | Medium |

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
*Last updated: 2026-05-25 — v1.2 in progress. Premium UI mock exists; RevenueCat dependency and live billing are still blocked.*
