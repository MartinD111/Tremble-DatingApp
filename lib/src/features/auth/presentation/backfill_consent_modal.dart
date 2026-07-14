import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/auth_repository.dart';
import '../../../core/translations.dart';

/// App-launch modal that forces pre-migration users (those with a null
/// `sexualOrientationConsent` on their Firestore doc) to record an
/// Art. 9 consent decision before continuing.
///
/// Contract:
/// - Non-dismissible via swipe or back button — the decision must be
///   recorded before the app becomes usable.
/// - Renders ABOVE the router-driven UI so it survives route changes
///   during the decision window.
/// - Accept → server writes consent=true + v1 + timestamp; modal
///   dismisses; normal app flow resumes.
/// - Decline → server writes consent=false + v1 + timestamp; modal
///   dismisses; scorer's bilateral orientation gate (compat step 2)
///   then filters this user out of orientation-adjacent matching. The
///   underlying gender + lookingFor fields stay in Firestore so a
///   later re-grant needs no re-entry — deletion is only forced
///   through the destructive Settings withdrawal path (step 6).
///
/// Once a decision is recorded (accept OR decline), the modal does
/// NOT re-appear until the consent version tag changes, which is what
/// enables the future re-prompt on `_v2` copy bumps.
class BackfillConsentModal extends ConsumerStatefulWidget {
  const BackfillConsentModal({super.key});

  @override
  ConsumerState<BackfillConsentModal> createState() =>
      _BackfillConsentModalState();
}

class _BackfillConsentModalState extends ConsumerState<BackfillConsentModal> {
  bool _submitting = false;

  Future<void> _decide({required bool granted}) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(authStateProvider.notifier)
          .setArt9Consent('orientation', granted: granted);
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        // Leave the modal up so the user can retry — a failed decision
        // must not silently become a decision.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final lang =
        user?.appLanguage.isNotEmpty == true ? user!.appLanguage : 'en';
    String tr(String key) {
      final result = t(key, lang);
      return result == key ? t(key, 'en') : result;
    }

    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.black.withValues(alpha: 0.88),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Icon(
                    Icons.shield_outlined,
                    color: theme.colorScheme.primary,
                    size: 48,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    tr('backfill_consent_title'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    tr('backfill_consent_body'),
                    style: GoogleFonts.instrumentSans(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    key: const Key('backfill-consent-accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed:
                        _submitting ? null : () => _decide(granted: true),
                    child: Text(
                      tr('backfill_consent_accept'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    key: const Key('backfill-consent-decline'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed:
                        _submitting ? null : () => _decide(granted: false),
                    child: Text(
                      tr('backfill_consent_decline'),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (_submitting) ...[
                    const SizedBox(height: 24),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Root-level gate that overlays [BackfillConsentModal] on top of the
/// running app when the signed-in user has never recorded an
/// orientation consent decision. Wraps the app's rendered child inside
/// [MaterialApp.router.builder] so the overlay survives route changes.
///
/// The gate is off while the user is signed out (no user doc to
/// evaluate) and while the user is mid-registration (the registration
/// flow collects the consent explicitly through consent_step.dart, so
/// showing the modal on top of that flow would be redundant).
class BackfillConsentGate extends ConsumerWidget {
  const BackfillConsentGate({super.key, required this.child});

  final Widget child;

  bool _shouldPrompt(AuthUser? user) {
    if (user == null) return false;
    // Never prompt during onboarding — the registration flow itself
    // collects consent through consent_step.dart. Once the user is
    // isOnboarded=true, the modal takes over as the single source of
    // truth for pre-migration accounts.
    if (!user.isOnboarded) return false;
    // Only pre-migration accounts have consent == null. Post-migration
    // users always have a bool.
    return user.sexualOrientationConsent == null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    return Stack(
      children: [
        child,
        if (_shouldPrompt(user))
          const Positioned.fill(child: BackfillConsentModal()),
      ],
    );
  }
}
