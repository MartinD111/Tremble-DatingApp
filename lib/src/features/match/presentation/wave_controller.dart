import 'dart:async';

import 'package:flutter/services.dart' show HapticFeedback;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/api_client.dart';
import '../../../shared/ui/wave_pill_service.dart';
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

  WaveSendState withInlineError(
    String targetUid, {
    String message = 'Wave ni bil poslan. Poskusi znova.',
  }) {
    return WaveSendState(
      inlineErrorTargetUid: targetUid,
      inlineErrorMessage: message,
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
      // The wave landed — the "{name} is nearby" prompt for this person is now
      // stale, so clear it if it is still floating (BUG-IS-NEARBY-PERSISTS).
      WavePillService.dismissForTarget(targetUid);
    } catch (error) {
      state = AsyncData(previousValue.withInlineError(
        targetUid,
        message: _mapWaveError(error),
      ));
    }
  }

  String _mapWaveError(Object error) {
    if (error is TrembleApiException) return error.message;
    return 'Wave ni bil poslan. Poskusi znova.';
  }
}
