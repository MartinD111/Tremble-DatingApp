import 'package:flutter/foundation.dart';
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
        platform: TargetPlatform.android,
      );

      expect(issue, RadarBleIssue.bluetoothOff);
    });

    test(
        'returns permissionDenied when bluetooth is on but permission is denied (Android)',
        () {
      final issue = resolveRadarBleIssue(
        adapterState: BluetoothAdapterState.on,
        permissionStatus: PermissionStatus.denied,
        platform: TargetPlatform.android,
      );

      expect(issue, RadarBleIssue.permissionDenied);
    });

    test('returns null when bluetooth is on and permission is granted', () {
      final issue = resolveRadarBleIssue(
        adapterState: BluetoothAdapterState.on,
        permissionStatus: PermissionStatus.granted,
        platform: TargetPlatform.android,
      );

      expect(issue, isNull);
    });

    test(
        'iOS: returns null when adapter is on regardless of permission status (CoreBluetooth contract)',
        () {
      final deniedIssue = resolveRadarBleIssue(
        adapterState: BluetoothAdapterState.on,
        permissionStatus: PermissionStatus.denied,
        platform: TargetPlatform.iOS,
      );
      final permanentlyDeniedIssue = resolveRadarBleIssue(
        adapterState: BluetoothAdapterState.on,
        permissionStatus: PermissionStatus.permanentlyDenied,
        platform: TargetPlatform.iOS,
      );
      final unknownIssue = resolveRadarBleIssue(
        adapterState: BluetoothAdapterState.on,
        permissionStatus: null,
        platform: TargetPlatform.iOS,
      );

      expect(deniedIssue, isNull);
      expect(permanentlyDeniedIssue, isNull);
      expect(unknownIssue, isNull);
    });

    test('iOS: unauthorized adapter still maps to permissionDenied', () {
      final issue = resolveRadarBleIssue(
        adapterState: BluetoothAdapterState.unauthorized,
        permissionStatus: PermissionStatus.granted,
        platform: TargetPlatform.iOS,
      );

      expect(issue, RadarBleIssue.permissionDenied);
    });

    test('transient adapter states never surface an overlay', () {
      for (final state in [
        BluetoothAdapterState.unknown,
        BluetoothAdapterState.turningOn,
      ]) {
        final issue = resolveRadarBleIssue(
          adapterState: state,
          permissionStatus: PermissionStatus.denied,
          platform: TargetPlatform.android,
        );
        expect(issue, isNull, reason: 'state=$state should not show overlay');
      }
    });
  });
}
