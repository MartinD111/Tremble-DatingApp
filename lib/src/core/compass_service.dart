import 'package:flutter_compass_v2/flutter_compass_v2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Live device compass heading in degrees (0–359, `0` = magnetic north), or
/// `null` when the device has no compass / the heading is momentarily
/// unavailable.
///
/// Deliberately RAW (unsmoothed): the radar turn-to-find feature applies angular
/// smoothing via `sonar_math.smoothHeading` in the consumer
/// (`SonarPingController`), so this stays a thin, feature-agnostic core
/// provider. Heading source per ADR-009 (`flutter_compass_v2`). On iOS this
/// uses CoreLocation heading, covered by the existing location authorization —
/// no new permission prompt.
final compassHeadingProvider = StreamProvider<double?>((ref) {
  final stream = FlutterCompass.events;
  if (stream == null) return Stream<double?>.value(null);
  return stream.map((event) => event.heading);
});
