import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';

class GenderStep extends StatelessWidget {
  const GenderStep({
    super.key,
    required this.selectedGender,
    required this.onGenderSelect,
    required this.isClassicAppearance,
    required this.onAppearanceToggle,
    required this.isDark,
    required this.onDarkModeToggle,
    required this.onBack,
    required this.onNext,
    required this.onNonBinaryTap,
    required this.tr,
  });

  final String? selectedGender;
  final ValueChanged<String> onGenderSelect;
  final bool isClassicAppearance;
  final ValueChanged<bool> onAppearanceToggle;
  final bool isDark;
  final ValueChanged<bool> onDarkModeToggle;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onNonBinaryTap;
  final String Function(String) tr;

  @override
  Widget build(BuildContext context) {
    return ScrollableFormPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TrembleBackButton(label: tr('back'), onPressed: onBack),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          StepHeader(tr('whats_your_gender')),
          const SizedBox(height: 40),
          OptionPill(
            label: tr('gender_male'),
            selected: selectedGender == 'male',
            icon: Icons.male,
            onTap: () => onGenderSelect('male'),
          ),
          OptionPill(
            label: tr('gender_female'),
            selected: selectedGender == 'female',
            icon: Icons.female,
            onTap: () => onGenderSelect('female'),
          ),
          OptionPill(
            label: tr('non_binary'),
            selected: selectedGender == 'non_binary',
            icon: LucideIcons.userX,
            onTap: () {
              onGenderSelect('non_binary');
              onNonBinaryTap();
            },
          ),
          const SizedBox(height: 32),
          StepHeader(tr('app_appearance'), subtitle: ''),
          const SizedBox(height: 16),
          _toggleRow(
            context,
            label: 'Classic or gender based',
            value: isClassicAppearance,
            onChanged: onAppearanceToggle,
          ),
          const SizedBox(height: 12),
          _toggleRow(
            context,
            label: 'Dark mode',
            value: isDark,
            onChanged: onDarkModeToggle,
          ),
          const SizedBox(height: 24),
          ContinueButton(
            enabled: selectedGender != null,
            onTap: onNext,
            label: tr('continue_btn'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _toggleRow(
    BuildContext context, {
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(15),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
