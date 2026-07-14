import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../auth/data/auth_repository.dart';
import '../../../../core/translations.dart';

/// Settings tile group that lets a user withdraw or re-grant any of the
/// three GDPR Art. 9 consents (orientation, religion, ethnicity).
///
/// Reads state from [authStateProvider]; withdrawal delegates to
/// [AuthNotifier.withdrawArt9Consent] which handles the server call +
/// optimistic local update. Re-granting is intentionally handled outside
/// this widget — the user is directed to Profile → Edit to re-enter the
/// underlying field, which the existing profile-edit flow already gates
/// on the corresponding consent.
///
/// Testing: see `test/features/settings/privacy_consents_section_test.dart`.
class PrivacyConsentsSection extends ConsumerWidget {
  const PrivacyConsentsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    if (user == null) return const SizedBox.shrink();

    final lang = user.appLanguage.isNotEmpty ? user.appLanguage : 'en';
    String tr(String key) {
      final result = t(key, lang);
      return result == key ? t(key, 'en') : result;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('privacy_consents_section_title'),
          style: GoogleFonts.instrumentSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tr('privacy_consents_section_subtitle'),
          style: GoogleFonts.instrumentSans(
            fontSize: 13,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),
        _ConsentTile(
          key: const Key('privacy-consents-orientation'),
          category: 'orientation',
          label: tr('privacy_consents_orientation_label'),
          consent: user.sexualOrientationConsent,
          version: user.sexualOrientationConsentVersion,
          at: user.sexualOrientationConsentAt,
          confirmBody: tr('privacy_consents_withdraw_orientation_confirm'),
          tr: tr,
        ),
        const SizedBox(height: 12),
        _ConsentTile(
          key: const Key('privacy-consents-religion'),
          category: 'religion',
          label: tr('privacy_consents_religion_label'),
          consent: user.religionConsent,
          version: user.religionConsentVersion,
          at: user.religionConsentAt,
          confirmBody: tr('privacy_consents_withdraw_religion_confirm'),
          tr: tr,
        ),
        const SizedBox(height: 12),
        _ConsentTile(
          key: const Key('privacy-consents-ethnicity'),
          category: 'ethnicity',
          label: tr('privacy_consents_ethnicity_label'),
          consent: user.ethnicityConsent,
          version: user.ethnicityConsentVersion,
          at: user.ethnicityConsentAt,
          confirmBody: tr('privacy_consents_withdraw_ethnicity_confirm'),
          tr: tr,
        ),
      ],
    );
  }
}

class _ConsentTile extends ConsumerWidget {
  const _ConsentTile({
    super.key,
    required this.category,
    required this.label,
    required this.consent,
    required this.version,
    required this.at,
    required this.confirmBody,
    required this.tr,
  });

  final String category;
  final String label;
  final bool? consent;
  final String? version;
  final DateTime? at;
  final String confirmBody;
  final String Function(String) tr;

  String _stateLabel() {
    if (consent == null) return tr('privacy_consents_state_never');
    return consent == true
        ? tr('privacy_consents_state_granted')
        : tr('privacy_consents_state_withdrawn');
  }

  Future<void> _confirmAndWithdraw(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: Text(confirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(tr('privacy_consents_cancel_button')),
          ),
          TextButton(
            key: const Key('privacy-consents-confirm-withdraw'),
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(tr('privacy_consents_confirm_button')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(authStateProvider.notifier).withdrawArt9Consent(category);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('privacy_consents_withdraw_button'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isGranted = consent == true;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            isGranted ? LucideIcons.shieldCheck : LucideIcons.shieldOff,
            color: isGranted
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    _stateLabel(),
                    if (version != null && version!.isNotEmpty)
                      '${tr('privacy_consents_version_label')} $version',
                    if (at != null) _formatDate(at!),
                  ].join(' · '),
                  style: GoogleFonts.instrumentSans(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isGranted)
            TextButton(
              key: Key('privacy-consents-$category-withdraw'),
              onPressed: () => _confirmAndWithdraw(context, ref),
              child: Text(
                tr('privacy_consents_withdraw_button'),
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}';
  }
}
