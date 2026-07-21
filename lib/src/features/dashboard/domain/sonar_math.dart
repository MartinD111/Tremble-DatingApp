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
