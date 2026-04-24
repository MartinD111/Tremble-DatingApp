# Tremble - Project TODOs

## Active Focus: Milestone v1.2 — Security & UI Polish 🚀

### 1. Security Hardening (Phase 9 + 11) ✅ COMPLETE
- [x] **SEC-001:** Enforce Firebase App Check (`enforceAppCheck: true`) on all 19 Cloud Functions.
- [x] **FUNCTIONS-DEPLOY:** All 19 Cloud Functions deployed to `tremble-dev` (2026-04-21).
- [x] Manual registration of Dev Debug Tokens (Aleksandar's tokens added).
- [x] Implementation of `FirebaseAppCheck` activation in mobile app (`main.dart`).

### 2. UI & UX Refinement (Phase C)
- [x] **TASK-006:** 30-Min Timer UI + Cancel Gumb (🔴 P0 - High Energy/Technical).
- [x] **TASK-003:** Match Card Redesign (Glassmorphism, Playfair Display 900).
- [x] **TASK-002:** Pills Transparency Fix (Opaque color: `0xFF2A2A28`).
- [x] **TASK-011:** Systematic cleanup of 40+ hardcoded Slovenian strings (D-25) — **COMPLETE**.
- [x] **TASK-007:** Notification Dedup & Logic Improvements (🔴 P1) — **COMPLETE**.
- [x] **TASK-004:** Profile Card Hobbies + Political Slider (🔴 P2) — **COMPLETE**.
- [x] **D-27:** Button Spinner UX (Forgot PW) — **COMPLETE**.
- [x] **D-26:** UgcActionSheet & Dialogs Glassmorphic Redesign — **COMPLETE**.
- [x] **Phase 11:** Technical Security Audit & Hardening (App Check, Zod, Firestore Rules) — **COMPLETE**.
- [x] **TASK-UX-01:** Visual "Ping" effect during registration flow transitions (🟠 P1).
- [x] **TASK-UX-02:** Lofi photo aesthetic guidance + technical corner brackets (🟡 P2).
- [x] **TASK-UX-03:** Interactive "Wave" simulation at end of registration (🔴 P0).
- [x] **TASK-UX-04:** Final "Go Live" ritual screen (🟠 P1).

### 3. Visual Identity — Plan 20260424-UI-Icon-Stability ✅ COMPLETE (2026-04-24)
- [x] **SPLASH-001:** Splash screen — rose icon, #1A1A18 fullscreen background (commit aee4c18)
- [x] **ICONS-001:** Launcher icons — full-color source, adaptive foreground, monochrome fixed (commit 887abe3)
- [x] **RADAR-001:** Radar pulse maxRadius 0.45 → 0.5, pulse reaches outer ring (commit 887abe3)
- [x] **MATCHES-001:** Matches title overlap with buttons fixed — Padding horizontal: 100 (commit 887abe3)
- [x] **ANIM-001:** Tab AnimatedSwitcher — ScaleTransition removed, fade-only 200 ms (commit 887abe3)

### 4. Technical Debt
- [x] **D-28:** Execute 17-item registration UI fix plan.
- [x] **D-25:** Move all hardcoded strings to `translations.dart`.
- [x] **D-39–D-42:** UI-Icon-Stability debt resolved (commit 887abe3).
- [ ] **D-37:** Test 3-state Map Toggle (TASK-008) — Martin, physical device.

---

## Infrastructure & Business
- [ ] **LEGAL:** Company registration and legal status for RevenueCat (Phase 8 on hold).
- [ ] **FOUNDER:** TestFlight internal beta build + review.
- [ ] Update landing page for Privacy Policy on `trembledating.com`.
- [ ] **MARTIN:** Register Martin's debug token in Firebase App Check (tremble-dev) before testing.

---
*Last Updated: 2026-04-24* — Build: ✅ passing | flutter analyze: ✅ 0 issues | Commit: 887abe3
