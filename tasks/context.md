## Session State — 2026-04-29 23:30
- Active Task: Gym Mode V2 — Event-driven geofence detection (COMPLETE)
- Environment: Dev
- Modified Files:
    - `pubspec.yaml` — added `geofence_service: ^6.0.0`
    - `lib/src/features/gym/application/gym_dwell_service.dart` — complete rewrite: polling timer removed, replaced with GeofenceService DWELL events
- Open Problems:
    - ADR-001 still open — BLE proximity background limits.
- System Status: flutter analyze clean (0 issues), APK builds ✅

## Session Handoff
- Completed:
    - Replaced foreground polling timer (1-min GPS poll) in GymDwellService with
      event-driven GeofenceService. State machine: ENTER → DWELL (10 min) → EXIT.
    - iOS UIBackgroundModes: location + Android ACCESS_BACKGROUND_LOCATION were
      already present — no native config changes needed.
    - EXIT event resets _notificationSent so re-entry re-notifies.
- In Progress:
    - Nothing.
- Blocked:
    - ADR-001: BLE background limits (unchanged).
- Next Action:
    - Device test: simulate entry into 80m radius → wait 10 min → verify DWELL
      notification fires. Use Xcode Location Simulation or Android Studio GPS mock.
    - V3 task (future): WillStartForegroundTask widget + native Android
      GeofencingClient via method channel for true killed-state 0%-battery geofencing.
    - Note: geofence_service 6.0.0+1 is officially discontinued (replaced by
      geofencing_api). Migration to geofencing_api is a V3 clean-up item.


---

## Infrastructure & Constraints
- **Security Update**: App Check is strictly enforced on all Cloud Functions.
- **Privacy Fix**: SEC-002 resolved. lat/lng coordinates are never permanently stored.
- **Policies**: All MPC rules and policies are now centralized within `MASTER_PLAN.md`.
- **Gym Mode**: `activeGymId` + `gymModeUntil` fields added to user doc (nullable). Not in Firestore Rules yet — add before prod deploy.
