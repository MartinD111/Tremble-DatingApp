import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:tremble/src/features/auth/data/auth_repository.dart';
import 'package:tremble/src/features/match/application/match_service.dart';
import 'package:tremble/src/features/match/domain/match.dart';
import 'package:tremble/src/features/match/presentation/match_reveal_screen.dart';
import 'package:tremble/src/features/matches/data/match_repository.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #authStateChanges) {
      return const Stream<AuthUser?>.empty();
    }
    return super.noSuchMethod(invocation);
  }
}

class _MockAuthNotifier extends AuthNotifier {
  _MockAuthNotifier(AuthUser? initial) : super(_FakeAuthRepository()) {
    state = initial;
  }
}

class _MockUser implements User {
  @override
  final String uid = 'me';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockFirebaseAuth implements FirebaseAuth {
  @override
  final User? currentUser = _MockUser();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  // BUG-MATCH-PAGE-LAYOUT (Session 55): on the reveal / "We have a match"
  // page the circular partner photo was drawn OVER the hobby pills, because the
  // hobby band (top-anchored Positioned) and the vertically-centered avatar
  // (Positioned.fill) were independent Stack layers with no vertical
  // coordination. The hobby chips must sit fully ABOVE the photo.
  testWidgets('hobby chips render fully above the partner photo (no overlap)',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2340); // ~360x780 logical
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final match = Match(
      id: 'm1',
      userIds: const ['me', 'partner_456'],
      createdAt: DateTime(2026, 7, 20),
      seenBy: const [],
      status: 'pending',
      gestures: const {'me': true, 'partner_456': true},
    );
    final partner = MatchProfile(
      id: 'partner_456',
      name: 'Sarah',
      age: 24,
      imageUrl: '',
      hobbies: const [
        {'id': 'hiking', 'name': 'Hiking'},
        {'id': 'swimming', 'name': 'Swimming'},
      ],
      bio: '',
      photoUrls: const [],
    );
    const me = AuthUser(
      id: 'me',
      name: 'Me',
      isPremium: false,
      isOnboarded: true,
      isEmailVerified: true,
      hobbies: [
        {'id': 'hiking', 'name': 'Hiking'},
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(_MockFirebaseAuth()),
          activeMatchesStreamProvider
              .overrideWith((ref) => const Stream.empty()),
          authStateProvider.overrideWith((ref) => _MockAuthNotifier(me)),
          partnerMatchProfileProvider('partner_456')
              .overrideWith((ref) => AsyncData(partner)),
        ],
        child: MaterialApp(home: MatchRevealScreen(match: match)),
      ),
    );

    // Let the reveal animation settle to its final resting layout.
    await tester.pump(const Duration(seconds: 3));

    final hobbies = find.byKey(const Key('reveal-hobbies'));
    final avatar = find.byKey(const Key('reveal-avatar'));
    expect(hobbies, findsOneWidget);
    expect(avatar, findsOneWidget);

    final hobbiesRect = tester.getRect(hobbies);
    final avatarRect = tester.getRect(avatar);
    expect(
      hobbiesRect.bottom,
      lessThanOrEqualTo(avatarRect.top),
      reason: 'hobby chips must sit fully above the partner photo '
          '(hobbies.bottom=${hobbiesRect.bottom}, avatar.top=${avatarRect.top})',
    );
  });
}
