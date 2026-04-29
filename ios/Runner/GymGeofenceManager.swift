import CoreLocation
import UserNotifications

/// Native OS geofence manager for Gym Mode.
///
/// Strategy (iOS):
///   1. Register CLCircularRegion for each gym (radius 70–100 m, default 80 m).
///   2. On didEnterRegion → schedule a UNTimeIntervalNotificationTrigger 10 min
///      from now. The notification system fires it even if the app is killed.
///   3. On didExitRegion → cancel the pending notification; the user left before
///      the 10-minute dwell elapsed.
///
/// Battery cost in killed state: 0 %.
/// iOS can monitor up to 20 CLCircularRegions; we stay well within that limit.
@objc class GymGeofenceManager: NSObject {
    @objc static let shared = GymGeofenceManager()

    private let locationManager = CLLocationManager()
    private var gymNames: [String: String] = [:] // regionIdentifier → gymName

    private override init() {
        super.init()
        locationManager.delegate = self
    }

    // MARK: - Public API (called from AppDelegate MethodChannel handler)

    @objc func startMonitoring(gyms: [[String: Any]]) {
        stopMonitoring() // clear existing before re-registering

        for gym in gyms {
            guard
                let id     = gym["id"]  as? String,
                let lat    = gym["lat"] as? Double,
                let lng    = gym["lng"] as? Double
            else { continue }

            let rawRadius = (gym["radiusMeters"] as? Double) ?? 80.0
            let radius    = min(max(rawRadius, 70.0), 100.0) // clamp 70–100 m
            let name      = gym["name"] as? String ?? id
            gymNames[id]  = name

            let center = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            let region = CLCircularRegion(center: center, radius: radius, identifier: id)
            region.notifyOnEntry = true
            region.notifyOnExit  = true

            locationManager.startMonitoring(for: region)
        }
    }

    @objc func stopMonitoring() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
            cancelDwellNotification(gymId: region.identifier)
        }
        gymNames.removeAll()
    }

    // MARK: - Notification helpers

    private func scheduleDwellNotification(gymId: String, gymName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Si v \(gymName)? 💪"
        content.body  = "Vklopiš Gym Mode in se poveži z drugimi!"
        content.sound = .default

        // 10 minutes from region entry — fires even if the app is killed.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 600, repeats: false)
        let request = UNNotificationRequest(
            identifier: notifId(gymId),
            content:    content,
            trigger:    trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[GymGeofence] Failed to schedule notification: \(error)")
            }
        }
    }

    private func cancelDwellNotification(gymId: String) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [notifId(gymId)])
    }

    private func notifId(_ gymId: String) -> String { "gym_dwell_\(gymId)" }
}

// MARK: - CLLocationManagerDelegate

extension GymGeofenceManager: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let gymName = gymNames[region.identifier] else { return }
        print("[GymGeofence] Entered \(region.identifier) — scheduling dwell notification in 10 min")
        scheduleDwellNotification(gymId: region.identifier, gymName: gymName)
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("[GymGeofence] Exited \(region.identifier) — cancelling pending notification")
        cancelDwellNotification(gymId: region.identifier)
    }

    func locationManager(
        _ manager: CLLocationManager,
        monitoringDidFailFor region: CLRegion?,
        withError error: Error
    ) {
        print("[GymGeofence] Monitoring failed for \(region?.identifier ?? "??"): \(error)")
    }
}
