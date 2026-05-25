# Tremble Mobile App — Gemini Context

## Active Mission: Phase E — Pulse Intercept (F12)
- **Status**: In progress
- **Goal**: Implement user-initiated ephemeral contact/photo sharing during Trembling Windows.
- **Privacy**: Zero-chat policy. No free-text chatrooms. All communication is button-triggered.
- **TTL**: F12 interactions must use `expiresAt` set to now + 10 minutes.

## Control Plane
- **Context**: `tasks/context.md`
- **Master Plan**: `tasks/MASTER_PLAN.md`
- **Lessons**: `tasks/lessons.md`
- **Active Blockers**: `tasks/blockers.md`

Read `tasks/context.md` and `tasks/blockers.md` before code changes. If `/tasks` is missing, stop and report `Control Plane Offline`.

## Active Blockers as of 2026-05-25
- `BLOCKER-003`: RevenueCat / Legal Setup blocks Phase 8 paywall work.
- `BLOCKER-005`: iOS dev provisioning for `com.pulse` blocks physical iPhone dev deploy.
- `BLOCKER-006`: Photo upload / onboarding E2E still needs real-image device verification.
- `BLOCKER-007`: Legal web pages are not confirmed live.

## Environment Rules
- Dev Firebase project: `tremble-dev`
- Prod Firebase project: `am---dating-app`
- Dev bundle ID: `com.pulse`
- Prod bundle ID: `tremble.dating.app`

Never mix dev and prod resources. Cross-contamination is a critical failure.

## Safe Local Commands
Run Flutter only with an explicit flavor:

```bash
flutter run --flavor dev --dart-define=FLAVOR=dev
flutter test --coverage --dart-define=FLAVOR=dev
flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev
```

Never run unflavored `flutter run` or `flutter build`.

## Local Pre-Commit Gate
The local Git hook `.git/hooks/pre-commit` runs:

```bash
flutter pub get --offline || flutter pub get
dart format --set-exit-if-changed .
flutter analyze --no-fatal-infos
flutter test --coverage --dart-define=FLAVOR=dev
cd functions
npm ci --silent
npm run lint
npm run build
npm test -- --passWithNoTests
```

If missing after a fresh clone, recreate it from `BOOTSTRAP.md` and run:

```bash
chmod +x .git/hooks/pre-commit
.git/hooks/pre-commit
```

## Escalate Before Touching
- `GoogleService-Info.plist`
- `google-services.json`
- `AndroidManifest.xml`
- `Info.plist`
- Firebase Security Rules
- Cloud Functions deployment to prod
- Core Firebase Auth logic

## Current Next Actions
1. Verify in Firebase Console that newly-created prod functions from the latest deploy are intentional.
2. Continue Phase E only through the control-plane workflow.
3. Keep App Check enforcement verified for every new Cloud Function.
