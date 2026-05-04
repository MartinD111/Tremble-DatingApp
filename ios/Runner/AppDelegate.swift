import Flutter
import UIKit
import GoogleMaps
import CoreMotion
import WidgetKit

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
            "app.tremble.radar.changed" as CFString,
            nil
        )
        return nil
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Google Maps SDK — key stored in Info.plist as MAPS_API_KEY.
        // Local dev: set MAPS_API_KEY in ios/Flutter/Debug.xcconfig.
        // CI/CD: inject MAPS_API_KEY as an xcconfig variable before build.
        if let mapsApiKey = Bundle.main.object(forInfoDictionaryKey: "MAPS_API_KEY") as? String,
           !mapsApiKey.isEmpty {
            GMSServices.provideAPIKey(mapsApiKey)
        }
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

        // ── Radar state sync (tile/widget/quick action ↔ Flutter) ───────────────
        // EventChannel: broadcasts radar state changes to Flutter
        let radarEventChannel = FlutterEventChannel(
            name: "app.tremble/radar/events",
            binaryMessenger: engineBridge.binaryMessenger
        )
        radarEventChannel.setStreamHandler(object: RadarEventStreamHandler())

        // MethodChannel: receives setRadarActive / getRadarActive / etc from Flutter
        let radarMethodChannel = FlutterMethodChannel(
            name: "app.tremble/radar",
            binaryMessenger: engineBridge.binaryMessenger
        )
        radarMethodChannel.setMethodCallHandler { call, result in
            switch call.method {
            case "setRadarActive":
                if let active = call.arguments as? [String: Any],
                   let isActive = active["active"] as? Bool {
                    RadarStateBridge.isActive = isActive
                    // Trigger widget timeline reload so lock screen widget re-renders
                    WidgetKit.WidgetCenter.shared.reloadAllTimelines()
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                }
            case "startRadarService":
                // iOS doesn't use foreground service — background modes handle this
                result(nil)
            case "stopRadarService":
                // iOS doesn't use foreground service
                result(nil)
            case "getRadarActive":
                result(RadarStateBridge.isActive)
            case "requestAddQsTile":
                // Quick Settings tiles are Android-only
                result(-1)
            case "requestPinWidget":
                // Widget pinning is handled via Settings → Customize Lock Screen
                result(false)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // ── Gym Mode — native OS geofencing ──────────────────────────────────
        // startMonitoring: registers CLCircularRegion for each gym. The OS
        //   schedules a UNTimeIntervalNotificationTrigger (10 min) on region
        //   entry — fires even if the app is killed (0 % battery cost).
        // stopMonitoring: removes all regions and cancels pending notifications.
        let geofenceChannel = FlutterMethodChannel(
            name: "tremble.dating.app/geofence",
            binaryMessenger: engineBridge.binaryMessenger
        )

        geofenceChannel.setMethodCallHandler { call, result in
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
        let motionEventChannel = FlutterEventChannel(
            name: "app.tremble/motion/events",
            binaryMessenger: engineBridge.binaryMessenger
        )
        motionEventChannel.setStreamHandler(MotionService.shared)
        
        let motionMethodChannel = FlutterMethodChannel(
            name: "app.tremble/motion",
            binaryMessenger: engineBridge.binaryMessenger
        )
        motionMethodChannel.setMethodCallHandler { call, result in
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
    }
}
