import 'package:flutter/material.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';
import 'partner_preference_modal.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ChildrenStep extends StatefulWidget {
  const ChildrenStep({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onBack,
    required this.onNext,
    required this.onSavePartner,
    required this.tr,
  });

  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final ValueChanged<List<String>?> onSavePartner;
  final String Function(String) tr;

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
                  ..._options.map((o) => OptionPill(
                        label: widget.tr('children_${o['key']}'),
                        selected: widget.selected == o['key'],
                        icon: o['icon'] as IconData?,
                        onTap: () => widget.onSelect(o['key'] as String),
                      )),
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
