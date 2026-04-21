import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
                  StepHeader(tr('whats_your_name')),
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
            if (verificationBanner != null) ...[
              const SizedBox(height: 16),
              verificationBanner!,
            ],
            const Spacer(),
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
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Styled input field used across multiple registration steps ───────────────
class RegistrationInputField extends StatelessWidget {
  const RegistrationInputField({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.keyboard,
    this.readOnly = false,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final TextInputType? keyboard;
  final bool readOnly;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.white60 : Colors.black54;
    final iconColor = isDark ? Colors.white38 : Colors.black38;
    final borderColor = isDark ? Colors.white30 : Colors.black26;
    final borderFocusColor = isDark ? Colors.white : Colors.black;

    return TextField(
      controller: controller,
      keyboardType: keyboard,
      readOnly: readOnly,
      style: GoogleFonts.instrumentSans(color: textColor, fontSize: 17),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.instrumentSans(color: hintColor),
        prefixIcon:
            icon != null ? Icon(icon, color: iconColor, size: 20) : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: BorderSide(color: borderFocusColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }
}
