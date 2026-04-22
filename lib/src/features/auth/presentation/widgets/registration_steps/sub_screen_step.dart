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
    // Respect the user's actual theme — not forced dark.
    // Watching themeModeProvider ensures this widget rebuilds on theme change.
    ref.watch(themeModeProvider);

    final screenHeight = MediaQuery.of(context).size.height;
    // Reduce vertical padding on small devices (e.g. iPhone SE: 667pt) to
    // prevent bottom overflow without requiring the user to scroll.
    final verticalPadding = screenHeight < 700 ? 20.0 : 32.0;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: verticalPadding,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
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
                  SizedBox(height: screenHeight < 700 ? 24.0 : 40.0),
                  ...options.map(
                    (o) => OptionPill(
                      label: o['label'] as String,
                      selected: selected == o['key'],
                      icon: o['icon'] as IconData?,
                      iconColor: o['iconColor'] as Color?,
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
                          // Belt-and-suspenders: ContinueButton is already
                          // disabled when selected is null, but guard again
                          // in case of rare race.
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
