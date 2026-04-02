# Technical Debt Register

| ID   | Description                                    | Risk   | Due       | Status |
|------|------------------------------------------------|--------|-----------|--------|
| D-01 | BLE implementation uses mock background logic  | High   | Phase 3   | ✅ RESOLVED — Verified by Claude Code 2026-04-02 — implementation already shipped in ble_service.dart |
| D-02 | Production Secrets missing in Cloud Functions  | High   | Phase 5   | 🔴 OPEN — requires manual founder action |
| D-03 | Missing explicit GDPR prompt for Location/BLE  | Medium | Phase 6   | ✅ RESOLVED — 2026-04-02: PermissionGateScreen implemented, consent_service.dart created, router + background_service guarded |
| D-04 | plan.md was out of sync with shipped work      | Low    | Immediate | ✅ RESOLVED — 2026-04-02 |
| D-05 | background_service.dart BLE mock not replaced despite ble_service.dart being real | High | Phase 3 | ✅ RESOLVED — Verified by Claude Code 2026-04-02 — implementation already shipped in ble_service.dart |
| D-06 | .agent/skills/flutter-ble/SKILL.md contains firebase-security content — mislabeled, needs replacement | Low | Immediate | 🔴 OPEN |
| D-07 | Cloud Functions deployed to prod (am---dating-app) in us-central1 instead of europe-west1. Dev project (tremble-dev) has never had functions deployed. | High | Phase 5 | 🔴 OPEN |
