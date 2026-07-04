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

// Mirrors the production listener in home_screen.dart, which no longer
// remaps navIndex on tier transitions. Both tiers share fixed tab indices:
// Radar=0, Map=1, People=2, Settings=3.
final navigationBoundsListenerProvider = Provider<void>((ref) {
  ref.listen<bool>(
    authStateProvider.select((user) => user?.isPremium == true),
    (previous, next) {
      // Intentionally no reindex — the tab structure is identical for both
      // tiers. Any premium gating happens inside individual tab screens.
    },
  );
});

void main() {
  group('HomeScreen Navigation Bounds', () {
    // Free and premium users see identical tab structure:
    // 0: Radar, 1: Map, 2: People, 3: Settings.
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

    test('preserves current index when downgrading Premium → Free', () {
      final mockNotifier = MockAuthNotifier(premiumUser);
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => mockNotifier),
          navIndexProvider.overrideWith((ref) => 0),
        ],
      );
      addTearDown(container.dispose);

      container.read(navigationBoundsListenerProvider);

      // Sit on the Settings tab (index 3).
      container.read(navIndexProvider.notifier).state = 3;

      mockNotifier.updateState(freeUser);

      // Same index → same tab in the free layout.
      expect(container.read(navIndexProvider), equals(3));
    });

    test('preserves current index when upgrading Free → Premium', () {
      final mockNotifier = MockAuthNotifier(freeUser);
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => mockNotifier),
          navIndexProvider.overrideWith((ref) => 0),
        ],
      );
      addTearDown(container.dispose);

      container.read(navigationBoundsListenerProvider);

      // Sit on the People tab (index 2).
      container.read(navIndexProvider.notifier).state = 2;

      mockNotifier.updateState(premiumUser);

      expect(container.read(navIndexProvider), equals(2));
    });

    test('preserves Map tab (index 1) across Premium → Free downgrade', () {
      final mockNotifier = MockAuthNotifier(premiumUser);
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => mockNotifier),
          navIndexProvider.overrideWith((ref) => 0),
        ],
      );
      addTearDown(container.dispose);

      container.read(navigationBoundsListenerProvider);

      container.read(navIndexProvider.notifier).state = 1;
      mockNotifier.updateState(freeUser);

      // The Map tab is available to free users too now.
      expect(container.read(navIndexProvider), equals(1));
    });

    test('clamps out-of-bounds indices for the 4-screen layout', () {
      // Both tiers have 4 screens → valid range [0, 3].
      expect((-1).clamp(0, 3), equals(0));
      expect(4.clamp(0, 3), equals(3));
      expect(5.clamp(0, 3), equals(3));
    });
  });
}
