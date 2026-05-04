import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

const _methodChannel = MethodChannel('app.tremble/radar');
const _eventChannel = EventChannel('app.tremble/radar/events');

/// Bridges Flutter ↔ native iOS for Radar (Quick Action, Lock Screen Widget, shared state).
/// Mirrors AndroidIntegrationService but for iOS only.
///
/// All public methods are no-ops on Android so call sites need no platform guards.
class IosIntegrationService {
  IosIntegrationService._();
  static final instance = IosIntegrationService._();

  Stream<bool>? _stateStream;

  /// Broadcasts Radar active/inactive changes pushed from the native side
  /// (quick action tap, lock screen widget tap, app foreground restore).
  /// Emits the current state immediately on first subscription.
  /// Returns an empty stream on Android.
  Stream<bool> get radarStateChanges {
    if (!Platform.isIOS) return const Stream.empty();
    _stateStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((e) => e as bool)
        .asBroadcastStream();
    return _stateStream!;
  }

  /// Push the authoritative Radar state to the native side so the lock screen
  /// widget re-renders. No-op on Android.
  Future<void> setRadarActive(bool active) async {
    if (!Platform.isIOS) return;
    await _methodChannel
        .invokeMethod<void>('setRadarActive', {'active': active});
  }

  /// iOS does not use a foreground service — background modes handle execution.
  /// No-op on iOS (already requested in Info.plist).
  Future<void> startRadarService() async {
    if (!Platform.isIOS) return;
  }

  /// iOS does not use a foreground service. No-op on iOS.
  Future<void> stopRadarService() async {
    if (!Platform.isIOS) return;
  }

  /// Read the persisted state (useful before the EventChannel emits its first
  /// event, e.g. at cold start). Returns false on Android.
  Future<bool> getRadarActive() async {
    if (!Platform.isIOS) return false;
    return await _methodChannel.invokeMethod<bool>('getRadarActive') ?? false;
  }

  /// iOS does not have Quick Settings tiles. Returns -1 on iOS.
  Future<int> requestAddQsTile() async {
    if (!Platform.isIOS) return -1;
    return -1;
  }

  /// iOS Quick Action is registered statically in Info.plist.
  /// Lock Screen widget is added via Settings → Customize Lock Screen.
  /// This method does nothing on iOS.
  Future<bool> requestPinWidget() async {
    if (!Platform.isIOS) return false;
    return false;
  }
}
