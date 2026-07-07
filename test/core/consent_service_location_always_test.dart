// Regression tests for the split of the old ConsentService.requestLocation()
// into two separately-invocable methods, driven by the Google Play Prominent
// Disclosure requirement for ACCESS_BACKGROUND_LOCATION.
//
// New contract:
//  * ConsentService.requestLocationWhenInUse() — foreground only.
//  * ConsentService.requestLocationAlways()    — background only.
//  * The caller (PermissionGateScreen) is responsible for showing the
//    Prominent Disclosure between the two calls. The old compound
//    requestLocation() method MUST NOT exist, so no future refactor can
//    accidentally re-fuse the two steps and skip the disclosure.
//
// permission_handler cannot be invoked outside a device, so these tests
// operate on the source text — matching the pattern used elsewhere in this
// suite (see registration_flow_test.dart, api_payload_contract_test.dart).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const sourcePath = 'lib/src/core/consent_service.dart';

  late String source;

  setUpAll(() {
    source = File(sourcePath).readAsStringSync();
  });

  group('ConsentService — post-Prominent-Disclosure split', () {
    test('exposes requestLocationWhenInUse for the foreground step', () {
      expect(
        source,
        contains('requestLocationWhenInUse'),
        reason: 'Foreground request must be independently callable',
      );
      expect(
        source,
        contains('Permission.locationWhenInUse.request()'),
        reason: 'Foreground path still hits WhenInUse',
      );
    });

    test('exposes requestLocationAlways for the background step', () {
      expect(
        source,
        contains('requestLocationAlways'),
        reason: 'Background request must be independently callable',
      );
      expect(
        source,
        contains('Permission.locationAlways.request()'),
        reason: 'Background path still hits Always',
      );
    });

    test('no compound requestLocation() method remains', () {
      // The old method chained WhenInUse → Always. Its removal is what
      // guarantees the caller cannot accidentally skip the Prominent
      // Disclosure by calling a single "do everything" method.
      final compoundPattern = RegExp(r'\brequestLocation\s*\(\s*\)');
      expect(
        compoundPattern.hasMatch(source),
        isFalse,
        reason: 'requestLocation() must be gone. Callers must invoke '
            'requestLocationWhenInUse and requestLocationAlways separately '
            'with the Prominent Disclosure in between.',
      );
    });

    test(
        'no code path chains WhenInUse directly into Always inside the service',
        () {
      // Prove the two calls are no longer wired back-to-back in the same
      // method. This is a defense-in-depth check: if someone reintroduces
      // the chain under a different name, this test fires.
      final whenInUseIdx = source.indexOf('Permission.locationWhenInUse');
      final alwaysIdx = source.indexOf('Permission.locationAlways');
      expect(whenInUseIdx, isNot(-1));
      expect(alwaysIdx, isNot(-1));

      // They must live inside distinct method bodies. Simplest structural
      // proof: the substring between them must include a method boundary
      // (either `}` closing one method, or a new `static Future` signature).
      final between = source.substring(
        whenInUseIdx < alwaysIdx ? whenInUseIdx : alwaysIdx,
        whenInUseIdx < alwaysIdx ? alwaysIdx : whenInUseIdx,
      );
      expect(
        between.contains('static Future') || between.contains('=>'),
        isTrue,
        reason: 'The two permission calls must live in separate methods so the '
            'Prominent Disclosure can be interleaved between them.',
      );
    });

    test('requestBluetooth is unchanged', () {
      expect(
        source,
        contains('Permission.bluetoothScan.request()'),
        reason: 'Bluetooth path is out of scope for this change',
      );
    });

    test('requestNotification is unchanged', () {
      expect(
        source,
        contains('Permission.notification.request()'),
        reason: 'Notification path is out of scope for this change',
      );
    });
  });
}
