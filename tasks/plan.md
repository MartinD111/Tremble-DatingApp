# Tremble — Unified Roadmap (GSD-MPC)

## Completed ✅
- **Phase 1: Foundation** — Architecture, Theme, Navigation.
- **Phase 2: Core UX** — Profiles, Swiping, Matching Flows.
- **Phase 3: Proximity Engine** — Real BLE + Geolocator implementation.
- **Phase 4: Messaging** — Basic structure.
- **Phase 5: Cloud & Infra** — Multi-Env, Auth, Bug Fixes.

---

## Active Phase 🚀
### Phase 6 — Brand Alignment & Wave Mechanic
- [ ] Swap teal (#00D9A6) → Tremble Rose (#F4436C) across the app.
- [ ] Install Font System (Playfair Display / Lora / Instrument Sans / JetBrains Mono).
- [ ] Update onboarding + CTA copy in `translations.dart`.
- [ ] Build Wave Mechanic: One-tap send, unidirectional hidden, mutual = match.
- [ ] Match Reveal screen with brand animation.
- [ ] **URGENT**: Finalize Google Maps API key injection (Local + CI).

---

## Upcoming ⏳
### Phase 7 — Messaging & Push Notifications
- Real-time chat after mutual wave (Firestore).
- FCM + APNs configuration.
- Notification types: Proximity, Mutual Wave, 24h Reminder.

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
