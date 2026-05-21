import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';
import 'partner_preference_modal.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Nicotine product options — cannabis is handled separately as a toggle
// ─────────────────────────────────────────────────────────────────────────────
class NicotineOptions {
  static final List<Map<String, dynamic>> products = [
    {'key': 'cigarettes', 'icon': LucideIcons.cigarette},
    {'key': 'vape', 'icon': LucideIcons.wind},
    {'key': 'iqos', 'icon': LucideIcons.zap},
    {'key': 'zyn', 'icon': LucideIcons.circle},
    {'key': 'shisha', 'icon': LucideIcons.flame},
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// NicotineStep — multi-select chips + separate cannabis toggle
// ─────────────────────────────────────────────────────────────────────────────
class NicotineStep extends StatefulWidget {
  const NicotineStep({
    super.key,
    required this.selected,
    required this.onToggle,
    required this.onBack,
    required this.onNext,
    required this.onSavePartner,
    required this.tr,
  });

  final List<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final ValueChanged<List<String>?> onSavePartner;
  final String Function(String) tr;

  @override
  State<NicotineStep> createState() => _NicotineStepState();
}

class _NicotineStepState extends State<NicotineStep> {
  bool _showCannabisDisclaimer = false;

  bool get _noneSelected => widget.selected.isEmpty;
  bool get _cannabisSelected => widget.selected.contains('cannabis');

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
            TrembleBackButton(
                label: widget.tr('back'), onPressed: widget.onBack),
            const SizedBox(height: 24),
            StepHeader(
              widget.tr('nicotine_title'),
              subtitle: widget.tr('nicotine_subtitle'),
            ),
            const SizedBox(height: 28),

            // ── "None" pill ───────────────────────────────────────────────────
            _NicotinePill(
              label: widget.tr('nicotine_none'),
              icon: LucideIcons.ban,
              selected: _noneSelected,
              isDark: isDark,
              primary: primary,
              onTap: () {
                for (final p in NicotineOptions.products) {
                  if (widget.selected.contains(p['key'])) {
                    widget.onToggle(p['key'] as String);
                  }
                }
                if (_cannabisSelected) widget.onToggle('cannabis');
                if (_showCannabisDisclaimer) {
                  setState(() => _showCannabisDisclaimer = false);
                }
              },
            ),
            const SizedBox(height: 16),

            // ── Product grid (no cannabis) ────────────────────────────────────
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: NicotineOptions.products.map((p) {
                final key = p['key'] as String;
                final icon = p['icon'] as IconData;
                final isSelected = widget.selected.contains(key);
                return _NicotineChip(
                  label: widget.tr('nicotine_$key'),
                  icon: icon,
                  selected: isSelected,
                  isDark: isDark,
                  primary: primary,
                  onTap: () => widget.onToggle(key),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Cannabis toggle ───────────────────────────────────────────────
            _CannabisToggleRow(
              label: widget.tr('nicotine_cannabis'),
              value: _cannabisSelected,
              isDark: isDark,
              primary: primary,
              onChanged: (val) {
                widget.onToggle('cannabis');
                setState(() => _showCannabisDisclaimer = val);
              },
            ),

            // ── Cannabis disclaimer ───────────────────────────────────────────
            if (_showCannabisDisclaimer) ...[
              const SizedBox(height: 12),
              _CannabisDisclaimer(
                text: widget.tr('cannabis_disclaimer'),
                isDark: isDark,
              ),
            ],

            const Spacer(),
            ContinueButton(
              enabled: true,
              label: widget.tr('continue_btn'),
              onTap: () {
                if (_noneSelected) {
                  showPartnerPreferenceModal(
                    context,
                    title: widget.tr('nicotine_partner_q'),
                    options: [
                      {
                        'key': 'no_preference',
                        'label': widget.tr('nicotine_pref_no_preference')
                      },
                      {
                        'key': 'none_only',
                        'label': widget.tr('nicotine_pref_none_only')
                      },
                      {'key': 'any', 'label': widget.tr('nicotine_pref_any')},
                    ],
                    userSelection: '',
                    showCustom: false,
                    onSave: widget.onSavePartner,
                    onNext: widget.onNext,
                    tr: widget.tr,
                  );
                } else {
                  widget.onNext();
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
// _CannabisToggleRow
// ─────────────────────────────────────────────────────────────────────────────
class _CannabisToggleRow extends StatelessWidget {
  const _CannabisToggleRow({
    required this.label,
    required this.value,
    required this.isDark,
    required this.primary,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final bool isDark;
  final Color primary;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: value
            ? primary.withValues(alpha: 0.18)
            : (isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04)),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: value ? primary : (isDark ? Colors.white24 : Colors.black12),
          width: value ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.leaf,
              size: 18,
              color:
                  value ? primary : (isDark ? Colors.white60 : Colors.black45)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.instrumentSans(
                fontSize: 15,
                fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                color: value
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: primary,
            activeTrackColor: primary.withValues(alpha: 0.35),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CannabisDisclaimer
// ─────────────────────────────────────────────────────────────────────────────
class _CannabisDisclaimer extends StatelessWidget {
  const _CannabisDisclaimer({required this.text, required this.isDark});

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: isDark ? 0.12 : 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.alertTriangle,
              size: 16, color: Colors.amber.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.instrumentSans(
                fontSize: 12,
                color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                height: 1.4,
              ),
            ),
          ),
        ],
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
