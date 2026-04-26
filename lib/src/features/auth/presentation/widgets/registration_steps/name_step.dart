import 'package:flutter/material.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';

class NameStep extends StatelessWidget {
  const NameStep({
    super.key,
    required this.nameController,
    required this.onBack,
    required this.onNext,
    required this.tr,
    this.verificationBanner,
  });

  final TextEditingController nameController;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final String Function(String) tr;

  /// Optional banner widget (email verification notice) injected from parent.
  final Widget? verificationBanner;

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
            ],
          ),
          const Spacer(),
          StepHeader(tr('whats_your_name')),
          if (verificationBanner != null) ...[
            const SizedBox(height: 16),
            verificationBanner!,
          ],
          const SizedBox(height: 24),
          TextField(
            controller: nameController,
            autofocus: true,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 28,
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
            onChanged: (_) {},
            decoration: InputDecoration(
              hintText: tr('name_hint'),
              hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 28,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: BorderSide(
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: BorderSide(
                  color: isDark ? Colors.white : Colors.black,
                  width: 2,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            ),
          ),
          const SizedBox(height: 24),
          // Rebuild when text changes — parent wraps in ValueListenableBuilder
          ListenableBuilder(
            listenable: nameController,
            builder: (_, __) => ContinueButton(
              enabled: nameController.text.trim().isNotEmpty,
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
