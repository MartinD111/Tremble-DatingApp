import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:screen_protector/screen_protector.dart';

/// Blocks screenshots and screen recordings on sensitive screens.
///
/// Always a no-op in debug mode so development is unaffected.
/// Android relies on FLAG_SECURE (OS handles everything).
/// iOS uses ScreenProtector for screenshot and app-switcher protection,
/// plus a listener so the UI can show [RecordingShield] during recordings.
class ScreenProtectionService {
  ScreenProtectionService._();

  /// Enable protection on the current screen.
  /// Call from [State.initState]. Fire-and-forget — no need to await.
  static void enable() {
    if (kDebugMode) return;
    if (defaultTargetPlatform == TargetPlatform.android) {
      FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      ScreenProtector.preventScreenshotOn();
      ScreenProtector.protectDataLeakageWithColor(const Color(0xFF1A1A18));
    }
  }

  /// Disable protection when leaving the screen.
  /// Call from [State.dispose]. Fire-and-forget — no need to await.
  static void disable() {
    if (kDebugMode) return;
    if (defaultTargetPlatform == TargetPlatform.android) {
      FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      ScreenProtector.preventScreenshotOff();
      ScreenProtector.protectDataLeakageWithColorOff();
    }
  }

  /// iOS only. [listener] receives `true` when recording starts,
  /// `false` when it stops.
  /// Internally maps to [ScreenProtector.addListener]'s second parameter
  /// (screenRecordListener). Screenshot listener is unused here.
  static void addRecordingListener(void Function(bool) listener) {
    if (kDebugMode) return;
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    ScreenProtector.addListener(null, listener);
  }

  /// Remove all previously registered recording listeners.
  static void removeRecordingListener() {
    if (kDebugMode) return;
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    ScreenProtector.removeListener();
  }
}

/// Full-screen graphite overlay shown when iOS detects screen recording.
/// Replaces sensitive content so the recording captures only the brand mark.
class RecordingShield extends StatelessWidget {
  const RecordingShield({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A18),
      child: Center(
        child: SvgPicture.asset(
          'Logo/tremble_icon_clean_transparent.svg',
          width: 80,
          height: 80,
          colorFilter: const ColorFilter.mode(
            Color(0xFFFAFAF7),
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
