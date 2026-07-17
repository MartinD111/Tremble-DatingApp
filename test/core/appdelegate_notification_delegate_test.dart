import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Source-level pins for the fix to the foreground-push stack overflow
/// (Sentry TREMBLE-FUNCTIONS-V/-W, the 1.0.0+23/+24 freeze).
///
/// The recursion: with Firebase's app-delegate proxy enabled (the default),
/// FIRMessagingRemoteNotificationsProxy claims UNUserNotificationCenter's
/// delegate, then FLTFirebaseMessagingPlugin wraps it and forwards
/// willPresentNotification back to it — an infinite loop that overflows the
/// stack on every foreground push.
///
/// firebase_messaging avoids this ONLY when the notification-center delegate
/// already conforms to FlutterAppLifeCycleProvider (which FlutterAppDelegate
/// does) at the moment the plugin registers. So the AppDelegate must set itself
/// as the delegate BEFORE GeneratedPluginRegistrant.register runs. The ordering
/// is the whole fix — a delegate assignment placed after registration would not
/// engage the guard. These tests can't boot Firebase, so they pin the source
/// contract, mirroring test/core/router_notification_pill_test.dart.
void main() {
  final source = File('ios/Runner/AppDelegate.swift').readAsStringSync();

  const delegateAssignment =
      'UNUserNotificationCenter.current().delegate = self';
  const pluginRegistration = 'GeneratedPluginRegistrant.register(with: self)';

  group('AppDelegate notification-center delegate ownership', () {
    test('sets the app as the UNUserNotificationCenter delegate', () {
      expect(source, contains(delegateAssignment));
    });

    test(
        'sets the delegate BEFORE plugin registration (engages the '
        'firebase_messaging anti-recursion guard)', () {
      final delegateAt = source.indexOf(delegateAssignment);
      final registerAt = source.indexOf(pluginRegistration);

      expect(delegateAt, greaterThanOrEqualTo(0),
          reason: 'delegate assignment missing — foreground push will recurse');
      expect(registerAt, greaterThanOrEqualTo(0),
          reason: 'plugin registration call missing');
      expect(delegateAt, lessThan(registerAt),
          reason: 'delegate MUST be set before GeneratedPluginRegistrant, or '
              'Firebase claims it first and the willPresent forwarding loops');
    });

    test(
        'keeps Firebase swizzling enabled (no FirebaseAppDelegateProxyEnabled '
        'opt-out in Info.plist — required for FCM token handling)', () {
      final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
      expect(infoPlist.contains('FirebaseAppDelegateProxyEnabled'), isFalse,
          reason: 'the fix keeps the proxy ON; disabling it would break FCM '
              'token handling per FlutterFire docs');
    });
  });
}
