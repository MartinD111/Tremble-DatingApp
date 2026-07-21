import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/features/dashboard/domain/sonar_ping.dart';

void main() {
  group('rssiToRadius', () {
    test('very close (-40 dBm) maps to center (0.0)', () {
      expect(rssiToRadius(-40), closeTo(0.0, 0.001));
    });
    test('far (-100 dBm) maps to edge (1.0)', () {
      expect(rssiToRadius(-100), closeTo(1.0, 0.001));
    });
    test('mid (-70 dBm) maps to ~0.5', () {
      expect(rssiToRadius(-70), closeTo(0.5, 0.02));
    });
    test('clamps values beyond the range', () {
      expect(rssiToRadius(-10), 0.0);
      expect(rssiToRadius(-140), 1.0);
    });
  });

  group('signalStateFor', () {
    test('fresh within grace', () {
      expect(
        signalStateFor(sinceLastSample: const Duration(seconds: 1)),
        SonarSignalState.fresh,
      );
    });
    test('graceHold between grace and lost', () {
      expect(
        signalStateFor(sinceLastSample: const Duration(seconds: 4)),
        SonarSignalState.graceHold,
      );
    });
    test('searching past lost threshold', () {
      expect(
        signalStateFor(sinceLastSample: const Duration(seconds: 7)),
        SonarSignalState.searching,
      );
    });
  });

  test('SonarPing.copyWith overrides only given fields', () {
    const p = SonarPing(
      radius: 0.4,
      angle: 1.0,
      signalState: SonarSignalState.fresh,
    );
    final q = p.copyWith(signalState: SonarSignalState.searching);
    expect(q.radius, 0.4);
    expect(q.angle, 1.0);
    expect(q.signalState, SonarSignalState.searching);
  });

  test('SonarPing carries raw rssi for diagnostics + copyWith preserves it',
      () {
    const p = SonarPing(
      radius: 0.4,
      angle: 1.0,
      rssi: -62.5,
      signalState: SonarSignalState.fresh,
    );
    expect(p.rssi, -62.5);
    // copyWith without rssi keeps the previous value…
    expect(p.copyWith(radius: 0.2).rssi, -62.5);
    // …and can override it.
    expect(p.copyWith(rssi: -80.0).rssi, -80.0);
    // empty ping has no rssi.
    expect(SonarPing.empty.rssi, isNull);
  });
}
