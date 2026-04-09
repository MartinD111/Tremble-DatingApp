# Tremble — Unified Roadmap (GSD-MPC)

## Completed ✅
- **Phase 1: Foundation** — Architecture, Theme, Navigation.
- **Phase 2: Core UX** — Profiles, Swiping, Matching Flows.
- **Phase 3: Proximity Engine** — Real BLE + Geolocator implementation.
- **Phase 4: Messaging** — Basic structure.
- **Phase 5: Cloud & Infra** — Multi-Env, Auth, Bug Fixes.

---

### Phase 6 — Brand Alignment & Wave Mechanic
- [x] Swap teal (#00D9A6) → Tremble Rose (#F4436C) across the app.
- [x] Install Font System (Playfair Display / Lora / Instrument Sans / JetBrains Mono).
- [x] Update onboarding + CTA copy in `translations.dart`.
- [x] Build Wave Mechanic: One-tap send, unidirectional hidden, mutual = match.
- [x] Match Reveal screen with brand animation.
- [x] **URGENT**: Finalize Google Maps API key injection (Local + CI).

---

## Active Phase 🚀
### Phase 7 — Interaction System v2.1 ✅ (Flutter complete, Functions pending deploy)
- [x] CROSSING_PATHS: anonimno BLE obvestilo (15-min anti-spam).
- [x] INCOMING_WAVE: Rich Push z imenom + sliko pošiljatelja.
- [x] MUTUAL_WAVE: Match notifikacija z deep link `/radar`.
- [x] Background "Pomahaj nazaj" handler (top-level, Firestore direct write).
- [x] Deep link routing — cold start + background-to-foreground.
- [x] Translations: `notify_*` + `action_*` ključi v EN/SL/DE.
- [x] **DONE**: `firebase deploy --only functions` → 19 funkcij deployanih v `tremble-dev` ✅
- [x] **DONE**: iOS Notification Service Extension — linked in Xcode, pod install clean ✅

### Phase 7.5 — Native iOS Polish ✅ COMPLETE
- [x] Create `ios/ImageNotification/NotificationService.swift`
- [x] Create `ios/ImageNotification/Info.plist`
- [x] Link target in Xcode (project.pbxproj)
- [x] Bundle IDs: `com.pulse.ImageNotification` (Debug) / `tremble.dating.app.ImageNotification` (Release/Profile)
- [x] Update ios/Podfile — `target 'ImageNotification'` with `Firebase/Messaging`
- [x] objectVersion set to 63 (CocoaPods 1.16.2 / Xcode 26.3 compat — DO NOT change back to 70)
- [x] .xcconfig files include `#include?` for Pods (Debug, Release, Profile)
- [x] CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = $(inherited)
- [x] Deployment target: iOS 15.0 across all targets
- [x] pod install clean ✅
Notes: Infrastructure for sender profile images in Wave push notifications is ready.
       Actual rich push image display requires physical device test + TestFlight build.

### Phase 8 — Paywall / Tremble Pro
- RevenueCat integration.
- Free vs. Pro (Unlimited waves + priority visibility).

### Phase 9 — Security Hardening & GDPR 🟡 Active
#### Step 1 — Firestore rules: proximity_events field validation
- [ ] Add write field validation to `proximity_events` (uid == request.auth.uid + required fields)
#### Step 2 — GDPR deletion pipeline fix 🟡 Plan written
- Plan: `.planning/phases/10-security-gdpr/10-01-PLAN.md`
- [ ] Unit tests (TDD RED) — 4 cases
- [ ] `deleteBatch` paginated helper
- [ ] Fix `deleteUserAccount` — waves, proximity_events, proximity_notifications, idempotencyKeys, reports
- [ ] Fix `exportUserData` — greetings → waves
- [ ] Emulator integration test
- [ ] Deploy to tremble-dev
- ⚠️ PENDING: Founder decision on `reports` deletion (Option A: full delete vs Option B: anonymise reportedId)
#### Step 3 — Firebase App Check enforcement
- [ ] Add `enforceAppCheck: true` to all 21 Cloud Functions
- [ ] Test with emulator (wrong token = rejection)
- [ ] Deploy to tremble-dev, validate

### Phase 10 — Launch Polish & Store Deploy
- App Store + Play Store listings.
- TestFlight internal → external beta.
- trembledating.com landing page update.
- Final Store submission.
