# Tremble - Project TODOs

## Active Focus: Milestone v2.0 — Foundation & Phase A

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

### 4. Phase A Execution (F1, F9) 🔴 NEXT
- [ ] **F9 (Radius Logic):** Implement GPS geohash pre-filter + BLE confirmation.
- [ ] **F1 (Google Maps/Places API):** Implement Session Token Model for autocomplete.

### 5. Infrastructure & Business Blockers
- [ ] **LEGAL:** Company registration and legal status for RevenueCat (Blocks F8).
- [ ] **F8 (Pricing):** Postponed until AMS Solutions established.
- [ ] **ADR-001:** iOS BLE Background State Restoration (Blocks TestFlight beta).
- [ ] Update landing page for Privacy Policy on `trembledating.com`.
- [ ] **MARTIN:** Register Martin's debug token in Firebase App Check (tremble-dev) before testing Cloud Functions.

---
*Last Updated: 2026-04-29* — Build: ✅ passing | flutter analyze: ✅ 0 issues
