import Flutter
import UIKit
import GoogleMaps

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
    }
}
