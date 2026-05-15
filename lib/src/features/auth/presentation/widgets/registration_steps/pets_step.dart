import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';

class PetsStep extends StatelessWidget {
  const PetsStep({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onBack,
    required this.onContinueTap,
    required this.tr,
  });

  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onBack;

  /// Called when Continue is tapped. Parent is responsible for showing
  /// the partner-preference modal and then advancing the page.
  final VoidCallback onContinueTap;
  final String Function(String) tr;

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
                    TrembleBackButton(onPressed: onBack, label: tr('back')),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),
                StepHeader(tr('pets')),
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
                  OptionPill(
                    label: tr('dog_person'),
                    icon: LucideIcons.dog,
                    selected: selected == 'dog',
                    onTap: () => onSelect('dog'),
                  ),
                  OptionPill(
                    label: tr('cat_person'),
                    icon: LucideIcons.cat,
                    selected: selected == 'cat',
                    onTap: () => onSelect('cat'),
                  ),
                  OptionPill(
                    label: tr('nothing'),
                    selected: selected == 'nothing',
                    onTap: () => onSelect('nothing'),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ContinueButton(
              enabled: selected != null,
              label: tr('continue_btn'),
              onTap: onContinueTap,
            ),
          ),
        ],
      ),
    );
  }
}
