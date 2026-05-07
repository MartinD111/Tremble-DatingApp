Plan ID: 20260508-geofencing-safe-zones
Risk Level: MEDIUM
Founder Approval Required: YES (Already approved via prompt)
Branch: feature/f13-geofencing

1. OBJECTIVE — Implement Geofencing Safe Zones (Home, Work, etc.) with Zero-Data backend storage, only persisting approximate Geohash grids.
2. SCOPE — 
    - `lib/src/features/map/domain/safe_zone_repository.dart`
    - UI in settings or map for setting safe zones
    - Backend proximity querying filtering
3. STEPS:
    - [x] Step 1: Create Geohash masking utility to convert strict radius safe zones into level 6/7 Geohashes.
    - [x] Step 2: Implement `SafeZoneRepository` to store Safe Zones locally and push only Geohashes to Firestore `users/{uid}`.
    - [x] Step 3: Implement client-side filtering logic to drop matched profiles that are within the exact local Safe Zone radius.
    - [x] Step 4: Add UI to `SettingsScreen` or Map overlay for adding a Safe Zone.
4. RISKS & TRADEOFFS — Geohash approximation means some nearby users outside the exact radius but inside the geohash might be filtered by the backend. Client-side exact filtering guarantees safety.
5. VERIFICATION:
    - Run `flutter analyze` and `flutter test`.
    - Ensure zero exact lat/lng is saved in Firestore `users/{uid}`.
