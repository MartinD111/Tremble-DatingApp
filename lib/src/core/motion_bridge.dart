import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'native_motion_service.dart';

/// Owns the lifetime of the **main-isolate** motion subscription and forwards
/// each event to the flutter_background_service isolate via `service.invoke`.
///
/// Why this lives on the main isolate: the `app.tremble/motion` and
/// `app.tremble/motion/events` channels are registered by `TrembleNativePlugin`
/// inside `AppDelegate.application(_:didFinishLaunchingWithOptions:)` — i.e.
/// only on the main FlutterEngine. The flutter_background_service spawns a
/// separate isolate with a fresh engine whose plugin set comes from
/// `GeneratedPluginRegistrant`, which does NOT include `TrembleNativePlugin`.
/// Calling `NativeMotionService.startMonitoring()` from that isolate therefore
/// raises `MissingPluginException`. Run-Club timer logic stays in the
/// background isolate (`background_service.dart`); it just consumes motion
/// state via `service.on('motionStateChanged')` instead of calling the channel
/// itself.
class MotionBridge {
  MotionBridge._();

  static StreamSubscription<MotionState>? _sub;

  /// Start motion monitoring and forward state to the background isolate.
  /// Idempotent — safe to call repeatedly (e.g. on every auth-change tick).
  static Future<void> start() async {
    if (_sub != null) return;

    _sub = NativeMotionService.instance.motionStateChanges.listen(
      (state) {
        FlutterBackgroundService().invoke(
          'motionStateChanged',
          {'state': state.name},
        );
      },
      onError: (_) {
        // Defensive: an async platform error on the event channel must not
        // tear down the subscription — keep forwarding any later events.
      },
    );

    try {
      await NativeMotionService.instance.startMonitoring();
    } on MissingPluginException {
      // Should never happen on a real device: TrembleNativePlugin registers
      // the channel synchronously in AppDelegate.didFinishLaunchingWithOptions.
      // Hit only in unit tests / simulators with no native side. Clean up so
      // a later retry can succeed.
      await stop();
    } catch (_) {
      // e.g. CMMotionActivityManager unavailable on this device. Clean up.
      await stop();
    }
  }

  /// Stop monitoring and detach the subscription. Idempotent.
  /// Call on logout so a re-login can re-establish a fresh subscription.
  static Future<void> stop() async {
    final sub = _sub;
    _sub = null;
    await sub?.cancel();
    try {
      await NativeMotionService.instance.stopMonitoring();
    } on MissingPluginException {
      // Nothing to stop — channel never registered. No-op.
    } catch (_) {
      // Best-effort stop.
    }
  }
}
