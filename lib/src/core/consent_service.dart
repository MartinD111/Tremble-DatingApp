import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPermissionsPresented = 'permissions_presented';

/// Tracks whether the permission gate has been shown to the user.
/// Initialized in main.dart via ProviderScope.overrides from SharedPreferences.
final permissionsPresentedProvider = StateProvider<bool>((ref) => false);

/// Handles OS permission requests and the one-shot "presented" flag.
class ConsentService {
  /// Returns true if the permission gate has already been shown.
  static Future<bool> hasPresented() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kPermissionsPresented) ?? false;
  }

  /// Marks the permission gate as shown. Call before navigating away from the gate.
  static Future<void> markPresented() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPermissionsPresented, true);
  }

  /// Request location permission (for Radar / Geo feature).
  static Future<PermissionStatus> requestLocation() =>
      Permission.locationWhenInUse.request();

  /// Request Bluetooth scan permission (for BLE proximity detection).
  /// On Android 12+ this maps to BLUETOOTH_SCAN. On older versions / iOS it
  /// requests the appropriate platform permission automatically.
  static Future<PermissionStatus> requestBluetooth() =>
      Permission.bluetoothScan.request();
}
