import 'dart:ui';
import 'package:flutter/material.dart';

class LiquidNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<LiquidNavItem> items;
  const LiquidNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    const double itemWidth = 64.0;
    const double navHeight = 72.0;
    const double paddingHorizontal = 16.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Center(
      heightFactor: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: navHeight,
            padding: const EdgeInsets.symmetric(horizontal: paddingHorizontal),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 40,
                  spreadRadius: -5,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Bubbly Background Indicator
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutQuart,
                  left: (currentIndex * itemWidth),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: itemWidth,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.45),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),

                // Navigation Items
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isSelected = currentIndex == index;

                    return GestureDetector(
                      onTap: () => onTap(index),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: itemWidth,
                        height: navHeight,
                        alignment: Alignment.center,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 600),
                          scale: isSelected ? 1.15 : 1.0,
                          curve: Curves.easeOutQuart,
                          child: Icon(
                            item.icon,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.4)
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.4)),
                            size: 28,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LiquidNavItem {
  final IconData icon;
  final String label;

  LiquidNavItem({required this.icon, required this.label});
}
