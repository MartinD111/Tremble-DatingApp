import 'package:flutter/material.dart';
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
    return ScrollableFormPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                StepHeader(tr('pets')),
                Positioned(
                  left: 0,
                  top: 0,
                  child: TrembleBackButton(
                    onPressed: onBack,
                    label: tr('back'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OptionPill(
            label: tr('dog_person'),
            selected: selected == 'dog',
            onTap: () => onSelect('dog'),
          ),
          OptionPill(
            label: tr('cat_person'),
            selected: selected == 'cat',
            onTap: () => onSelect('cat'),
          ),
          OptionPill(
            label: tr('nothing'),
            selected: selected == 'nothing',
            onTap: () => onSelect('nothing'),
          ),
          const SizedBox(height: 24),
          ContinueButton(
            enabled: selected != null,
            label: tr('continue_btn'),
            onTap: onContinueTap,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
