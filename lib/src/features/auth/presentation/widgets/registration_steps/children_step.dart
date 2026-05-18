import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';
import 'partner_preference_modal.dart';

class ChildrenStep extends StatefulWidget {
  const ChildrenStep({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onBack,
    required this.onNext,
    required this.onSavePartner,
    required this.tr,
    this.hasChildren,
    required this.onHasChildrenChanged,
  });

  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final ValueChanged<List<String>?> onSavePartner;
  final String Function(String) tr;
  final bool? hasChildren;
  final ValueChanged<bool> onHasChildrenChanged;

  @override
  State<ChildrenStep> createState() => _ChildrenStepState();
}

class _ChildrenStepState extends State<ChildrenStep> {
  static const _options = [
    {'key': 'want_someday', 'icon': LucideIcons.heart},
    {'key': 'dont_want', 'icon': LucideIcons.ban},
    {'key': 'have_and_want_more', 'icon': LucideIcons.users},
    {'key': 'have_and_dont_want_more', 'icon': LucideIcons.userCheck},
    {'key': 'not_sure', 'icon': LucideIcons.helpCircle},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final textColor = isDark ? Colors.white : Colors.black;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TrembleBackButton(
                      onPressed: widget.onBack,
                      label: widget.tr('back'),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),
                StepHeader(widget.tr('do_you_want_children')),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Want kids options ───────────────────────────────────────
                  ..._options.map((o) => OptionPill(
                        label: widget.tr('children_${o['key']}'),
                        selected: widget.selected == o['key'],
                        icon: o['icon'] as IconData?,
                        onTap: () => widget.onSelect(o['key'] as String),
                      )),
                  const SizedBox(height: 24),
                  // ── Do you have kids toggle ─────────────────────────────────
                  _HasChildrenToggle(
                    label: widget.tr('has_children'),
                    value: widget.hasChildren ?? false,
                    isDark: isDark,
                    primary: primary,
                    textColor: textColor,
                    onChanged: widget.onHasChildrenChanged,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ContinueButton(
              enabled: widget.selected != null,
              label: widget.tr('continue_btn'),
              onTap: () {
                final sel = widget.selected;
                if (sel == null) return;
                showPartnerPreferenceModal(
                  context,
                  title: widget.tr('do_you_want_children'),
                  options: _options
                      .map((o) => {
                            'key': o['key'] as String,
                            'label': widget.tr('children_${o['key']}'),
                            'icon': o['icon'] as IconData,
                          })
                      .toList(),
                  userSelection: sel,
                  showCustom: true,
                  onSave: widget.onSavePartner,
                  onNext: widget.onNext,
                  tr: widget.tr,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HasChildrenToggle extends StatelessWidget {
  const _HasChildrenToggle({
    required this.label,
    required this.value,
    required this.isDark,
    required this.primary,
    required this.textColor,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final bool isDark;
  final Color primary;
  final Color textColor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: value
            ? primary.withValues(alpha: 0.10)
            : (isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.03)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? primary.withValues(alpha: 0.5)
              : (isDark ? Colors.white24 : Colors.black12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.baby,
            size: 18,
            color: value ? primary : (isDark ? Colors.white60 : Colors.black45),
          ),
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
            inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
