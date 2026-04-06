import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/registration_flow.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/permission_gate_screen.dart';
import '../features/auth/data/auth_repository.dart';
import 'consent_service.dart';

// Placeholders for screens if they don't exist yet/imported
import '../features/dashboard/presentation/home_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/matches/data/match_repository.dart'; // MatchProfile is here
import '../features/profile/presentation/profile_detail_screen.dart'; // Correct path
import '../features/profile/presentation/profile_card_preview.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/safety/presentation/blocked_users_screen.dart';
import '../shared/ui/gradient_scaffold.dart'; // Assume exists

// Listens to auth state and permission gate changes, notifies GoRouter to
// re-run redirect without recreating the router instance.
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen<AuthUser?>(authStateProvider, (_, __) => notifyListeners());
    _ref.listen<AsyncValue<bool>>(gdprConsentProvider, (_, __) => notifyListeners());
  }

  AuthUser? get authState => _ref.read(authStateProvider);
  bool get hasConsent => _ref.read(gdprConsentProvider).asData?.value ?? true;
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
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
          // careful with casting, ensure extra is passed
          final match = state.extra as MatchProfile?;
          // If match is null, maybe redirect or show error?
          // For now assuming safe
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
    ],
    redirect: (context, state) {
      final authState = notifier.authState;
      final isLoggedIn = authState != null;
      final isOnboarded = authState?.isOnboarded ?? false;
      final hasConsent = notifier.hasConsent;
      
      final path = state.uri.toString();
      final isLoginRoute = path == '/login';
      final isOnboardingRoute = path == '/onboarding';
      final isPermissionRoute = path == '/permission-gate';

      if (!isLoggedIn) {
        if (isOnboardingRoute) return null;
        if (path == '/forgot-password') return null;
        return isLoginRoute ? null : '/login';
      }

      if (!isOnboarded) {
        // Allow user to stay on login so they can choose when to register.
        if (isLoginRoute || isOnboardingRoute) return null;
        return '/login';
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
});
