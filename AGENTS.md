# MPC v5 — Tremble Mobile App

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

## Active Blockers (as of 2026-07-16)

Signed production build `1.0.0+22` is preserved and App Store-validated. Remaining blockers are external gates — no application code work is queued on any of them. Full detail in `tasks/blockers.md`.

| ID | Blocker | Impact |
|----|---------|--------|
| BLOCKER-STORE-005 | Firebase-stored APNs credential + build-22 physical-iPhone foreground/background/killed + explicit Wave Back verification | iOS push readiness gate |
| BLOCKER-STORE-003 | Play Console background-location declaration, screenshots, demo video | Android launch gate |
| BLOCKER-STORE-004 | Play Console foreground-services declaration | Android launch gate |
| BLOCKER-LEGAL-001 | DPIA reconciliation with the shipped architecture | Legal submission gate |
| BLOCKER-LEGAL-004 | Weekend Getaway user-local timezone code refactor + ToS wording alignment | Product/legal submission gate |
| FOLLOWUP-SEC-002 | Scoped `DEBUG` env + rotation of genuine server credentials (R2/Resend/Upstash) exposed in a local authenticated tool transcript | Security hygiene (not a submission blocker) |

> BLOCKER-003 (AMS Solutions d.o.o. registration) ✅ RESOLVED 2026-05-07
> ADR-001 (iOS BLE Background State Restoration) ✅ RESOLVED 2026-04-29 — NativeMotionService EventChannel wired.
> SEC-001 (App Check) ✅ RESOLVED 2026-04-29 — Enforced on all Cloud Functions.
> B005 (iOS Dev Provisioning for com.pulse) ✅ RESOLVED
> B006 (Photo Upload E2E) ✅ RESOLVED
> B007 (Legal Web Pages / RevenueCat SDK wired) ✅ RESOLVED
> B008 (Prod Firestore Rules active_run_crosses) ✅ RESOLVED 2026-05-24 — Verified active on am---dating-app.
> B009 (WavePillService FCM) ✅ RESOLVED 2026-05-26 — Wired in router.dart.
> BLOCKER-STORE-001 (iOS Privacy Manifest + encryption declaration) ✅ RESOLVED 2026-07-14.
> BLOCKER-STORE-002 (iOS Info.plist Contacts contradiction) ✅ RESOLVED 2026-07-16.
> BLOCKER-LEGAL-002 (Cannabis Art. 10 exposure) ✅ RESOLVED 2026-07-14 — removed from product.
> BLOCKER-LEGAL-003 (Art. 9 sexual-orientation consent) ✅ RESOLVED 2026-07-14 — PR #41 + CF prod deploy.
> BLOCKER-LEGAL-005 (Paywall false advertising) ✅ RESOLVED 2026-07-14.
> Crossing-Paths iOS delivery repair ✅ RESOLVED 2026-07-16 — PR #48 `eef99c0` (canonical identity, bounded retry, Redis dedup, explicit iOS Wave Back action bridge).
> FCM token Firestore Rules recovery regression suite ✅ RESOLVED 2026-07-16 — PR #49 `1cf5446`.

---

## Stack

```
Flutter 3 + Riverpod 2 + GoRouter
Firebase: Auth, Firestore, Cloud Functions (europe-west1)
Storage: Cloudflare R2 (media.trembledating.com — GET only, LIST disabled)
Redis: Upstash (EU region — verify)
Email: Resend (info@trembledating.com)
Domain: trembledating.com
RevenueCat: purchases_flutter v10.2.0 + purchases_ui_flutter
```

**Environments — strict separation, no exceptions:**

| | Dev | Prod |
|--|-----|------|
| Firebase | `tremble-dev` | `am---dating-app` |
| Bundle ID | `com.pulse` | TBD — confirm in Firebase console |
| Run command | `flutter run --flavor dev --dart-define-from-file=.env.json` | `flutter run --flavor prod --dart-define-from-file=.env.prod.json` |

Cross-contamination between environments = critical failure. Stop and escalate.

---

## Core Philosophy

```
DISCOVER → PLAN → BUILD → VERIFY → OPERATE → EVOLVE
```

### Non-Negotiable Rules

- No coding without an approved plan.
- No deploy without passing quality checks.
- No generic AI output — every visual decision must align with the Tremble brand system.
- No assumptions about permissions (BLE, Location) or auth flows.
- No autonomous action on Firebase Security Rules, Cloud Functions, or native iOS/Android config without founder approval.
- Never run un-flavored `flutter build`. For dev `flutter run`, use `flutter run --dart-define-from-file=.env.json`.
- GlassCard: useGlassEffect defaults to false. Only enable explicitly where glass effect is intentional (light theme contexts).

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
| 1 | Foundation — Architecture, Theme, Nav | ✅ |
| 2 | Core UX — Profiles, Matching | ✅ |
| 3 | Proximity Engine — BLE + Geohash Radius | ✅ |
| 4 | Signals & Push Notifications (Waves, FCM, WavePillService) | ✅ |
| 5 | Matching Algorithm — Event/Gym/Run scoring, Match Categories | ✅ |
| 6 | Infra & Security — App Check, Firestore Rules, GDPR deletion pipeline | ✅ |
| F1 | Protomaps — Google Maps SDK replaced, planet.pmtiles on R2, Worker at maps.trembledating.com | ✅ |
| 7 | Launch Polish — signed `1.0.0+22` IPA preserved; APNs/device + legal + store-console gates pending | ⏳ External gates only — no code lane queued |

Phase does not close until all exit criteria pass. See `.planning/ROADMAP.md` for the 11-phase GSD framing used by the `.planning/` control plane.

---

## Lessons (Permanent — Never Deleted)

**Rule #1** — Never run un-flavored `flutter build`. For dev `flutter run`, use `flutter run --dart-define-from-file=.env.json`.
Source: Multi-Env Setup, March 2026.

**Rule #2** — Do not bypass Riverpod strictly typed state. Never mutate state directly in UI layer.

**Rule #3** — Read a file before editing it. Always. No assumptions about current content.

**Rule #4** — Client-side rate limit guards must read from the same source the backend writes to. Mismatched sources (e.g. users/{uid}.wavesThisMonth vs rateLimits/{uid}:wave_monthly.count) produce silent always-pass guards.
Source: Wave limit implementation, May 2026.

**Rule #5** — firebase firestore:rules:get and firestore:fields:list are not valid Firebase CLI commands. Use Firebase Rules API for rules verification and gcloud firestore fields ttls list for TTL policy checks.
Source: TTL verification sprint, May 2026.

**Rule #6** — Never assume CF schema matches Flutter model field types. CF validation errors (Expected string, received array / received object) are silent in the UI — only visible in logcat. Always verify toApiPayload() output against CF Zod schema before device testing.
Source: completeOnboarding serialization fix, June 2026.

**Rule #7** — Client and server must read the same canonical user fields. Production writes `name`, `age`, `birthDate` (via `auth_repository.dart`). Any Cloud Function that reads `displayName` or `dateOfBirth` will silently produce "Someone, 0" payloads in production while unit tests pass on a mismatched fixture. Tests must assert on the values pushed into the FCM payload, not the mere presence of a field.
Source: CROSSING_PATHS / INCOMING_WAVE identity repair, July 2026 (PR #48).

**Rule #8** — Notification receipt is never user intent. Background handlers may refresh silent state (e.g. `proximity.updatedAt`) but must not write waves, matches, or any other action document. A reciprocal Wave is only legal when the OS delivers a real `UNNotificationResponse.actionIdentifier` (iOS) or Android tap action, forwarded through the `app.tremble/notification_actions` MethodChannel to `NotificationActionDispatcher`.
Source: background-wave abuse audit, July 2026 (PR #48).

**Rule #9** — Firestore `onDocumentCreated` triggers that call FCM must set `retry: true` and pair retry with Redis-keyed deduplication (`delivered`, `no-token`, `permanent-failure`, `attempts`). Retry without dedup produces duplicate delivery; dedup without retry drops permanently on the first APNs error.
Source: `onWaveCreated` delivery hardening, July 2026 (PR #48).

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

---

## The Orchestral Loop

```
1. SYNC        → context.md + blockers.md + lessons.md. >48h old? Re-validate.
2. HYPOTHESIZE → Root cause first. "UI stutters" → real problem: expensive build method or bad image cache.
3. PLAN        → 5-step plan. HIGH/CRITICAL = founder approval before step 4.
4. EXECUTE     → One logical component at a time. Never mix native changes with UI refactors in the same commit.
5. VERIFY      → flutter test. flutter analyze (zero warnings). UI change = screenshot or recording.
6. REFLECT     → Mistake → lessons.md. Shortcut → blockers.md. Major decision → ADR.
7. CLOSE       → Update context.md handoff block.
```

### 5-Step Plan Template

```markdown
Plan ID: YYYYMMDD-[feature-name]
Risk Level: LOW / MEDIUM / HIGH / CRITICAL
Founder Approval Required: YES / NO
Branch: feature/[name]

1. OBJECTIVE — one sentence: what does done look like?
2. SCOPE — files affected + what does NOT change
3. STEPS — each: one atomic action + verification method
4. RISKS & TRADEOFFS — what could go wrong, mitigation, debt introduced
5. VERIFICATION — unit tests, integration tests, device test (BLE if applicable), flutter analyze, coverage target
```

---

## Flutter Verification Protocol

Run in this order after every significant change:

```bash
flutter analyze --no-fatal-infos
flutter test --dart-define-from-file=.env.json
flutter build apk --debug --flavor dev --dart-define-from-file=.env.json --dart-define=FLAVOR=dev
```

For BLE changes, also run on physical device — emulator cannot simulate Bluetooth hardware.
For Firebase changes, run against emulator suite first: `firebase emulators:start`.

---

## App Architecture

Maintained in `tasks/system_map.md`. Update when structure changes.

```
lib/src/
├── core/
│   ├── ble_service.dart           ← BLE interface (flutter_blue_plus) + adapter/permission state providers
│   ├── router.dart                ← GoRouter + WavePillService FCM wiring
│   └── firebase_options_*.dart    ← Dev/Prod config maps
├── features/
│   ├── auth/                      ← Login, Onboarding, AuthUser (wavesThisMonth from rateLimits)
│   ├── dashboard/                 ← Radar, RunRecap (TTL timer, Free/Pro diff, gone-forever flag)
│   ├── matches/                   ← Match history, Near-Miss, wave limit guard
│   ├── map/                       ← Protomaps, EventRecap
│   ├── gym/                       ← Gym Mode
│   ├── recap/                     ← RecapTTLProvider, ViewedRecapsRepository
│   └── profile/                   ← Bio, Images, wave limit guard
└── shared/                        ← GlassCard (useGlassEffect default: false), Buttons, shared hooks

Infrastructure:
- 175 Dart files, 51 Dart test files, 293 Flutter tests passing, Cloud Functions 149 tests / 13 suites passing
- Signed production build `1.0.0+22` preserved under ignored `release-symbols/ios-1.0.0+22/`; App Store validation passed
- Platforms: iOS (Swift base), Android (Kotlin base)
- CI/CD: GitHub Actions — protected `main`; PR-Metadata gate requires `[PLAN-ID: YYYYMMDD-short-name]` title + `Verification checklist / unit tests / integration tests / security scan` body sections
- Firestore TTL: proximity ✅ ACTIVE, rateLimits ✅ ACTIVE
- Firestore Rules: token-only recovery ruleset active on `am---dating-app`, protected by a permanent 15-case emulator regression suite (PR #49)
- Legal pages live: trembledating.com/privacy ✅ trembledating.com/tos (EN) ✅ trembledating.com/erasure ✅ — `/sl/tos` and `/dsa-contact` still pending publication
```

---

## Quality Gates

| Dimension | Weight | Pass Threshold |
|-----------|--------|----------------|
| Logic & Tests | 30% | Zero `analyze` errors, passing tests |
| UI & Performance | 25% | No overflow errors, ≥60 FPS |
| Cross-Platform | 20% | Builds on iOS and Android |
| Security | 15% | Rules verified, no exposed secrets |
| UX Compliance | 10% | Adheres to brand tokens + `policies/design.yaml` |

---

## Visual Contract

```yaml
# Enforced at code review. Block PR if violated.
style_contract:
  - Dark theme by default. Four themes total: dark/male, dark/female, light/male, light/female.
  - GlassCard: useGlassEffect defaults to false. Enable only in light theme contexts explicitly.
  - Google Fonts only — no system fonts
  - Animations: radar pulse, match reveal — fluid, never decorative
  - No Material default blue (#2196F3) — use Tremble brand tokens
  - Primary rose: #F4436C | Signal yellow: #F5C842 | Confirm green: #2D9B6F | Deep graphite: #1A1A18 | Warm cream: #FAFAF7
  - Typography: Playfair Display / Lora / Instrument Sans / JetBrains Mono
  - Those four ship in `assets/fonts/` and `allowRuntimeFetching` is off — no
    other GoogleFonts family may be called, it would fetch at runtime and crash
    first launch offline. Add variants via `tool/fetch_fonts.py`.
  - Forbidden: glassmorphism on content cards in dark theme, 3D phone mockups, stock couple photos
  - Forbidden copy: revolutionary, seamless, game-changing, "find love today"
```

---

## Deploy Pipeline

```
Local (flutter run --dart-define-from-file=.env.json)
        ↓
flutter analyze --no-fatal-infos + flutter test --dart-define=FLAVOR=dev (GitHub Actions)
        ↓
Firebase Rules (Emulator suite)
        ↓
Beta Build (TestFlight / Play Console Internal)
        ↓
Founder sign-off
        ↓
Production (flutter build ipa/appbundle --flavor prod)
```

TestFlight currently pending store product configurations.

---

## Session End Checklist

- [ ] `tasks/context.md` updated with handoff block
- [ ] Open work committed or stashed with note
- [ ] New blockers in `tasks/blockers.md`
- [ ] Mistakes in `tasks/lessons.md`
- [ ] No secrets in any committed file
- [ ] CI passing or failure documented
