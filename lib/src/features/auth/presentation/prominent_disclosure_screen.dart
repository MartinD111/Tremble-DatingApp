import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/translations.dart';
import '../../../shared/ui/glass_card.dart';
import '../../../shared/ui/primary_button.dart';

/// Google Play "Prominent Disclosure" screen for ACCESS_BACKGROUND_LOCATION.
///
/// Play policy requires a standalone disclosure — separate from the Privacy
/// Policy and separate from the app's general consent flow — that runs BEFORE
/// the OS background-location prompt. Bundling this into the onboarding
/// consent screen is a documented review-rejection path.
///
/// Contract: this widget only shows copy and buttons. It does not touch
/// permission_handler and never fires the OS prompt directly. The caller
/// awaits `Navigator.push<bool>` and interprets the return value:
///   * `true`  — user tapped the primary CTA. Caller MAY now invoke
///               [ConsentService.requestLocationAlways].
///   * `false` or `null` — user tapped "Not now" or backed out. Caller MUST
///               NOT invoke the background-location request; app usage still
///               proceeds with foreground-only location.
class ProminentDisclosureScreen extends ConsumerWidget {
  const ProminentDisclosureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80),
                Icon(
                  LucideIcons.mapPin,
                  color: colorScheme.primary,
                  size: 48,
                ).animate().fadeIn(duration: 400.ms).scale(
                      begin: const Offset(0.85, 0.85),
                      duration: 400.ms,
                      curve: Curves.easeOut,
                    ),
                const SizedBox(height: 28),
                Text(
                  t('disclosure_bg_location_headline', lang),
                  style: textTheme.displaySmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ).animate().fadeIn(duration: 500.ms).slideY(
                      begin: 0.1,
                      end: 0,
                      duration: 500.ms,
                      curve: Curves.easeOut,
                    ),
                const SizedBox(height: 20),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    t('disclosure_bg_location_body', lang),
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(
                        alpha: isDark ? 0.78 : 0.7,
                      ),
                      height: 1.55,
                    ),
                  ),
                ).animate().fadeIn(delay: 120.ms, duration: 450.ms),
                const SizedBox(height: 40),
                PrimaryButton(
                  text: t('disclosure_bg_location_cta_allow', lang),
                  onPressed: () => Navigator.of(context).pop(true),
                ).animate().fadeIn(delay: 280.ms, duration: 400.ms).slideY(
                      begin: 0.1,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeOut,
                    ),
                const SizedBox(height: 12),
                PrimaryButton(
                  text: t('disclosure_bg_location_cta_not_now', lang),
                  isSecondary: true,
                  onPressed: () => Navigator.of(context).pop(false),
                ).animate().fadeIn(delay: 340.ms, duration: 400.ms),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Route name for callers that push the disclosure via a named route or need
// to distinguish it in analytics/router logs.
const String prominentDisclosureRouteName = '/background-location-disclosure';
