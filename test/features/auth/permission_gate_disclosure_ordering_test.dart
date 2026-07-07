// Source-text contract for the Play Prominent Disclosure ordering inside
// PermissionGateScreen._onAccept.
//
// If a future refactor drops the disclosure push, or reorders it below the
// background request, this test fires. The whole point of the disclosure
// screen is that it appears BEFORE ACCESS_BACKGROUND_LOCATION — a subtle
// reordering here is exactly the kind of change that would silently break
// Play compliance without any runtime error.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const gatePath =
      'lib/src/features/auth/presentation/permission_gate_screen.dart';

  late String source;

  setUpAll(() {
    source = File(gatePath).readAsStringSync();
  });

  group('PermissionGateScreen — Prominent Disclosure ordering', () {
    test('imports the ProminentDisclosureScreen', () {
      expect(
        source,
        contains("import 'prominent_disclosure_screen.dart';"),
        reason: 'The gate screen must depend on the disclosure widget so the '
            'flow can push it between foreground grant and background '
            'request.',
      );
    });

    test('never invokes the removed compound requestLocation()', () {
      final compound = RegExp(r'requestLocation\s*\(\s*\)');
      expect(
        compound.hasMatch(source),
        isFalse,
        reason: 'The compound method was removed on purpose. Its return would '
            'skip the disclosure by rechaining foreground + background '
            'inside ConsentService.',
      );
    });

    test('foreground request runs before the disclosure push', () {
      final foreground = source.indexOf('requestLocationWhenInUse');
      final push = source.indexOf('ProminentDisclosureScreen');
      expect(foreground, isNot(-1));
      expect(push, isNot(-1));
      expect(
        foreground < push,
        isTrue,
        reason: 'Foreground grant is a prerequisite for showing the background '
            'disclosure — the disclosure exists to explain the SECOND-stage '
            'permission that only makes sense after foreground is granted.',
      );
    });

    test('disclosure push runs before the background request', () {
      final push = source.indexOf('ProminentDisclosureScreen');
      final background = source.indexOf('requestLocationAlways');
      expect(push, isNot(-1));
      expect(background, isNot(-1));
      expect(
        push < background,
        isTrue,
        reason: 'Play policy: the disclosure screen MUST appear before the OS '
            'background-location prompt. Reversing this order defeats the '
            'entire point of the screen.',
      );
    });

    test('background request is gated on the disclosure return value', () {
      // The disclosure returns Future<bool?>; if the user tapped "Not now"
      // we must skip the background request. Structurally, the background
      // call must live inside an `if (allowBackground == true)` block.
      final gatePattern = RegExp(r'if\s*\(\s*allowBackground\s*==\s*true\s*\)');
      expect(
        gatePattern.hasMatch(source),
        isTrue,
        reason: 'The background request must be conditional on the disclosure '
            'result. Without this guard, the "Not now" path would still '
            'fire the OS prompt — the user-visible bug is the whole reason '
            'the disclosure returns a bool.',
      );
    });

    test('grantConsent runs regardless of the background choice', () {
      // The "Not now" path must not block app usage. Consent for foreground
      // BLE + Location is still granted so the router lets the user in.
      //
      // There are two grantConsent() call sites in this file:
      // _recheckLocationOnResume (top of file) and _onAccept (below). We
      // care about the _onAccept one, which — since _onAccept lives below
      // _recheckLocationOnResume — is the LAST occurrence in the source.
      final gateIdx = source.indexOf('if (allowBackground');
      final grantIdxInOnAccept = source.lastIndexOf('grantConsent()');
      expect(gateIdx, isNot(-1),
          reason: 'disclosure gate must exist in _onAccept');
      expect(grantIdxInOnAccept, isNot(-1),
          reason: 'grantConsent() must be called on the accept path');
      expect(
        grantIdxInOnAccept > gateIdx,
        isTrue,
        reason: 'grantConsent should follow the disclosure branch so the "Not '
            'now" path still lands here and completes onboarding.',
      );
    });
  });
}
