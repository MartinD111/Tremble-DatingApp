import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/features/auth/data/auth_repository.dart';

void main() {
  group('AuthUser wave limits', () {
    test('free users at five monthly waves should see the premium paywall', () {
      const user = AuthUser(
        id: 'free-user',
        isPremium: false,
        wavesThisMonth: 5,
      );

      expect(user.hasReachedFreeWaveLimit, isTrue);
    });

    test('premium users are not blocked by the free wave limit', () {
      const user = AuthUser(
        id: 'premium-user',
        isPremium: true,
        wavesThisMonth: 5,
      );

      expect(user.hasReachedFreeWaveLimit, isFalse);
    });

    test('does not read wavesThisMonth from Firestore user data', () {
      final user = AuthUser.fromFirestore(
        'free-user',
        {'wavesThisMonth': 4},
      );

      expect(user.wavesThisMonth, 0);
      expect(user.hasReachedFreeWaveLimit, isFalse);
    });

    test(
        'mutualWaveCounterField produces the correct field name for a known date',
        () {
      // 2026-06-06 UTC → June 2026 → 'mutualWaves_2026_06'
      final field = mutualWaveCounterField(DateTime.utc(2026, 6, 6, 10, 0, 0));
      expect(field, 'mutualWaves_2026_06');
    });

    test('mutualWaveCounterField uses two-digit zero-padded month', () {
      final field = mutualWaveCounterField(DateTime.utc(2026, 1, 15, 8, 0, 0));
      expect(field, 'mutualWaves_2026_01');
    });

    test('maps wavesThisMonth from users/{uid}.mutualWaves_YYYY_MM field', () {
      final user = AuthUser.fromFirestore(
        'free-user',
        const {},
        wavesThisMonth: 5,
      );

      expect(user.wavesThisMonth, 5);
      expect(user.hasReachedFreeWaveLimit, isTrue);
    });

    test('pro users at twenty monthly waves should see limit reached', () {
      const userUnder = AuthUser(
        id: 'pro-user',
        isPremium: true,
        wavesThisMonth: 19,
      );
      const userLimit = AuthUser(
        id: 'pro-user',
        isPremium: true,
        wavesThisMonth: 20,
      );
      const userOver = AuthUser(
        id: 'pro-user',
        isPremium: true,
        wavesThisMonth: 21,
      );

      expect(userUnder.hasReachedProWaveLimit, isFalse);
      expect(userLimit.hasReachedProWaveLimit, isTrue);
      expect(userOver.hasReachedProWaveLimit, isTrue);
    });

    test('hasReachedWaveLimit delegates correctly based on premium status', () {
      const freeUnder = AuthUser(
        id: 'free-user',
        isPremium: false,
        wavesThisMonth: 4,
      );
      const freeLimit = AuthUser(
        id: 'free-user',
        isPremium: false,
        wavesThisMonth: 5,
      );
      const proUnder = AuthUser(
        id: 'pro-user',
        isPremium: true,
        wavesThisMonth: 19,
      );
      const proLimit = AuthUser(
        id: 'pro-user',
        isPremium: true,
        wavesThisMonth: 20,
      );

      expect(freeUnder.hasReachedWaveLimit, isFalse);
      expect(freeLimit.hasReachedWaveLimit, isTrue);
      expect(proUnder.hasReachedWaveLimit, isFalse);
      expect(proLimit.hasReachedWaveLimit, isTrue);
    });
  });

  group('AuthUser API payload', () {
    test('serializes onboarding fields for the Cloud Function contract', () {
      const user = AuthUser(
        id: 'onboarding-user',
        nicotineUse: ['vape'],
        hobbies: [
          {'id': 'running', 'label': 'Running'},
          {'id': 'music', 'label': 'Music'},
        ],
      );

      final payload = user.toApiPayload();

      expect(payload['hobbies'], ['running', 'music']);
      expect(payload['nicotineUse'], 'vape');
      expect(payload.containsKey('nicotineFilter'), isFalse);
    });
  });
}
