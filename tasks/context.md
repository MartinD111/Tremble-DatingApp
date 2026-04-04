## Session State — 2026-04-04
- Session ID: RegFlow-BugFix-2026-04-04
- Active Task: Registration flow bug fixes (Bugs 1-3)
- Environment: Dev (tremble-dev)
- Modified Files:
    - lib/src/core/router.dart
    - lib/src/features/auth/presentation/registration_flow.dart
- Open Problems:
    - D-03: Consent screen reimplementation (consent_service.dart + permission_gate_screen.dart missing)
    - D-09: Firestore triggers (onBleProximity, onUserDocCreated) still in us-central1
    - D-11: Deprecated androidProvider/appleProvider in main.dart
    - D-12: Firestore TTL policies unconfirmed in Firebase Console
    - D-13: GOOGLE_WEB_CLIENT_ID unconfirmed in prod Functions config
- System Status: flutter analyze 2 info warnings only (D-11, pre-existing). 0 errors.
- Last Release: Phase 5 AppCheck Complete

## Session Handoff (For Aleksandar)
- Completed:
    - Bug 1 FIXED: router.dart — GoRouter was recreated on every authStateProvider change (new GoRouter = full nav reset from initialLocation). Replaced ref.watch with _RouterNotifier (ChangeNotifier + refreshListenable). Router now created once; redirect re-evaluates on auth change via notifyListeners(). Eliminates 2-second jarring redirect.
    - Bug 2 FIXED: registration_flow.dart _nextPage() — Google users' displayName pre-filled _nameController, causing ternary to jump to Gender (7) skipping Name (6). Now always jumps to Name (6) from Birthday (4) for authenticated users.
    - Bug 3 FIXED: registration_flow.dart _nextPage()/_prevPage() — animateToPage() slid through intermediate pages (email/password, name both visible during animation). Replaced with jumpToPage() for skip branches — instant, no intermediate pages rendered.
    - Page-index comment corrected (was wrong, now matches actual PageView children order).
- Blocked:
    - D-13 (HIGH/Phase 5): GOOGLE_WEB_CLIENT_ID not confirmed in prod Functions config
    - D-09 (Medium/Phase 5): Firestore triggers still in us-central1
    - D-12 (Medium/Phase 5): TTL policies not confirmed active
    - D-03 (Medium/Phase 6): consent_service.dart + permission_gate_screen.dart need reimplementation
- Next Action: Test registration flow on device — run `flutter run --flavor dev --dart-define=FLAVOR=dev`. Test: (1) cold open with previously-authenticated unonboarded user, (2) Google sign-in name confirmation step, (3) no page overlap during navigation.
- Staleness Rule: If this block is >48h old, re-validate before executing.
