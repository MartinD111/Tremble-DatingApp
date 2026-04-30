## Session State — 2026-04-30 10:48
- Active Task: Finalized Run Club Implementation
- Environment: Dev
- Modified Files: `functions/src/modules/proximity/proximity.functions.ts`, `functions/src/index.ts`, `lib/src/features/dashboard/data/run_club_repository.dart`, `lib/src/features/dashboard/presentation/home_screen.dart`, `lib/src/features/dashboard/presentation/widgets/live_run_card.dart`
- Open Problems: None. F6 is fully implemented and end-to-end logical flow is verified.
- System Status: Build passing (Native Bridges registered), zero analyze errors.

## Session Handoff
- Completed: 
    - Updated `activeRunCrossesProvider` to filter out user-dismissed encounters (`dismissedBy`).
    - Added `onRunCrossUpdated` Cloud Function to listen for mutual `signals` = `true`.
    - Handled standard match creation and rich FCM pushes for mutual Run Club waves.
    - Verified `HomeScreen` logic that automatically routes new Run Club matches to `MatchRevealScreen`.
- In Progress: Waiting for real-world physical device testing.
- Blocked: None.
- Next Action: 
    - Perform physical device testing to validate BLE manufacturer data (-85 dBm threshold) for Run Club intercept.
    - Test match reveal user experience in physical proximity context.

---

## Infrastructure & Constraints
- **Security Update**: App Check is strictly enforced on all Cloud Functions.
- **Privacy Fix**: SEC-002 resolved. lat/lng coordinates are never permanently stored.
- **Policies**: All MPC rules and policies are now centralized within `MASTER_PLAN.md`.
- **Gym Mode**: `activeGymId` + `gymModeUntil` fields added to user doc (nullable). Not in Firestore Rules yet — add before prod deploy.

## Infrastructure & Constraints
- **Security Update**: App Check is strictly enforced on all Cloud Functions.
- **Privacy Fix**: SEC-002 resolved. lat/lng coordinates are never permanently stored.
- **Policies**: All MPC rules and policies are now centralized within `MASTER_PLAN.md`.
- **Gym Mode**: `activeGymId` + `gymModeUntil` fields added to user doc (nullable). Not in Firestore Rules yet — add before prod deploy.
