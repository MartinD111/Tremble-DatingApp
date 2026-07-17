import Flutter
import UIKit
import CoreMotion
import WidgetKit
import UserNotifications
import flutter_background_service_ios

public class TrembleNativePlugin: NSObject, FlutterPlugin {
    private var radarMethodChannel: FlutterMethodChannel?
    private var radarEventChannel: FlutterEventChannel?
    private var geofenceChannel: FlutterMethodChannel?
    private var motionMethodChannel: FlutterMethodChannel?
    private var motionEventChannel: FlutterEventChannel?
    private var bleRestoreMethodChannel: FlutterMethodChannel?
    private var bleRestoreEventChannel: FlutterEventChannel?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = TrembleNativePlugin()
        instance.setupChannels(with: registrar)
        registrar.addMethodCallDelegate(instance, channel: instance.radarMethodChannel!)
        // Note: we only need to add delegate to one channel if they share the same instance,
        // but it's cleaner to just set handlers directly as before, but keeping references.
    }

    private func setupChannels(with registrar: FlutterPluginRegistrar) {
        let binaryMessenger = registrar.messenger()
        
        // ── Radar state sync ──────────────────────────────────────────────────
        radarEventChannel = FlutterEventChannel(
            name: "app.tremble/radar/events",
            binaryMessenger: binaryMessenger
        )
        radarEventChannel?.setStreamHandler(RadarEventStreamHandler())

        radarMethodChannel = FlutterMethodChannel(
            name: "app.tremble/radar",
            binaryMessenger: binaryMessenger
        )
        radarMethodChannel?.setMethodCallHandler { call, result in
            switch call.method {
            case "setRadarActive":
                if let active = call.arguments as? [String: Any],
                   let isActive = active["active"] as? Bool {
                    RadarStateBridge.isActive = isActive
                    WidgetKit.WidgetCenter.shared.reloadAllTimelines()
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                }
            case "startRadarService", "stopRadarService":
                result(nil)
            case "getRadarActive":
                result(RadarStateBridge.isActive)
            case "requestAddQsTile":
                result(-1)
            case "requestPinWidget":
                result(false)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // ── Gym Mode — native OS geofencing ──────────────────────────────────
        geofenceChannel = FlutterMethodChannel(
            name: "tremble.dating.app/geofence",
            binaryMessenger: binaryMessenger
        )
        geofenceChannel?.setMethodCallHandler { call, result in
            switch call.method {
            case "startMonitoring":
                guard let gyms = call.arguments as? [[String: Any]] else {
                    result(FlutterError(
                        code: "INVALID_ARGS",
                        message: "Expected [[String: Any]] for gym list",
                        details: nil
                    ))
                    return
                }
                GymGeofenceManager.shared.startMonitoring(gyms: gyms)
                result(nil)
            case "stopMonitoring":
                GymGeofenceManager.shared.stopMonitoring()
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        // ── Motion Service — native Activity Recognition ─────────────────────
        motionEventChannel = FlutterEventChannel(
            name: "app.tremble/motion/events",
            binaryMessenger: binaryMessenger
        )
        motionEventChannel?.setStreamHandler(MotionService.shared)
        
        motionMethodChannel = FlutterMethodChannel(
            name: "app.tremble/motion",
            binaryMessenger: binaryMessenger
        )
        motionMethodChannel?.setMethodCallHandler { call, result in
            switch call.method {
            case "startMonitoring":
                MotionService.shared.startMonitoring()
                result(nil)
            case "stopMonitoring":
                MotionService.shared.stopMonitoring()
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // ── BLE State Restoration ─────────────────────────────────────────────
        bleRestoreEventChannel = FlutterEventChannel(
            name: "app.tremble/ble/restore/events",
            binaryMessenger: binaryMessenger
        )
        bleRestoreEventChannel?.setStreamHandler(BleRestoreBridge.shared)

        bleRestoreMethodChannel = FlutterMethodChannel(
            name: "app.tremble/ble/restore",
            binaryMessenger: binaryMessenger
        )
        bleRestoreMethodChannel?.setMethodCallHandler { call, result in
            switch call.method {
            case "bootstrap":
                result(nil) // No-op — debug confirmation
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Handled via closures in setupChannels
    }
}
class MotionService: NSObject, FlutterStreamHandler {
    static let shared = MotionService()
    
    private let activityManager = CMMotionActivityManager()
    private var eventSink: FlutterEventSink?
    private let queue = OperationQueue()
    
    private var isMonitoring = false
    
    override private init() {
        super.init()
        queue.name = "app.tremble.motionQueue"
    }
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
    
    func startMonitoring() {
        guard CMMotionActivityManager.isActivityAvailable(), !isMonitoring else { return }
        
        isMonitoring = true
        activityManager.startActivityUpdates(to: queue) { [weak self] activity in
            guard let self = self, let activity = activity else { return }
            
            var state = "UNKNOWN"
            if activity.running {
                state = "RUNNING"
            } else if activity.stationary {
                state = "STATIONARY"
            } else if activity.walking {
                state = "WALKING"
            }
            
            if state != "UNKNOWN" {
                DispatchQueue.main.async {
                    self.eventSink?(state)
                }
            }
        }
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        activityManager.stopActivityUpdates()
    }
}

/// Streams radar state changes from native (quick action, widget, app logic) to Flutter.
class RadarEventStreamHandler: NSObject, FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        RadarStateBridge.eventSink = events
        // Emit current state immediately
        events(RadarStateBridge.isActive)
        // Register for Darwin notification from widget or quick action
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let callback: CFNotificationCallback = { center, observer, name, object, userInfo in
            if let sink = RadarStateBridge.eventSink {
                sink(RadarStateBridge.isActive)
            }
        }
        CFNotificationCenterAddObserver(
            center,
            Unmanaged.passUnretained(self).toOpaque(),
            callback,
            "app.tremble.radar.changed" as CFString,
            nil,
            .deliverImmediately
        )
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        RadarStateBridge.eventSink = nil
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterRemoveObserver(
            center,
            Unmanaged.passUnretained(self).toOpaque(),
            CFNotificationName(rawValue: "app.tremble.radar.changed" as CFString),
            nil
        )
        return nil
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
    private static let pendingNotificationActionsKey = "app.tremble.pendingNotificationActions"
    private static let maxPendingNotificationActions = 100
    private var notificationActionsChannel: FlutterMethodChannel?

    private func setupNotificationActionsChannel() {
        guard let controller = window?.rootViewController as? FlutterViewController else { return }
        let channel = FlutterMethodChannel(
            name: "app.tremble/notification_actions",
            binaryMessenger: controller.binaryMessenger
        )
        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "getPendingActions":
                result(self.pendingNotificationActions())
            case "acknowledgeAction":
                guard let arguments = call.arguments as? [String: Any],
                      let id = arguments["id"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Missing action id", details: nil))
                    return
                }
                self.removePendingNotificationAction(id: id)
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        notificationActionsChannel = channel
    }

    private func pendingNotificationActions() -> [[String: String]] {
        UserDefaults.standard.array(forKey: Self.pendingNotificationActionsKey)
            as? [[String: String]] ?? []
    }

    private func persistWaveBackAction(response: UNNotificationResponse) {
        guard response.actionIdentifier == "WAVE_BACK_ACTION" else { return }

        let userInfo = response.notification.request.content.userInfo
        let gcmMessageId = userInfo["gcm.message_id"] as? String
        let waveId = userInfo["waveId"] as? String
        guard userInfo["type"] as? String == "INCOMING_WAVE",
              let messageId = [gcmMessageId, waveId]
            .compactMap({ $0?.trimmingCharacters(in: .whitespacesAndNewlines) })
            .first(where: { !$0.isEmpty }),
              let senderId = (userInfo["senderId"] as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
              !senderId.isEmpty else { return }

        let id = "WAVE_BACK_ACTION|\(messageId)|\(senderId)"
        var record: [String: String] = [
            "id": id,
            "actionIdentifier": response.actionIdentifier,
            "senderId": senderId,
            "type": "INCOMING_WAVE",
        ]
        if let gcmMessageId, !gcmMessageId.isEmpty {
            record["gcm.message_id"] = gcmMessageId
        }
        if let waveId, !waveId.isEmpty {
            record["waveId"] = waveId
        }

        var pending = pendingNotificationActions()
        guard !pending.contains(where: { $0["id"] == id }) else { return }
        pending.append(record)
        if pending.count > Self.maxPendingNotificationActions {
            pending.removeFirst(pending.count - Self.maxPendingNotificationActions)
        }
        UserDefaults.standard.set(pending, forKey: Self.pendingNotificationActionsKey)
        notificationActionsChannel?.invokeMethod("pendingActionsChanged", arguments: nil)
    }

    private func removePendingNotificationAction(id: String) {
        let remaining = pendingNotificationActions().filter { $0["id"] != id }
        UserDefaults.standard.set(remaining, forKey: Self.pendingNotificationActionsKey)
    }

    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        persistWaveBackAction(response: response)
        super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
    }



    override func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        if shortcutItem.type == "app.tremble.radar.toggle" {
            let newState = !RadarStateBridge.isActive
            RadarStateBridge.isActive = newState
            // Trigger widget reload
            WidgetKit.WidgetCenter.shared.reloadAllTimelines()
            completionHandler(true)
        } else {
            completionHandler(false)
        }
    }



    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        SwiftFlutterBackgroundServicePlugin.taskIdentifier = "app.tremble.radar"

        // Own the notification-center delegate BEFORE plugin registration.
        // firebase_messaging skips replacing the delegate when it already
        // conforms to FlutterAppLifeCycleProvider (which FlutterAppDelegate
        // does), specifically to avoid an infinite willPresentNotification
        // forwarding loop (flutterfire#4026). Without this line the Firebase
        // app-delegate-proxy claims the delegate first, the plugin then wraps
        // it, and every foreground push recurses until the stack overflows —
        // the 1.0.0+23/+24 freeze (Sentry TREMBLE-FUNCTIONS-V/-W). Swizzling
        // stays enabled, so FCM token handling is unaffected.
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }

        GeneratedPluginRegistrant.register(with: self)
        if let registrar = self.registrar(forPlugin: "TrembleNativePlugin") {
            TrembleNativePlugin.register(with: registrar)
        }
        setupNotificationActionsChannel()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
