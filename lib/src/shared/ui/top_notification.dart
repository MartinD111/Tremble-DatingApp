import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TopNotification {
  static void show({
    required BuildContext context,
    required String message,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _TopNotificationWidget(
        message: message,
        icon: icon,
        duration: duration,
        onDismissed: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _TopNotificationWidget extends StatefulWidget {
  final String message;
  final IconData? icon;
  final Duration duration;
  final VoidCallback onDismissed;

  const _TopNotificationWidget({
    Key? key,
    required this.message,
    this.icon,
    required this.duration,
    required this.onDismissed,
  }) : super(key: key);

  @override
  _TopNotificationWidgetState createState() => _TopNotificationWidgetState();
}

class _TopNotificationWidgetState extends State<_TopNotificationWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;
  bool _dismissed = false;

  double _dragX = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted && !_dismissed) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismissed();
      }
    });
  }

  void _dismissHorizontal(double toX) {
    if (_dismissed) return;
    _dismissed = true;
    // Animate the card off-screen in the swipe direction then remove
    final screenWidth = MediaQuery.of(context).size.width;
    final target = toX > 0 ? screenWidth + 200.0 : -(screenWidth + 200.0);

    // Use a simple animation from current drag position to off-screen
    final slideOut = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    final tween = Tween<double>(begin: _dragX, end: target);
    slideOut.addListener(() {
      if (mounted) setState(() => _dragX = tween.evaluate(slideOut));
    });
    slideOut.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        slideOut.dispose();
        if (mounted) widget.onDismissed();
      }
    });
    slideOut.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final primary = Theme.of(context).colorScheme.primary;

    return Positioned(
      top: topPadding + 20,
      left: 24,
      right: 24,
      child: Material(
        type: MaterialType.transparency,
        child: SlideTransition(
          position: _offsetAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: GestureDetector(
              onTap: _dismiss,
              onHorizontalDragUpdate: (details) {
                if (_dismissed) return;
                setState(() => _dragX += details.delta.dx);
              },
              onHorizontalDragEnd: (details) {
                if (_dismissed) return;
                final velocity = details.primaryVelocity ?? 0;
                final threshold = MediaQuery.of(context).size.width * 0.35;
                if (_dragX.abs() > threshold || velocity.abs() > 600) {
                  _dismissHorizontal(_dragX);
                } else {
                  // Snap back
                  setState(() => _dragX = 0.0);
                }
              },
              child: Transform.translate(
                offset: Offset(_dragX, 0),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            widget.icon ?? Icons.check,
                            size: 32,
                            color: primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Material(
                        type: MaterialType.transparency,
                        child: Text(
                          widget.message,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.instrumentSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white : const Color(0xFF1A1A18),
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
