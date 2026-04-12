import 'package:flutter/material.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';
import 'partner_preference_modal.dart';

/// Generic single-select registration step that optionally shows a
/// partner-preference bottom sheet after the user confirms their answer.
class SubScreenStep extends StatelessWidget {
  const SubScreenStep({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.onBack,
    required this.onNext,
    this.onSavePartner,
    this.showCustomPartnerPref = true,
    this.overrideContinue,
    required this.tr,
  });

  final String title;
  final List<Map<String, Object>> options;
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final ValueChanged<List<String>?>? onSavePartner;
  final bool showCustomPartnerPref;
  final VoidCallback? overrideContinue;
  final String Function(String) tr;

  @override
  Widget build(BuildContext context) {
    return ScrollableFormPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: TrembleBackButton(
              onPressed: onBack,
              label: tr('back'),
            ),
          ),
          const SizedBox(height: 24),
          StepHeader(title),
          const SizedBox(height: 40),
          ...options.map(
            (o) => OptionPill(
              label: o['label'] as String,
              selected: selected == o['key'],
              icon: o['icon'] as IconData?,
              onTap: () => onSelect(o['key'] as String),
            ),
          ),
          const SizedBox(height: 24),
          ContinueButton(
            enabled: selected != null,
            label: tr('continue_btn'),
            onTap: overrideContinue ??
                () {
                  final savePartner = onSavePartner;
                  final currentSelected = selected;
                  // Belt-and-suspenders: ContinueButton is already disabled when
                  // selected is null, but guard again in case of rare race.
                  if (currentSelected == null) return;
                  if (savePartner != null) {
                    showPartnerPreferenceModal(
                      context,
                      title: title,
                      options: options,
                      userSelection: currentSelected,
                      showCustom: showCustomPartnerPref,
                      onSave: savePartner,
                      onNext: onNext,
                    );
                  } else {
                    onNext();
                  }
                },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
