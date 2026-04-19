import 'package:flutter/material.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';

class IntroversionStep extends StatelessWidget {
  const IntroversionStep({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onBack,
    required this.onContinueTap,
    required this.tr,
  });

  /// 0.0 = full introvert, 1.0 = full extrovert.
  final double value;
  final ValueChanged<double> onChanged;
  final VoidCallback onBack;

  /// Called when Continue is tapped. Parent is responsible for showing
  /// the partner-range modal and then advancing the page.
  final VoidCallback onContinueTap;
  final String Function(String) tr;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ScrollableFormPage(
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                StepHeader(tr('introversion')),
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
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr('introvert'),
                style:
                    TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
              Text(
                tr('extrovert'),
                style:
                    TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
            ],
          ),
          Slider(
            value: value,
            onChanged: onChanged,
            divisions: 10,
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveColor:
                isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              () {
                final pct = (value * 100).toInt();
                if (pct <= 30) return '$pct% ${tr('introvert')}';
                if (pct >= 70) return '$pct% ${tr('extrovert')}';
                return '$pct% Ambivert';
              }(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ContinueButton(
            enabled: true,
            label: tr('continue_btn'),
            onTap: onContinueTap,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
