import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/core/motion.dart';

void main() {
  group('TrembleMotion', () {
    test('exposes the ADR-002 motion curves', () {
      expect(TrembleMotion.stoicEntrance, const Cubic(0.16, 1.0, 0.3, 1.0));
      expect(TrembleMotion.snappyFeedback, const Cubic(0.2, 0.8, 0.2, 1.0));
      expect(TrembleMotion.theatricalReveal, const Cubic(0.86, 0.0, 0.07, 1.0));
    });

    test('exposes the ADR-002 standard durations', () {
      expect(TrembleMotion.instant, const Duration(milliseconds: 150));
      expect(TrembleMotion.feedback, const Duration(milliseconds: 200));
      expect(TrembleMotion.entrance, const Duration(milliseconds: 400));
      expect(TrembleMotion.theatrical, const Duration(milliseconds: 900));
    });
  });
}
