## Session State — 2026-04-29 23:55
- Active Task: Planning Firestore Security Rules (HIGH Risk)
- Environment: Dev
- Modified Files: None
- Open Problems: ADR-001 still open.
- System Status: Build passing.
## Session Handoff
- Completed: F3 Match Categories + History Filters. Verified Rule #45 (Secret detection) resides properly in lessons.md.
- In Progress: Planning Firestore Security Rules for restricted field modifications (`users/{userId}`).
- Blocked: ADR-001.
- Next Action:
    - Review and approve Firestore Security Rules Plan (5-Step plan generated).
    - Execute field-level lockdown for client-side user data updates.


---

## Infrastructure & Constraints
- **Security Update**: App Check is strictly enforced on all Cloud Functions.
- **Privacy Fix**: SEC-002 resolved. lat/lng coordinates are never permanently stored.
- **Policies**: All MPC rules and policies are now centralized within `MASTER_PLAN.md`.
- **Gym Mode**: `activeGymId` + `gymModeUntil` fields added to user doc (nullable). Not in Firestore Rules yet — add before prod deploy.
