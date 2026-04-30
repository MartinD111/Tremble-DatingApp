import 'package:flutter/services.dart';

enum MotionState { running, stationary, walking, unknown }

/// Bridges Flutter ↔ native Activity Recognition (Android) and CoreMotion (iOS)
/// to detect if the user is running, walking or stationary without using GPS.
class NativeMotionService {
  NativeMotionService._();
  static final instance = NativeMotionService._();

  static const _eventChannel = EventChannel('app.tremble/motion/events');
  static const _methodChannel = MethodChannel('app.tremble/motion');

  Stream<MotionState>? _stateStream;

  /// Broadcasts the current motion state.
  Stream<MotionState> get motionStateChanges {
    _stateStream ??= _eventChannel.receiveBroadcastStream().map((e) {
      final stateStr = e as String;
      switch (stateStr) {
        case 'RUNNING':
          return MotionState.running;
        case 'STATIONARY':
          return MotionState.stationary;
        case 'WALKING':
          return MotionState.walking;
        default:
          return MotionState.unknown;
      }
    }).asBroadcastStream();
    return _stateStream!;
  }

  /// Starts the native motion monitoring
  Future<void> startMonitoring() async {
    await _methodChannel.invokeMethod<void>('startMonitoring');
  }

  /// Stops the native motion monitoring
  Future<void> stopMonitoring() async {
    await _methodChannel.invokeMethod<void>('stopMonitoring');
  }
}
