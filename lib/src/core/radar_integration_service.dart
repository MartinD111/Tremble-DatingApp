import 'dart:io';
import 'android_integration_service.dart';
import 'ios_integration_service.dart';

/// Platform-agnostic Radar integration service.
/// Routes to AndroidIntegrationService on Android, IosIntegrationService on iOS.
class RadarIntegrationService {
  RadarIntegrationService._();

  static final RadarIntegrationService instance = RadarIntegrationService._();

  /// Broadcasts Radar state changes from native side (tile/quick action/widget tap).
  Stream<bool> get radarStateChanges {
    if (Platform.isAndroid) {
      return AndroidIntegrationService.instance.radarStateChanges;
    } else if (Platform.isIOS) {
      return IosIntegrationService.instance.radarStateChanges;
    }
    return const Stream.empty();
  }

  /// Sync radar state to native side. Updates tile, widget, quick action appearance.
  Future<void> setRadarActive(bool active) async {
    if (Platform.isAndroid) {
      return AndroidIntegrationService.instance.setRadarActive(active);
    } else if (Platform.isIOS) {
      return IosIntegrationService.instance.setRadarActive(active);
    }
  }

  /// Start the radar foreground service (Android) or enable background location (iOS).
  Future<void> startRadarService() async {
    if (Platform.isAndroid) {
      return AndroidIntegrationService.instance.startRadarService();
    } else if (Platform.isIOS) {
      return IosIntegrationService.instance.startRadarService();
    }
  }

  /// Stop the radar service.
  Future<void> stopRadarService() async {
    if (Platform.isAndroid) {
      return AndroidIntegrationService.instance.stopRadarService();
    } else if (Platform.isIOS) {
      return IosIntegrationService.instance.stopRadarService();
    }
  }

  /// Read persisted radar state from native SharedPreferences / UserDefaults.
  Future<bool> getRadarActive() async {
    if (Platform.isAndroid) {
      return AndroidIntegrationService.instance.getRadarActive();
    } else if (Platform.isIOS) {
      return IosIntegrationService.instance.getRadarActive();
    }
    return false;
  }

  /// Request OS to add Quick Settings tile (Android 13+). Returns result code.
  /// iOS: always -1 (not applicable).
  Future<int> requestAddQsTile() async {
    if (Platform.isAndroid) {
      return AndroidIntegrationService.instance.requestAddQsTile();
    }
    return -1;
  }

  /// Request launcher to pin widget to home screen (Android) or lock screen (iOS).
  /// Returns true if request submitted, false if unsupported.
  Future<bool> requestPinWidget() async {
    if (Platform.isAndroid) {
      return AndroidIntegrationService.instance.requestPinWidget();
    } else if (Platform.isIOS) {
      return IosIntegrationService.instance.requestPinWidget();
    }
    return false;
  }
}
