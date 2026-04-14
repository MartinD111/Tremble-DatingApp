# Plan ID: 20260414-navigation-fixes
Risk Level: LOW
Founder Approval Required: NO
Branch: fix/navigation-stack

1. OBJECTIVE — Fix the back button in My Profile and ensure navigation stack is preserved after editing profile.
2. SCOPE — `lib/src/features/profile/presentation/edit_profile_screen.dart`, `lib/src/features/profile/presentation/profile_card_preview.dart`
3. STEPS —
    - **EditProfileScreen**: Change `context.go('/profile-preview')` to `context.pop()` in `_saveChanges` to prevent clearing the navigation stack.
    - **ProfileCardPreview**: Ensure the back button correctly pops the screen (already has `context.pop()`).
    - **Verification**: Ensure the navigation flow `Settings -> My Profile -> Edit -> Save -> My Profile -> Settings` works without getting stuck.
4. RISKS & TRADEOFFS — Minimal risk. Using `pop()` instead of `go()` ensures the user's previous screen (Settings) remains in history.
5. VERIFICATION —
    - `flutter analyze`
    - Manual review of navigation logic.
