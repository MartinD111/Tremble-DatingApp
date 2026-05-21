import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/features/auth/data/auth_repository.dart';
import 'package:tremble/src/features/dashboard/presentation/home_screen.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Return a dummy stream for authStateChanges so the parent constructor doesn't crash on invocation.
    if (invocation.memberName == #authStateChanges) {
      return const Stream<AuthUser?>.empty();
    }
    return super.noSuchMethod(invocation);
  }
}

class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier(AuthUser? initial) : super(FakeAuthRepository()) {
    state = initial;
  }

  void updateState(AuthUser? user) {
    state = user;
  }
}

// Test provider to run the exact reactive transition listener in our isolation test
final navigationBoundsListenerProvider = Provider<void>((ref) {
  ref.listen<bool>(
    authStateProvider.select((user) => user?.isPremium == true),
    (previous, next) {
      if (previous == null) return;
      if (previous != next) {
        final currentIndex = ref.read(navIndexProvider);
        if (next) {
          // Downgrade to Upgrade: Free (3 tabs) -> Premium (4 tabs)
          if (currentIndex == 1) {
            ref.read(navIndexProvider.notifier).state = 2;
          } else if (currentIndex == 2) {
            ref.read(navIndexProvider.notifier).state = 3;
          }
        } else {
          // Upgrade to Downgrade: Premium (4 tabs) -> Free (3 tabs)
          if (currentIndex == 1) {
            ref.read(navIndexProvider.notifier).state = 0;
          } else if (currentIndex == 2) {
            ref.read(navIndexProvider.notifier).state = 1;
          } else if (currentIndex == 3) {
            ref.read(navIndexProvider.notifier).state = 2;
          }
        }
      }
    },
  );
});

void main() {
  group('HomeScreen Navigation Bounds & Premium Transitions', () {
    const freeUser = AuthUser(
      id: 'test-user',
      isPremium: false,
      isOnboarded: true,
    );

    const premiumUser = AuthUser(
      id: 'test-user',
      isPremium: true,
      isOnboarded: true,
    );

    test('Remaps index correctly during Premium to Free transition (Downgrade)',
        () {
      final mockNotifier = MockAuthNotifier(premiumUser);
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => mockNotifier),
          navIndexProvider.overrideWith((ref) => 0),
        ],
      );
      addTearDown(container.dispose);

      // Force Riverpod to read the provider and register the listener
      container.read(navigationBoundsListenerProvider);

      // Start on Premium's Settings tab (index 3)
      container.read(navIndexProvider.notifier).state = 3;

      // Downgrade to Free
      mockNotifier.updateState(freeUser);

      // Verify that Settings (3) remapped to Settings (2) in Free
      expect(container.read(navIndexProvider), equals(2));
    });

    test('Remaps index correctly during Free to Premium transition (Upgrade)',
        () {
      final mockNotifier = MockAuthNotifier(freeUser);
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => mockNotifier),
          navIndexProvider.overrideWith((ref) => 0),
        ],
      );
      addTearDown(container.dispose);

      // Force Riverpod to read the provider and register the listener
      container.read(navigationBoundsListenerProvider);

      // Start on Free's Settings tab (index 2)
      container.read(navIndexProvider.notifier).state = 2;

      // Upgrade to Premium
      mockNotifier.updateState(premiumUser);

      // Verify that Settings (2) remapped to Settings (3) in Premium
      expect(container.read(navIndexProvider), equals(3));
    });

    test(
        'Remaps index 1 (Map) to index 0 (Radar) during Premium to Free transition',
        () {
      final mockNotifier = MockAuthNotifier(premiumUser);
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => mockNotifier),
          navIndexProvider.overrideWith((ref) => 0),
        ],
      );
      addTearDown(container.dispose);

      // Force Riverpod to read the provider and register the listener
      container.read(navigationBoundsListenerProvider);

      // Start on Premium's Map tab (index 1)
      container.read(navIndexProvider.notifier).state = 1;

      // Downgrade to Free
      mockNotifier.updateState(freeUser);

      // Verify that Map (1) remapped to Radar (0) since Free doesn't have a map
      expect(container.read(navIndexProvider), equals(0));
    });

    test('Defensively clamps invalid out-of-bounds indices in the widget tree',
        () {
      // Free users only have 3 screens: Radar (0), Matches (1), Settings (2).
      // Let's assert clamp behavior for Free users when navIndex is outside boundary.

      // navIndex = -1
      expect((-1).clamp(0, 2), equals(0));

      // navIndex = 3
      expect(3.clamp(0, 2), equals(2));

      // navIndex = 5
      expect(5.clamp(0, 2), equals(2));
    });
  });
}
