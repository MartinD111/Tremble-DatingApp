## Session State — 2026-04-14 23:55
- Active Task: Fix Back Buttons & Navigation Stack
- Environment: Dev (tremble-dev)
- Modified Files: `edit_profile_screen.dart`, `profile_card_preview.dart`
- Open Problems: None
- System Status: `flutter analyze` clean. Navigation stack preserved after saving profile.

## Session Handoff
- Completed:
    - **Back Button Fixes**:
        - Fixed `EditProfileScreen` save redirection: replaced `context.go('/profile-preview')` with `context.pop()`. This prevents the navigation stack from being wiped out, allowing users to go back to Settings from the profile preview after saving.
        - Made `ProfileCardPreview` back button more resilient: added `context.canPop()` check with a fallback to `context.go('/')`.
    - **UI Consistency**: Verified that `ProfileDetailScreen` also handles back navigation correctly through its `PopScope`.
- In Progress: None.
- Next Action: Address ADR-001 (BLE background service).
