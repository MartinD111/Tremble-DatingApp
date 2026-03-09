# System Architecture Map

## Overview
Tremble is a passive, proximity-based dating application. It utilizes BLE (Bluetooth Low Energy) and geolocation for background match discovery, with a high-fidelity glassmorphic UI.

## Technology Stack
- **Framework:** Flutter (iOS/Android) `sdk: >=3.2.0 <4.0.0`
- **State Management:** Riverpod (`flutter_riverpod`)
- **Routing:** GoRouter (`go_router`)
- **UI Architecture:** Material Design + Custom Glassmorphism

## Core Modules (`lib/src/features/`)
1. **Auth:** Firebase Authentication (`firebase_auth`)
2. **Dashboard:** Main application entry and high-level states
3. **Map:** Location rendering using `flutter_map` and `latlong2`
4. **Matches:** Proximity match logic and history
5. **Profile:** User profile management
6. **Settings:** Preferences and permissions (Location/BLE)

## Infrastructure Core (`lib/src/core/`)
- **Backend/DB:** Firebase Firestore (`cloud_firestore`), Cloud Functions
- **Security:** Firebase AppCheck (PlayIntegrity / DeviceCheck)
- **Observability:** Firebase Crashlytics for fatal error tracking
- **Background Operations:** `flutter_background_service`
- **Networking:** HTTP client, Geohash utilities (`dart_geohash`)
- **Hardware Integration:** 
  - BLE: `flutter_blue_plus`
  - Location: `geolocator`
  - Permissions: `permission_handler`

## External Integrations
- Firebase Services (Auth, Firestore, Messaging, AppCheck, Crashlytics, Functions)
- Notifications: `flutter_local_notifications`

## Current Architectural State
- **Status:** Initialized. Core libraries and file structure are present.
- **Immediate Focus:** Stabilize iOS build environment (CocoaPods/Firebase integration).
