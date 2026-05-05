import Foundation
#if canImport(Flutter)
import Flutter
#endif

/// Shared state bridge between the main app and WidgetKit extension via App Group UserDefaults.
/// Persists radar active/inactive state and broadcasts state changes via Darwin NotificationCenter.
///
/// Both the app and widget extension read/write to the same UserDefaults suite, keyed by bundle ID.
/// When state changes, a notification is posted so AppDelegate can forward to Flutter EventChannel.
class RadarStateBridge {
  private static let appGroup: String = {
    #if FLAVOR_DEV
      return "group.com.pulse.radar"
    #else
      return "group.tremble.dating.app.radar"
    #endif
  }()

  private static let key = "radarActive"
  private static let notificationName = "app.tremble.radar.changed"

  static var isActive: Bool {
    get {
      let defaults = UserDefaults(suiteName: appGroup) ?? UserDefaults.standard
      return defaults.bool(forKey: key)
    }
    set {
      let defaults = UserDefaults(suiteName: appGroup) ?? UserDefaults.standard
      defaults.set(newValue, forKey: key)
      defaults.synchronize()
      // Broadcast to any listeners (AppDelegate EventChannel, widget refresh)
      notifyFlutter(newValue)
    }
  }

  #if canImport(Flutter)
  static var eventSink: FlutterEventSink?
  #endif

  /// Post Darwin notification so AppDelegate can relay state to Flutter EventChannel.
  /// Called whenever state changes (from app logic, quick action, or widget).
  static func notifyFlutter(_ active: Bool) {
    // Push event to Flutter EventChannel if sink is active
    #if canImport(Flutter)
    DispatchQueue.main.async {
      eventSink?(active)
    }
    #endif
    // Post Darwin notification for inter-process signaling
    // (WidgetKit extension → main app when widget taps toggle)
    CFNotificationCenterPostNotification(
      CFNotificationCenterGetDarwinNotifyCenter(),
      CFNotificationName(notificationName as NSString),
      nil,
      nil,
      true
    )
  }
}
