## Session State — [2026-05-06 18:30]
- Active Task: Fix manual run mode activation by adding missing Cloud Functions (COMPLETED)
- Environment: Dev
- Modified Files:
    - `functions/src/modules/gym/gym.functions.ts` — added `onRunModeActivate`, `onRunModeDeactivate`, `expireRunModes`
    - `functions/src/modules/events/events.functions.ts` — added `onEventModeDeactivate`
    - `functions/src/index.ts` — exported all 4 new Cloud Functions
- Open Problems: None
- System Status: Cloud Functions build passing (tsc), ready for Firebase deploy.

## Session Handoff
- Completed:
    - **Fixed Manual Run Mode Activation — Missing Cloud Functions**:
        - Root cause: `onRunModeActivate`, `onRunModeDeactivate`, and `onEventModeDeactivate` Cloud Functions were completely missing from codebase, causing silent failures when user tapped activation buttons
        - **Added to `functions/src/modules/gym/gym.functions.ts`:**
          - `onRunModeActivate` — writes `isRunModeActive: true` and `runModeUntil` (+4h) to user doc
          - `onRunModeDeactivate` — clears `isRunModeActive: false` and `runModeUntil: null`
          - `expireRunModes` — scheduled hourly to auto-expire stale sessions (mirrors gym pattern)
        - **Added to `functions/src/modules/events/events.functions.ts`:**
          - `onEventModeDeactivate` — clears `activeEventId: null` and `eventModeUntil: null`
        - **Updated `functions/src/index.ts`:**
          - Exported `onRunModeActivate`, `onRunModeDeactivate`, `expireRunModes` from gym module
          - Exported `onEventModeDeactivate` from events module
        - Cloud Functions TypeScript build passes (tsc) with 0 errors
        - **Next action:** Deploy with `firebase deploy --only functions --project tremble-dev` and test on device
- In Progress: None
- Blocked: None
- Next Action: Deploy Cloud Functions to dev Firebase, then test run mode activation on device
