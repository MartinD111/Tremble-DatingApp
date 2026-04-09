import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/theme_provider.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/radar_background.dart';

class GradientScaffold extends ConsumerWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final bool extendBody;
  final List<Color>? gradientColors;

  const GradientScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.extendBody = false,
    this.gradientColors,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final showPing = user?.showPingAnimation ?? true;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final bgColors = gradientColors ??
        TrembleTheme.getGradient(
          isDarkMode: isDark,
          isPrideMode: user?.isPrideMode ?? false,
          gender: user?.gender,
        );

    return Scaffold(
      extendBody: extendBody,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: bgColors,
              ),
            ),
          ),
          if (showPing)
            _SubtlePingOverlay(
              accentColor: bgColors.isNotEmpty
                  ? bgColors.first
                  : const Color(0xFFF4436C),
            ),
          SafeArea(
            child: DefaultTextStyle(
              style: GoogleFonts.instrumentSans(
                color: Colors.white,
                fontSize: 14,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight pulsing dots overlay — subtle ambient animation
class _SubtlePingOverlay extends StatefulWidget {
  final Color accentColor;
  const _SubtlePingOverlay({required this.accentColor});

  @override
  State<_SubtlePingOverlay> createState() => _SubtlePingOverlayState();
}

class _SubtlePingOverlayState extends State<_SubtlePingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  final List<PulsingDot> _dots = [];

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _generateDots();
  }

  void _generateDots() {
    final random = math.Random(42); // Use fixed seed or remove for randomness
    for (int i = 0; i < 12; i++) {
      _dots.add(PulsingDot(
        angle: random.nextDouble() * 2 * math.pi,
        distance: 0.3 + random.nextDouble() * 0.6,
        delay: random.nextDouble(),
      ));
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _pulseController]),
      builder: (context, child) {
        return CustomPaint(
          painter: RadarPainter(
            rotation: _rotationController.value,
            pulseAnimation: _pulseController,
            dots: _dots,
            accentColor: widget.accentColor,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}
