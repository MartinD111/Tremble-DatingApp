import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../../../shared/widgets/radar_painter.dart';

class RadarAnimation extends StatefulWidget {
  final bool isScanning;
  final double? pingDistance; // 0.0 = center, 1.0 = edge, null = no ping
  final double? pingAngle; // angle in radians for ping position
  final Color? brandColor;

  const RadarAnimation({
    super.key,
    this.isScanning = true,
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

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _pingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.isScanning) {
      _radarController.repeat();
    }

    if (widget.pingDistance != null) {
      _pingController.repeat();
    }

    _initBackgroundService();
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
    } else if (!widget.isScanning && _radarController.isAnimating) {
      _radarController.stop();
    }

    if (widget.pingDistance != null && !_pingController.isAnimating) {
      _pingController.repeat();
    } else if (widget.pingDistance == null && _pingController.isAnimating) {
      _pingController.stop();
    }
  }

  @override
  void dispose() {
    _radarController.dispose();
    _pingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_radarController, _pingController]),
      builder: (context, child) {
        return CustomPaint(
          painter: RadarPainter(
            radarProgress: _radarController.value,
            pingProgress: _pingController.value,
            pingDistance: widget.pingDistance,
            pingAngle: widget.pingAngle ?? pi / 4,
            brandColor: widget.brandColor ?? Theme.of(context).primaryColor,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}
