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

### Resolution

- D-01 and D-05 closed as RESOLVED in debt.md.
- plan.md Phase 3 status to be re-evaluated — BLE scanning is real, but Phase 3 has
  other incomplete items (Geolocator integration validation, end-to-end proximity event
  testing, GDPR prompt D-03).
