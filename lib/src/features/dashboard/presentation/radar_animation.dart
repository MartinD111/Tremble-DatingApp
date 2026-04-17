import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../../../shared/widgets/radar_painter.dart';
import '../../../shared/ui/tremble_logo.dart';

class RadarAnimation extends StatefulWidget {
  final bool isScanning;
  final bool isVibrationEnabled;
  final double? pingDistance; // 0.0 = center, 1.0 = edge, null = no ping
  final double? pingAngle; // angle in radians for ping position
  final Color? brandColor;

  const RadarAnimation({
    super.key,
    this.isScanning = true,
    this.isVibrationEnabled = true,
    this.pingDistance,
    this.pingAngle,
    this.brandColor,
  });

  @override
  State<RadarAnimation> createState() => _RadarAnimationState();
}

class _RadarAnimationState extends State<RadarAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _radarController;
  late final AnimationController _pingController;
  late final AnimationController _logoController;
  late final Animation<double> _logoOpacity;
  double _lastPingValue = 0.0;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _pingController = AnimationController(
      vsync: this,
      duration: _calculatePingDuration(widget.pingDistance),
    )..addListener(_handlePingAnimation);

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _logoOpacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    if (widget.isScanning) {
      _radarController.repeat();
      _logoController.repeat(reverse: true);
    }

    if (widget.pingDistance != null) {
      _pingController.repeat();
    }

    _initBackgroundService();
  }

  void _handlePingAnimation() {
    if (_pingController.value < _lastPingValue) {
      // Trigger haptic feedback when the ping animation restarts
      if (widget.isVibrationEnabled) {
        HapticFeedback.lightImpact();
      }
    }
    _lastPingValue = _pingController.value;
  }

  Duration _calculatePingDuration(double? distance) {
    if (distance == null) return const Duration(milliseconds: 1500);
    // Exponential-like feel: closer is much faster
    // 0.0 distance -> 250ms
    // 1.0 distance -> 2000ms
    final ms = (250 + (pow(distance, 1.5) * 1750)).toInt();
    return Duration(milliseconds: ms);
  }

  void _initBackgroundService() async {
    final service = FlutterBackgroundService();
    service.on('update').listen((event) {});
  }

  @override
  void didUpdateWidget(covariant RadarAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !_radarController.isAnimating) {
      _radarController.repeat();
      _logoController.repeat(reverse: true);
    } else if (!widget.isScanning && _radarController.isAnimating) {
      _radarController.stop();
      _logoController
        ..stop()
        ..value = 0.0; // reset to 0.4 opacity (tween begin)
    }

    if (widget.pingDistance != null) {
      // Update duration based on new distance
      _pingController.duration = _calculatePingDuration(widget.pingDistance);
      if (!_pingController.isAnimating) {
        _pingController.repeat();
      }
    } else if (widget.pingDistance == null && _pingController.isAnimating) {
      _pingController.stop();
    }
  }

  @override
  void dispose() {
    _radarController.dispose();
    _pingController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [_radarController, _pingController, _logoController]),
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              painter: RadarPainter(
                radarProgress: _radarController.value,
                pingProgress: _pingController.value,
                pingDistance: widget.pingDistance,
                pingAngle: widget.pingAngle ?? pi / 4,
                brandColor: widget.brandColor ?? Theme.of(context).primaryColor,
                gridColor: Theme.of(context).colorScheme.onSurface,
              ),
              size: Size.infinite,
            ),
            IgnorePointer(
              child: Opacity(
                opacity: _logoOpacity.value,
                child: const TrembleLogo(size: 52),
              ),
            ),
          ],
        );
      },
    );
  }
}
