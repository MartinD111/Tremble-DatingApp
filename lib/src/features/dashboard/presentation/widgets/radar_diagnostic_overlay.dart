import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tremble/src/features/dashboard/application/proximity_ping_controller.dart';
import 'package:tremble/src/features/dashboard/domain/sonar_ping.dart';

/// Developer-only diagnostic panel for the trembling-window radar.
///
/// Renders the live sonar signals — raw smoothed RSSI, computed dot radius,
/// orbit/bearing angle, and freshness state — plus placeholders for the
/// signals that arrive in Phase B (server geohash `bearing` / `distanceBucket`
/// and the device compass `heading`). This makes the prod-only two-phone test
/// sessions debuggable: a blank or wrong dot can be read on-device instead of
/// guessed at (writer not firing vs. bearing wrong vs. compass noisy).
///
/// Guarded by [kDebugMode] — it compiles to `SizedBox.shrink()` in release, so
/// it can never ship to users even on a prod-flavor TestFlight/debug build.
class RadarDiagnosticOverlay extends ConsumerWidget {
  const RadarDiagnosticOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kDebugMode) return const SizedBox.shrink();

    final sonar = ref.watch(sonarPingControllerProvider);

    return IgnorePointer(
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF33FF99), width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('SONAR ⋅ DEBUG', '', header: true),
            _row('RSSI', _fmtDbm(sonar.rssi)),
            _row('radius', _fmt(sonar.radius)),
            _row('angle', _fmtRad(sonar.angle)),
            _row('state', _stateLabel(sonar.signalState)),
            // Phase B signals — wired once B2 (server bearing) + B3 (compass)
            // land; shown as "—" until then so the panel shape is stable.
            _row('bearing', '—'),
            _row('bucket', '—'),
            _row('heading', '—'),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool header = false}) {
    final style = GoogleFonts.jetBrainsMono(
      color: header ? const Color(0xFF33FF99) : Colors.white,
      fontSize: header ? 10 : 11,
      fontWeight: header ? FontWeight.w700 : FontWeight.w500,
      letterSpacing: header ? 1.2 : 0,
      height: 1.35,
    );
    if (header) return Text(label, style: style);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: style.copyWith(color: Colors.white54),
          ),
        ),
        Text(value, style: style),
      ],
    );
  }

  String _fmt(double? v) => v == null ? '—' : v.toStringAsFixed(2);

  String _fmtDbm(double? v) => v == null ? '—' : '${v.toStringAsFixed(1)} dBm';

  String _fmtRad(double? v) => v == null ? '—' : '${v.toStringAsFixed(2)} rad';

  String _stateLabel(SonarSignalState state) => switch (state) {
        SonarSignalState.fresh => 'fresh',
        SonarSignalState.graceHold => 'graceHold',
        SonarSignalState.searching => 'searching',
      };
}
