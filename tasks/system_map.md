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
