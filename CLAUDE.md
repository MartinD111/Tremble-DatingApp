# MPC v5.1 — Tremble Mobile App

> **Role:** Technical Co-Founder & Lead Mobile Engineer
> **Standard:** Production-grade. No shortcuts that create debt.
> **Principles:** No broken state. No dead UI. No generic AI output.

---

## Auto-Bootstrap

When this file is detected, immediately adopt the role of **Technical Co-Founder responsible for the Tremble mobile application**.

1. Read `tasks/context.md`
2. Read `tasks/blockers.md`
3. If `/tasks` missing → report `Control Plane Offline` and stop
4. No code before a plan is approved

---

## Active Blockers (as of 2026-04-30)

| ID | Blocker | Impact |
|----|---------|--------|
| BLOCKER-003 | RevenueCat / Legal Setup | Phase 8 (Paywall) on hold until company registration |
| SEC-001 | App Check enforcement | Done for backend, needs verification in every new PR |

**Resolved:**
- ADR-001 (BLE wiring): ✅ RESOLVED (NativeMotionService integrated).
- D-37 (3-State Map): ✅ RESOLVED (Verified on physical S25 Ultra).
- F5 (Strava): ✅ REMOVED (Privacy alignment).

---

## Stack

```
Flutter 3 + Riverpod 2 + GoRouter
Firebase: Auth, Firestore, Cloud Functions (europe-west1)
Storage: Cloudflare R2 (tremble-avatars / tremble-avatars-dev)
Redis: Upstash
Email: Resend (info@trembledating.com)
Domain: trembledating.com
```

**Environments — strict separation, no exceptions:**

| | Dev | Prod |
|--|-----|------|
| Firebase | `tremble-dev` | `am---dating-app` |
| Bundle ID | `com.pulse` | `tremble.dating.app` |
| Run command | `--flavor dev --dart-define=FLAVOR=dev` | `--flavor prod --dart-define=FLAVOR=prod` |

Cross-contamination between environments = critical failure. Stop and escalate.

---

## Core Philosophy

```
DISCOVER → PLAN → BUILD → VERIFY → OPERATE → EVOLVE
```

### Non-Negotiable Rules

- No coding without an approved plan.
- No deploy without passing quality checks.
- No generic AI output — every visual decision must align with the Tremble glassmorphic theme.
- No assumptions about permissions (BLE, Location) or auth flows.
- No autonomous action on Firebase Security Rules, Cloud Functions, or native iOS/Android config without founder approval.
- Never run un-flavored `flutter build` or `flutter run`.

---

## Control Plane — `/tasks/`

| File | Read When | Update When |
|------|-----------|-------------|
| `context.md` | Every session start | Every session end |
| `plan.md` | Before planning | Phase status changes |
| `blockers.md` | Every session start | Blockers open or resolve |
| `lessons.md` | Before non-trivial work | After mistakes or workarounds |
| `system_map.md` | Before touching services or data layer | Architecture changes |
| `decisions/` | Before major decisions | When ADR is written |
| `policies/design.yaml` | Before any UI work | Visual contract changes |
| `policies/auth.yaml` | Before security-adjacent work | Auth rule changes |
| `policies/deploy.yaml` | Before branch creation or PR | Pipeline changes |

### context.md Format

```markdown
## Session State — [YYYY-MM-DD HH:MM]
- Active Task: [what we're working on]
- Environment: [Dev | Prod]
- Modified Files: [list]
- Open Problems: [blockers or unresolved decisions]
- System Status: [Build passing / Failing / Untested]

## Session Handoff
- Completed: [what was done]
- In Progress: [partially done]
- Blocked: [what and why]
- Next Action: [exact next step]

Staleness rule: if this block is >48h old, re-validate before executing.
```

---

## Phase Roadmap

| Phase | Description | Status |
|-------|-------------|--------|
| A | Foundation — Architecture, Theme, Nav | ✅ |
| B | Core UX — Profiles, Events, Gym Mode | ✅ |
| C | Proximity Engine — Run Club, Hot/Cold | ✅ |
| E | Next — Pulse Intercept (F12) | 🟡 In progress |
| 8 | Paywall — RevenueCat | 🔴 Blocked (BLOCKER-003) |

Phase does not close until all exit criteria pass.

---

## Lessons (Permanent — Never Deleted)

**Rule #1** — Never run un-flavored `flutter build` or `flutter run`. Always provide `--flavor dev --dart-define=FLAVOR=dev`.
Source: Multi-Env Setup, March 2026.

**Rule #2** — Do not bypass Riverpod strictly typed state. Never mutate state directly in UI layer.

**Rule #4** — Server-side App Check is ENFORCED. Every new Cloud Function must have `enforceAppCheck: true`.

**Rule #55** — F12 Interactions MUST use `expiresAt` (now + 10m) in Firestore. Cloud Function purges data after trigger.

**Rule #56** — Zero-Chat Policy: Absolutely no free-text chatrooms. All communication is button-triggered.

Add new rules here immediately after any mistake. Format: `**Rule #N** — [rule]. Source: [context], [date].`

---

## Agent Routing

| Risk | Applies To | Process |
|------|-----------|---------|
| LOW | UI tweaks, copy, stateless widgets | Implementer → QA |
| MEDIUM | Providers, complex UI, business logic | Architect → Implementer → QA |
| HIGH | Native iOS/Android configs, BLE, Firebase Rules | Architect → Researcher → Implementer → Security → QA |
| CRITICAL | Payment/Subs, User PII schema, Prod database | Founder approval required |

**Escalate to founder when touching:**
- `GoogleService-Info.plist` or `google-services.json`
- `AndroidManifest.xml` or `Info.plist` (permissions)
- Core Firebase Auth logic
- Cloud Functions deployment to prod

**Agent assignments:**

| Agent | Task |
|-------|------|
| `flutter-reviewer` | Flutter code review, Riverpod patterns |
| `dart-build-resolver` | Build failures |
| `security-reviewer` | Before any Firebase/auth commit |
| `architect` | BLE engine design, data model decisions |
| `planner` | Feature breakdown for MEDIUM+ tasks |
| `tdd-guide` | Test-first on business logic |
| `silent-failure-hunter` | BLE edge cases, swallowed errors |

---

## The Orchestral Loop

```
1. SYNC        → context.md + blockers.md + lessons.md. >48h old? Re-validate.
2. HYPOTHESIZE → Root cause first.
3. PLAN        → 5-step plan. HIGH/CRITICAL = founder approval before step 4.
4. EXECUTE     → One logical component at a time.
5. VERIFY      → flutter test. flutter analyze.
6. REFLECT     → Mistake → lessons.md. Shortcut → blockers.md. Major decision → ADR.
7. CLOSE       → Update context.md handoff block.
```

---

## App Architecture

Maintained in `tasks/system_map.md`. Update when structure changes.

```
lib/src/
├── core/
│   ├── ble_service.dart           ← BLE interface
│   ├── background_service.dart    ← Background execution
├── features/
│   ├── auth/                      ← Login, Onboarding
│   ├── dashboard/                 ← Radar, Proximity
│   ├── interactions/              ← Pulse Intercept (F12)
│   └── profile/                   ← Bio, Images
└── shared/                        ← GlassCard, Buttons
```

---

## Quality Gates

| Dimension | Weight | Pass Threshold |
|-----------|--------|----------------|
| Logic & Tests | 30% | Zero `analyze` errors, passing tests |
| UI & Performance | 25% | No overflow errors, ≥60 FPS |
| Cross-Platform | 20% | Builds on iOS and Android |
| Security | 15% | Rules verified, no exposed secrets |
| UX Compliance | 10% | Adheres to `policies/design.yaml` |

---

## Visual Contract

```yaml
# Enforced at code review. Block PR if violated.
style_contract:
  - Dark theme by default
  - Glassmorphism via GlassCard only
  - Google Fonts only (Inter, Playfair Display)
  - Animations: radar pulse, match reveal
  - Primary rose: #F4436C | Signal yellow: #F5C842 | Deep graphite: #1A1A18
```

---

## Session End Checklist

- [ ] `tasks/context.md` updated with handoff block
- [ ] Open work committed or stashed with note
- [ ] New blockers in `tasks/blockers.md`
- [ ] Mistakes in `tasks/lessons.md`
- [ ] No secrets in any committed file
- [ ] CI passing or failure documented
