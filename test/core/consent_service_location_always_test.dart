// Regression tests for H2 — Location "Always" tier escalation.
//
// ConsentService.requestLocation() MUST:
//  1. First request Permission.locationWhenInUse
//  2. Only if granted AND on iOS, also request Permission.locationAlways
//  3. Return the WhenInUse status (callers key off that value)
//
// These tests operate on the source text because permission_handler requires
// a real device to invoke. They pin the structural contract so a future
// refactor cannot silently regress to the single-call implementation.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const sourcePath = 'lib/src/core/consent_service.dart';

  late String source;

  setUpAll(() {
    source = File(sourcePath).readAsStringSync();
  });

  group('ConsentService.requestLocation() — two-step location escalation', () {
    test('imports dart:io Platform', () {
      expect(
        source,
        contains("import 'dart:io' show Platform;"),
        reason: 'Platform.isIOS guard requires dart:io import',
      );
    });

    test('requests locationWhenInUse first', () {
      expect(
        source,
        contains('Permission.locationWhenInUse.request()'),
        reason: 'Step 1: WhenInUse is the entry-level location permission',
      );
    });

    test('requests locationAlways on iOS after WhenInUse granted', () {
      expect(
        source,
        contains('Permission.locationAlways.request()'),
        reason: 'Step 2: iOS requires explicit escalation to Always tier',
      );
    });

    test('Platform.isIOS guard present to gate the second request', () {
      expect(
        source,
        contains('Platform.isIOS'),
        reason: 'Second request must only fire on iOS, not Android',
      );
    });

    test('second request is inside the whenInUse.isGranted block', () {
      // Verify ordering: isGranted check must appear before locationAlways.
      final isGrantedIdx = source.indexOf('whenInUse.isGranted');
      final alwaysIdx = source.indexOf('locationAlways.request()');
      expect(isGrantedIdx, isNot(-1), reason: 'isGranted check must exist');
      expect(alwaysIdx, isNot(-1),
          reason: 'locationAlways.request() must exist');
      expect(
        isGrantedIdx < alwaysIdx,
        isTrue,
        reason:
            'locationAlways.request() must be nested inside the isGranted block',
      );
    });

    test('requestLocation is an async method, not a one-liner arrow function',
        () {
      // The old implementation was:
      //   static Future<PermissionStatus> requestLocation() =>
      //       Permission.locationWhenInUse.request();
      // After H2 it must be an async function body.
      expect(
        source,
        contains('requestLocation() async'),
        reason: 'requestLocation must be an async function to await both calls',
      );
    });

    test('method still returns the WhenInUse status', () {
      expect(
        source,
        contains('return whenInUse'),
        reason: 'Callers depend on the WhenInUse PermissionStatus return value',
      );
    });

    test('requestBluetooth is unchanged', () {
      expect(
        source,
        contains('Permission.bluetoothScan.request()'),
        reason: 'H2 scope is location only — bluetoothScan must stay intact',
      );
    });
  });
}
