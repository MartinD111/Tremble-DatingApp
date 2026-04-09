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
- [ ] **PENDING (HIGH – Xcode)**: iOS Notification Service Extension za slike v push.

### Phase 8 — Paywall / Tremble Pro
- RevenueCat integration.
- Free vs. Pro (Unlimited waves + priority visibility).

### Phase 9 — Security Hardening & GDPR
- Firebase App Check enforcement in Cloud Functions.
- Firestore Rules audit + hardening.
- GDPR deletion pipeline validation.

### Phase 10 — Launch Polish & Store Deploy
- App Store + Play Store listings.
- TestFlight internal → external beta.
- trembledating.com landing page update.
- Final Store submission.
