import CoreBluetooth
import Flutter

/// BLE State Restoration Bridge — owns a CBCentralManager with a restoration
/// identifier so iOS can re-arm the scan after the app is force-quit.
///
/// This is intentionally separate from flutter_blue_plus's CBCentralManager
/// (which has no restoration identifier). Two CBCentralManagers are allowed;
/// each receives its own delegate callbacks.
///
/// Architecture:
///   - CBCentralManager: scans for Tremble service UUID
///   - CBPeripheralManager: keeps BLE advertising alive across restores
///   - FlutterEventChannel: streams {rssi, uuid} events to Dart
///   - FlutterMethodChannel: exposes "bootstrap" for debug confirmation
class BleRestoreBridge: NSObject, FlutterStreamHandler {

    static let shared = BleRestoreBridge()

    // ── Constants ────────────────────────────────────────────────────────────
    private static let centralRestoreId    = "app.tremble.ble.central"
    private static let peripheralRestoreId = "app.tremble.ble.peripheral"
    private static let trembleServiceUUID  = CBUUID(string: "73a9429f-fd01-4ac9-9e5a-eabd0d31438e")

    // ── Core Bluetooth managers ──────────────────────────────────────────────
    private var centralManager: CBCentralManager!
    private var peripheralManager: CBPeripheralManager!

    // ── Flutter channel ──────────────────────────────────────────────────────
    private var eventSink: FlutterEventSink?

    // ── Dedup guard ──────────────────────────────────────────────────────────
    // Prevents flooding the Dart side with duplicate discoveries within a
    // short window (same device re-discovered in < 10 s).
    private var lastEmitTimestamps: [String: Date] = [:]
    private static let dedupIntervalSeconds: TimeInterval = 10

    // ── Init ─────────────────────────────────────────────────────────────────
    private override init() {
        super.init()

        centralManager = CBCentralManager(
            delegate: self,
            queue: DispatchQueue(label: "app.tremble.ble.central.queue"),
            options: [
                CBCentralManagerOptionRestoreIdentifierKey: BleRestoreBridge.centralRestoreId
            ]
        )

        peripheralManager = CBPeripheralManager(
            delegate: self,
            queue: DispatchQueue(label: "app.tremble.ble.peripheral.queue"),
            options: [
                CBPeripheralManagerOptionRestoreIdentifierKey: BleRestoreBridge.peripheralRestoreId
            ]
        )
    }

    // ── FlutterStreamHandler ─────────────────────────────────────────────────

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    // ── Scan helpers ─────────────────────────────────────────────────────────

    private func startScanIfPoweredOn() {
        guard centralManager.state == .poweredOn else { return }

        // Already scanning? No-op.
        if centralManager.isScanning { return }

        centralManager.scanForPeripherals(
            withServices: [BleRestoreBridge.trembleServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        print("[BleRestoreBridge] Scan started for Tremble service UUID")
    }

    private func emitEvent(rssi: Int, uuid: String) {
        let now = Date()
        if let last = lastEmitTimestamps[uuid],
           now.timeIntervalSince(last) < BleRestoreBridge.dedupIntervalSeconds {
            return // duplicate within window — skip
        }
        lastEmitTimestamps[uuid] = now

        DispatchQueue.main.async { [weak self] in
            self?.eventSink?([
                "rssi": rssi,
                "uuid": uuid
            ])
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BleRestoreBridge: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            startScanIfPoweredOn()
        case .poweredOff, .unauthorized, .unsupported:
            print("[BleRestoreBridge] Central state: \(central.state.rawValue) — scan not possible")
        default:
            break
        }
    }

    /// Called by iOS when the app is relaunched into the background after a
    /// force-quit. The system passes back any peripherals that were connected
    /// or pending at the time of termination.
    func centralManager(
        _ central: CBCentralManager,
        willRestoreState dict: [String: Any]
    ) {
        print("[BleRestoreBridge] willRestoreState — re-arming scan")
        // Re-start scan. centralManagerDidUpdateState will fire after this
        // with .poweredOn, but we call startScan explicitly for immediacy.
        startScanIfPoweredOn()
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let rssiValue = RSSI.intValue
        let uuid = peripheral.identifier.uuidString

        // Ignore peripherals with unreasonable RSSI (too far or erroneous)
        guard rssiValue >= -90 else { return }

        print("[BleRestoreBridge] Discovered \(uuid) RSSI=\(rssiValue)")
        emitEvent(rssi: rssiValue, uuid: uuid)
    }
}

// MARK: - CBPeripheralManagerDelegate

extension BleRestoreBridge: CBPeripheralManagerDelegate {

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            print("[BleRestoreBridge] Peripheral manager powered on")
        default:
            print("[BleRestoreBridge] Peripheral state: \(peripheral.state.rawValue)")
        }
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        willRestoreState dict: [String: Any]
    ) {
        print("[BleRestoreBridge] Peripheral willRestoreState")
        // Peripheral advertising is automatically restored by iOS — no action needed.
    }
}
