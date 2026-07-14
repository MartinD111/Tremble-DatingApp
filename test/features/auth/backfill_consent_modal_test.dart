import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tremble/src/features/auth/data/auth_repository.dart';
import 'package:tremble/src/features/auth/presentation/backfill_consent_modal.dart';

/// Records the (category, granted) pair for every setArt9Consent call so
/// the tests can assert accept → true and decline → false without
/// touching the real Cloud Function.
class _RecordingRepository implements AuthRepository {
  final List<({String category, bool granted})> decisions = [];
  Object? nextError;

  @override
  Future<void> setArt9Consent(String category, {required bool granted}) async {
    if (nextError != null) throw nextError!;
    decisions.add((category: category, granted: granted));
  }

  @override
  Stream<AuthUser?> authStateChanges() => const Stream<AuthUser?>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SeededAuthNotifier extends AuthNotifier {
  _SeededAuthNotifier(AuthUser? initial, AuthRepository repo) : super(repo) {
    state = initial;
  }
}

Widget _makeApp({
  required AuthUser? user,
  required _RecordingRepository repo,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      authStateProvider.overrideWith((ref) => _SeededAuthNotifier(user, repo)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: BackfillConsentGate(
          child: const Center(child: Text('BEHIND_GATE')),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackfillConsentGate', () {
    testWidgets('does NOT overlay the modal when consent is already granted',
        (tester) async {
      final user = AuthUser(
        id: 'u1',
        isOnboarded: true,
        sexualOrientationConsent: true,
        sexualOrientationConsentVersion: 'v1',
        sexualOrientationConsentAt: DateTime.utc(2026, 7, 14),
      );
      await tester.pumpWidget(
        _makeApp(user: user, repo: _RecordingRepository()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BackfillConsentModal), findsNothing);
      expect(find.text('BEHIND_GATE'), findsOneWidget);
    });

    testWidgets(
        'does NOT overlay the modal when consent is already explicitly false',
        (tester) async {
      final user = AuthUser(
        id: 'u1',
        isOnboarded: true,
        sexualOrientationConsent: false,
        sexualOrientationConsentVersion: 'v1',
        sexualOrientationConsentAt: DateTime.utc(2026, 7, 14),
      );
      await tester.pumpWidget(
        _makeApp(user: user, repo: _RecordingRepository()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BackfillConsentModal), findsNothing);
    });

    testWidgets('does NOT overlay the modal while the user is mid-onboarding',
        (tester) async {
      // Registration flow collects the consent itself via consent_step.
      // If the modal fired on top of it, the two would fight for state.
      final user = AuthUser(
        id: 'u1',
        isOnboarded: false,
        sexualOrientationConsent: null,
      );
      await tester.pumpWidget(
        _makeApp(user: user, repo: _RecordingRepository()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BackfillConsentModal), findsNothing);
    });

    testWidgets(
        'overlays the modal when isOnboarded=true and consent is null (pre-migration)',
        (tester) async {
      final user = AuthUser(
        id: 'u1',
        isOnboarded: true,
        sexualOrientationConsent: null,
      );
      await tester.pumpWidget(
        _makeApp(user: user, repo: _RecordingRepository()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BackfillConsentModal), findsOneWidget);
      expect(
        find.byKey(const Key('backfill-consent-accept')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('backfill-consent-decline')),
        findsOneWidget,
      );
    });

    testWidgets('Accept writes consent=true and dismisses the modal',
        (tester) async {
      final repo = _RecordingRepository();
      final user = AuthUser(
        id: 'u1',
        isOnboarded: true,
        sexualOrientationConsent: null,
      );
      await tester.pumpWidget(_makeApp(user: user, repo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('backfill-consent-accept')));
      await tester.pumpAndSettle();

      expect(repo.decisions, [(category: 'orientation', granted: true)]);
      expect(find.byType(BackfillConsentModal), findsNothing);
    });

    testWidgets('Decline writes consent=false and dismisses the modal',
        (tester) async {
      final repo = _RecordingRepository();
      final user = AuthUser(
        id: 'u1',
        isOnboarded: true,
        sexualOrientationConsent: null,
      );
      await tester.pumpWidget(_makeApp(user: user, repo: repo));
      await tester.pumpAndSettle();

      await tester
          .ensureVisible(find.byKey(const Key('backfill-consent-decline')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('backfill-consent-decline')));
      await tester.pumpAndSettle();

      expect(repo.decisions, [(category: 'orientation', granted: false)]);
      expect(find.byType(BackfillConsentModal), findsNothing);
    });

    testWidgets('server error leaves the modal up so the user can retry',
        (tester) async {
      final repo = _RecordingRepository()..nextError = Exception('offline');
      final user = AuthUser(
        id: 'u1',
        isOnboarded: true,
        sexualOrientationConsent: null,
      );
      await tester.pumpWidget(_makeApp(user: user, repo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('backfill-consent-accept')));
      await tester.pumpAndSettle();

      // No decision recorded, modal still there.
      expect(repo.decisions, isEmpty);
      expect(find.byType(BackfillConsentModal), findsOneWidget);
    });
  });
}
