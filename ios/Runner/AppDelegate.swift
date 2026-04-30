import Flutter
import UIKit
import GoogleMaps
import CoreMotion

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

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

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
