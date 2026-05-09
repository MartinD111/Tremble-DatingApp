import Flutter
import UIKit
import GoogleMaps
import CoreMotion
import WidgetKit
import flutter_background_service_ios

public class TrembleNativePlugin: NSObject, FlutterPlugin {
    private var radarMethodChannel: FlutterMethodChannel?
    private var radarEventChannel: FlutterEventChannel?
    private var geofenceChannel: FlutterMethodChannel?
    private var motionMethodChannel: FlutterMethodChannel?
    private var motionEventChannel: FlutterEventChannel?

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
        if let mapsApiKey = Bundle.main.object(forInfoDictionaryKey: "MAPS_API_KEY") as? String,
           !mapsApiKey.isEmpty {
            GMSServices.provideAPIKey(mapsApiKey)
        }

        SwiftFlutterBackgroundServicePlugin.taskIdentifier = "app.tremble.radar"
        SwiftFlutterBackgroundServicePlugin.setPluginRegistrantCallback { registry in
            GeneratedPluginRegistrant.register(with: registry)
            if let registrar = registry.registrar(forPlugin: "TrembleNativePlugin") {
                TrembleNativePlugin.register(with: registrar)
            }
        }

        GeneratedPluginRegistrant.register(with: self)
        if let registrar = self.registrar(forPlugin: "TrembleNativePlugin") {
            TrembleNativePlugin.register(with: registrar)
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
