## Session State — 2026-05-02
- Active Task: Matches screen & Radar mode button redesign
- Environment: Dev
- Modified Files:
  - `lib/src/features/matches/presentation/matches_screen.dart` — full rewrite: dropdown title, section picker, filter popup, help dialog
  - `lib/src/features/dashboard/presentation/home_screen.dart` — _GymModeButton: tap=toast, long-press=mode picker sheet
  - `lib/src/core/translations.dart` — new keys: section_your_gym/event/run/matches, gym_mode_*_hint, mode_picker_*, filter_period, no_gym_selected, your_gyms, gym_mode_nav_hint (EN + SL)
- Open Problems: Run Mode / Event Mode activation in _ModePickerSheet shows snackbar only — real backend hookup pending when those features are built.
- System Status: Zero analysis warnings. Build passing.

## Session Handoff
- Completed:
    - **Matches dropdown**: Title replaced with borderless "Section ▾" trigger. Dropdown shows 4 rows: Your Gym (active gym pill + "Your gyms" button), Your Event, Your Run, Your Matches. Tapping a row filters the list and syncs the tab bar.
    - **Filter popup**: Horizontal chip row removed. Filter icon (⧉) opens a `showMenu` popup above the button with period options. Active filter shown as a dismissible pill below the header.
    - **Help dialog**: Redesigned with per-section icon + title + description rows.
    - **Gym Mode Button (radar)**: Single tap → SnackBar info toast. Long press → `_ModePickerSheet` bottom sheet. Sheet uses two-tap confirm: tap once to select (highlighted + "Tap again"), tap again to activate.
- In Progress: None.
- Blocked: Run Mode / Event Mode backend not yet built — mode picker activates Gym via GymModeSheet; Run/Event show confirmation toast only.
- Next Action:
    - On-device test: People tab → "Your Matches ▾" → open dropdown → verify all 4 sections render.
    - On-device test: Gym section row → tap empty pill → GymModeSheet opens.
    - On-device test: Radar → long-press dumbbell → mode picker → select Run → second tap → snackbar.
    - On-device test: Radar → single tap dumbbell → info toast appears.

---

## Infrastructure & Constraints
- **Zero-Chat Architecture**: Tremble strictly forbids free-text chatrooms (Rule #56). All interactions are limited to atomic "Waves" and "Signal" calibration.
- **Security Update**: App Check is strictly enforced on all Cloud Functions.
- **Privacy Fix**: SEC-002 resolved. lat/lng coordinates are never permanently stored.
- **Gym Mode**: `activeGymId` + `gymModeUntil` fields added to user doc (nullable). Not in Firestore Rules yet — add before prod deploy.

