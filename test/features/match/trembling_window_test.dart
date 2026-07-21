import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_background_service_platform_interface/flutter_background_service_platform_interface.dart';
import 'package:tremble/src/features/dashboard/presentation/home_screen.dart';
import 'package:tremble/src/features/dashboard/presentation/widgets/radar_search_overlay.dart';
import 'package:tremble/src/features/dashboard/application/radar_search_session.dart';
import 'package:tremble/src/features/dashboard/application/warmth_controller.dart';
import 'package:tremble/src/features/dashboard/application/proximity_ping_controller.dart';
import 'package:tremble/src/features/dashboard/domain/warmth_direction.dart';
import 'package:tremble/src/features/dashboard/domain/sonar_ping.dart';
import 'package:tremble/src/features/dashboard/data/run_club_repository.dart';
import 'package:tremble/src/features/match/application/match_service.dart';
import 'package:tremble/src/features/match/domain/match.dart' as wave_match;
import 'package:tremble/src/features/match/presentation/widgets/pulse_intercept_bar.dart';
import 'package:tremble/src/features/match/presentation/widgets/trembling_partner_card.dart';
import 'package:tremble/src/features/matches/data/match_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:tremble/src/features/auth/data/auth_repository.dart';
import 'package:tremble/src/features/profile/data/profile_repository.dart';
import 'package:tremble/src/features/profile/domain/public_profile.dart';
import 'package:tremble/src/core/api_client.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tremble/src/features/gym/data/gym_repository.dart';
import 'package:tremble/src/features/match/data/wave_repository.dart';
import 'package:tremble/src/features/gym/application/gym_dwell_service.dart';
import 'package:tremble/src/features/subscriptions/application/revenuecat_subscription.dart';
import 'package:tremble/src/core/translations.dart';
import 'package:clock/clock.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
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
}

class MockProfileRepository implements ProfileRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }

  @override
  Future<PublicProfile> getPublicProfile(String uid) async {
    return PublicProfile(
      id: uid,
      name: 'Sarah',
      age: 24,
      photoUrls: [],
      hobbies: [],
    );
  }
}

class FakeWarmthController extends WarmthController {
  @override
  WarmthDirection build() => WarmthDirection.neutral;
}

/// Stubs the sonar so pumping the radar never starts its real BLE
/// subscription or freshness timers (which widget tests flag as pending).
/// Returns a benign `fresh` state so the "Searching…" caption (and its
/// animation ticker) is not rendered in these overlay tests.
class FakeSonarPingController extends SonarPingController {
  @override
  SonarPing build() => const SonarPing(signalState: SonarSignalState.fresh);
}

class MyMockPlatform extends FlutterBackgroundServicePlatform {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #on) {
      return const Stream<Map<String, dynamic>?>.empty();
    }
    return super.noSuchMethod(invocation);
  }
}

class MockUser implements User {
  @override
  final String uid = 'me';

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class MockFirebaseAuth implements FirebaseAuth {
  @override
  final User? currentUser = MockUser();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class MockFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class FakeWaveRepository implements WaveRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class FakeGymRepository implements GymRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class FakeRunClubRepository implements RunClubRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

List<Override> get _defaultOverrides => [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      authStateProvider.overrideWith((ref) => MockAuthNotifier(null)),
      activeMatchesStreamProvider.overrideWith((ref) => const Stream.empty()),
      activeRunCrossesProvider.overrideWith((ref, id) => const Stream.empty()),
      warmthControllerProvider.overrideWith(() => FakeWarmthController()),
      sonarPingControllerProvider.overrideWith(() => FakeSonarPingController()),
      firebaseAuthProvider.overrideWithValue(MockFirebaseAuth()),
      firestoreProvider.overrideWithValue(MockFirestore()),
      waveRepositoryProvider.overrideWithValue(FakeWaveRepository()),
      gymRepositoryProvider.overrideWithValue(FakeGymRepository()),
      runClubRepositoryProvider.overrideWithValue(FakeRunClubRepository()),
      gymDwellServiceProvider.overrideWithValue(null),
      revenueCatIsPremiumProvider.overrideWith((ref) => false),
      appLanguageProvider.overrideWith(() => AppLanguageNotifier('en')),
      currentTimeProvider.overrideWith((ref) => () => clock.now()),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FlutterBackgroundServicePlatform.instance = MyMockPlatform();
  });

  group('Trembling Window Widget Tests', () {
    // Pulse Intercept now lives DURING the trembling window (radar search),
    // not on the match reveal. It is meetup assistance, not part of the reveal.
    testWidgets('PulseInterceptBar sends phone and photo intercept requests',
        (WidgetTester tester) async {
      final requests = <({String targetUid, String type})>[];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PulseInterceptBar(
                targetUid: 'partner_456',
                requestPulseIntercept: ({
                  required String targetUid,
                  required String type,
                }) async {
                  requests.add((targetUid: targetUid, type: type));
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Send Phone'), findsOneWidget);
      expect(find.text('Send Photo'), findsOneWidget);

      await tester.tap(find.text('Send Phone'));
      await tester.pump();

      expect(
        requests,
        contains((targetUid: 'partner_456', type: 'phone')),
      );
      expect(find.text('Phone Sent'), findsOneWidget);

      await tester.tap(find.text('Send Photo'));
      await tester.pump();

      expect(
        requests,
        contains((targetUid: 'partner_456', type: 'photo')),
      );
      expect(find.text('Photo Sent'), findsOneWidget);
    });

    testWidgets('PulseInterceptBar shows inline pulse intercept errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PulseInterceptBar(
                targetUid: 'partner_456',
                requestPulseIntercept: ({
                  required String targetUid,
                  required String type,
                }) async {
                  throw TrembleApiException(
                    code: 'failed-precondition',
                    message: 'Add your phone number before sending it.',
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Send Phone'));
      await tester.pump();

      expect(
        find.text('Add your phone number before sending it.'),
        findsOneWidget,
      );
      expect(find.text('Send Phone'), findsOneWidget);
    });

    testWidgets(
        'RadarSearchOverlay shows Pulse Intercept when partnerUid is set',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _defaultOverrides,
          child: MaterialApp(
            home: Scaffold(
              body: RadarSearchOverlay(
                session: RadarSearchSession(
                  partnerName: 'Sarah',
                  partnerUid: 'partner_456',
                  expiresAt: clock.now().add(const Duration(minutes: 30)),
                  onStop: () async {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PulseInterceptBar), findsOneWidget);
      expect(find.text('Send Phone'), findsOneWidget);
      expect(find.text('Send Photo'), findsOneWidget);
    });

    testWidgets(
        'RadarSearchOverlay hides Pulse Intercept when partnerUid is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _defaultOverrides,
          child: MaterialApp(
            home: Scaffold(
              body: RadarSearchOverlay(
                session: RadarSearchSession(
                  partnerName: 'Sarah',
                  expiresAt: clock.now().add(const Duration(minutes: 30)),
                  onStop: () async {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PulseInterceptBar), findsNothing);
    });

    testWidgets('RadarSearchOverlay displays ticking timer that stops at 00:00',
        (WidgetTester tester) async {
      final expiresAt =
          clock.now().add(const Duration(minutes: 30, milliseconds: 16));
      var stopped = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: _defaultOverrides,
          child: MaterialApp(
            home: Scaffold(
              body: RadarSearchOverlay(
                session: RadarSearchSession(
                  partnerName: 'Sarah',
                  expiresAt: expiresAt,
                  onStop: () async => stopped = true,
                ),
              ),
            ),
          ),
        ),
      );

      // Verify initial state shows 30:00
      expect(find.text('30:00'), findsOneWidget);
      expect(find.byIcon(LucideIcons.clock), findsOneWidget);

      // Pump 1 second
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(); // Allow timer setState to trigger rebuild
      expect(find.text('29:59'), findsOneWidget);

      // Tap stop button
      await tester.tap(find.text('STOP'));
      await tester.pump();
      expect(stopped, isTrue);

      // Pump past expiration
      await tester.pump(const Duration(minutes: 30));
      expect(find.text('00:00'), findsOneWidget);
    });

    testWidgets('Stop shows a spinner while the onStop round-trip is in flight',
        (WidgetTester tester) async {
      final completer = Completer<void>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: _defaultOverrides,
          child: MaterialApp(
            home: Scaffold(
              body: RadarSearchOverlay(
                session: RadarSearchSession(
                  partnerName: 'Sarah',
                  expiresAt: clock.now().add(const Duration(minutes: 30)),
                  onStop: () => completer.future,
                ),
              ),
            ),
          ),
        ),
      );

      // No spinner until Stop is tapped.
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.text('STOP'));
      await tester.pump();

      // Spinner is shown while awaiting; the label stays visible.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('STOP'), findsOneWidget);

      // Completing the round-trip clears the spinner.
      completer.complete();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Stop surfaces a retry snackbar and re-enables when it fails',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _defaultOverrides,
          child: MaterialApp(
            home: Scaffold(
              body: RadarSearchOverlay(
                session: RadarSearchSession(
                  partnerName: 'Sarah',
                  expiresAt: clock.now().add(const Duration(minutes: 30)),
                  onStop: () async => throw Exception('markMatchFound failed'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('STOP'));
      await tester.pump(); // start the future
      await tester.pump(); // let the error propagate + snackbar insert

      // The failure is surfaced (not swallowed), and the button re-enables.
      expect(find.text('Try again'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('mutual wave triggers Trembling Window UI state in HomeScreen',
        (WidgetTester tester) async {
      // Setup overrides:
      // 1. Current user is Premium
      final testSearchProvider =
          StateProvider<wave_match.Match?>((ref) => null);
      final testUser = const AuthUser(
        id: 'me',
        name: 'Me',
        isPremium: true,
        isOnboarded: true,
        isEmailVerified: true,
      );

      final container = ProviderContainer(
        overrides: [
          ..._defaultOverrides,
          currentSearchProvider
              .overrideWith((ref) => ref.watch(testSearchProvider)),
          authStateProvider.overrideWith((ref) => MockAuthNotifier(testUser)),
          effectiveIsPremiumProvider.overrideWith((ref) => true),
          profileRepositoryProvider.overrideWithValue(MockProfileRepository()),
          publicProfileProvider('partner_456')
              .overrideWith((ref) async => PublicProfile(
                    id: 'partner_456',
                    name: 'Sarah',
                    age: 24,
                    photoUrls: const [],
                    hobbies: const [],
                  )),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const HomeScreen(),
          ),
        ),
      );

      // Wait for any initial initialization/animations
      await tester.pumpAndSettle();

      // Initially currentSearchProvider is null, so scan button should be displayed
      expect(find.byType(RadarSearchOverlay), findsNothing);

      // Simulate receiving a mutual wave (Match is pending)
      final match = wave_match.Match(
        id: 'match_123',
        userIds: ['me', 'partner_456'],
        createdAt: DateTime.now(),
        seenBy: [],
        status: 'pending',
        gestures: {'me': true, 'partner_456': true},
      );

      container.read(testSearchProvider.notifier).state = match;

      // Pump to trigger build and wait for the public profile future to resolve
      await tester.pump();
      await tester
          .pump(const Duration(milliseconds: 100)); // allow future to complete
      await tester.pumpAndSettle();

      // Trembling Window UI state (RadarSearchOverlay) should now be displayed
      expect(find.byType(RadarSearchOverlay), findsOneWidget);
      expect(
          find.text('30:00').evaluate().isNotEmpty ||
              find.text('29:59').evaluate().isNotEmpty,
          isTrue);
    });
  });

  // BUG-TREMBLE-PROFILE-TAP (Session 55): tapping the trembling-window partner
  // card must open the SAME gated card as history (basic for Free, full for
  // Premium) and must NEVER route Free users through the paywall — the empty
  // RevenueCat offerings there rendered a debug "offerings empty" overlay ON
  // TOP of the trembling window.
  group('Trembling partner tap gating', () {
    const partnerId = 'partner_456';
    final match = wave_match.Match(
      id: 'match_123',
      userIds: const ['me', partnerId],
      createdAt: DateTime(2026, 7, 20),
      seenBy: const [],
      status: 'pending',
      gestures: const {'me': true, partnerId: true},
    );
    final partner = MatchProfile(
      id: partnerId,
      name: 'Sarah',
      age: 24,
      imageUrl: '',
      hobbies: const [],
      bio: '',
      photoUrls: const [],
    );

    Future<List<String>> _tapPartnerCard(
      WidgetTester tester, {
      required bool isPremium,
    }) async {
      final pushed = <String>[];
      final user = AuthUser(
        id: 'me',
        name: 'Me',
        isPremium: isPremium,
        isOnboarded: true,
        isEmailVerified: true,
      );

      final container = ProviderContainer(
        overrides: [
          ..._defaultOverrides,
          currentSearchProvider.overrideWith((ref) => match),
          authStateProvider.overrideWith((ref) => MockAuthNotifier(user)),
          effectiveIsPremiumProvider.overrideWith((ref) => isPremium),
          partnerMatchProfileProvider(partnerId)
              .overrideWith((ref) => AsyncData(partner)),
        ],
      );
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          GoRoute(
            path: '/profile',
            builder: (_, state) {
              pushed.add(state.uri.toString());
              return const SizedBox.shrink();
            },
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TremblingPartnerCard), findsOneWidget);
      await tester.tap(find.byType(TremblingPartnerCard));
      await tester.pump();
      await tester.pump();
      return pushed;
    }

    testWidgets('Free user opens the basic card, never the paywall',
        (tester) async {
      final pushed = await _tapPartnerCard(tester, isPremium: false);

      // Free path routes to the reduced basic card (mirrors history), so the
      // RevenueCat paywall/offerings are never touched from this tap.
      expect(pushed, ['/profile?showActions=false&basic=true']);
    });

    testWidgets('Premium user opens the full profile card', (tester) async {
      final pushed = await _tapPartnerCard(tester, isPremium: true);

      expect(pushed, ['/profile']);
    });
  });
}
