# Tremble - Project TODOs

## Active Focus: Milestone v2.0 — Phase D & Launch Polish

### 1. Planning & Consolidation ✅ COMPLETE (2026-04-29)
- [x] Consolidate fragmented plans (`tremble-impl-plan-v2`, `store_submission`, `handoff_ios_radar`, etc.) into `MASTER_PLAN.md`.
- [x] Integrate all YAML policies into the `MASTER_PLAN.md`.
- [x] Clean up `tasks/` directory by deleting redundant `.md` and `.yaml` files.

### 2. Security Hardening (Phase 9 + 11) ✅ COMPLETE
- [x] **SEC-001:** Enforce Firebase App Check on all Cloud Functions.
- [x] Manual registration of Dev Debug Tokens (Aleksandar's tokens added).

### 3. Technical Debt & UI Polish ✅ COMPLETE
- [x] Move all hardcoded strings to `translations.dart` (D-25).
- [x] UI-Icon-Stability debt resolved (splash, launcher icons, match titles overlap).
- [x] Visual "Ping" effect and "Wave" simulation during registration.
- [x] **D-37:** Test 3-state Map Toggle (TASK-008) — Martin, physical device.

### 4. Phase A Execution (F1, F9) ✅ COMPLETE
- [x] **F9 (Radius Logic):** GPS geohash pre-filter + BLE confirmation. ✅ COMPLETE
- [x] **F1 Flutter layer:** `PlacesService` (session token model) + `email_location_step` + `edit_profile_screen` migrated. ✅ COMPLETE
- [x] **F1 Native Config:** N/A — Places API (New) je čisti REST, native spremembe niso potrebne. ✅
- [x] **F1 API Key:** GCP: Places API (New) aktiviran. Ključ omejen samo na Places API (New).
- [ ] **F1 Verifikacija:** Zaženi z `--dart-define=PLACES_KEY_DEV=[REDACTED]` in testiraj na napravi.
- [x] **F11 (Nicotine):** Migrated legacy smoking boolean to flexible multi-select nicotine list logic. ✅ COMPLETE
- [x] **F3 (Match Categories):** Implemented Event, Activity, Gym tabs + history date filters. ✅ COMPLETE
- [x] **F10 (Gym Mode):** Native Geofencing, GymModeSheet, and Dwell Service. ✅ COMPLETE

### 5. Infrastructure & Business Blockers
- [ ] **LEGAL:** Company registration and legal status for RevenueCat (Blocks F8).
- [ ] **F8 (Pricing):** Postponed until AMS Solutions established.
- [ ] **ADR-001:** iOS BLE Background State Restoration (Blocks TestFlight beta).
- [ ] Update landing page for Privacy Policy on `trembledating.com`.
- [ ] **MARTIN:** Register Martin's debug token in Firebase App Check (tremble-dev) before testing Cloud Functions.

### 6. Phase F6 Execution (Run Club) ⏳ NEXT
- [x] **F6 Native:** Bridge `CMMotionActivityManager` (iOS) & `Activity Recognition` (Android). ✅
- [x] **F6 Logic:** Implement 10-min TTL in Firestore handshake function. ✅
- [x] **F6 UI:** Build **Live Run Card** for Dashboard (blur/pulse effect). ✅
- [x] **F6 UI:** Implement **Post-Run Recap** screen with 10-min countdown. ✅
- [x] **F6 Interaction:** Implement **Mid-Run Intercept** notification override. ✅
- [x] **F6 History:** Add "Run Club" tags and context to match history cards. ✅

### 7. Phase F13 Execution (Stealth & Safety) ⏳ PLANNING
- [x] **F13 Architecture:** Draft ADR for local SHA-256 contact hashing. ✅
- [x] **F13 Localization:** Implement SLO/EN/DE translations with Brand ID voice. ✅
- [x] **F13 Backend:** Create `onContactAnonymityCheck` Cloud Function (Zero-Data logic). ✅
- [x] **F13 Anonymity:** Implement client-side `ContactService` with local encryption. ✅
- [x] **F13 Safe Zones:** Build `SafeZoneRepository` and map-based Zone Picker UI. ✅
- [x] **F13 Logic:** Update `DiscoveryService` with Safe Zone masking. ✅
- [x] **F13 UX:** Implement confirmation modals and independent zone toggles. ✅

---
*Last Updated: 2026-05-08* — Build: ✅ passing | flutter analyze: ✅ 0 issues | F13 Planning ⏳
