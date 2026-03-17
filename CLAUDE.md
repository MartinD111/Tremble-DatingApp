# TREMBLE — Project Intelligence Layer
# MPC Workflow + GSD + Claude Code Agents & Skills

---

## AUTO-BOOTSTRAP

When this file is detected, immediately adopt the role defined in `MPC workflow.md`:
**Technical Co-Founder & Lead Systems Architect**

Startup sequence (mandatory, every session):
1. Read `tasks/context.md` — current state + last handoff
2. Read `tasks/plan.md` — active phase and exit criteria
3. Read `tasks/lessons.md` — permanent project rules
4. Check context staleness: if last handoff > 48h → re-validate before executing
5. Report current status before doing anything else

If `/tasks` is missing → report "Control Plane Offline" and stop.

---

## PROJECT LOCATION

```
Repo root:   ~/AMS Solutions/Tremble/Pulse---Dating-app/
Flutter SDK: ~/flutter (global, 3.41.4 stable)
Git remote:  git@github.com:unfab/Tremble (SSH)
Collaborator: Martin Dumanić — handles Android/Windows (Samsung S25 Ultra)
```

---

## CURRENT STATUS (as of 2026-03-13)

- **Phase 5 — Production Readiness** (85% complete)
- CI/CD: stable (GitHub Actions, Base64 secret injection, Flutter stable channel)
- AppCheck: **PRIORITY 1** — HIGH risk task, requires founder approval before implementation
- BLE: **PRIORITY 2** — `background_service.dart` is mock, ADR-001 mandates real Hybrid BLE+Geo
- UX Polish: handed to Martin (parallel)
- Premium Paywall: after AppCheck + BLE

**Phase 5 exit criteria (nothing launches without these):**
- [ ] AppCheck enforced on all Firebase endpoints (Play Integrity + DeviceCheck)
- [ ] Real BLE + Geo engine replacing mock in background_service.dart
- [ ] Production secrets set in Firebase Secret Manager: `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `RESEND_API_KEY`
- [ ] Separate Dev Firebase project created (currently working directly on prod — HIGH risk)
- [ ] Android build verified locally (Martin)
- [ ] Cloud Functions security review complete
- [ ] UX Polish complete
- [ ] Premium Flow + Paywall implemented
- [ ] Landing page with Privacy Policy + GDPR live on domain
- [ ] Phase 6 Final Audit passed

---

## CRITICAL OPEN BLOCKERS (from tasks/todo.md)

These block launch — not nice-to-haves:

| # | Blocker | Risk | Note |
|---|---------|------|------|
| B-01 | Production secrets not set in Firebase Secret Manager | HIGH | `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `RESEND_API_KEY` |
| B-02 | No separate Dev Firebase project | HIGH | Currently working on prod data directly |
| B-03 | AppCheck enforcement not enabled | HIGH | Registered but not enforced |
| B-04 | Android build not verified locally | MEDIUM | Martin's task |
| B-05 | Cloud Functions security review pending | HIGH | Before any prod traffic |
| B-06 | Privacy Policy + GDPR landing page missing | MEDIUM | Required for App Store + Play Store |

**B-02 is the most dangerous** — any dev mistake hits prod data directly. Create Dev Firebase project before next coding session.

---

## PHASE 5 CRITICAL PATH

### PRIORITY 1 — AppCheck (HIGH risk)
- Agent chain: architect → researcher → implementer → auditor → qa → sre
- Founder approval required after architect
- `firebase_app_check: ^0.3.1+2` already in pubspec
- Steps: Console registration → SDK integration → Cloud Functions enforcement → testing
- Do NOT enforce AppCheck before testing — will lock out dev builds

### PRIORITY 2 — BLE Real Implementation (MEDIUM→HIGH risk)
- Read ADR-001 in full before touching any BLE code: `tasks/decisions/ADR-001-ble-proximity-engine.md`
- Architecture: Hybrid BLE (flutter_blue_plus) + Geo (geolocator) in background isolate
- Files to replace: `lib/src/core/background_service.dart`, `lib/src/core/ble_service.dart`
- New Cloud Function needed: `onBleProximity`
- New Firestore collection: `proximity_events/`
- DO NOT upgrade flutter_blue_plus to 2.x before BLE implementation is complete on 1.36.8

---

## STACK

```
Flutter 3.41.4 + Riverpod 2 + GoRouter 17
Firebase (europe-west1): Auth, Firestore, Functions, Messaging, AppCheck, Crashlytics
Cloudflare R2 (avatar storage — ADR decision, not Firebase Storage)
Upstash Redis
Resend (transactional email)
BLE: flutter_blue_plus ^1.32.12 (do not upgrade until BLE engine is implemented)
Location: geolocator ^13.0.1
Background: flutter_background_service ^5.1.0
```

---

## ARCHITECTURE (key files)

```
lib/
  src/
    core/
      ble_service.dart          ← BLE logic (real implementation needed per ADR-001)
      background_service.dart   ← MOCK timer — must be replaced with Hybrid BLE+Geo
      geo_service.dart
      upload_service.dart       ← Cloudflare R2
      api_client.dart
      theme.dart                ← Glassmorphic design system
      router.dart
    features/
      auth/                     ← Firebase Auth + Google Sign-In
      dashboard/                ← home_screen.dart + radar_animation.dart
      matches/                  ← match_repository.dart + match_dialog.dart
      profile/                  ← edit, preview, detail screens
      map/                      ← pulse_map_screen.dart
      settings/
      safety/                   ← blocked users + UGC moderation
    shared/ui/
      glass_card.dart
      liquid_nav_bar.dart
      gradient_scaffold.dart
      premium_paywall.dart
tasks/
  context.md        ← READ FIRST every session
  plan.md           ← roadmap
  lessons.md        ← permanent rules
  debt.md           ← known shortcuts
  system_map.md     ← architecture blueprint
  agent_router.yaml ← risk-based agent routing
  decisions/
    ADR-001-ble-proximity-engine.md   ← Hybrid BLE+Geo decision (READ before any BLE work)
    ADR-002-ugc-safety-privacy.md
```

---

## AGENT ROUTING

Route all tasks through `tasks/agent_router.yaml`. Risk levels:

| Risk | Chain | Founder Approval |
|------|-------|-----------------|
| LOW | implementer → qa | No |
| MEDIUM | architect → implementer → auditor → qa | No |
| HIGH | architect → researcher → implementer → auditor → qa → sre | Yes (after architect) |
| CRITICAL | same as HIGH + second review after auditor | Yes (×2) |

**Always HIGH risk:** AppCheck, auth changes, PII, Firebase rules, payment flow
**Always MEDIUM risk:** new screens, BLE implementation, UI components
**LOW risk:** copy changes, style tweaks, non-auth bug fixes

---

## AGENT SELECTION

Auto-select agents based on task type:

- `flutter-expert` → any Flutter UI, widgets, animations, BLE, Riverpod state
- `mobile-developer` → background service, platform permissions, iOS/Android specifics
- `backend-developer` → Cloud Functions, Firestore rules, AppCheck, Firebase infra
- `ux-researcher` → screen design decisions, user flows, glassmorphic components
- `technical-writer` → ADRs, handoff docs, lessons.md updates

---

## SKILLS

For ALL UI work — screens, components, animations — load and follow:
`~/.claude/skills/frontend-design/SKILL.md`

Tremble UI contract:
- Dark theme primary, glassmorphism selective (not everywhere)
- Google Fonts — no system fonts, no generic defaults
- Animations: fluid and purposeful — radar pulse, match reveal, proximity glow
- Every screen must feel intentionally designed — not scaffolded
- Reference: `lib/src/core/theme.dart`, `lib/src/shared/ui/glass_card.dart`

---

## GSD INTEGRATION

GSD commands available in this project (installed globally via `npx get-shit-done-cc`):

```
/gsd:map-codebase        → run first in new session to map current stack state
/gsd:discuss-phase 5     → clarify Phase 5 implementation details before building
/gsd:execute-phase 5     → build Phase 5 tasks with full context
/gsd:verify-work         → verify completion against exit criteria
/gsd:resume-work         → resume from last session state
/gsd:health              → check project health and blockers
```

GSD handles execution context. MPC handles governance. They do not conflict.
GSD's STATE.md (if created) supplements but does not replace `tasks/context.md`.

---

## NON-NEGOTIABLE RULES (from MPC + lessons.md)

1. No code without an approved plan
2. Read `tasks/context.md` before every session — no exceptions
3. No merge without passing CI + policy checks
4. context.md > 48h old → re-validate before executing
5. BLE + auth + PII + payments → always HIGH risk → always founder approval
6. Glassmorphic execution only — no default/basic Flutter components
7. One logical change per commit, one commit per verification
8. Mock timer in `background_service.dart` must not be extended — ADR-001 mandates real BLE
9. Do not enforce AppCheck before dev/staging build exclusions are configured
10. Do not upgrade flutter_blue_plus to 2.x until BLE engine is complete on current version

---

## HUMAN ESCALATION (stop and ask)

Stop immediately and surface to founder when:
- Task touches auth, payments, or user PII
- Two consecutive verification attempts failed
- New paid infrastructure would be introduced
- ADR is required for architectural decision
- Incident reaches L2 or above
- Confidence in approach is below threshold
