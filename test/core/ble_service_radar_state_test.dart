import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tremble/src/core/ble_service.dart';

void main() {
  group('resolveRadarBleIssue', () {
    test('returns bluetoothOff before permission denied when adapter is off',
        () {
      final issue = resolveRadarBleIssue(
        adapterState: BluetoothAdapterState.off,
        permissionStatus: PermissionStatus.denied,
      );

      expect(issue, RadarBleIssue.bluetoothOff);
    });

    test(
        'returns permissionDenied when bluetooth is on but permission is denied',
        () {
      final issue = resolveRadarBleIssue(
        adapterState: BluetoothAdapterState.on,
        permissionStatus: PermissionStatus.denied,
      );

      expect(issue, RadarBleIssue.permissionDenied);
    });

    test('returns null when bluetooth is on and permission is granted', () {
      final issue = resolveRadarBleIssue(
        adapterState: BluetoothAdapterState.on,
        permissionStatus: PermissionStatus.granted,
      );

      expect(issue, isNull);
    });
  });
}
