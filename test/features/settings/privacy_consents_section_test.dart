import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tremble/src/features/auth/data/auth_repository.dart';
import 'package:tremble/src/features/settings/presentation/widgets/privacy_consents_section.dart';

/// Fake repository — captures the category argument passed to
/// [withdrawArt9Consent] so the widget test can assert the callable is
/// invoked with the correct category. Server-side FieldValue.delete is
/// covered by the CF test `withdrawArt9Consent` in
/// functions/src/__tests__/users.test.ts — this test proves the client
/// binds to that callable, not that the server deletes the field
/// (which requires the CF suite, not a Flutter widget test).
class _RecordingAuthRepository implements AuthRepository {
  final List<String> withdrawnCategories = [];

  @override
  Future<void> withdrawArt9Consent(String category) async {
    withdrawnCategories.add(category);
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
  required AuthUser user,
  required _RecordingAuthRepository repo,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      authStateProvider.overrideWith((ref) => _SeededAuthNotifier(user, repo)),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: PrivacyConsentsSection(),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrivacyConsentsSection', () {
    testWidgets(
        'renders all three tiles and reflects granted / withdrawn state',
        (tester) async {
      final user = AuthUser(
        id: 'u1',
        sexualOrientationConsent: true,
        sexualOrientationConsentVersion: 'v1',
        sexualOrientationConsentAt: DateTime.utc(2026, 7, 14),
        religionConsent: false,
        religionConsentVersion: 'v1',
        religionConsentAt: DateTime.utc(2026, 7, 14),
        ethnicityConsent: null,
      );
      await tester.pumpWidget(
        _makeApp(user: user, repo: _RecordingAuthRepository()),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('privacy-consents-orientation')),
          findsOneWidget);
      expect(
          find.byKey(const Key('privacy-consents-religion')), findsOneWidget);
      expect(
          find.byKey(const Key('privacy-consents-ethnicity')), findsOneWidget);

      // Orientation is granted → withdraw button visible for that tile.
      expect(
        find.byKey(const Key('privacy-consents-orientation-withdraw')),
        findsOneWidget,
      );
      // Religion is withdrawn → no withdraw button.
      expect(
        find.byKey(const Key('privacy-consents-religion-withdraw')),
        findsNothing,
      );
      // Ethnicity never asked → no withdraw button.
      expect(
        find.byKey(const Key('privacy-consents-ethnicity-withdraw')),
        findsNothing,
      );
    });

    testWidgets(
        'confirming withdrawal invokes repository with the correct category',
        (tester) async {
      final repo = _RecordingAuthRepository();
      final user = AuthUser(
        id: 'u1',
        sexualOrientationConsent: true,
        sexualOrientationConsentVersion: 'v1',
        sexualOrientationConsentAt: DateTime.utc(2026, 7, 14),
      );
      await tester.pumpWidget(_makeApp(user: user, repo: repo));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('privacy-consents-orientation-withdraw')),
      );
      await tester.pumpAndSettle();

      // Confirmation dialog is open — hit the "Yes, withdraw" button.
      expect(
        find.byKey(const Key('privacy-consents-confirm-withdraw')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const Key('privacy-consents-confirm-withdraw')),
      );
      await tester.pumpAndSettle();

      expect(repo.withdrawnCategories, ['orientation']);
    });

    testWidgets(
        'cancelling the confirmation dialog does NOT invoke the repository',
        (tester) async {
      final repo = _RecordingAuthRepository();
      final user = AuthUser(
        id: 'u1',
        religionConsent: true,
        religionConsentVersion: 'v1',
        religionConsentAt: DateTime.utc(2026, 7, 14),
      );
      await tester.pumpWidget(_makeApp(user: user, repo: repo));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('privacy-consents-religion-withdraw')),
      );
      await tester.pumpAndSettle();

      // Tap Cancel (any button that is not the confirm one).
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repo.withdrawnCategories, isEmpty);
    });
  });
}
