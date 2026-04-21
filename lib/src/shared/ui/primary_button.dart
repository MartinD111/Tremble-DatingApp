import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isSecondary;
  final bool isLoading;
  final double? width;
  final double? height;
  final IconData? icon;

  const PrimaryButton(
      {super.key,
      required this.text,
      required this.onPressed,
      this.isSecondary = false,
      this.isLoading = false,
      this.width,
      this.height,
      this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSecondary
            ? (isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04))
            : Theme.of(context).colorScheme.primary,
        foregroundColor: isSecondary
            ? Theme.of(context).colorScheme.onSurface
            : Colors.white,
        side: isSecondary
            ? BorderSide(color: isDark ? Colors.white24 : Colors.black12)
            : null,
        minimumSize: Size(width ?? double.infinity, height ?? 56),
        maximumSize: width != null ? Size(width!, height ?? 56) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        elevation: 0,
      ),
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : (icon != null ? Icon(icon) : const SizedBox.shrink()),
      label: isLoading
          ? const SizedBox.shrink()
          : Text(
              text,
              style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontSize: 16) ??
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    );
  }
}
