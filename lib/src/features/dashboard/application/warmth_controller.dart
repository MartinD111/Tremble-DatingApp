import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tremble/src/core/ble_service.dart';
import 'package:tremble/src/features/dashboard/application/dev_simulation_controller.dart';
import 'package:tremble/src/features/dashboard/domain/warmth_direction.dart';
import 'package:tremble/src/features/match/application/match_service.dart';
import 'package:tremble/src/features/auth/data/auth_repository.dart';

part 'warmth_controller.g.dart';

@riverpod
class WarmthController extends _$WarmthController {
  final List<int> _rssiBuffer = [];
  static const int _bufferLimit = 5;
  String? _lastSessionId;

  @override
  WarmthDirection build() {
    final search = ref.watch(currentSearchProvider);
    final devSim = ref.watch(devSimulationControllerProvider);

    // Identify the current session to detect resets
    final sessionId = devSim.isMutualWaveActive
        ? 'dev_${state.hashCode}' // Dev mode is a distinct session
        : search?.id;

    if (sessionId != _lastSessionId) {
      _rssiBuffer.clear();
      _lastSessionId = sessionId;
    }

    // Scenario A: Dev Mode Simulation
    if (devSim.isMutualWaveActive) {
      // Map pingDistance (0.9 -> 0.1) to fake RSSI (-90 -> -45)
      final fakeRssi = (-90 + (1.0 - devSim.pingDistance) * 50).toInt();
      return _computeWarmthFromNewRssi(fakeRssi);
    }

    // Scenario B: Real BLE Search
    if (search != null) {
      final ble = ref.watch(bleServiceProvider);
      final partnerId =
          search.getPartnerId(ref.read(authStateProvider)?.id ?? '');

      // We listen to the proximity stream and update the state
      final subscription = ble.proximityStream.listen((rssiMap) {
        if (rssiMap.containsKey(partnerId)) {
          final rssi = rssiMap[partnerId]!;
          state = _computeWarmthFromNewRssi(rssi);
        }
      });

      ref.onDispose(() => subscription.cancel());
    }

    return WarmthDirection.neutral;
  }

  WarmthDirection _computeWarmthFromNewRssi(int rssi) {
    _rssiBuffer.add(rssi);
    if (_rssiBuffer.length > _bufferLimit) {
      _rssiBuffer.removeAt(0);
    }

    if (_rssiBuffer.length < 3) return WarmthDirection.neutral;

    final recent = _rssiBuffer.last;
    // Compare with a point 2-3 steps back to filter noise
    final prev = _rssiBuffer[_rssiBuffer.length - 3];
    final delta = recent - prev;

    // Threshold ±3 dBm — below this is noise.
    if (delta > 3) return WarmthDirection.warmer;
    if (delta < -3) return WarmthDirection.colder;

    // If we have a neutral trend but we are very close, keep neutral or last known?
    // User requested: warmer, colder, neutral.
    return WarmthDirection.neutral;
  }
}
