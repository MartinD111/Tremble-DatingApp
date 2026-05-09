import Foundation

let path = "ios/Runner/AppDelegate.swift"
var content = try! String(contentsOfFile: path)

content = content.replacingOccurrences(
    of: "func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {",
    with: "func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {\n        // NOOP\n    }\n\n    override func application(\n        _ application: UIApplication,\n        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?\n    ) -> Bool {\n        if let mapsApiKey = Bundle.main.object(forInfoDictionaryKey: \"MAPS_API_KEY\") as? String,\n           !mapsApiKey.isEmpty {\n            GMSServices.provideAPIKey(mapsApiKey)\n        }\n\n        GeneratedPluginRegistrant.register(with: self)\n\n        guard let controller = window?.rootViewController as? FlutterViewController else {\n            return super.application(application, didFinishLaunchingWithOptions: launchOptions)\n        }\n        let binaryMessenger = controller.binaryMessenger\n"
)

content = content.replacingOccurrences(
    of: "GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)",
    with: ""
)

content = content.replacingOccurrences(
    of: "engineBridge.binaryMessenger",
    with: "binaryMessenger"
)

content = content.replacingOccurrences(
    of: "\"app.tremble.radar.changed\" as CFString",
    with: "CFNotificationName(rawValue: \"app.tremble.radar.changed\" as CFString)"
)

content = content.replacingOccurrences(
    of: """
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
""",
    with: ""
)

try! content.write(toFile: path, atomically: true, encoding: .utf8)
