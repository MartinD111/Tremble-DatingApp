import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';
import 'partner_preference_modal.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Nicotine product options — enum-like constants kept close to the UI
// ─────────────────────────────────────────────────────────────────────────────
class NicotineOptions {
  static final List<Map<String, dynamic>> products = [
    {'key': 'cigarettes', 'icon': LucideIcons.cigarette},
    {'key': 'vape', 'icon': LucideIcons.wind},
    {'key': 'iqos', 'icon': LucideIcons.zap},
    {'key': 'zyn', 'icon': LucideIcons.circle},
    {'key': 'shisha', 'icon': LucideIcons.flame},
    {'key': 'cannabis', 'icon': LucideIcons.leaf},
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// NicotineStep — multi-select chips + "None" pill
// ─────────────────────────────────────────────────────────────────────────────
class NicotineStep extends StatelessWidget {
  const NicotineStep({
    super.key,
    required this.selected,
    required this.onToggle,
    required this.onBack,
    required this.onNext,
    required this.onSavePartner,
    required this.tr,
  });

  /// Currently selected product keys (empty = none).
  final List<String> selected;

  /// Toggle a single product key on/off.
  final ValueChanged<String> onToggle;
  final VoidCallback onBack;
  final VoidCallback onNext;

  /// Partner filter — single-choice string: 'any' | 'none_only' | 'no_preference'
  final ValueChanged<List<String>?> onSavePartner;
  final String Function(String) tr;

  bool get _noneSelected => selected.isEmpty;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            TrembleBackButton(label: tr('back'), onPressed: onBack),
            const Spacer(),
            StepHeader(
              tr('nicotine_title'),
              subtitle: tr('nicotine_subtitle'),
            ),
            const SizedBox(height: 28),

            // ── "None" pill ───────────────────────────────────────────────────
            _NicotinePill(
              label: tr('nicotine_none'),
              icon: LucideIcons.ban,
              selected: _noneSelected,
              isDark: isDark,
              primary: primary,
              onTap: () {
                // Tapping "None" clears all selections
                for (final p in NicotineOptions.products) {
                  if (selected.contains(p['key'])) {
                    onToggle(p['key'] as String);
                  }
                }
              },
            ),
            const SizedBox(height: 16),

            // ── Product grid ──────────────────────────────────────────────────
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: NicotineOptions.products.map((p) {
                final key = p['key'] as String;
                final icon = p['icon'] as IconData;
                final isSelected = selected.contains(key);
                return _NicotineChip(
                  label: tr('nicotine_$key'),
                  icon: icon,
                  selected: isSelected,
                  isDark: isDark,
                  primary: primary,
                  onTap: () => onToggle(key),
                );
              }).toList(),
            ),

            const Spacer(),
            ContinueButton(
              enabled: true, // always enabled — "none" is valid
              label: tr('continue_btn'),
              onTap: () {
                if (_noneSelected) {
                  // User uses nothing → ask partner preference
                  showPartnerPreferenceModal(
                    context,
                    title: tr('nicotine_partner_q'),
                    options: [
                      {
                        'key': 'no_preference',
                        'label': tr('nicotine_pref_no_preference')
                      },
                      {
                        'key': 'none_only',
                        'label': tr('nicotine_pref_none_only')
                      },
                      {'key': 'any', 'label': tr('nicotine_pref_any')},
                    ],
                    userSelection: '',
                    showCustom: false,
                    onSave: onSavePartner,
                    onNext: onNext,
                    tr: tr,
                  );
                } else {
                  onNext();
                }
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NicotinePill — full-width "None" option row
// ─────────────────────────────────────────────────────────────────────────────
class _NicotinePill extends StatelessWidget {
  const _NicotinePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: 0.18)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color:
                selected ? primary : (isDark ? Colors.white24 : Colors.black12),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: selected
                    ? primary
                    : (isDark ? Colors.white60 : Colors.black45)),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.instrumentSans(
                fontSize: 16,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            const Spacer(),
            if (selected) Icon(Icons.check_circle, color: primary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NicotineChip — compact chip for individual products
// ─────────────────────────────────────────────────────────────────────────────
class _NicotineChip extends StatelessWidget {
  const _NicotineChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: 0.18)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color:
                selected ? primary : (isDark ? Colors.white24 : Colors.black12),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected
                    ? primary
                    : (isDark ? Colors.white60 : Colors.black45)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.instrumentSans(
                fontSize: 14,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
