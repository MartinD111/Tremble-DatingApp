import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// A single skeleton placeholder rectangle with a pulsing shimmer animation.
///
/// The shimmer oscillates between a barely-visible and slightly-visible opacity
/// so the placeholder reads as "loading content" without being distracting.
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 6,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.06, end: 0.18).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: _opacity.value)
              : TrembleTheme.textColor.withValues(alpha: _opacity.value),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

/// Renders [child] only after [delay] has elapsed.
///
/// Use this to gate skeleton screens so they are never shown when data arrives
/// quickly — the skeleton only appears if the fetch takes longer than [delay].
class DelayedChild extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const DelayedChild({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 300),
  });

  @override
  State<DelayedChild> createState() => _DelayedChildState();
}

class _DelayedChildState extends State<DelayedChild> {
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _visible ? widget.child : const SizedBox.shrink();
}
