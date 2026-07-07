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
  /// Request foreground location ("When In Use") only.
  ///
  /// Callers must NOT chain this into a background-location request without
  /// showing the Prominent Disclosure screen first — Google Play policy for
  /// ACCESS_BACKGROUND_LOCATION requires a standalone disclosure between the
  /// foreground grant and the OS background-permission prompt.
  ///
  /// See [requestLocationAlways] for the background step and
  /// ProminentDisclosureScreen for the disclosure UI that must precede it.
  static Future<PermissionStatus> requestLocationWhenInUse() =>
      Permission.locationWhenInUse.request();

  /// Request background location ("Always" tier).
  ///
  /// Must only be invoked AFTER the user has affirmatively tapped the primary
  /// CTA on ProminentDisclosureScreen. This method itself does not check for
  /// disclosure — that responsibility lives in the caller.
  ///
  /// On iOS this triggers the system dialog:
  ///   "Allow [App] to always access your location?"
  /// backed by NSLocationAlwaysAndWhenInUseUsageDescription in Info.plist.
  ///
  /// On Android 10 this triggers a runtime dialog; on Android 11+ it opens
  /// the app's Location settings so the user can choose "Allow all the time".
  /// Both count as the OS prompt that Google Play policy gates behind the
  /// Prominent Disclosure.
  ///
  /// Returns the resulting permission status.
  static Future<PermissionStatus> requestLocationAlways() =>
      Permission.locationAlways.request();

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
