# Tremble — Proximity Dating App

## What This Is

Tremble is a Flutter mobile app (iOS + Android) for proximity-based dating. It uses Bluetooth Low Energy to passively detect when two users are physically near each other, then lets each send a "wave." A mutual wave unlocks the profile and enables chat. The app runs in the background — users live their lives, Tremble works quietly. It is the anti-Tinder: zero swiping, zero scrolling, one tap to act.

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
- ✓ Auth redirect loop fixed (login → onboarding routing) — Bug fix 2026-04-08
- ✓ Google Maps API key injection mechanism (Android + iOS) — Bug fix 2026-04-08
- ✓ Email verification banner in registration flow — Bug fix 2026-04-08

### Active

#### Brand Alignment (Phase 6)
- [ ] Color token swap: teal (#00D9A6) → Tremble Rose (#F4436C) across all UI
- [ ] Font system: Playfair Display 900 (display), Lora 400/500 (body), Instrument Sans 500–700 (UI), JetBrains Mono (telemetry)
- [ ] Onboarding copy: brand voice — short, direct, confident. No generic AI output.
- [ ] Registration CTA copy fix

#### Wave & Match Mechanic (Phase 6)
- [ ] Wave mechanic: one-tap send, unidirectional hidden (no visibility of one-sided interest)
- [ ] Mutual wave → profile unlock → chat entry
- [ ] Match resolution screen with brand-aligned reveal animation

#### Messaging (Phase 7)
- [ ] Real-time chat after mutual wave (Firestore or Firebase Realtime DB)
- [ ] Push notifications: 3 types only — proximity event, mutual wave, 24h inactivity reminder
- [ ] No marketing push, no gamification notifications

#### Paywall / Tremble Pro (Phase 8)
- [ ] Freemium: 5 outgoing waves/month free
- [ ] Tremble Pro (~€9.99/month): unlimited waves + priority match visibility
- [ ] Paywall triggers after first proximity event (value proven before ask)
- [ ] RevenueCat integration for iOS/Android subscription management

#### Security & Compliance (Phase 9)
- [ ] Firebase App Check enforced in Cloud Functions (SEC-001)
- [ ] Firestore Security Rules audit and hardening
- [ ] GDPR deletion pipeline validation (72h SLA, cascading delete across Firestore + R2 + Auth)
- [ ] PII encryption at rest verification

#### Launch (Phase 10)
- [ ] App Store Connect metadata, screenshots, preview video
- [ ] Google Play Console listing
- [ ] TestFlight distribution (internal → external beta)
- [ ] trembledating.com landing page (minimal: hero, demo animation, waitlist/store redirect)

### Out of Scope

- Video profiles or audio notes — complexity vs signal ratio; profile must be fast to read
- In-app social feed or content layer — this is a coordination tool, not a platform
- Web app — mobile-only by design (BLE requires native)
- B2B Events API — documented as future phase in strategic doc; not v1
- Aggregated proximity analytics (data layer) — requires user base first; deferred post-launch
- Swipe mechanic — explicitly anti-Tinder by design

## Context

### Technical Environment

- **Stack:** Flutter 3 + Riverpod 2 + GoRouter | Firebase (Auth, Firestore, Functions, europe-west1) | Cloudflare R2 | Upstash Redis | Resend (info@trembledating.com)
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
| SEC-001 | App Check not enforced in Cloud Functions | Prod security gap |
| URGENT | Real Google Maps API key not yet filled in | Maps broken on both platforms |

### Known Debt

- ADR-003: Color token swap (teal → rose) — documented, not executed
- Font system not installed in Flutter project
- `.agent/skills/flutter-ble/SKILL.md` contains wrong content (firebase-security) — mislabeled

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
| Paywall after first proximity event | Value proven before monetization ask — higher conversion intent | — Pending |
| RevenueCat for subscriptions | Cross-platform subscription management; avoids StoreKit/Play Billing complexity | — Pending |
| Wave: unidirectional hidden | No visibility of one-sided interest — reduces rejection anxiety, aligns with brand values | — Pending |

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
*Last updated: 2026-04-08 after initial GSD project initialization — brownfield, all prior phases inferred from codebase and session history*
