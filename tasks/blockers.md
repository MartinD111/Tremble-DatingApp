# Blockers & Investigation Findings

---

## BLOCKER-001 — D-01/D-05 Were Stale: BLE Already Implemented

**Date:** 2026-04-02
**Raised by:** Claude Code — HALT condition triggered during implementation planning
**Status:** Resolved (no code change required)

### Finding

`background_service.dart` already correctly delegates all BLE operations to `ble_service.dart`.
No mock BLE logic exists in the file. The debt entries D-01 and D-05 described a prior state
that had already been shipped before this session.

### Evidence

| Check | File | Lines | Result |
|---|---|---|---|
| Imports BleService | background_service.dart | 12 | ✅ |
| Instantiates BleService() singleton | background_service.dart | 76 | ✅ |
| Calls bleService.start() on service start | background_service.dart | 82 | ✅ |
| Calls bleService.stop() on stopService event | background_service.dart | 86 | ✅ |
| Calls bleService.stop() on pauseRadar event | background_service.dart | 92 | ✅ |
| Calls bleService.start() on resumeRadar event | background_service.dart | 98 | ✅ |
| FlutterBluePlus.startScan() used with Tremble UUID | ble_service.dart | 88–91 | ✅ |
| FlutterBluePlus.scanResults stream consumed | ble_service.dart | 94–98 | ✅ |
| FlutterBluePlus.stopScan() on stop | ble_service.dart | 64 | ✅ |
| Proximity events written to Firestore | ble_service.dart | 109–117 | ✅ |

### What the 60s timer in background_service.dart actually is

The `Timer.periodic(Duration(seconds: 60))` at line 105 is **not a BLE mock**.
It handles four unrelated responsibilities:
1. Battery level read for notification content
2. Idle proximity notification (no BLE encounter in 6+ hours, daytime only)
3. Android foreground notification content update
4. `radarState` event emission to the UI (degraded vs full mode)

None of these are BLE scanning. They are correct and intentional background housekeeping.

### Secondary Finding — Mislabeled Skill File

`.agent/skills/flutter-ble/SKILL.md` contains the **Firebase Security** skill
(`name: firebase-security` in frontmatter). It is placed in the wrong directory
and provides zero flutter-ble guidance. Logged as D-06.

### Decision Rule Applied

> "If you find that background_service.dart already calls ble_service.dart correctly:
> HALT, write findings to tasks/blockers.md, do not modify anything."

HALT was applied. No code was modified.

### Final Resolution (2026-04-15)

Despite the previous assessment (Blocker-001), a final review of the codebase and the user's explicit active blocker list confirmed that the `BackgroundService` still relied on a mock-like structure for the radar pulse.

**Actions taken:**
- Integrated `BleService` with real `flutter_blue_plus` scanning and advertising into `BackgroundService`.
- Implemented the "Found!" mechanic in `RadarSearchOverlay` connected to `WaveRepository`.
- Resolved all static analysis errors in `HomeScreen`, `MatchesScreen`, and `MatchService` caused by the integration.
- Codebase is now stable and ready for physical device testing.


---

## BLOCKER-002 — Critical Functional Failures (Handoff to Aleksandar)

**Date:** 2026-04-15
**Raised by:** Founder (User)
**Status:** OPEN

### Reported Issues

1.  **Matching Logic Broken:** Logic for matching needs correction. The timer mechanism (or lack thereof) is not functioning as intended. Physical testing is required to observe current behavior.
2.  **Profile UI (Manual Alignment Required):** "My Profile" and "Edit Profile" screens require manual layout adjustments. AI-generated layouts (Gemini) are currently failing to meet the visual specification requirements.
3.  **Hobbies Placement:** Specific hobby placement within "My Profile" needs to be manually corrected.
4.  **Data Persistence Failure (CRITICAL):**
    *   User profile images are not saving.
    *   Hobbies selection is not saving.
5.  **Firebase API Error — "Pozdrav" (Greet):**
    *   The "Pozdrav" function is failing due to a Firebase API error.
    *   Consequently, greeted persons are not being saved to the "Ljudje" (People) list/collection.
6.  **Map Visibility:** The Tremble Map is currently not visible/rendering.
7.  **Visual Asset Update:** The Radar icon/animation needs to be replaced with the Tremble logo asset.

### Next Steps for Aleksandar

-   [ ] Verify the matching logic flow and restore the 30-minute timer/session constraint.
-   [ ] Manually overhaul `lib/src/features/profile/presentation/profile_detail_screen.dart` and `edit_profile_screen.dart` for pixel-perfect positioning.
-   [ ] Debug Firestore write operations for images and hobbies in `ProfileRepository` or equivalent.
-   [ ] Investigate and fix the Firebase function/API call for the "Pozdrav" feature.
-   [ ] Verify map initialization and key configuration.
-   [ ] Swap Radar pulsing assets with the provided logo asset.

