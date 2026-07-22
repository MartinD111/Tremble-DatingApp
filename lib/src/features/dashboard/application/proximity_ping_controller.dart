import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vibration/vibration.dart';
import 'package:tremble/src/core/ble_service.dart';
import 'package:tremble/src/core/compass_service.dart';
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

  // Phase B turn-to-find: absolute bearing to the partner (server, 0-359°) +
  // smoothed device heading (compass). When both are present the dot points at
  // the real direction; otherwise it falls back to the slow orbit.
  double? _bearing;
  double? _heading;
  String? _distanceBucket;

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

    final myUid = ref.read(authStateProvider)?.id ?? '';

    // Phase B: server-computed bearing to the partner + coarse distance bucket
    // (re-read whenever the match doc updates → build re-runs). The partner's
    // location never reaches here — only these derived values.
    _bearing = search.bearingForUser(myUid);
    _distanceBucket = search.distanceBucket;

    // Live device heading (compass) → smoothed, re-aims the dot as the phone
    // turns without rebuilding the whole controller. Raw source is null-safe.
    ref.listen(compassHeadingProvider, (_, next) {
      final h = next.valueOrNull;
      if (h == null) return;
      _heading = _heading == null ? h : smoothHeading(_heading!, h);
      // Re-aim the current dot at compass framerate (keeps radius/state).
      state = state.copyWith(angle: _currentAngle());
    });

    // Freshness heartbeat — fades the dot to "searching" when RSSI goes quiet,
    // and keeps the orbit angle advancing between samples.
    _freshnessTimer?.cancel();
    _freshnessTimer = Timer.periodic(
        const Duration(milliseconds: 500), (_) => _tickFreshness());

    final partnerId = search.getPartnerId(myUid);

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
        angle: _currentAngle(),
        rssi: _smoothedRssi,
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
    final angle = _currentAngle();
    switch (signalState) {
      case SonarSignalState.fresh:
      case SonarSignalState.graceHold:
        state = SonarPing(
          radius: _lastRadius,
          angle: angle,
          rssi: _smoothedRssi,
          signalState: signalState,
        );
      case SonarSignalState.searching:
        _stopPingLoop();
        // Approach stage: no fresh BLE lock, but if the server has given a
        // coarse distance bucket, still show the dot at that range so the user
        // can hunt by direction from ~150m out. Falls to null (no dot) only
        // when we have neither RSSI nor a bucket.
        state = SonarPing(
          radius: bucketToRadius(_distanceBucket),
          angle: angle,
          rssi: _smoothedRssi,
          signalState: SonarSignalState.searching,
        );
    }
  }

  /// The dot's screen angle: the coarse bearing (partner direction relative
  /// to where the phone points) only when it is meaningful at approach range,
  /// otherwise the slow searching orbit.
  double _currentAngle() {
    final bearing = _bearing;
    final heading = _heading;
    if (bearing != null &&
        heading != null &&
        bearingIsMeaningful(_distanceBucket)) {
      return dotAngle(bearingDeg: bearing, headingDeg: heading);
    }
    return orbitAngle(_orbit.elapsed);
  }

  void _reset() {
    _stopPingLoop();
    _freshnessTimer?.cancel();
    _freshnessTimer = null;
    _orbit.stop();
    _smoothedRssi = null;
    _lastRadius = null;
    _lastSampleAt = null;
    _bearing = null;
    _heading = null;
    _distanceBucket = null;
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
