import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

const String gdprConsentKey = 'gdpr_ble_location_consent';

/// Tracks whether the user has granted GDPR consent for BLE + Location access.
///
/// Persisted in SharedPreferences. Consumed by:
///   - router.dart (redirect guard)
///   - background_service.dart (gate before BleService/GeoService start)
class GdprConsentNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(gdprConsentKey) ?? false;
  }

  Future<void> grantConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(gdprConsentKey, true);
    state = const AsyncValue.data(true);
  }

  /// Called after fresh registration so the permission gate always shows.
  Future<void> resetConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(gdprConsentKey, false);
    state = const AsyncValue.data(false);
  }
}

final gdprConsentProvider =
    AsyncNotifierProvider<GdprConsentNotifier, bool>(GdprConsentNotifier.new);

/// Handles OS permission requests.
class ConsentService {
  /// Request location permission (for Radar / Geo feature).
  ///
  /// On iOS this is a two-step process:
  /// 1. Request "When In Use" so the system shows the standard location dialog.
  /// 2. If granted, immediately escalate to "Always" so GeoService can update
  ///    the geohash while the app is backgrounded (BLE proximity requires it).
  ///    iOS requires the second request to originate from Dart — there is no
  ///    single-call path to "Always" from a cold state.
  ///
  /// On Android, ACCESS_BACKGROUND_LOCATION in AndroidManifest.xml handles the
  /// background tier automatically once ACCESS_FINE_LOCATION is granted at
  /// runtime — no second Dart call is needed.
  static Future<PermissionStatus> requestLocation() async {
    final whenInUse = await Permission.locationWhenInUse.request();

    if (whenInUse.isGranted) {
      if (Platform.isIOS) {
        // iOS requires an explicit second request after "When In Use" is
        // granted. The system shows a separate prompt:
        // "Allow [App] to always access your location?"
        // with the explanatory note set in Info.plist
        // (NSLocationAlwaysAndWhenInUseUsageDescription).
        //
        // UX rationale shown to the user before this request:
        // "So Tremble can detect people nearby even when you're not looking
        // at the app." This is surfaced by the permission_gate_screen before
        // calling ConsentService.requestLocation().
        await Permission.locationAlways.request();
      }
      // Android: ACCESS_BACKGROUND_LOCATION in AndroidManifest.xml handles
      // the background tier automatically — no second runtime request needed.
    }

    return whenInUse;
  }

  /// Request Bluetooth scan permission (for BLE proximity detection).
  /// On Android 12+ this maps to BLUETOOTH_SCAN. On older versions / iOS it
  /// requests the appropriate platform permission automatically.
  static Future<PermissionStatus> requestBluetooth() =>
      Permission.bluetoothScan.request();

  /// Request notification permission so waves and proximity alerts can be
  /// delivered while the app is backgrounded.
  ///
  /// Requested at the onboarding permission gate so users grant it before the
  /// first wave arrives (previously gated on a wave arriving in the foreground,
  /// which silently dropped pushes for any user who never saw one). The
  /// existing in-app prompt in home_screen remains as a fallback for users who
  /// declined here.
  static Future<PermissionStatus> requestNotification() async {
    final status = await Permission.notification.request();

    if (Platform.isAndroid) {
      // Android 13+ requires the FCM channel-level permission via the
      // notifications plugin in addition to the OS-level permission above.
      await NotificationService.notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    return status;
  }
}
