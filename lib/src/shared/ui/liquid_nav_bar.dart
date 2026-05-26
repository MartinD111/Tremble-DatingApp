import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LiquidNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<LiquidNavItem> items;
  final Set<int> pulsingIndexes;
  final Widget Function(int index, Widget child)? itemWrapper;
  const LiquidNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.pulsingIndexes = const {},
    this.itemWrapper,
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
                    final isPulsing = pulsingIndexes.contains(index);

                    final itemChild = Container(
                      width: itemWidth,
                      height: navHeight,
                      alignment: Alignment.center,
                      child: _PulsingNavIcon(
                        icon: item.icon,
                        isSelected: isSelected,
                        isPulsing: isPulsing,
                        color: isSelected || isPulsing
                            ? Colors.white
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.4)
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.4)),
                      ),
                    );

                    final wrappedChild = itemWrapper != null
                        ? itemWrapper!(index, itemChild)
                        : itemChild;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onTap(index);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: wrappedChild,
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

class _PulsingNavIcon extends StatefulWidget {
  const _PulsingNavIcon({
    required this.icon,
    required this.isSelected,
    required this.isPulsing,
    required this.color,
  });

  final IconData icon;
  final bool isSelected;
  final bool isPulsing;
  final Color color;

  @override
  State<_PulsingNavIcon> createState() => _PulsingNavIconState();
}

class _PulsingNavIconState extends State<_PulsingNavIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isPulsing) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PulsingNavIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing != oldWidget.isPulsing) {
      if (widget.isPulsing) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.animateTo(0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        final pulseScale = widget.isPulsing ? _scale.value : 1.0;
        return AnimatedScale(
          duration: const Duration(milliseconds: 600),
          scale: (widget.isSelected ? 1.15 : 1.0) * pulseScale,
          curve: Curves.easeOutQuart,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: widget.isPulsing
                  ? [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.48),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ]
                  : const [],
            ),
            child: Icon(widget.icon, color: widget.color, size: 28),
          ),
        );
      },
    );
  }
}

class LiquidNavItem {
  final IconData icon;
  final String label;

  LiquidNavItem({required this.icon, required this.label});
}
