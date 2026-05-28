import 'package:flutter/material.dart';
import '../../../../../shared/ui/tremble_back_button.dart';
import 'step_shared.dart';

const int nameMaxLength = 50;

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
                StepHeader(tr('whats_your_name')),
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
                  if (verificationBanner != null) ...[
                    verificationBanner!,
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: nameController,
                    maxLength: nameMaxLength,
                    autofocus: true,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 28,
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                    onChanged: (_) {},
                    decoration: InputDecoration(
                      hintText: tr('name_hint'),
                      counterText: '',
                      hintStyle:
                          Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 20),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListenableBuilder(
                    listenable: nameController,
                    builder: (context, _) {
                      final remaining =
                          nameMaxLength - nameController.text.length;
                      final counterColor = remaining < 10
                          ? const Color(0xFFF4436C)
                          : (isDark ? Colors.white54 : Colors.black45);
                      final counterText = tr('name_chars_remaining')
                          .replaceAll('{count}', remaining.toString());

                      return Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          counterText,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: counterColor,
                                  ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ListenableBuilder(
              listenable: nameController,
              builder: (_, __) => ContinueButton(
                enabled: nameController.text.trim().isNotEmpty,
                onTap: onNext,
                label: tr('continue_btn'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
