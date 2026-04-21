import 'package:flutter/material.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';

class StatusStep extends StatelessWidget {
  const StatusStep({
    super.key,
    required this.status,
    required this.onStatusSelect,
    required this.onBack,
    required this.onNext,
    required this.tr,
  });

  final String? status;
  final ValueChanged<String> onStatusSelect;
  final VoidCallback onBack;
  final VoidCallback onNext;
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
            SizedBox(
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  StepHeader(tr('status')),
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
            const Spacer(),
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
            const Spacer(),
            ContinueButton(
              enabled: status != null,
              onTap: onNext,
              label: tr('continue_btn'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
