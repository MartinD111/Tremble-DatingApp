import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/features/dashboard/domain/sonar_math.dart';

void main() {
  group('bearingIsMeaningful', () {
    for (final bucket in ['~150m', 'far']) {
      test('returns true for exact approach bucket $bucket', () {
        expect(bearingIsMeaningful(bucket), isTrue);
      });
    }

    for (final bucket in <String?>['close', '~50m', null, 'unknown']) {
      test('returns false for non-approach bucket $bucket', () {
        expect(bearingIsMeaningful(bucket), isFalse);
      });
    }
  });

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

  // Painter convention (radar_painter.dart): angle 0 = right (east), +clockwise
  // (screen y is down). dotAngle rotates so the partner sits at the TOP of the
  // radar when the user faces them; the dot swings as the phone rotates.
  group('dotAngle', () {
    const halfPi = math.pi / 2;

    test('facing the partner → dot at the top (3π/2 in painter space)', () {
      expect(dotAngle(bearingDeg: 0, headingDeg: 0), closeTo(3 * halfPi, 1e-9));
      // Absolute values do not matter, only the relative bearing.
      expect(
        dotAngle(bearingDeg: 123, headingDeg: 123),
        closeTo(3 * halfPi, 1e-9),
      );
    });

    test('partner 90° to the right → dot at the right (0)', () {
      expect(dotAngle(bearingDeg: 90, headingDeg: 0), closeTo(0.0, 1e-9));
    });

    test('partner behind (180°) → dot at the bottom (π/2)', () {
      expect(dotAngle(bearingDeg: 180, headingDeg: 0), closeTo(halfPi, 1e-9));
    });

    test('turning right moves the partner to the left (π)', () {
      // Partner due north, user now faces east → partner is on the left.
      expect(dotAngle(bearingDeg: 0, headingDeg: 90), closeTo(math.pi, 1e-9));
    });

    test('result is always wrapped into [0, 2π)', () {
      final a = dotAngle(bearingDeg: 0, headingDeg: 270);
      expect(a, greaterThanOrEqualTo(0.0));
      expect(a, lessThan(2 * math.pi));
    });
  });

  // Angular EMA for the noisy magnetometer heading — must take the SHORT way
  // around the 0/360 seam, never the long way.
  group('smoothHeading', () {
    test('no change when target equals current', () {
      expect(smoothHeading(100, 100), closeTo(100, 1e-9));
    });

    test('moves a fraction toward the target', () {
      expect(smoothHeading(0, 100, alpha: 0.5), closeTo(50, 1e-9));
    });

    test('crosses the 360 seam upward via the short arc', () {
      // 350 → 10 should pass through 0, landing near 0, not near 180.
      expect(smoothHeading(350, 10, alpha: 0.5), closeTo(0, 1e-9));
    });

    test('crosses the 360 seam downward via the short arc', () {
      expect(smoothHeading(10, 350, alpha: 0.5), closeTo(0, 1e-9));
    });

    test('always returns a value in [0, 360)', () {
      final v = smoothHeading(359, 2, alpha: 0.9);
      expect(v, greaterThanOrEqualTo(0));
      expect(v, lessThan(360));
    });
  });
}
