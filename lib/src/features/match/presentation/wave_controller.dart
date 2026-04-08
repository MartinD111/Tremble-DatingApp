import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/wave_repository.dart';

part 'wave_controller.g.dart';

@riverpod
class WaveController extends _$WaveController {
  @override
  FutureOr<void> build() {}

  Future<void> handleWave(String targetUid) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(waveRepositoryProvider).sendWave(targetUid));
  }
}
