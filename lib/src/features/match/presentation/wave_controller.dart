import 'dart:async';

import 'package:flutter/services.dart' show HapticFeedback;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/wave_repository.dart';

part 'wave_controller.g.dart';

class WaveSendState {
  const WaveSendState({
    this.optimisticTargetUid,
    this.inlineErrorTargetUid,
    this.inlineErrorMessage,
  });

  final String? optimisticTargetUid;
  final String? inlineErrorTargetUid;
  final String? inlineErrorMessage;

  WaveSendState withOptimisticTarget(String targetUid) {
    return WaveSendState(optimisticTargetUid: targetUid);
  }

  WaveSendState withInlineError(String targetUid) {
    return WaveSendState(
      inlineErrorTargetUid: targetUid,
      inlineErrorMessage: 'Wave ni bil poslan. Poskusi znova.',
    );
  }

  bool isOptimisticFor(String targetUid) => optimisticTargetUid == targetUid;

  String? inlineErrorFor(String targetUid) {
    return inlineErrorTargetUid == targetUid ? inlineErrorMessage : null;
  }
}

@riverpod
class WaveController extends _$WaveController {
  @override
  FutureOr<WaveSendState> build() => const WaveSendState();

  Future<void> handleWave(
    String targetUid, {
    Future<void> Function()? writeWave,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final previousValue = state.valueOrNull ?? const WaveSendState();
    final optimisticValue = previousValue.withOptimisticTarget(targetUid);

    unawaited(HapticFeedback.lightImpact());
    state = AsyncData(optimisticValue);

    try {
      final operation = writeWave ??
          () => ref.read(waveRepositoryProvider).sendWave(targetUid);
      await operation().timeout(timeout);
    } catch (_) {
      state = AsyncData(previousValue.withInlineError(targetUid));
    }
  }
}
