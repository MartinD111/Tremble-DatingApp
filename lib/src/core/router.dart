import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/registration_flow.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/permission_gate_screen.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/dashboard/presentation/home_screen.dart';
import '../features/dashboard/presentation/run_recap_screen.dart';
import '../features/map/presentation/event_recap_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/matches/data/match_repository.dart';
import '../features/profile/presentation/profile_detail_screen.dart';
import '../features/profile/presentation/profile_card_preview.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/safety/presentation/blocked_users_screen.dart';
import '../features/safety/presentation/anonymous_mode_screen.dart';
import '../features/safety/presentation/safe_zones_screen.dart';
import '../features/gym/presentation/my_gyms_screen.dart';
import '../features/match/presentation/match_reveal_screen.dart';
import '../features/match/domain/match.dart';
import '../shared/ui/gradient_scaffold.dart';
import 'consent_service.dart';
import 'notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ── Navigator Key ─────────────────────────────────────────────────────────────
// Exposed so notification handlers (outside the widget tree) can navigate.
final rootNavigatorKey = GlobalKey<NavigatorState>();

// ── Routing Decision — pure function ─────────────────────────────────────────
// Extracted from the GoRouter redirect callback so it can be unit-tested
// without spinning up GoRouter. Must remain a pure function with no side
// effects: same inputs always produce the same output.
//
// Returns the redirect path or null (stay on current path).
@visibleForTesting
String? computeRedirect({
  required bool isInitialized,
  required AuthUser? authUser,
  required AsyncValue<ProfileStatus> profileStatus,
  required bool hasConsent,
  required String currentPath,
  // Whether the current Firebase user has verified their email.
  // Passed separately so this function stays testable without a Firebase instance.
  bool isEmailVerified = false,
  // Whether the current Firebase user authenticated via a social provider
  // (Google / Apple). Social users skip the email-verified check below.
  bool isSocialUser = false,
}) {
  if (kDebugMode) {
    debugPrint(
      '[TREMBLE_ROUTER] computeRedirect() called: currentPath=$currentPath, '
      'isInitialized=$isInitialized, authUser=${authUser?.email}, '
      'profileLoading=${profileStatus.isLoading}, hasConsent=$hasConsent',
    );
  }

  // Auth stream not yet settled — hold, show splash
  if (!isInitialized) {
    if (kDebugMode) debugPrint('[TREMBLE_ROUTER] Not initialized, holding...');
    return null;
  }

  // 1. Not logged in
  if (authUser == null) {
    if (currentPath == '/onboarding' || currentPath == '/forgot-password') {
      return null;
    }
    final redirect = currentPath == '/login' ? null : '/login';
    if (kDebugMode)
      debugPrint('[TREMBLE_ROUTER] No authUser, redirecting to: $redirect');
    return redirect;
  }

  // 2. Profile check in-flight — hold (router shows splash via '/' builder)
  if (profileStatus.isLoading) {
    if (kDebugMode) debugPrint('[TREMBLE_ROUTER] Profile loading, holding...');
    return null;
  }

  final status = profileStatus.value;

  // 3. Doc missing or not yet onboarded → force to /onboarding
  final needsOnboarding = status == null ||
      status is ProfileStatusNotFound ||
      (status is ProfileStatusReady && !status.isOnboarded);

  if (kDebugMode) {
    debugPrint(
      '[TREMBLE_ROUTER] Profile status: $status, needsOnboarding=$needsOnboarding',
    );
  }

  if (needsOnboarding) {
    if (currentPath == '/onboarding' || currentPath == '/forgot-password') {
      return null;
    }
    // Guard: a stale email+password session that was never completed (email
    // not yet verified, no Firestore profile draft) should land on /login so the
    // user can choose to sign in or register fresh — NOT silently resume an
    // orphaned registration flow that they may not remember starting.
    if (!isSocialUser && !isEmailVerified) {
      final redirect = currentPath == '/login' ? null : '/login';
      if (kDebugMode) {
        debugPrint(
          '[TREMBLE_ROUTER] Stale email session (not verified, no profile), redirecting to: $redirect',
        );
      }
      return redirect;
    }
    final redirect = '/onboarding';
    if (kDebugMode)
      debugPrint(
          '[TREMBLE_ROUTER] Needs onboarding, redirecting to: $redirect');
    return redirect;
  }

  // 3b. Ghost-onboarded safety net: Firestore says isOnboarded=true but the
  // profile has no name AND no photos — the dev-mode CF fallback wrote only
  // the flag, not the full payload (now fixed in markOnboardedDirectly).
  // Route to /login so the user sees the landing page. From there they can
  // tap "Are you new" (which signs them out first) to restart registration,
  // or sign in with valid credentials. Do NOT route to /onboarding — that
  // looks identical to "Are you new" being auto-pressed, which is confusing.
  if (authUser.name == null && authUser.photoUrls.isEmpty) {
    return currentPath == '/login' ? null : '/login';
  }

  // 4. Onboarded — GDPR consent gate
  if (!hasConsent) {
    return currentPath == '/permission-gate' ? null : '/permission-gate';
  }
  if (currentPath == '/permission-gate') return '/';

  // 5. Fully onboarded — block auth/onboarding routes
  if (currentPath == '/login' || currentPath == '/onboarding') return '/';

  return null;
}

// ── Splash Loading Screen ─────────────────────────────────────────────────────
// Shown at '/' while the Firestore profile snapshot is in-flight.
// Prevents any flash of the Home/Radar UI before profile state is confirmed.
class _SplashLoadingScreen extends StatelessWidget {
  const _SplashLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A1A18), // Deep graphite
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFF4436C), // Primary rose
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}

// ── Notification Deep Link Handler ────────────────────────────────────────────
// Routes MUTUAL_WAVE notifications to the MatchRevealScreen.
// Fetches the Match document from Firestore using the matchId in the payload.
Future<void> handleNotificationNavigation(
  Map<String, dynamic> data, {
  Duration delay = Duration.zero,
}) async {
  final type = data['type'] as String?;
  final actionId = data['actionId'] as String?;

  // 0. Run Club intercept — tap opens the RunRecapScreen
  if (type == 'RUN_INTERCEPT') {
    if (delay > Duration.zero) await Future.delayed(delay);
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      ctx.push('/run-recap');
    }
    return;
  }

  // 1. Handle "Wave" action button from Proximity Notification
  if (actionId == 'NEARBY_WAVE_ACTION') {
    final targetUid = data['fromUid'] as String?;
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (targetUid != null && myUid != null) {
      try {
        await FirebaseFirestore.instance.collection('waves').add({
          'fromUid': myUid,
          'toUid': targetUid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint(
            '[ROUTER] Auto-wave sent via notification action: $myUid → $targetUid');
      } catch (e) {
        debugPrint('[ROUTER] Auto-wave failed: $e');
      }
    }
    // After waving, we might want to stay on the current screen or show a confirmation.
    // For now, we just proceed.
  }

  // 2. Handle navigation for Mutual Waves (Matches)
  final matchId = data['matchId'] as String?;
  if (type == 'MUTUAL_WAVE' && matchId != null) {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .get();

      if (!doc.exists) return;

      final match = Match.fromFirestore(doc);

      // Small delay ensures GoRouter is fully mounted before navigation
      if (delay > Duration.zero) await Future.delayed(delay);

      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        ctx.pushNamed('match_reveal', extra: match);
      }
    } catch (e) {
      debugPrint('[ROUTER] Notification navigation failed: $e');
    }
  }
}

// ── Router Notifier ───────────────────────────────────────────────────────────
// Listens to auth state, profile status, and consent changes, then notifies
// GoRouter to re-run redirect without recreating the router instance.
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  // True once the first auth state has been emitted by the Firebase stream.
  // Until then redirect returns null (hold) to prevent a transient
  // null → /login flash on cold start.
  bool _initialized = false;

  // True once the Firebase Auth stream has fired at least once.
  // Used to gate profileStatusProvider's initialization signal — the
  // profileStatus stream emits notFound immediately when authState is null,
  // but authState starts as null even for returning users before Firebase
  // restores their persisted session. Allowing that transient notFound to
  // set _initialized = true causes a /login flash for returning users.
  bool _authStreamFired = false;

  _RouterNotifier(this._ref) {
    // Fast path: Riverpod already has a hydrated AuthUser (e.g. returning user
    // whose Firestore fetch completed synchronously from cache).
    if (_ref.read(authStateProvider) != null) {
      _initialized = true;
      _authStreamFired = true;
    }

    // The auth stream is the primary initialization signal. It fires once very
    // quickly at startup (within a few frames) regardless of whether a session
    // exists. We MUST wait for it before trusting profileStatus = notFound,
    // because authStateProvider starts as null even for returning users.
    _ref.listen<AuthUser?>(authStateProvider, (prev, next) {
      debugPrint('[ROUTER] authStateProvider → user: ${next?.id ?? 'null'}');
      _authStreamFired = true;
      _initialized = true;
      notifyListeners();
    });
    _ref.listen<AsyncValue<bool>>(
        gdprConsentProvider, (_, __) => notifyListeners());
    // profileStatusProvider supplements the auth stream:
    // - When authState is non-null: emits once the Firestore snapshot arrives,
    //   allowing the router to react to profile changes without re-auth.
    // - When authState is null AND _authStreamFired: the null is real (signed
    //   out), so notFound is a valid initialization signal.
    // - When authState is null AND !_authStreamFired: the null is transient
    //   (Firebase hasn't restored the session yet). Ignore — hold the router.
    _ref.listen<AsyncValue<ProfileStatus>>(profileStatusProvider, (_, next) {
      debugPrint(
          '[ROUTER] profileStatusProvider → $next  authStreamFired=$_authStreamFired');
      if (!next.isLoading && _authStreamFired) _initialized = true;
      notifyListeners();
    });

    // Unblock the signed-out cold-start dead-lock:
    //
    // AuthNotifier starts with super(null). When Firebase auth stream emits
    // null (no session), AuthNotifier.state stays null (same value) and
    // Riverpod's equality check silences the authStateProvider listener above
    // — _authStreamFired is never set, so _initialized stays false forever.
    //
    // authInitializedProvider listens to the raw Firebase stream (no asyncMap),
    // so it always resolves on the first emission. When it resolves to false
    // (no user), we know Firebase has settled and it's safe to initialize.
    // When it resolves to true (user exists), the authStateProvider listener
    // handles initialization once the Firestore fetch completes.
    _ref.listen<AsyncValue<bool>>(authInitializedProvider, (_, next) {
      debugPrint('[ROUTER] authInitializedProvider → $next');
      if (next.hasValue && !next.value! && !_initialized) {
        debugPrint(
            '[ROUTER] no session — unblocking router (was timeout or clean signout)');
        _authStreamFired = true;
        _initialized = true;
        notifyListeners();
      }
    });
  }

  bool get isInitialized => _initialized;
  AuthUser? get authState => _ref.read(authStateProvider);
  bool get hasConsent => _ref.read(gdprConsentProvider).value ?? false;
  AsyncValue<ProfileStatus> get profileStatus =>
      _ref.read(profileStatusProvider);

  /// True if the current Firebase user has verified their email address.
  /// Used by computeRedirect to distinguish stale partial-registration
  /// sessions (unverified, password provider) from returning verified users.
  bool get isEmailVerified {
    if (kDebugMode) return true; // Dev: skip email verification gate
    return _ref.read(firebaseAuthProvider).currentUser?.emailVerified ?? false;
  }

  /// True if the current user authenticated via Google or Apple.
  /// Social users have no email-verification requirement.
  bool get isSocialUser {
    final providers =
        _ref.read(firebaseAuthProvider).currentUser?.providerData ?? [];
    return providers.any(
        (p) => p.providerId == 'google.com' || p.providerId == 'apple.com');
  }
}

// ── Router Provider ───────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: notifier,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const RegistrationFlow(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/permission-gate',
        builder: (context, state) => const PermissionGateScreen(),
      ),
      GoRoute(
        path: '/',
        // Consumer (not container.read) so the builder rebuilds when
        // authStateProvider emits. Without this, the initial cold-start build
        // captures authUser=null and renders the splash permanently — even
        // after the auth stream resolves, because redirect returning "stay"
        // does not trigger a route rebuild.
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            final authUser = ref.watch(authStateProvider);
            if (authUser == null) return const _SplashLoadingScreen();
            return const GradientScaffold(child: HomeScreen());
          },
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) {
          final match = state.extra as MatchProfile?;
          final showActions =
              state.uri.queryParameters['showActions'] != 'false';
          if (match == null) {
            return const _ProfileNotFoundRedirect();
          }
          return ProfileDetailScreen(match: match, showActions: showActions);
        },
      ),
      GoRoute(
        path: '/profile-preview',
        builder: (context, state) => const ProfileCardPreview(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) =>
            const GradientScaffold(child: SettingsScreen()),
      ),
      GoRoute(
        path: '/blocked-users',
        builder: (context, state) => const BlockedUsersScreen(),
      ),
      GoRoute(
        path: '/anonymous-mode',
        builder: (context, state) => const AnonymousModeScreen(),
      ),
      GoRoute(
        path: '/safe-zones',
        builder: (context, state) => const SafeZonesScreen(),
      ),
      GoRoute(
        path: '/my-gyms',
        builder: (context, state) => const MyGymsScreen(),
      ),
      GoRoute(
        path: '/run-recap',
        builder: (context, state) =>
            const GradientScaffold(child: RunRecapScreen()),
      ),
      GoRoute(
        path: '/event-recap',
        name: 'event_recap',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return EventRecapScreen(
            eventName: extra?['eventName'] as String? ?? '',
            eventId: extra?['eventId'] as String? ?? '',
            pulseSecondsRemaining: extra?['pulseSecondsRemaining'] as int?,
          );
        },
      ),
      GoRoute(
        path: '/match-reveal',
        name: 'match_reveal',
        builder: (context, state) {
          final match = state.extra as Match?;
          if (match == null) {
            return const Scaffold(body: Center(child: Text('Match not found')));
          }
          return MatchRevealScreen(match: match);
        },
      ),
    ],
    redirect: (context, state) {
      final result = computeRedirect(
        isInitialized: notifier.isInitialized,
        authUser: notifier.authState,
        profileStatus: notifier.profileStatus,
        hasConsent: notifier.hasConsent,
        currentPath: state.uri.toString(),
        isEmailVerified: notifier.isEmailVerified,
        isSocialUser: notifier.isSocialUser,
      );
      debugPrint('[ROUTER] redirect ${state.uri} → ${result ?? '(stay)'}  '
          'init=${notifier.isInitialized} '
          'user=${notifier.authState?.id ?? 'null'} '
          'profile=${notifier.profileStatus} '
          'consent=${notifier.hasConsent}');
      return result;
    },
  );

  // ── Local Notification handling (including action buttons) ───────────────
  NotificationService.initialize(
    onNotificationTap: (data) {
      handleNotificationNavigation(data);
    },
  );

  // ── Notification deep link: cold start (app was terminated) ──────────────
  // Runs once when the router is first created.
  // Delay of 500ms ensures GoRouter is fully mounted before navigating.
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      handleNotificationNavigation(
        message.data,
        delay: const Duration(milliseconds: 500),
      );
    }
  });

  // ── Notification deep link: app brought from background ───────────────────
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    handleNotificationNavigation(message.data);
  });

  return router;
});

// Shown when /profile is reached without a MatchProfile extra (e.g. deep link,
// hot reload). Pops back on first frame so the user never sees a broken screen.
class _ProfileNotFoundRedirect extends StatefulWidget {
  const _ProfileNotFoundRedirect();

  @override
  State<_ProfileNotFoundRedirect> createState() =>
      _ProfileNotFoundRedirectState();
}

class _ProfileNotFoundRedirectState extends State<_ProfileNotFoundRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
        } else {
          router.go('/');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}
