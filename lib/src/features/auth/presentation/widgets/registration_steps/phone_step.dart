import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';

class PhoneStep extends StatelessWidget {
  const PhoneStep({
    super.key,
    required this.phoneController,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
    required this.tr,
  });

  final TextEditingController phoneController;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final String Function(String) tr;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScrollableFormPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TrembleBackButton(onPressed: onBack, label: tr('back')),
              const Spacer(),
              TextButton(
                onPressed: onSkip,
                child: Text(
                  tr('skip'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          StepHeader(
            tr('whats_your_phone'),
            subtitle: tr('phone_subtitle'),
          ),
          const SizedBox(height: 32),
          RegistrationInputField(
            label: tr('phone_label'),
            controller: phoneController,
            icon: LucideIcons.phone,
            keyboard: TextInputType.phone,
          ),
          const SizedBox(height: 32),
          ListenableBuilder(
            listenable: phoneController,
            builder: (_, __) => ContinueButton(
              enabled: phoneController.text.trim().length >= 7,
              onTap: onNext,
              label: tr('continue_btn'),
            ),
          ),
          const Spacer(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
