import 'package:flutter/material.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';
import 'partner_preference_modal.dart';

class SmokingStep extends StatelessWidget {
  const SmokingStep({
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
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            TrembleBackButton(label: tr('back'), onPressed: onBack),
            const Spacer(),
            StepHeader(tr('do_you_smoke')),
            const SizedBox(height: 32),
            OptionPill(
              label: tr('smoke_yes'),
              selected: selected == 'yes',
              onTap: () => onSelect('yes'),
            ),
            OptionPill(
              label: tr('smoke_no'),
              selected: selected == 'no',
              onTap: () => onSelect('no'),
            ),
            const Spacer(),
            ContinueButton(
              enabled: selected != null,
              label: tr('continue_btn'),
              onTap: () {
                if (selected == 'no') {
                  showPartnerPreferenceModal(
                    context,
                    title: tr('do_you_smoke'),
                    options: [
                      {'key': 'no', 'label': tr('smoke_no')},
                    ],
                    userSelection: 'no',
                    showCustom: false,
                    onSave: onSavePartner,
                    onNext: onNext,
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
