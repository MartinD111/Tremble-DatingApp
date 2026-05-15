import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme_provider.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';
import 'partner_preference_modal.dart';

/// Generic single-select registration step that optionally shows a
/// partner-preference bottom sheet after the user confirms their answer.
class SubScreenStep extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);

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
                      onPressed: onBack,
                      label: tr('back'),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),
                StepHeader(title),
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
                  ...options.map(
                    (o) => OptionPill(
                      label: o['label'] as String,
                      selected: selected == o['key'],
                      icon: o['icon'] as IconData?,
                      iconColor: o['iconColor'] as Color?,
                      onTap: () => onSelect(o['key'] as String),
                    ),
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
              onTap: overrideContinue ??
                  () {
                    final savePartner = onSavePartner;
                    final currentSelected = selected;
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
                        tr: tr,
                      );
                    } else {
                      onNext();
                    }
                  },
            ),
          ),
        ],
      ),
    );
  }
}
