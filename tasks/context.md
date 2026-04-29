## Session State — 2026-04-29 17:30
- Active Task: F10 — Gym Mode (COMPLETE)
- Environment: Dev
- Modified Files:
    - `functions/src/modules/gym/gym.functions.ts` — NEW: onGymModeActivate, onGymModeDeactivate, expireGymSessions
    - `functions/src/modules/matches/matches.functions.ts` — gym match type detection added
    - `functions/src/index.ts` — gym module exported
    - `lib/src/features/gym/data/gym_repository.dart` — NEW: GymRepository
    - `lib/src/features/gym/application/gym_mode_controller.dart` — NEW: GymModeController (Riverpod)
    - `lib/src/features/gym/presentation/gym_mode_sheet.dart` — NEW: GymModeSheet UI
    - `lib/src/features/dashboard/presentation/home_screen.dart` — dumbbell icon + _GymModeButton
- Open Problems:
    - ADR-001 still open — BLE proximity engine still uses mock timer.
    - F10 Gym list is empty until `gyms` Firestore collection is seeded.
- System Status: Build passing. All 3 gym Cloud Functions deployed to `tremble-dev`. flutter analyze clean.

## Session Handoff
- Completed:
    - F10 — Gym Mode full implementation:
        - Backend: gym.functions.ts (activate/deactivate/expire), gym match type in matches.functions.ts
        - Flutter: GymRepository, GymModeController, GymModeSheet, home_screen dumbbell button
        - Deployed to tremble-dev. Committed + pushed (0584a38).
    - plan_gym_mode.md updated to reflect actual implementation (replaces old draft).
- In Progress:
    - Nothing. Clean handoff.
- Blocked:
    - ADR-001: BLE background service.
    - F10 device test requires at least one gym seeded in Firestore `gyms` collection.
- Next Action:
    - Seed `gyms` collection in Firebase Console (tremble-dev) with at least one test gym.
    - Device test F10 flow on physical Android (Martin) or iOS simulator.
    - After test passes: implement gym match badge in `matches_screen.dart` (P1).

---

## Infrastructure & Constraints
- **Security Update**: App Check is strictly enforced on all Cloud Functions.
- **Privacy Fix**: SEC-002 resolved. lat/lng coordinates are never permanently stored.
- **Policies**: All MPC rules and policies are now centralized within `MASTER_PLAN.md`.
- **Gym Mode**: `activeGymId` + `gymModeUntil` fields added to user doc (nullable). Not in Firestore Rules yet — add before prod deploy.
