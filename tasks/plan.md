# Plan ID: 20260418-security-ui-polish
Risk Level: MEDIUM
Founder Approval Required: YES (for Security Rules)
Branch: feature/security-ui-polish

1. OBJECTIVE — Enforce Firebase App Check for production hardening and polish the Match/Map UX.
2. SCOPE — `functions/`, `lib/src/features/match/`, `lib/src/features/map/`, `main.dart`
3. STEPS —
    - **Security**: Activate App Check in Flutter and enable enforcement in Cloud Functions middlware.
    - **Match UI**: Redesign the MatchDialog to use branded Glassmorphism and high-fidelity typography.
    - **Map UI**: Implement the 3-state zoom logic for city-level and country-level pulse data.
    - **Verification**: Zero analysis issues and manual verification of App Check token status on physical device.
4. RISKS & TRADEOFFS — App Check may block old clients. We must register all dev devices first.
5. VERIFICATION —
    - `npm run build` (functions)
    - `flutter analyze`
    - Manual App Check bypass test on unregistered emulator.
