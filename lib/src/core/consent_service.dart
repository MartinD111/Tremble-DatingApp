import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static Future<PermissionStatus> requestLocation() =>
      Permission.locationWhenInUse.request();

  /// Request Bluetooth scan permission (for BLE proximity detection).
  /// On Android 12+ this maps to BLUETOOTH_SCAN. On older versions / iOS it
  /// requests the appropriate platform permission automatically.
  static Future<PermissionStatus> requestBluetooth() =>
      Permission.bluetoothScan.request();
}
