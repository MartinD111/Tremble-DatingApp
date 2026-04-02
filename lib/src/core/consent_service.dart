import 'package:flutter_riverpod/flutter_riverpod.dart';
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
}

final gdprConsentProvider =
    AsyncNotifierProvider<GdprConsentNotifier, bool>(GdprConsentNotifier.new);
