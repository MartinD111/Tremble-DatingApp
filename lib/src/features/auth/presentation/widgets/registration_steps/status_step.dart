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
                StepHeader(tr('status')),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      label: status == 'student'
                          ? tr('course_of_study')
                          : tr('job_title'),
                      controller: occupationController,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ContinueButton(
              enabled: status != null,
              onTap: onNext,
              label: tr('continue_btn'),
            ),
          ),
        ],
      ),
    );
  }
}
