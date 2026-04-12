import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/features/auth/data/auth_repository.dart';
import 'package:tremble/src/core/router.dart' show computeRedirect;

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const _testUser = AuthUser(id: 'uid-123', email: 'test@test.com');
const _onboardedUser = AuthUser(
  id: 'uid-123',
  email: 'test@test.com',
  isOnboarded: true,
  name: 'Test User', // needed so ghost-onboarded guard (name==null) does not fire
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('computeRedirect — unauthenticated', () {
    test('uninitialized → null (hold)', () {
      expect(
        computeRedirect(
          isInitialized: false,
          authUser: null,
          profileStatus: const AsyncLoading(),
          hasConsent: false,
          currentPath: '/',
        ),
        isNull,
      );
    });

    test('no user, at / → redirect to /login', () {
      expect(
        computeRedirect(
          isInitialized: true,
          authUser: null,
          profileStatus: const AsyncLoading(),
          hasConsent: false,
          currentPath: '/',
        ),
        equals('/login'),
      );
    });

    test('no user, already at /login → null (stay)', () {
      expect(
        computeRedirect(
          isInitialized: true,
          authUser: null,
          profileStatus: const AsyncLoading(),
          hasConsent: false,
          currentPath: '/login',
        ),
        isNull,
      );
    });

    test('no user, at /onboarding → null (allow — registration flow)', () {
      expect(
        computeRedirect(
          isInitialized: true,
          authUser: null,
          profileStatus: const AsyncLoading(),
          hasConsent: false,
          currentPath: '/onboarding',
        ),
        isNull,
      );
    });

    // Stale-session regression: profileStatusProvider may still hold a
    // previously-cached AsyncData from a prior session. Even if it reports
    // isOnboarded=true, null authUser must always return /login.
    test('no user, stale profileStatus=ready(onboarded=true) → /login', () {
      expect(
        computeRedirect(
          isInitialized: true,
          authUser: null,
          profileStatus: const AsyncData(
            ProfileStatus.ready(isOnboarded: true),
          ),
          hasConsent: true,
          currentPath: '/',
        ),
        equals('/login'),
      );
    });

    test('no user, stale profileStatus=ready(onboarded=true), at /settings → /login', () {
      expect(
        computeRedirect(
          isInitialized: true,
          authUser: null,
          profileStatus: const AsyncData(
            ProfileStatus.ready(isOnboarded: true),
          ),
          hasConsent: true,
          currentPath: '/settings',
        ),
        equals('/login'),
      );
    });
  });

  group('computeRedirect — authenticated, profile loading', () {
    test('profile status isLoading → null (hold — splash)', () {
      expect(
        computeRedirect(
          isInitialized: true,
          authUser: _testUser,
          profileStatus: const AsyncLoading(),
          hasConsent: false,
          currentPath: '/',
        ),
        isNull,
      );
    });
  });

  group('computeRedirect — authenticated, profile not found', () {
    test('doc not found → redirect to /onboarding (social user resuming)', () {
      expect(
        computeRedirect(
          isInitialized: true,
          authUser: _testUser,
          profileStatus:
              const AsyncData(ProfileStatus.notFound()),
          hasConsent: false,
          currentPath: '/',
          isSocialUser: true,
        ),
        equals('/onboarding'),
      );
    });

    test('doc not found, stale unverified email session → redirect to /login', () {
      expect(
        computeRedirect(
          isInitialized: true,
          authUser: _testUser,
          profileStatus:
              const AsyncData(ProfileStatus.notFound()),
          hasConsent: false,
          currentPath: '/',
          isSocialUser: false,
          isEmailVerified: false,
        ),
        equals('/login'),
      );
    });

    test('doc not found, already at /onboarding → null (stay)', () {
      expect(
        computeRedirect(
          isInitialized: true,
          authUser: _testUser,
          profileStatus:
              const AsyncData(ProfileStatus.notFound()),
          hasConsent: false,
          currentPath: '/onboarding',
        ),
        isNull,
      );
    });
  });

  group('computeRedirect — authenticated, isOnboarded=false', () {
    test('doc exists, isOnboarded=false → redirect to /onboarding (verified user)', () {
      expect(
        computeRedirect(
          isInitialized: true,
          authUser: _testUser,
          profileStatus: const AsyncData(
            ProfileStatus.ready(isOnboarded: false),
          ),
          hasConsent: false,
          currentPath: '/',
          isEmailVerified: true,
        ),
        equals('/onboarding'),
      );
    });

    test('doc exists, isOnboarded=false, at /settings → /onboarding (verified user)', () {
      expect(
        computeRedirect(
          isInitialized: true,
          authUser: _testUser,
          profileStatus: const AsyncData(
            ProfileStatus.ready(isOnboarded: false),
          ),
          hasConsent: false,
          currentPath: '/settings',
          isEmailVerified: true,
        ),
        equals('/onboarding'),
      );
    });

    test('doc exists, isOnboarded=false, stale unverified session → /login', () {
      expect(
        computeRedirect(
          isInitialized: true,
          authUser: _testUser,
          profileStatus: const AsyncData(
            ProfileStatus.ready(isOnboarded: false),
          ),
          hasConsent: false,
          currentPath: '/',
          isSocialUser: false,
          isEmailVerified: false,
        ),
        equals('/login'),
      );
    });
  });

  group('computeRedirect — onboarded, no consent', () {
    test('isOnboarded=true, no consent → /permission-gate', () {
      expect(
        computeRedirect(
          isInitialized: true,
          authUser: _onboardedUser,
          profileStatus: const AsyncData(
            ProfileStatus.ready(isOnboarded: true),
          ),
          hasConsent: false,
          currentPath: '/',
        ),
        equals('/permission-gate'),
      );
    });

    test('already at /permission-gate, no consent → null (stay)', () {
      expect(
        computeRedirect(
          isInitialized: true,
          authUser: _onboardedUser,
          profileStatus: const AsyncData(
            ProfileStatus.ready(isOnboarded: true),
          ),
          hasConsent: false,
          currentPath: '/permission-gate',
        ),
        isNull,
      );
    });
  });

  group('computeRedirect — fully onboarded with consent', () {
    test('/permission-gate after consent granted → redirect to /', () {
      expect(
        computeRedirect(
          isInitialized: true,
          authUser: _onboardedUser,
          profileStatus: const AsyncData(
            ProfileStatus.ready(isOnboarded: true),
          ),
          hasConsent: true,
          currentPath: '/permission-gate',
        ),
        equals('/'),
      );
    });

    test('at /login while fully onboarded → redirect to /', () {
      expect(
        computeRedirect(
          isInitialized: true,
          authUser: _onboardedUser,
          profileStatus: const AsyncData(
            ProfileStatus.ready(isOnboarded: true),
          ),
          hasConsent: true,
          currentPath: '/login',
        ),
        equals('/'),
      );
    });

    test('at /onboarding while fully onboarded → redirect to /', () {
      expect(
        computeRedirect(
          isInitialized: true,
          authUser: _onboardedUser,
          profileStatus: const AsyncData(
            ProfileStatus.ready(isOnboarded: true),
          ),
          hasConsent: true,
          currentPath: '/onboarding',
        ),
        equals('/'),
      );
    });

    test('at / while fully onboarded → null (stay)', () {
      expect(
        computeRedirect(
          isInitialized: true,
          authUser: _onboardedUser,
          profileStatus: const AsyncData(
            ProfileStatus.ready(isOnboarded: true),
          ),
          hasConsent: true,
          currentPath: '/',
        ),
        isNull,
      );
    });

    test('at /settings while fully onboarded → null (stay)', () {
      expect(
        computeRedirect(
          isInitialized: true,
          authUser: _onboardedUser,
          profileStatus: const AsyncData(
            ProfileStatus.ready(isOnboarded: true),
          ),
          hasConsent: true,
          currentPath: '/settings',
        ),
        isNull,
      );
    });
  });

  group('computeRedirect — ghost-onboarded guard', () {
    // isOnboarded=true in Firestore but name+photos are empty.
    // This happens when the dev-mode Cloud Function fallback wrote only the
    // flag and not the full payload (now fixed), or if a registration was
    // aborted mid-way through the Cloud Function call.
    const ghostUser = AuthUser(
      id: 'uid-ghost',
      email: 'ghost@test.com',
      isOnboarded: true,
      // name is null, photoUrls is [] — matches the safety-net condition
    );

    test('isOnboarded=true but no name and no photos → /login (landing page)', () {
      expect(
        computeRedirect(
          isInitialized: true,
          authUser: ghostUser,
          profileStatus: const AsyncData(
            ProfileStatus.ready(isOnboarded: true),
          ),
          hasConsent: true,
          currentPath: '/',
        ),
        equals('/login'),
      );
    });

    test('ghost user already at /login → null (stay)', () {
      expect(
        computeRedirect(
          isInitialized: true,
          authUser: ghostUser,
          profileStatus: const AsyncData(
            ProfileStatus.ready(isOnboarded: true),
          ),
          hasConsent: true,
          currentPath: '/login',
        ),
        isNull,
      );
    });

    test('isOnboarded=true, has name but no photos → null (stay — valid profile)', () {
      const userWithName = AuthUser(
        id: 'uid-ghost',
        email: 'ghost@test.com',
        isOnboarded: true,
        name: 'Alice',
        // photoUrls empty — name alone is enough to pass the guard
      );
      expect(
        computeRedirect(
          isInitialized: true,
          authUser: userWithName,
          profileStatus: const AsyncData(
            ProfileStatus.ready(isOnboarded: true),
          ),
          hasConsent: true,
          currentPath: '/',
        ),
        isNull,
      );
    });
  });
}
