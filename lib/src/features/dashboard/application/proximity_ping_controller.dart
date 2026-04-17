import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vibration/vibration.dart';
import 'package:tremble/src/core/ble_service.dart';
import 'package:tremble/src/features/match/application/match_service.dart';
import 'package:tremble/src/features/auth/data/auth_repository.dart';

part 'proximity_ping_controller.g.dart';

@riverpod
class ProximityPingController extends _$ProximityPingController {
  bool _isLooping = false;
  double? _smoothedRssi;
  
  // Smoothing factor (0.0 to 1.0, lower = smoother but slower to react)
  static const double _smoothingAlpha = 0.3;

  @override
  bool build() {
    final search = ref.watch(currentSearchProvider);
    final ble = ref.watch(bleServiceProvider);
    
    if (search == null) {
      _stopPingLoop();
      ble.setHighFrequencyMode(false);
      return false;
    }

    // Enable high frequency scanning when a search is active
    ble.setHighFrequencyMode(true);

    // Listen to RSSI updates for the partner
    final partnerId = search.getPartnerId(ref.read(authStateProvider)?.id ?? '');
    
    final sub = ble.proximityStream.listen((rssiMap) {
      if (rssiMap.containsKey(partnerId)) {
        final newRssi = rssiMap[partnerId]!.toDouble();
        
        // Apply EMA smoothing to RSSI to prevent frequency jitter
        if (_smoothedRssi == null) {
          _smoothedRssi = newRssi;
        } else {
          _smoothedRssi = (_smoothedRssi! * (1 - _smoothingAlpha)) + (newRssi * _smoothingAlpha);
        }
        
        // ONLY start the vibration loop if both users have accepted (isMutual)
        if (search.isMutual) {
          _startPingLoop();
        } else {
          _stopPingLoop();
        }
      }
    });

    ref.onDispose(() {
      sub.cancel();
      _stopPingLoop();
    });

    return true;
  }

  void _startPingLoop() {
    if (_isLooping || _smoothedRssi == null) return;
    _isLooping = true;
    _pingStep();
  }

  void _stopPingLoop() {
    _isLooping = false;
    _smoothedRssi = null;
  }

  Future<void> _pingStep() async {
    if (!_isLooping || _smoothedRssi == null) {
      _isLooping = false;
      return;
    }

    // Capture current values for this ping
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

    // Trigger vibration
    await _triggerPing(intensity: intensity, sharpness: sharpness);

    // Update state to trigger UI pulse
    state = !state;

    // Wait for the calculated interval before next step
    await Future.delayed(interval);
    
    // Recursive call for next ping
    if (_isLooping) {
      _pingStep();
    }
  }

  Future<void> _triggerPing({required int intensity, required double sharpness}) async {
    final hasVibrator = await Vibration.hasVibrator();
    if (!hasVibrator) return;

    // Use amplitude for Android and sharpness for iOS
    Vibration.vibrate(
      duration: 100,
      amplitude: intensity,
      sharpness: sharpness,
    );
  }
}
