# System Architecture Map

Tremble App Structure
│
├── lib/src/core/
│   ├── ble_service.dart          ← BLE Hardware Interface (flutter_blue_plus)
│   ├── background_service.dart   ← Background execution rules
│   └── firebase_options_*.dart   ← Dev/Prod Config Maps
│
├── lib/src/features/
│   ├── auth/                     ← Login, Google Sign-In, Onboarding
│   ├── dashboard/                ← Radar, Proximity discovery
│   ├── matches/                  ← Swipe queue, Match resolutions
│   └── profile/                  ← Bio, Images, Preferences
│
└── lib/src/shared/               ← Reusable Glassmorphism, Buttons, Hooks

Infrastructure:
- Platforms: iOS (Swift base), Android (Kotlin base)
- Backend:   Firebase (Auth, Firestore, Cloud Functions)
- Storage:   Cloudflare R2 (for media) / Firebase Storage
- Flavors:   Dev (com.pulse) | Prod (tremble.dating.app)

## Data Flows & PII (SEC-005)
- **Onboarding PII:** Collected via `completeOnboarding` (Firebase Function). Includes: Email (encrypted at rest), Birthdate (converted to age), Gender, InterestedIn, Hobbies, Location (ephemeral/obfuscated).
- **Proximity Data:** BLE RSSI and discovery logs are ephemeral and stored in memory only. No permanent disk storage for local device sightings.
- **Retention:** All PII follows deletion jobs defined in `functions/src/modules/gdpr`.
