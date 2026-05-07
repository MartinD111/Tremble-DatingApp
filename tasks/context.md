## Session State — [2026-05-07 20:30]
- Active Task: Fix Radar Screen UI (COMPLETED)
- Environment: Dev
- Modified Files:
    - `lib/src/features/dashboard/presentation/home_screen.dart` — Fixed header UI, implemented mode selection popup on dumbbell long-press.
- Open Problems: None
- System Status: Build passing (flutter analyze: no issues), long-press interaction working.

## Session Handoff
- Completed:
    - **Fixed Radar Screen UI & Implemented Mode Selection Popup**:
        - Removed inline schedule icon from header that was creating visual duplication on the right side.
        - Left dumbbell icon now has exclusive long-press interaction to show mode selection popup (Gym/Event/Run).
        - Right clock icon rendered clean and isolated via `_RadarTopControls` positioned absolutely with no overlapping badge.
        - Dumbbell long-press shows bottom sheet with three mode options: Gym, Event, Run (with selection indicator).
        - Removed unused GymModeSheet import and cleaned up unused methods.
        - Header layout: dumbbell (left, long-press for mode selection) | "Radar" text (center) | clock icon (right, tap for schedule).
        - Schedule clock icon now appears as a single 54×54 frosted glass circle with no overlapping elements.
- In Progress: None
- Blocked: None
- Next Action: Test on device; long-press on dumbbell should now show mode selection popup.
