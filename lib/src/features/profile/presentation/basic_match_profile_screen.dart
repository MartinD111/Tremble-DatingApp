import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme.dart';
import '../../../core/translations.dart';
import '../../../shared/ui/gradient_scaffold.dart';
import '../../../shared/ui/tremble_header.dart';
import '../../../shared/ui/premium_paywall.dart';
import '../../auth/data/auth_repository.dart';
import '../../matches/data/match_repository.dart';
import '../../matches/presentation/matches_screen.dart'
    show sharedFirstHobbyNames;

/// Free-tier "basic card" opened when a Free user taps a mutual match tile
/// (ADR-007 §1, Session-53 spec). Shows only photo + name/age + up to 3
/// hobbies (shared-first, like the tile), plus a subtle "See full profile"
/// CTA that opens the Premium paywall — the full [ProfileDetailScreen] card
/// stays Premium-gated. Premium users bypass this screen and open the full
/// card directly.
class BasicMatchProfileScreen extends ConsumerWidget {
  const BasicMatchProfileScreen({super.key, required this.match});

  final MatchProfile match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final lang = user?.appLanguage ?? 'en';
    final primary = Theme.of(context).primaryColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtextColor = textColor.withValues(alpha: 0.6);

    final hobbies =
        sharedFirstHobbyNames(user?.hobbies ?? const [], match.hobbies);

    return GradientScaffold(
      child: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 96, 24, 32),
              child: Column(
                children: [
                  const Spacer(),
                  CircleAvatar(
                    radius: 72,
                    backgroundImage: NetworkImage(match.imageUrl),
                    backgroundColor: Colors.white12,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    match.name,
                    textAlign: TextAlign.center,
                    style: TrembleTheme.displayFont(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${match.age} ${t('years', lang)}',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 15,
                      color: subtextColor,
                    ),
                  ),
                  if (hobbies.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final hobby in hobbies)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              hobby,
                              style: GoogleFonts.instrumentSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  const Spacer(),
                  // Subtle upgrade CTA — the full profile card is Premium-gated.
                  _SeeFullProfileCta(
                    label: t('see_full_profile', lang),
                    primary: primary,
                    onTap: () => PremiumPaywallBottomSheet.show(context),
                  ),
                ],
              ),
            ),
          ),
          TrembleHeader(
            title: '',
            titleOpacity: 0.0,
            buttonsOpacity: 1.0,
            onBack: () {
              if (context.canPop()) context.pop();
            },
          ),
        ],
      ),
    );
  }
}

class _SeeFullProfileCta extends StatelessWidget {
  const _SeeFullProfileCta({
    required this.label,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: primary.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.crown, size: 18, color: primary),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
