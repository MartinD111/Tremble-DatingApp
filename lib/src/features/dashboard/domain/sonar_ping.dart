import 'package:flutter/foundation.dart';

/// Freshness of the partner signal driving the sonar dot.
enum SonarSignalState { fresh, graceHold, searching }

/// One frame of sonar state consumed by the radar ping providers.
///
/// [radius]: `0.0` = center (close) … `1.0` = edge (far); `null` = no dot.
/// [angle]: radians for the dot's bearing on the radar; `null` = unknown.
/// [rssi]: raw smoothed signal strength (dBm) — diagnostic only, surfaced by
/// the dev radar overlay (`kDebugMode`); never rendered in production UI.
@immutable
class SonarPing {
  const SonarPing({
    this.radius,
    this.angle,
    this.rssi,
    this.signalState = SonarSignalState.searching,
  });

  final double? radius;
  final double? angle;
  final double? rssi;
  final SonarSignalState signalState;

  SonarPing copyWith({
    double? radius,
    double? angle,
    double? rssi,
    SonarSignalState? signalState,
  }) =>
      SonarPing(
        radius: radius ?? this.radius,
        angle: angle ?? this.angle,
        rssi: rssi ?? this.rssi,
        signalState: signalState ?? this.signalState,
      );

  static const empty = SonarPing();
}

/// Classifies the partner signal by how long since the last RSSI sample.
/// `<= grace` → [SonarSignalState.fresh]; `<= lost` → [SonarSignalState.graceHold]
/// (hold the last hint briefly); beyond → [SonarSignalState.searching].
SonarSignalState signalStateFor({
  required Duration sinceLastSample,
  Duration grace = const Duration(seconds: 3),
  Duration lost = const Duration(seconds: 6),
}) {
  if (sinceLastSample <= grace) return SonarSignalState.fresh;
  if (sinceLastSample <= lost) return SonarSignalState.graceHold;
  return SonarSignalState.searching;
}

/// Maps smoothed RSSI (dBm) to a radar radius. `-40 dBm` (close) → `0.0`
/// (center), `-100 dBm` (far) → `1.0` (edge). Mirrors the proximity factor
/// range already used by the vibration ping loop.
double rssiToRadius(double rssi) {
  final factor = (rssi.clamp(-100.0, -40.0) + 100.0) / 60.0; // 0 far … 1 close
  return 1.0 - factor;
}
