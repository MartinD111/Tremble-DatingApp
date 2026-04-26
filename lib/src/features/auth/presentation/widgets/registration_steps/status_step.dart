import 'package:flutter/material.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';

class StatusStep extends StatelessWidget {
  const StatusStep({
    super.key,
    required this.status,
    required this.onStatusSelect,
    required this.occupationController,
    required this.onBack,
    required this.onNext,
    required this.tr,
  });

  final String? status;
  final ValueChanged<String> onStatusSelect;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final String Function(String) tr;
  final TextEditingController occupationController;

  @override
  Widget build(BuildContext context) {
    return ScrollableFormPage(
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
          StepHeader(tr('status')),
          const SizedBox(height: 24),
          OptionPill(
            label: tr('student'),
            selected: status == 'student',
            onTap: () => onStatusSelect('student'),
          ),
          OptionPill(
            label: tr('employed'),
            selected: status == 'employed',
            onTap: () => onStatusSelect('employed'),
          ),
          if (status != null) ...[
            const SizedBox(height: 16),
            RegistrationInputField(
              label:
                  status == 'student' ? tr('course_of_study') : tr('job_title'),
              controller: occupationController,
            ),
          ],
          const Spacer(),
          const SizedBox(height: 24),
          ContinueButton(
            enabled: status != null,
            onTap: onNext,
            label: tr('continue_btn'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
