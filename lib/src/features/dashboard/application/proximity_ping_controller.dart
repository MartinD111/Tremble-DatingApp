import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vibration/vibration.dart';
import 'package:tremble/src/core/ble_service.dart';
import 'package:tremble/src/features/dashboard/domain/sonar_ping.dart';
import 'package:tremble/src/features/dashboard/domain/sonar_math.dart';
import 'package:tremble/src/features/match/application/match_service.dart';
import 'package:tremble/src/features/auth/data/auth_repository.dart';

part 'proximity_ping_controller.g.dart';

/// Sonar data source for the trembling-window radar dot.
///
/// Sources the partner's smoothed BLE RSSI from [BleService.proximityStream]
/// (the same signal behind the warmth mechanic) and emits a [SonarPing] the
/// production writer pipes into `pingDistanceProvider` / `pingAngleProvider`.
///
/// Phase A: distance drives the dot radius (near → center) and the ping loop
/// rate; the angle is a slow orbit (no bearing yet). Signal loss fades the dot
/// to a "searching" state. Phase B replaces the orbit with a real bearing.
///
/// Also drives the existing haptic ping loop (closer → faster/stronger).
@riverpod
class SonarPingController extends _$SonarPingController {
  bool _isLooping = false;
  double? _smoothedRssi;
  double? _lastRadius;
  DateTime? _lastSampleAt;
  final Stopwatch _orbit = Stopwatch();
  Timer? _freshnessTimer;

  // Smoothing factor (0.0 to 1.0, lower = smoother but slower to react).
  static const double _smoothingAlpha = 0.3;

  @override
  SonarPing build() {
    final search = ref.watch(currentSearchProvider);
    final isPremium = ref.watch(effectiveIsPremiumProvider);
    final ble = ref.watch(bleServiceProvider);

    ble.setHighFrequencyMode(search != null && isPremium);

    if (search == null) {
      _reset();
      return SonarPing.empty;
    }

    _orbit
      ..reset()
      ..start();

    // Freshness heartbeat — fades the dot to "searching" when RSSI goes quiet,
    // and keeps the orbit angle advancing between samples.
    _freshnessTimer?.cancel();
    _freshnessTimer = Timer.periodic(
        const Duration(milliseconds: 500), (_) => _tickFreshness());

    final partnerId =
        search.getPartnerId(ref.read(authStateProvider)?.id ?? '');

    final sub = ble.proximityStream.listen((rssiMap) {
      if (!rssiMap.containsKey(partnerId)) return;
      final newRssi = rssiMap[partnerId]!.toDouble();

      // EMA smoothing to prevent radius/frequency jitter.
      _smoothedRssi = _smoothedRssi == null
          ? newRssi
          : (_smoothedRssi! * (1 - _smoothingAlpha)) +
              (newRssi * _smoothingAlpha);

      _lastSampleAt = DateTime.now();
      _lastRadius = rssiToRadius(_smoothedRssi!);
      state = SonarPing(
        radius: _lastRadius,
        angle: orbitAngle(_orbit.elapsed),
        signalState: SonarSignalState.fresh,
      );

      // Haptic ping loop only once both users have accepted (mutual wave).
      if (search.isMutual) {
        _startPingLoop();
      } else {
        _stopPingLoop();
      }
    });

    ref.onDispose(() {
      sub.cancel();
      _reset();
    });

    return SonarPing.empty;
  }

  /// Recomputes freshness on a fixed cadence: holds the last hint through the
  /// grace window, then fades the dot (radius → null) once truly lost. Keeps
  /// the orbit angle live so the dot never freezes.
  void _tickFreshness() {
    final last = _lastSampleAt;
    final since = last == null
        ? const Duration(days: 1)
        : DateTime.now().difference(last);
    final signalState = signalStateFor(sinceLastSample: since);
    final angle = orbitAngle(_orbit.elapsed);
    switch (signalState) {
      case SonarSignalState.fresh:
      case SonarSignalState.graceHold:
        state = SonarPing(
          radius: _lastRadius,
          angle: angle,
          signalState: signalState,
        );
      case SonarSignalState.searching:
        _stopPingLoop();
        state = SonarPing(
          radius: null,
          angle: angle,
          signalState: SonarSignalState.searching,
        );
    }
  }

  void _reset() {
    _stopPingLoop();
    _freshnessTimer?.cancel();
    _freshnessTimer = null;
    _orbit.stop();
    _smoothedRssi = null;
    _lastRadius = null;
    _lastSampleAt = null;
  }

  void _startPingLoop() {
    if (_isLooping || _smoothedRssi == null) return;
    _isLooping = true;
    _pingStep();
  }

  void _stopPingLoop() {
    _isLooping = false;
  }

  Future<void> _pingStep() async {
    if (!_isLooping || _smoothedRssi == null) {
      _isLooping = false;
      return;
    }

    final rssi = _smoothedRssi!;
    // factor: 0.0 (at -100dBm, far) to 1.0 (at -40dBm, very close)
    final factor = (rssi.clamp(-100.0, -40.0) + 100.0) / 60.0;

    // Interval: 4000ms (far) down to 200ms (close)
    final intervalMs = (4000 - (factor * 3800)).toInt();
    final interval = Duration(milliseconds: intervalMs);

    // Intensity (Android): 60 to 255
    final intensity = (60 + (factor * 195)).toInt();
    // Sharpness (iOS): 0.2 to 1.0
    final sharpness = 0.2 + (factor * 0.8);

    await _triggerPing(intensity: intensity, sharpness: sharpness);

    await Future<void>.delayed(interval);

    if (_isLooping) {
      _pingStep();
    }
  }

  /// Haptic is a non-critical peripheral — a vibration failure (unsupported
  /// device, missing plugin in tests) must never crash the sonar loop.
  Future<void> _triggerPing({
    required int intensity,
    required double sharpness,
  }) async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (!hasVibrator) return;
      Vibration.vibrate(
        duration: 100,
        amplitude: intensity,
        sharpness: sharpness,
      );
    } on Exception {
      // Ignore — haptics are best-effort.
    }
  }
}
