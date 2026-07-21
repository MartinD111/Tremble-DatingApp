import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/features/dashboard/domain/sonar_math.dart';

void main() {
  group('orbitAngle', () {
    test('starts at 0', () {
      expect(orbitAngle(Duration.zero), closeTo(0.0, 1e-9));
    });
    test('quarter period ≈ π/2', () {
      expect(
        orbitAngle(const Duration(milliseconds: 2500)),
        closeTo(math.pi / 2, 1e-3),
      );
    });
    test('wraps at full period', () {
      expect(orbitAngle(const Duration(seconds: 10)), closeTo(0.0, 1e-3));
    });
  });
}
