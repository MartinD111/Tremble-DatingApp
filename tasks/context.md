## Session State — 2026-04-27 09:30
- Active Task: UI Visibility Optimization (Male Dark Mode)
- Environment: Dev
- Modified Files:
    - `lib/src/core/theme.dart`
    - `lib/src/features/settings/presentation/widgets/preference_pill_row.dart`
    - `lib/src/features/profile/presentation/edit_profile_screen.dart`
- Open Problems:
    - ADR-001 still open — BLE proximity engine still uses mock timer.
- System Status: Build passing, flutter analyze clean.

## Session Handoff — 2026-04-27 09:35
- Completed:
    - **Icon Visibility Fix (Male Dark Mode)**: Improved contrast for "edit circle" (pencil) icons by switching male dark mode primary color to `azure` and increasing widget opacity/border levels.
- Next Action: Proceed with ADR-001 (BLE background service integration) as it's the main blocker for TestFlight.


---

## Phase 1 & 2: Registration Resilience ✅ COMPLETE

| Item | Status |
|------|--------|
| Checkpoint | ✅ `onboardingCheckpoint` in Firestore |
| Auth Loop  | ✅ router.dart allows drafts to resume /onboarding |
| Signal Calibration | ✅ Hardware Rebrand, zero-writing policy, Signal Lock |
| Dedup (007) | ✅ Upstash Redis rate-limiting |

---

- **Security Update**: Phase 11 complete. Cloud Functions deployed to `tremble-dev`.
- **Infrastructure**: `.firebaserc` aliases `dev` and `prod` strictly mapped.
- **Privacy Fix**: SEC-002 resolved. lat/lng removed from proximity writes. Deployed dev + prod 2026-04-24.
- **Prod Firestore**: Full rules (users, drafts, matches, waves, proximity, proximity_events, rateLimits, idempotencyKeys, gdprRequests, default deny) deployed to am---dating-app 2026-04-24.
- **Prod Backup**: Point-in-time recovery (7 days) + daily backup (7 days expiry) enabled 2026-04-24.
