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
    final devSim = ref.watch(devSimulationControllerProvider);

    // Scenario A: Dev Mode Simulation — no network dependency.
    if (devSim.isMutualWaveActive) {
      const sessionId = 'dev_sim';
      if (sessionId != _lastSessionId) {
        _rssiBuffer.clear();
        _lastSessionId = sessionId;
      }
      final fakeRssi = (-90 + (1.0 - devSim.pingDistance) * 50).toInt();
      return _computeWarmthFromNewRssi(fakeRssi);
    }

    // Scenario B: Real BLE — guard against loading/error state from Firestore.
    // Use .asData to avoid throwing when the stream hasn't resolved yet.
    final matchAsyncValue = ref.watch(activeMatchesStreamProvider);
    final search = matchAsyncValue.asData != null
        ? ref.watch(currentSearchProvider)
        : null;

    if (search == null) {
      _rssiBuffer.clear();
      _lastSessionId = null;
      return WarmthDirection.neutral;
    }

    if (search.id != _lastSessionId) {
      _rssiBuffer.clear();
      _lastSessionId = search.id;
    }

    final ble = ref.watch(bleServiceProvider);
    final partnerId =
        search.getPartnerId(ref.read(authStateProvider)?.id ?? '');

    final subscription = ble.proximityStream.listen((rssiMap) {
      if (rssiMap.containsKey(partnerId)) {
        state = _computeWarmthFromNewRssi(rssiMap[partnerId]!);
      }
    });

    ref.onDispose(subscription.cancel);

    return WarmthDirection.neutral;
  }

  WarmthDirection _computeWarmthFromNewRssi(int rssi) {
    _rssiBuffer.add(rssi);
    if (_rssiBuffer.length > _bufferLimit) {
      _rssiBuffer.removeAt(0);
    }

    if (_rssiBuffer.length < 3) return WarmthDirection.neutral;

    final recent = _rssiBuffer.last;
    final prev = _rssiBuffer[_rssiBuffer.length - 3];
    final delta = recent - prev;

    if (delta > 3) return WarmthDirection.warmer;
    if (delta < -3) return WarmthDirection.colder;
    return WarmthDirection.neutral;
  }
}
