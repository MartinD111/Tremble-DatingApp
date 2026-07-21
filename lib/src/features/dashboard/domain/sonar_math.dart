import 'dart:math' as math;

/// Slow orbit angle (radians) used when no real bearing is available yet —
/// the "distance known, direction searching" state. Completes one full sweep
/// every [period]. Result is in `[0, 2π)`.
double orbitAngle(
  Duration elapsed, {
  Duration period = const Duration(seconds: 10),
}) {
  final t = elapsed.inMicroseconds / period.inMicroseconds;
  final frac = t - t.floorToDouble();
  return frac * 2 * math.pi;
}

const double _twoPi = 2 * math.pi;

double _wrapTwoPi(double radians) => ((radians % _twoPi) + _twoPi) % _twoPi;

/// Screen angle (radians) for the partner dot, given the absolute compass
/// [bearingDeg] to the partner (0–359° from north) and the device's current
/// [headingDeg] (0–359° from north).
///
/// Output is in the radar painter's convention (`radar_painter.dart`): angle
/// `0` = right/east, increasing clockwise (screen y is down). The relative
/// bearing `bearing − heading` is rotated by `−π/2` so that when the user faces
/// the partner (relative bearing `0`) the dot sits at the TOP of the radar, and
/// it swings clockwise/anticlockwise as the phone turns. Result is `[0, 2π)`.
double dotAngle({required double bearingDeg, required double headingDeg}) {
  final relativeRad = (bearingDeg - headingDeg) * math.pi / 180.0;
  return _wrapTwoPi(relativeRad - math.pi / 2);
}

/// Angular exponential moving average for the noisy magnetometer heading.
///
/// Blends [newDeg] into [prevDeg] by [alpha] (0–1; higher = snappier) taking
/// the SHORT way around the 0/360 seam, so 350° → 10° passes through 0 rather
/// than sweeping back through 180. Returns degrees in `[0, 360)`.
double smoothHeading(double prevDeg, double newDeg, {double alpha = 0.2}) {
  var delta = (newDeg - prevDeg) % 360.0;
  if (delta > 180.0) delta -= 360.0;
  if (delta < -180.0) delta += 360.0;
  final result = prevDeg + alpha * delta;
  return (result % 360.0 + 360.0) % 360.0;
}
