import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final recapTTLProvider =
    StateNotifierProvider.family<RecapTTLNotifier, RecapTTLState, String>(
  (ref, recapId) {
    return RecapTTLNotifier();
  },
);

class RecapTTLState {
  final int remainingSeconds;
  final bool isExpired;

  const RecapTTLState({
    this.remainingSeconds = 600,
    this.isExpired = false,
  });

  RecapTTLState copyWith({
    int? remainingSeconds,
    bool? isExpired,
  }) {
    return RecapTTLState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isExpired: isExpired ?? this.isExpired,
    );
  }
}

class RecapTTLNotifier extends StateNotifier<RecapTTLState> {
  RecapTTLNotifier() : super(const RecapTTLState());

  Timer? _timer;

  void start() {
    if (_timer != null) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final nextRemaining = state.remainingSeconds - 1;
      state = state.copyWith(
        remainingSeconds: nextRemaining < 0 ? 0 : nextRemaining,
        isExpired: nextRemaining <= 0,
      );

      if (state.isExpired) {
        _timer?.cancel();
        _timer = null;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
