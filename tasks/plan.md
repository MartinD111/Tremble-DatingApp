Plan ID: 20260503-remove-redundant-labels
Risk Level: LOW
Founder Approval Required: NO
Branch: feature/cleanup-matches-ui

1. OBJECTIVE — Remove "Your Run" and "Your Event" redundant labels from the sub-header bar in MatchesScreen.
2. SCOPE — `lib/src/features/matches/presentation/matches_screen.dart`
3. STEPS:
    - Modify `_SectionContextBar.build`: Check if `section` is `event` or `run`. If so, return `const SizedBox.shrink()`.
    - Modify `MatchesScreen.build`: Wrap the `Padding` containing `_SectionContextBar` with a condition so it doesn't add extra vertical space when the bar is empty.
4. RISKS & TRADEOFFS — Minimal. The spacing between the header and the list might feel tighter; I'll monitor this.
5. VERIFICATION:
    - Run `flutter analyze` to ensure no errors.
    - Manually verify the UI.
