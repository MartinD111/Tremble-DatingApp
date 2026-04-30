# System Architecture Map

Tremble App Structure
│
├── lib/src/core/
│   ├── ble_service.dart          ← BLE Hardware Interface (flutter_blue_plus)
│   ├── background_service.dart   ← Background execution rules
│   └── firebase_options_*.dart   ← Dev/Prod Config Maps
│
├── lib/src/features/
│   ├── auth/                     ← Login, Google Sign-In, Onboarding (PingOverlay, RitualStep)
│   ├── dashboard/                ← Radar, Proximity discovery (WaveSimulationOverlay)
│   ├── matches/                  ← Swipe queue, Match resolutions
│   └── profile/                  ← Bio, Images, Preferences
│
└── lib/src/shared/               ← Reusable Glassmorphism, Buttons, Hooks, LucideIcons (primary UI icons)

Infrastructure:
- Platforms: iOS (Swift base), Android (Kotlin base)
- Secret Manager: 40 items (Secret Manager, not hardcoded)
- CI/CD: GitHub Actions (Base64 secret injection, flutter stable channel)
- Backend:   Firebase (Auth, Firestore, Cloud Functions - Node 22 runtime)
- Redis:     Upstash Redis (Deduplication, Global Rate Limiting, Cooldowns)
- Storage:   Cloudflare R2 (for media) / Firebase Storage
- Flavors:   Dev (com.pulse) | Prod (tremble.dating.app)

## Data Flows & PII (SEC-005)
- **Onboarding PII:** Collected via `completeOnboarding` (Firebase Function). Includes: Email (encrypted at rest), Birthdate (converted to age), Gender, InterestedIn, Hobbies, Location (ephemeral/obfuscated).
- **Proximity Data:** BLE RSSI and discovery logs are ephemeral and stored in memory only. No permanent disk storage for local device sightings.
- **Retention:** All PII follows deletion jobs defined in `functions/src/modules/gdpr`.
