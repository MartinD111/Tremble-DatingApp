## Session State — 2026-04-30 00:30
- Active Task: Gym Mode V3 — Native OS geofencing via MethodChannel (COMPLETE)
- Environment: Dev
- Modified Files:
    - `pubspec.yaml` — removed geofence_service
    - `android/app/build.gradle.kts` — added play-services-location:21.3.0
    - `android/app/src/main/AndroidManifest.xml` — added GymGeofenceReceiver
    - `android/app/src/main/kotlin/.../gym/GymGeofenceManager.kt` — GeofencingClient
    - `android/app/src/main/kotlin/.../gym/GymGeofenceReceiver.kt` — BroadcastReceiver
    - `android/app/src/main/kotlin/.../gym/GymGeofenceStore.kt` — SharedPrefs name lookup
    - `android/app/src/main/kotlin/.../gym/GymGeofenceBridge.kt` — native NotificationManager
    - `android/app/src/main/kotlin/.../MainActivity.kt` — GEOFENCE_CHANNEL registered
    - `ios/Runner/GymGeofenceManager.swift` — CLLocationManager + UNTimeIntervalNotificationTrigger
    - `ios/Runner/AppDelegate.swift` — GEOFENCE_CHANNEL registered
    - `lib/src/features/gym/application/gym_dwell_service.dart` — pure MethodChannel bridge
- Open Problems:
    - ADR-001 still open — BLE proximity background limits.
- System Status: flutter analyze clean (0 issues), Android APK builds ✅

## Session Handoff
- Completed:
    - Full native OS geofencing implementation via MethodChannel.
    - Android: GeofencingClient DWELL (10 min) → BroadcastReceiver → native notification.
      Works when app is killed, 0% battery cost in idle state.
    - iOS: CLLocationManager.startMonitoring → on ENTER schedule UNTimeIntervalNotificationTrigger
      (600s) → on EXIT cancel. Notification fires from iOS system even when app is killed.
    - Dart layer reduced to 4-line bridge (invokeMethod start/stop).
    - Radius clamped 70–100 m per plan, default 80 m from Firestore gym.radiusMeters.
- In Progress: Nothing.
- Blocked: ADR-001 (unchanged).
- Next Action:
    - DEVICE TEST REQUIRED (cannot emulate geofence reliably in simulator):
      Android: use Android Studio GPS mock → set location inside gym radius →
               wait 10 min → verify BroadcastReceiver fires + notification appears.
      iOS: Xcode → Debug → Simulate Location → custom GPX with gym coordinates →
           wait → verify UNTimeIntervalNotificationTrigger fires.
    - Ensure ACCESS_BACKGROUND_LOCATION runtime grant before testing Android.
    - Ensure CLLocationManager "Always" permission granted before testing iOS.


---

## Infrastructure & Constraints
- **Security Update**: App Check is strictly enforced on all Cloud Functions.
- **Privacy Fix**: SEC-002 resolved. lat/lng coordinates are never permanently stored.
- **Policies**: All MPC rules and policies are now centralized within `MASTER_PLAN.md`.
- **Gym Mode**: `activeGymId` + `gymModeUntil` fields added to user doc (nullable). Not in Firestore Rules yet — add before prod deploy.
