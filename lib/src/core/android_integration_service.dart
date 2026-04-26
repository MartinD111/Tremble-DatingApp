import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

const _methodChannel = MethodChannel('app.tremble/radar');
const _eventChannel = EventChannel('app.tremble/radar/events');

/// Bridges Flutter ↔ native Android for Radar (Quick Settings tile, widget,
/// NowBar notification) state synchronisation.
///
/// All public methods are no-ops on iOS so call sites need no platform guards.
class AndroidIntegrationService {
  AndroidIntegrationService._();
  static final instance = AndroidIntegrationService._();

  Stream<bool>? _stateStream;

  /// Broadcasts Radar active/inactive changes pushed from the native side
  /// (tile tap, widget tap). Emits the current state immediately on first
  /// subscription. Returns an empty stream on iOS.
  Stream<bool> get radarStateChanges {
    if (!Platform.isAndroid) return const Stream.empty();
    _stateStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((e) => e as bool)
        .asBroadcastStream();
    return _stateStream!;
  }

  /// Push the authoritative Radar state to the native side so the tile and
  /// widget re-render. No-op on iOS.
  Future<void> setRadarActive(bool active) async {
    if (!Platform.isAndroid) return;
    await _methodChannel
        .invokeMethod<void>('setRadarActive', {'active': active});
  }

  /// Read the persisted state (useful before the EventChannel emits its first
  /// event, e.g. at cold start). Returns false on iOS.
  Future<bool> getRadarActive() async {
    if (!Platform.isAndroid) return false;
    return await _methodChannel.invokeMethod<bool>('getRadarActive') ?? false;
  }

  /// Request the OS to add the Quick Settings tile (Android 13+).
  /// Returns the StatusBarManager tile result code, or -1 on older OS / iOS.
  Future<int> requestAddQsTile() async {
    if (!Platform.isAndroid) return -1;
    return await _methodChannel.invokeMethod<int>('requestAddQsTile') ?? -1;
  }

  /// Request the launcher to show the pin-widget dialog.
  /// Returns true if the request was submitted, false if unsupported / iOS.
  Future<bool> requestPinWidget() async {
    if (!Platform.isAndroid) return false;
    return await _methodChannel.invokeMethod<bool>('requestPinWidget') ?? false;
  }
}
