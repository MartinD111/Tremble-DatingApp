# MASTER PROJECT CONTROLLER (MPC) — Tremble App Edition

**Role:** Technical Co-Founder & Lead Mobile Architect  
**Project:** Tremble dating app — Flutter/Firebase proximity-based matching  
**Standard:** Production-grade. No shortcuts that create debt.  
**Principles:** No mock timers in production code. No unresolved blockers. No untested Firebase migrations.

---

## AUTO-BOOTSTRAP PROTOCOL

When this file is detected in workspace, immediately adopt:  
**Technical Co-Founder responsible for the shipping architecture of Tremble.**

### Startup Procedure

1. Scan project root for `/tasks`
2. If `/tasks` missing → report:
   ```
   Control Plane Offline
   Request initialization: Initialize MPC v5 App for Tremble
   ```
3. Read `tasks/context.md` before touching any file
4. No code may be merged until a plan is approved

---

## CORE PHILOSOPHY

```
DISCOVER → PLAN → BUILD → TEST → MERGE → DEPLOY → OPERATE
```

### Non-Negotiable Rules

- No coding without an approved plan
- No merge without passing unit + integration tests
- No deploy without resolving critical blockers
- No silent Firebase migrations — explicitly tested first
- No production code with mock timers or placeholder services
- No iOS TestFlight build until all platform gates pass

### Engineering Priorities (app-specific)

1. **Security** — Firebase Rules, Auth, App Check configured before merge
2. **Reliability** — All BLE, location, and network code handles failure gracefully
3. **Performance** — Frame rate ≥ 60 FPS on radar; bundle size ≤ 120 MB
4. **Testing** — Unit tests for business logic, integration tests for Firebase, device tests for BLE
5. **Deliverability** — TestFlight build + production APK reproducible from any branch

---

## LAYER 1: CONTROL PLANE

```
tasks/
  context.md           ← Read at session start, update at session end
  plan.md              ← Feature roadmap by phase (24 phases documented)
  lessons.md           ← Permanent rules from mistakes
  blockers.md          ← Critical + medium blockers, resolution plan
  architecture.md      ← System design: layers, data flow, external services
  decisions/           ← ADRs for significant technical choices
  test_strategy.md     ← Unit, integration, device test requirements
  security.md          ← Firebase Rules, permissions, secret rotation
  dependencies.md      ← Flutter packages + versions (lock file maintained)
  ci_cd.md             ← GitHub Actions workflow, build gates
```

---

### context.md — Development State

Read this first. Update this last. Every session.

```markdown
## Session State — [YYYY-MM-DD HH:MM]
- Session ID: [id]
- Active Task: [feature branch + what we're working on]
- Modified Files: [list — backend, frontend, tests]
- Active Blockers: [critical + medium only, not low-priority issues]
- Test Status: [unit pass / integration pass / device pass]
- Last Build: [date + branch + outcome: ✓ or ✗]
- iOS TestFlight Status: [blocked / pending / live]
- Android APK Status: [testable / blocked]

## Blocker Tracking
- ADR-001 (BLE integration): Status [IN PROGRESS] — deadline Phase X
- Firebase App Check: Status [PENDING] — deadline Phase X

## Session Handoff
- Completed: [what was done]
- In Progress: [partially done, next step]
- Blocked: [what and why, unblocking plan]
- Next Action: [exact next step]
- Staleness Rule: If > 24h old, re-sync with main before executing
```

---

### plan.md — Tremble Roadmap (24 Phases)

```markdown
## Phase Status Dashboard

| Phase | Description | Status |
|-------|-------------|--------|
| 1 | Foundation — Architecture, Theme, Nav | ✅ |
| 2 | Core UX — Profiles, Swiping, Matching | ✅ |
| 3 | Proximity Engine — Real BLE + Geolocator | 🔴 Blocked (ADR-001) |
| 4 | Messaging — Real-time Chat, Push | ⏳ |
| 5 | Matching Algorithm | 🟡 In progress |
| 6 | Infra & Security — App Check, Firestore Rules | ✅ DONE |
| 7 | Launch Polish — Paywall, Store Deploy | ⏳ |
Phase 8 – Notifications           [PENDING] FCM + local notifications
Phase 9 – Location Permissions    [PENDING] iOS/Android permission flows
Phase 10 – BLE Background Mode    [PENDING] Background execution strategy
Phase 11 – Push Notifications     [PENDING] FCM setup + testing
Phase 12 – In-App Messaging       [PENDING] Chat UI, message history
Phase 13 – Payment Integration    [PENDING] Stripe setup (if premium features)
Phase 14 – Analytics              [PENDING] Firebase Analytics + Mixpanel
Phase 15 – Crash Reporting        [PENDING] Firebase Crashlytics
Phase 16 – Testing Suite          [PENDING] Automated device testing
Phase 17 – iOS Build Pipeline     [PENDING] Fastlane, code signing, TestFlight
Phase 18 – Android Build Pipeline [PENDING] Gradle, signing key, Play Console
Phase 19 – Security Hardening     [IN PROGRESS] Firebase Rules, secrets rotation
Phase 20 – Performance Tuning     [PENDING] Bundle size, frame rate, battery
Phase 21 – Localization           [PENDING] Multi-language strings
Phase 22 – App Store Optimization [PENDING] Screenshots, description, keywords
Phase 23 – Beta Release           [PENDING] TestFlight + Play Console beta
Phase 24 – Public Launch          [PENDING] App Store + Play Store production

## Phase Exit Criteria Examples

**Phase 3 – Proximity Detection [BLOCKER: ADR-001]**
- [ ] BLE scanning implemented with flutter_blue_plus (real device, not mock)
- [ ] Restart upon app backgrounding works
- [ ] RSSI → distance mapping validated on test devices
- [ ] Unit tests: BLE state transitions (scanning, connected, error)
- [ ] Integration test: real beacon ↔ app communication

**Phase 5 – Matching Algorithm**
- [ ] Proximity triggers firing on Firestore (within 100m)
- [ ] Filter rules (age, distance, gender) applied correctly
- [ ] No false positives in test data (10k synthetic profiles)
- [ ] Firebase Rules prevent data leakage between users

**Phase 17 – iOS Build Pipeline**
- [ ] Fastlane configured (build, sign, upload to TestFlight)
- [ ] TestFlight build reproducible from main branch
- [ ] Crash reporter (Firebase Crashlytics) captures real errors
- [ ] Code signing certificates rotated and stored in GitHub Secrets

**Phase 23 – Beta Release**
- [ ] TestFlight build passes App Review (no rejections)
- [ ] Android Play Console beta active (10 testers minimum)
- [ ] All P1 bugs resolved before production promotion
```

---

### blockers.md — Unresolved Problems

```markdown
## CRITICAL BLOCKERS

### ADR-001: BLE Integration (flutter_blue_plus wiring)
**Status:** IN PROGRESS — iOS TestFlight gated  
**Issue:** Background service still using mock timer instead of real flutter_blue_plus BLE scanning  
**Impact:** Cannot test proximity detection on real devices; app does not actually scan for nearby users  
**Root Cause:** flutter_blue_plus integration in background_service.dart incomplete  
**Unblocking Plan:**
1. Replace mock Timer with real BLE stream: `flutterBluePlus.scanResults.listen(...)`
2. Wire RSSI → distance mapping function
3. Device test: run on two iOS devices, verify radar updates on proximity
4. Retest on Android with real Bluetooth hardware
5. TestFlight build gate: pass device test before promoting to beta
**Owner:** Aleksandar  
**ETA:** [DATE]

### Firebase App Check Enforcement
**Status:** ✅ RESOLVED (2026-04-20)
**Resolution:** All 19 Cloud Functions in `tremble-dev` now use `enforceAppCheck: true` and verify `request.appToken`. All dev devices registered with Debug Tokens. 

## MEDIUM BLOCKERS

### Background Mode Permissions (iOS/Android)
**Status:** PENDING  
**Issue:** BLE scanning in background requires special permission flows  
**Impact:** App stops scanning when backgrounded (defeats proximity core mechanic)  
**Unblocking Plan:**
1. iOS: NSBluetoothPeripheralUsageDescription + background modes configuration
2. Android: foreground service setup (notification required)
3. Integration test: app backgrounded for 10 min, radar updates continue
**Owner:** Martin (Android), Aleksandar (iOS)  
**ETA:** [DATE]

## LOW PRIORITY (tracked but not blocking)

- [ ] Localization strings (UI works in English)
- [ ] Analytics (basic Firebase Analytics sufficient for MVP)
- [ ] In-app messaging (fallback to email for critical messages)
```

---

### architecture.md — System Design

```markdown
## Tremble App Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Frontend (iOS/Android)           │
├──────────────────┬──────────────────┬──────────────────────┤
│   Flutter BLE    │   Firestore      │   Location /         │
│   (proximity)    │   (realtime)     │   Permissions        │
└──────────────────┴──────────────────┴──────────────────────┘
         │                    │                    │
         ↓                    ↓                    ↓
┌─────────────────────────────────────────────────────────────┐
│                    Firebase (google-services)               │
├──────────────────┬──────────────────┬──────────────────────┤
│   Firestore      │   Cloud          │   Realtime           │
│   (users,        │   Functions      │   Database           │
│    matches,      │   (matching)     │   (messages)         │
│    messages)     │                  │                      │
└──────────────────┴──────────────────┴──────────────────────┘
         │                    │                    │
         ↓                    ↓                    ↓
┌─────────────────────────────────────────────────────────────┐
│                    External Services                        │
├──────────────────┬──────────────────┬──────────────────────┤
│   Resend         │   Cloudflare R2  │   Upstash Redis      │
│   (emails)       │   (avatars)      │   (cache layer)      │
└──────────────────┴──────────────────┴──────────────────────┘
```

### Data Flow: Proximity Matching

```
1. User A opens app → BLE scanner starts
2. Scanner discovers User B's BLE advertising packet (RSSI -60 dBm)
3. RSSI mapped to distance ≈ 50m
4. Cloud Function triggered: check matching rules (age, gender, distance)
5. If match: create Match document in Firestore
6. Both clients receive realtime notification via Firestore listener
7. Users can open chat (Realtime Database for low-latency messages)
```

### External Services Integration

- **Firebase Firestore:** User profiles, matches, read-only data
- **Firebase Cloud Functions:** Matching algorithm (triggered by proximity)
- **Firebase Realtime Database:** Live messaging (fallback to Firestore if needed)
- **Cloudflare R2:** Avatar image storage (signed URLs)
- **Resend:** Transactional emails (welcome, password reset)
- **Google Cloud Secret Manager:** API keys, database secrets (no hardcoding)

---

## Technology Stack

| Layer | Technology | Version | Locked |
|-------|------------|---------|--------|
| Frontend | Flutter | 3.19+ | pubspec.lock |
| BLE | flutter_blue_plus | 1.31+ | pubspec.lock |
| Navigation | Go Router | 13.0+ | pubspec.lock |
| State | Riverpod | 2.4+ | pubspec.lock |
| Auth | Firebase Auth | - | google-services.json |
| Database | Firestore | - | Firebase Console |
| Messaging | Realtime DB | - | Firebase Console |
| Backend | Cloud Functions | Node.js 20 | package-lock.json |
| Storage | Cloudflare R2 | - | Cloudflare Console |
```

---

### test_strategy.md — Quality Gates

```markdown
## Test Levels

### Level 1: Unit Tests (every commit)
```dart
test('BLE RSSI -60 dBm maps to distance ~50m', () {
  final distance = rssiToDistance(-60, txPower: -55);
  expect(distance, inInclusiveRange(45, 55));
});

test('Matching filter rejects users outside age range', () {
  final user = User(age: 35);
  final match = matchingFilter(user, ageMin: 25, ageMax: 30);
  expect(match, false);
});
```

### Level 2: Integration Tests (before merge)
- Firebase Firestore write/read cycle
- Matching algorithm with synthetic data (10k profiles)
- Authentication flow (sign up → sign in → sign out)
- BLE event ordering (scan start → device found → scan stop)

### Level 3: Device Tests (before TestFlight)
- Run on real iOS device + real Android device (not emulator)
- BLE scanning continues for 30 minutes
- Messaging latency < 2 seconds
- No excessive battery drain (< 5% per hour in background)
- No crashes in error scenarios (no internet, BLE disabled, etc.)

### Level 4: Staging Tests (before production)
- Firebase production rules active (strict permissions)
- App Check enforcement ON (SafetyNet + DeviceCheck required)
- All Cloud Functions deployed to production project
- Smoke test: real user sign up → match created → message sent

**Test Results Required for Merge:**
```
✓ Unit tests pass (100% critical paths)
✓ Integration tests pass
✓ Linter clean (no warnings)
✓ Code coverage ≥ 80% (critical modules)
```

**Test Results Required for TestFlight:**
```
✓ All above + device tests pass
✓ No P1 bugs open
✓ Crash rate < 0.1% (from Firebase Crashlytics)
```
```

---

### blockers.md (continued) — Tracking Format

Every blocker has:
- Status (PENDING / IN PROGRESS / RESOLVED)
- Impact (what cannot be shipped)
- Unblocking steps (exact actions needed)
- Owner (who is responsible)
- ETA (realistic date)

Never delete resolved blockers — move to resolved section with date + resolution note.

---

### security.md — Firebase & Auth

```markdown
## Firebase Security Posture

### Firestore Rules
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      allow read: if request.auth.uid != null; // public profiles only
    }
    match /matches/{docId} {
      allow read, write: if request.auth.uid in resource.data.userIds;
    }
  }
}
```

### Cloud Functions: App Check Enforcement
```javascript
const appCheck = require('@google-cloud/app-check');

exports.createMatch = functions.https.onCall(
  { cors: true, enforceAppCheck: true },
  async (data, context) => {
    if (!context.app) throw new Error('App Check failed');
    // ... matching logic
  }
);
```

### Secret Rotation
- API keys stored in Secret Manager (not repo)
- CI/CD injects at build time (GitHub Secrets)
- Keys rotated quarterly (automated reminder)
- No Firebase keys in git history (scanned by tool)

### Firebase App Check
- iOS: DeviceCheck token
- Android: SafetyNet token
- Enforcement: enabled in Cloud Functions, Firestore rules
- Testing: mock token available in iOS simulator only
```

---

### dependencies.md — Version Pinning

```markdown
## Flutter Dependencies (pubspec.lock)

Critical packages — if version changes, device test required:

| Package | Version | Lock | Reason |
|---------|---------|------|--------|
| flutter_blue_plus | 1.31.0 | YES | BLE core |
| firebase_core | 2.27.0 | YES | Firebase SDK |
| cloud_firestore | 4.16.0 | YES | Database |
| go_router | 13.1.0 | YES | Navigation |
| riverpod | 2.4.0 | YES | State mgmt |

Non-critical packages may float within minor version.

Update strategy:
1. Test upgrade in dev branch
2. Run full device test suite
3. Merge if no regressions
4. Document in CHANGELOG

Never auto-update critical packages in CI.
```

---

### ci_cd.md — Build Pipeline

```markdown
## GitHub Actions Workflow

```yaml
name: Build & Test

on: [push, pull_request]

jobs:
  unit_tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v3

  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter analyze

  build_ios:
    runs-on: macos-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build ios --release
      - uses: ruby/setup-ruby@v1
      - run: fastlane ios build_testflight

  build_android:
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build apk --release --split-per-abi
```

**Merge gates:**
- Unit tests pass
- Linter passes
- Code coverage > 80%
- No P1 bugs assigned

**TestFlight promotion gates:**
- All merge gates + device test pass
- Crash rate < 0.1%
- No unresolved blockers
- Build number incremented
```

---

## LAYER 2: RISK-BASED TASK ROUTING

| Risk | Applies To | Gate |
|------|-----------|------|
| LOW | UI tweaks, string changes, documentation | Unit test pass → merge |
| MEDIUM | New features, Firebase Rules changes, state mgmt | Plan → integrate test → device test → merge |
| HIGH | BLE integration, security changes, payment, deploy | Plan → founder approval → full test suite → code review → merge |

### Escalate to Founder When:

- Touching BLE service or permission flows
- Modifying Firestore Rules or Cloud Functions
- Changing Firebase project configuration (App Check, analytics)
- Adding new external service or API
- Any security-related change (auth, encryption, secrets)
- Introducing technical debt (justified by deadline only)

---

## LAYER 3: THE ORCHESTRAL LOOP

Every task follows this sequence. No steps skipped.

```
1. SYNC
   Read context.md, blockers.md, architecture.md
   Is context.md > 24h old? Re-validate before executing.
   Are any blockers unblocked since last session? Update.

2. HYPOTHESIZE
   What is the real problem?
   Example: "App crashes on iOS" → investigate: BLE permission?
   Firebase Rules? Memory leak? OS version?

3. PLAN
   Risk-based 5-step plan (see template below).
   HIGH risk tasks require founder approval before executing.

4. EXECUTE
   One feature per branch.
   One test per test file.
   Atomic commits (one logical change per commit).

5. TEST & VERIFY
   Unit tests: pass
   Integration tests (if data layer): pass
   Linter: clean
   Device tests (if HIGH risk): pass on 2+ real devices

6. REFLECT
   Did anything go wrong or require a workaround?
   → Add to lessons.md
   Did we take a shortcut?
   → Add to blockers.md (even if low-priority)
   Did we make a significant architectural choice?
   → Write ADR

7. MERGE & CLOSE
   Create PR with descriptive message (reference plan ID)
   Update context.md with session handoff
   Close any resolved blockers
   Commit with: "feat: [description] (#plan-id)"
```

---

## LAYER 4: ARCHITECTURE MAP

Current Tremble project structure:

```
Tremble/Pulse---Dating-app/
├── lib/
│   ├── main.dart
│   ├── models/          ← User, Match, Message data structures
│   ├── services/        ← BLE, Firebase, Auth services
│   ├── screens/         ← UI screens (home, profile, matches)
│   ├── widgets/         ← Reusable UI components
│   └── utils/           ← Helpers (RSSI mapping, validators)
├── test/
│   ├── unit/            ← Service logic tests
│   └── integration/     ← Firestore + Cloud Functions tests
├── ios/                 ← Swift code, Info.plist, permissions
├── android/             ← Kotlin code, AndroidManifest.xml
├── pubspec.yaml         ← Flutter dependencies
├── pubspec.lock         ← Locked versions
├── firebase.json        ← Cloud Functions config
├── functions/           ← Node.js Cloud Functions
│   ├── src/
│   │   ├── matching.ts  ← Proximity-triggered matching
│   │   └── auth.ts      ← User initialization
│   └── package-lock.json
├── tasks/               ← MPC control plane (this file lives here)
│   ├── context.md
│   ├── blockers.md
│   ├── architecture.md
│   └── decisions/
└── .github/workflows/   ← CI/CD (GitHub Actions)
```

---

## LAYER 5: QUALITY STANDARD

### App Quality Score

| Dimension | Weight | Pass Threshold |
|-----------|--------|----------------|
| Unit test coverage (critical paths) | 25% | ≥ 80% |
| Integration tests (Firebase flow) | 25% | 100% pass |
| Device stability (P0 + P1 bugs) | 25% | 0 open |
| Performance (frame rate, memory) | 15% | 60 FPS radar; ≤ 200 MB memory |
| Security (Firebase Rules, App Check) | 10% | Zero misconfigurations |

**Blocker if any dimension fails.**

---

## LAYER 6: BUILD & DEPLOY PIPELINE

```
Feature branch (feature/*)
  ↓
Push → GitHub Actions
  ↓
Unit tests + linter + code analysis
  ↓
If main: build iOS + Android
  ↓
If build succeeds: Fastlane → TestFlight (iOS) + Play Console beta (Android)
  ↓
Manual device testing (if P0 feature)
  ↓
Merge to main only if all gates pass
  ↓
Production promotion (TestFlight → App Store, Play Console → Play Store)
  ↓
Monitor: Firebase Crashlytics + Analytics
```

No direct edits to main. All changes via pull request + CI/CD.

---

## LAYER 7: INCIDENT RESPONSE

Two levels: feature branch regressions vs. production issues.

| Level | Trigger | Response |
|-------|---------|----------|
| L1 | Unit test failure, linter warning, merge conflict | Fix in branch before merge |
| L2 | TestFlight crash, production bug, security issue | Fix immediately, hotfix branch, founder notified |

### L2 Response

1. Create hotfix branch from main
2. Identify root cause (Firebase Crashlytics, logs)
3. Write unit test that reproduces issue
4. Fix code
5. Device test on 2+ devices
6. Merge hotfix
7. Promote TestFlight build
8. Monitor for 24 hours (Crashlytics)
9. Add incident summary to lessons.md

---

## 5-STEP PLAN TEMPLATE

```markdown
Plan ID: YYYYMMDD-[feature-name]
Risk Level: LOW / MEDIUM / HIGH
Founder Approval Required: YES / NO
Branch: feature/[name]

1. OBJECTIVE
   One sentence. What does done look like?
   Example: "BLE scanning starts on app open, finds devices within 500m radius."

2. SCOPE
   Files affected: list files that will change
   Examples: lib/services/ble_service.dart, test/services/ble_service_test.dart
   What does NOT change: (clarify boundaries)

3. STEPS
   Step 1: [atomic action + verification method]
   Example: "Implement BLE scanning in ble_service.dart using flutter_blue_plus. Verify: unit test passes."
   
   Step 2: [continue...]
   Step 3: [continue...]
   Step 4: [continue...]
   Step 5: [final verification + commit]

4. RISKS & TRADEOFFS
   - What could go wrong? (e.g., BLE permission denied on real device)
   - Mitigation: (error handling, fallback)
   - Any debt introduced? → reference blockers.md
   - Any assumptions? (list them)

5. VERIFICATION
   - Unit tests: [list test cases]
   - Integration tests: (if applicable)
   - Device test: (if P0 feature — yes/no + which devices)
   - Linter: (must pass)
   - Code coverage: (target ≥ 80%)
   - Screenshots: (UI changes only)
```

---

## INITIALIZATION

```
Initialize MPC v5 App for Tremble
Role: Technical Co-Founder
Current phase: 5 (matching algorithm)
Active blockers: ADR-001 (BLE), Firebase App Check
```

The system will:
1. Load `/tasks` directory
2. Read current context.md
3. Validate blocker status
4. Identify next 5-step plan before any code
5. Escalate blockers to founder if no ETA
6. Propose merge strategy for in-flight PRs

---

## FINAL OBJECTIVE

The goal is not a proof of concept.

The goal is an app that:
- **Works** — BLE scanning + matching logic functional on real devices
- **Persists** — user data safe in Firestore, no data loss
- **Performs** — 60 FPS radar animation, < 200 MB memory, < 5% battery per hour
- **Complies** — Firebase Rules enforce user privacy, App Check blocks unauthorized access
- **Ships** — TestFlight → App Store + Play Store with zero P0 bugs

This is the product that asks strangers for Bluetooth permission.  
It must earn that trust through reliability and security first.
