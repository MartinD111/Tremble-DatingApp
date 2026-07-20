import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tremble/src/features/auth/data/auth_repository.dart';
import 'package:tremble/src/features/matches/data/match_repository.dart';
import 'package:tremble/src/features/profile/presentation/basic_match_profile_screen.dart';

import '../../support/network_image_mock.dart';

class _FakeAuthRepo implements AuthRepository {
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

// Custom hobby ids (unknown to HobbyData) so parseHobbies preserves the names
// verbatim, keeping the assertions deterministic.
MatchProfile _match() => MatchProfile.fromApi({
      'id': 'p1',
      'name': 'Nika',
      'age': 29,
      'photoUrls': ['https://cdn.test/nika.jpg'],
      'hobbies': [
        {'id': 'custom_hike_xyz', 'name': 'Hiking'},
        {'id': 'custom_swim_xyz', 'name': 'Swimming'},
      ],
      'hasMutualWave': true,
    });

Widget _app(Widget child, {AuthUser? user}) => ProviderScope(
      overrides: [
        authStateProvider
            .overrideWith((ref) => _SeededAuthNotifier(user, _FakeAuthRepo())),
      ],
      child: MaterialApp(home: child),
    );

void main() {
  testWidgets(
      'basic card shows name, age, up to 3 hobbies and the See full profile CTA',
      (tester) async {
    await mockNetworkImages(() async {
      await tester.pumpWidget(_app(BasicMatchProfileScreen(match: _match())));
      await tester.pump();

      expect(find.text('Nika'), findsOneWidget);
      expect(find.textContaining('29'), findsWidgets);
      expect(find.text('Hiking'), findsOneWidget);
      expect(find.text('Swimming'), findsOneWidget);
      // The upgrade CTA — the full profile card stays Premium-gated.
      expect(find.text('See full profile'), findsOneWidget);
    });
  });

  testWidgets('the See full profile CTA is interactive (wired to onTap)',
      (tester) async {
    await mockNetworkImages(() async {
      await tester.pumpWidget(_app(BasicMatchProfileScreen(match: _match())));
      await tester.pump();

      // The CTA wraps the label in an InkWell whose onTap opens the paywall
      // (PremiumPaywallBottomSheet.show). Assert it is present and live rather
      // than driving the unconfigured RevenueCat controller (which never
      // settles in a test harness).
      final inkWell = tester.widget<InkWell>(
        find.ancestor(
          of: find.text('See full profile'),
          matching: find.byType(InkWell),
        ),
      );
      expect(inkWell.onTap, isNotNull);
    });
  });
}
