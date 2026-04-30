## Session State — 2026-04-30 18:00
- Active Task: Phase 6.4 — Run Club Interactivity (High Priority Notifications)
- Environment: Dev
- Modified Files: `lib/src/core/background_service.dart`, `lib/src/core/notification_service.dart`, `lib/src/core/translations.dart`
- Open Problems: None. Run Club now handles background taps directly and triggers state changes correctly via isolate streams.
- System Status: Build passing, zero analyze errors.

## Session Handoff
- Completed:
    - Implemented background notification action handler (`runClubNotificationTapBackground`) as a top-level function.
    - Added Action Categories for iOS in `NotificationService.dart` (`RUN_CLUB_ACTIVATION_CATEGORY` & `RUN_CLUB_DEACTIVATION_CATEGORY`).
    - Refactored `background_service.dart` to trigger actionable prompts instead of blunt auto-activation:
      - **5 min run:** Prompt "🏃‍♂️ Zaznali smo tek - Vklopi/Prezri"
      - **15 min stationary:** Prompt "⏸️ Si končal s tekom? - Izklopi/Pusti aktivno"
      - **20 min stationary:** Auto-deactivate with "💤 Samodejni izklop" notification.
    - Added `notify_incoming_wave_run_body` into `translations.dart` for Mid-Run Active Wave interception.
- In Progress: Active Wave UI adjustments (F4) for Trembling Window.
- Blocked: None.
- Next Action:
    - Update the UI logic in `F4 (Trembling Window)` if any specific rendering adjustments are needed for Run Club waves.
    - Physical device test to ensure actionable notifications open and perform actions gracefully.

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
