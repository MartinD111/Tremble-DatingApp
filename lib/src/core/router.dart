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
import '../features/settings/presentation/settings_screen.dart';
import '../features/matches/data/match_repository.dart';
import '../features/profile/presentation/profile_detail_screen.dart';
import '../features/profile/presentation/profile_card_preview.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/safety/presentation/blocked_users_screen.dart';
import '../features/match/presentation/match_reveal_screen.dart';
import '../features/match/domain/match.dart';
import '../shared/ui/gradient_scaffold.dart';
import 'consent_service.dart';

// ── Navigator Key ─────────────────────────────────────────────────────────────
// Exposed so notification handlers (outside the widget tree) can navigate.
final rootNavigatorKey = GlobalKey<NavigatorState>();

// ── Notification Deep Link Handler ────────────────────────────────────────────
// Routes MUTUAL_WAVE notifications to the MatchRevealScreen.
// Fetches the Match document from Firestore using the matchId in the payload.
Future<void> handleNotificationNavigation(
  Map<String, dynamic> data, {
  Duration delay = Duration.zero,
}) async {
  final type = data['type'] as String?;
  final matchId = data['matchId'] as String?;

  if (type != 'MUTUAL_WAVE' || matchId == null) return;

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

// ── Router Notifier ───────────────────────────────────────────────────────────
// Listens to auth state and permission gate changes, notifies GoRouter to
// re-run redirect without recreating the router instance.
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  // True once the first auth state has been emitted by the Firebase stream.
  // Until then we return null from redirect so GoRouter does nothing — this
  // prevents the transient null → /login redirect that caused the crash when
  // navigating back from /profile-preview.
  bool _initialized = false;

  _RouterNotifier(this._ref) {
    if (_ref.read(authStateProvider) != null) {
      _initialized = true;
    }

    _ref.listen<AuthUser?>(authStateProvider, (prev, next) {
      _initialized = true;
      notifyListeners();
    });
    _ref.listen<AsyncValue<bool>>(
        gdprConsentProvider, (_, __) => notifyListeners());
  }

  bool get isInitialized => _initialized;
  AuthUser? get authState => _ref.read(authStateProvider);
  bool get hasConsent => _ref.read(gdprConsentProvider).value ?? false;
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
        builder: (context, state) =>
            const GradientScaffold(child: HomeScreen()),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) {
          final match = state.extra as MatchProfile?;
          if (match == null) {
            return const Scaffold(
                body: Center(child: Text("Profile not found")));
          }
          return ProfileDetailScreen(match: match);
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
      if (!notifier.isInitialized) return null;

      final authState = notifier.authState;
      final isLoggedIn = authState != null;
      final isOnboarded = authState?.isOnboarded ?? false;
      final hasConsent = notifier.hasConsent;

      final path = state.uri.toString();
      final isLoginRoute = path == '/login';
      final isOnboardingRoute = path == '/onboarding';
      final isPermissionRoute = path == '/permission-gate';
      final isForgotPasswordRoute = path == '/forgot-password';

      if (!isLoggedIn) {
        if (isOnboardingRoute || isForgotPasswordRoute) return null;
        return isLoginRoute ? null : '/login';
      }

      if (!isOnboarded) {
        if (isOnboardingRoute || isForgotPasswordRoute) return null;
        return '/onboarding';
      }

      // GDPR consent gate — shown once after onboarding, never again after granted.
      if (isLoggedIn && isOnboarded && !hasConsent) {
        return isPermissionRoute ? null : '/permission-gate';
      }

      if (isLoggedIn && isOnboarded && hasConsent && isPermissionRoute) {
        return '/';
      }

      if (isLoggedIn && isOnboarded && (isLoginRoute || isOnboardingRoute)) {
        return '/';
      }

      return null;
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
