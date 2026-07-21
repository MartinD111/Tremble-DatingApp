import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/shared/widgets/radar_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RadarPainter sweep', () {
    test('paints the sweep line while idle scanning', () async {
      final bytes = await _paintRadar(pingDistance: null);

      expect(_redAt(bytes, x: 90, y: 50), greaterThan(0));
    });

    test('does not paint the sweep line while sonar ping is active', () async {
      final bytes = await _paintRadar(pingDistance: 0.5);

      expect(_redAt(bytes, x: 90, y: 50), 0);
    });
  });
}

Future<ByteData> _paintRadar({required double? pingDistance}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const size = Size(100, 100);

  RadarPainter(
    radarProgress: 0,
    pingProgress: 0,
    activationProgress: 0,
    pingDistance: pingDistance,
    pingAngle: math.pi,
    brandColor: Colors.red,
    gridColor: Colors.transparent,
  ).paint(canvas, size);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  picture.dispose();
  image.dispose();

  return byteData!;
}

int _redAt(ByteData bytes, {required int x, required int y}) {
  const width = 100;
  final index = ((y * width) + x) * 4;
  return bytes.getUint8(index);
}
