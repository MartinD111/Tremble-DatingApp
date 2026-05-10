import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import 'tremble_back_button.dart';

/// A brand-consistent floating header with a back button and centered title.
class TrembleHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final double titleOpacity; // Applied to title
  final double buttonsOpacity; // Applied to buttons for scroll-aware fading
  final bool showBackButton;

  const TrembleHeader({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.titleOpacity = 1.0, // Default to fully visible
    this.buttonsOpacity = 1.0, // Default to fully visible
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + 12, 24, 0),
      height: MediaQuery.of(context).padding.top + 90,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centers the title relative to the entire screen width
          Positioned.fill(
            child: Center(
              child: AnimatedOpacity(
                opacity: titleOpacity,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 56), // Prevent button overlap
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TrembleTheme.displayFont(
                      color: textColor,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Back button on the left
          if (showBackButton)
            Align(
              alignment: Alignment.centerLeft,
              child: AnimatedOpacity(
                opacity: buttonsOpacity,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                child: TrembleBackButton(
                    onPressed: onBack ??
                        () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/');
                          }
                        }),
              ),
            ),
          // Optional actions on the right (balanced by back button size)
          if (actions != null)
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                opacity: buttonsOpacity,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
