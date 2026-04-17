# Plan ID: 20260417-bugfix-wave-profile
Risk Level: MEDIUM
Founder Approval Required: NO
Branch: feature/bugfix-wave-profile

1. OBJECTIVE — Fix broken greeting logic (BUG-001) and enable profile saving (BUG-002).
2. SCOPE — `lib/src/features/matches/data/match_repository.dart`, `functions/src/modules/users/users.schema.ts`
3. STEPS —
    - **MatchRepository**: Replace `sendGreeting` Cloud Function call (legacy) with direct write to `waves` collection via `WaveRepository.sendWave()`.
    - **Cloud Functions**: Update `updateProfileSchema` in `users.schema.ts` to include missing fields (`gender`, `introvertScale`, `hasChildren`, etc.) and ensure compatibility with current mobile app payload.
    - **Verification**: Run `npm run build` in functions and `flutter analyze` in mobile app.
4. RISKS & TRADEOFFS — Backend changes require deployment. Strict schema is maintained for security.
5. VERIFICATION —
    - `npm run build` (functions)
    - `flutter analyze`
    - Manual test of profile save.

