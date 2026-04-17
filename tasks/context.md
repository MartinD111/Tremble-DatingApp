## Session State — 2026-04-18
- Active Task: BUG-001 + BUG-002 — RESOLVED
- Environment: Dev
- Modified Files:
    - lib/src/features/matches/data/match_repository.dart
    - lib/src/features/profile/presentation/profile_detail_screen.dart
    - functions/src/modules/users/users.schema.ts
    - tasks/context.md
    - tasks/debt.md
- Open Problems: None from this session. Cloud Functions (users.schema.ts) need to be deployed to tremble-dev to be active.
- System Status: flutter analyze — 0 issues. npm run build — clean.

## Session Handoff
- Completed:
    - BUG-001 (D-31): MatchController now uses WaveRepository.sendWave() — legacy sendGreeting CF call removed.
    - BUG-002 (D-32): updateProfileSchema expanded with 21 missing fields (gender, age, birthDate, height, hasChildren, company, school, partner prefs, UI settings).
    - Removed pre-existing unused import in profile_detail_screen.dart.
- In Progress: None.
- Blocked: Cloud Functions deploy to tremble-dev pending (manual step).
- Next Action:
    1. Deploy Cloud Functions to tremble-dev: `firebase deploy --only functions --project tremble-dev`
    2. Manual test: profile save + wave send on dev device.
    3. D-25, D-26, D-27 (hardcoded strings, ugc_action_sheet, forgot password spinner) remain pending.

