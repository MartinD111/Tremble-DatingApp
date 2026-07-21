import 'package:flutter/foundation.dart';

/// Freshness of the partner signal driving the sonar dot.
enum SonarSignalState { fresh, graceHold, searching }

/// One frame of sonar state consumed by the radar ping providers.
///
/// [radius]: `0.0` = center (close) … `1.0` = edge (far); `null` = no dot.
/// [angle]: radians for the dot's bearing on the radar; `null` = unknown.
@immutable
class SonarPing {
  const SonarPing({
    this.radius,
    this.angle,
    this.signalState = SonarSignalState.searching,
  });

  final double? radius;
  final double? angle;
  final SonarSignalState signalState;

  SonarPing copyWith({
    double? radius,
    double? angle,
    SonarSignalState? signalState,
  }) =>
      SonarPing(
        radius: radius ?? this.radius,
        angle: angle ?? this.angle,
        signalState: signalState ?? this.signalState,
      );

  static const empty = SonarPing();
}

/// Maps smoothed RSSI (dBm) to a radar radius. `-40 dBm` (close) → `0.0`
/// (center), `-100 dBm` (far) → `1.0` (edge). Mirrors the proximity factor
/// range already used by the vibration ping loop.
double rssiToRadius(double rssi) {
  final factor = (rssi.clamp(-100.0, -40.0) + 100.0) / 60.0; // 0 far … 1 close
  return 1.0 - factor;
}
