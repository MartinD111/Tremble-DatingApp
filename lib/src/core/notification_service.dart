import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Background Message Handler — MUST be a top-level function.
//
// Handles silent background actions when the app is terminated or in background.
// Called when user taps "Pomahaj nazaj" action button in the OS notification.
//
// Important: Riverpod is NOT available here. We write directly to Firestore.
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final clickAction = message.data['click_action'];
  final type = message.data['type'];

  // Handle "Pomahaj nazaj" or "Wave back" silent background actions
  // clickAction covers iOS category actions, type covers generic FCM data
  if (clickAction == 'WAVE_BACK_ACTION' ||
      clickAction == 'NEARBY_WAVE_ACTION' ||
      type == 'INCOMING_WAVE') {
    final targetUid = message.data['senderId'] ?? message.data['fromUid'];
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    if (targetUid != null && targetUid.isNotEmpty && myUid != null) {
      try {
        // Direct Firestore write — bypasses Riverpod (not available in isolate)
        await FirebaseFirestore.instance.collection('waves').add({
          'fromUid': myUid,
          'toUid': targetUid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[NOTIFY] Background wave sent: $myUid → $targetUid');
      } catch (e) {
        debugPrint('[NOTIFY] Background wave failed: $e');
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification Channels
// ─────────────────────────────────────────────────────────────────────────────

/// Channel IDs — used as stable identifiers for Android notification channels.
abstract class TrembleNotificationChannels {
  static const String wave = 'tremble_wave';
  static const String match = 'tremble_match';
  static const String proximity = 'tremble_proximity';
}

/// Payload types — must match the `type` field sent by Cloud Functions.
abstract class TrembleNotificationType {
  static const String crossingPaths = 'CROSSING_PATHS';
  static const String incomingWave = 'INCOMING_WAVE';
  static const String mutualWave = 'MUTUAL_WAVE';
}

// ─────────────────────────────────────────────────────────────────────────────
// NotificationService
// ─────────────────────────────────────────────────────────────────────────────

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Call ONCE before runApp() in main.dart.
  /// Registers the background handler so it's ready before any notification arrives.
  static void registerBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  /// Call after runApp() once the app is initialized (e.g., in AppShell initState).
  static Future<void> initialize({
    /// Called when user taps a notification and the app opens.
    /// Receives the notification payload data Map.
    void Function(Map<String, dynamic> data)? onNotificationTap,
  }) async {
    // ── Local Notifications init ──────────────────────────
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // ── iOS: Register NEARBY_CATEGORY and WAVE_CATEGORY with action buttons ───
    // This must be done before any notification of this category arrives.
    final List<DarwinNotificationCategory> categories = [
      DarwinNotificationCategory(
        'NEARBY_CATEGORY',
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(
            'NEARBY_WAVE_ACTION',
            '👋 Wave',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
            },
          ),
          DarwinNotificationAction.plain(
            'NEARBY_DISMISS_ACTION',
            'Dismiss',
          ),
        ],
        options: <DarwinNotificationCategoryOption>{
          DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
        },
      ),
      DarwinNotificationCategory(
        'WAVE_CATEGORY',
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(
            'WAVE_BACK_ACTION',
            '👋 Wave back',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
            },
          ),
        ],
      ),
    ];

    final iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      notificationCategories: categories,
    );

    await _notifications.initialize(
      InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null && onNotificationTap != null) {
          try {
            final data =
                Map<String, dynamic>.from(json.decode(details.payload!));
            // If an action button was pressed, add the actionId to the data map
            if (details.actionId != null) {
              data['actionId'] = details.actionId;
            }
            onNotificationTap(data);
          } catch (e) {
            debugPrint('[NOTIFY] Error decoding notification payload: $e');
            onNotificationTap({'type': details.payload});
          }
        }
      },
    );

    // ── Foreground FCM messages ───────────────────────────
    // Haptic throttle: suppress duplicate vibrations within 2 seconds.
    // Protects against BLE + FCM race conditions arriving near-simultaneously.
    DateTime? _lastHapticAt;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final type = message.data['type'];
      final notification = message.notification;

      // Haptic feedback on wave received — throttled to once per 2 seconds
      if (type == TrembleNotificationType.incomingWave ||
          type == TrembleNotificationType.mutualWave) {
        final now = DateTime.now();
        if (_lastHapticAt == null ||
            now.difference(_lastHapticAt!) > const Duration(seconds: 2)) {
          _lastHapticAt = now;
          HapticFeedback.heavyImpact();
        }
      }

      if (notification != null) {
        _showForegroundNotification(message);
      }
    });

    // ── App opened from background notification ───────────
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (onNotificationTap != null) {
        onNotificationTap(message.data);
      }
    });
  }

  /// Saves the FCM token to the user's Firestore document.
  /// Must be called after the user is authenticated.
  static Future<void> saveToken(String userId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'fcmToken': token});
        debugPrint('[NOTIFY] FCM Token saved for $userId');
      }
    } catch (e) {
      debugPrint('[NOTIFY] Error saving FCM token: $e');
    }
  }

  /// Handles the initial message when the app is launched from a terminated state.
  /// Returns the message data if there was one, null otherwise.
  static Future<Map<String, dynamic>?> getInitialMessageData() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    return message?.data;
  }

  // ── Internal ──────────────────────────────────────────

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final type = message.data['type'];
    final notification = message.notification!;

    // Choose the right channel based on notification type
    String channelId;
    String channelName;
    Importance importance;
    Priority priority;

    if (type == TrembleNotificationType.mutualWave) {
      channelId = TrembleNotificationChannels.match;
      channelName = 'Tremble — Mahanje nazaj';
      importance = Importance.max;
      priority = Priority.max;
    } else if (type == TrembleNotificationType.incomingWave) {
      channelId = TrembleNotificationChannels.wave;
      channelName = 'Tremble — Mahanje';
      importance = Importance.high;
      priority = Priority.high;
    } else {
      channelId = TrembleNotificationChannels.proximity;
      channelName = 'Tremble — V bližini';
      importance = Importance.defaultImportance;
      priority = Priority.defaultPriority;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: importance,
      priority: priority,
      showWhen: true,
      largeIcon: notification.android?.imageUrl != null
          ? FilePathAndroidBitmap(notification.android!.imageUrl!)
          : null,
      actions: type == 'CROSSING_PATHS'
          ? <AndroidNotificationAction>[
              const AndroidNotificationAction(
                'NEARBY_WAVE_ACTION',
                '👋 Wave',
                showsUserInterface: true,
              ),
              const AndroidNotificationAction(
                'NEARBY_DISMISS_ACTION',
                'Dismiss',
              ),
            ]
          : null,
    );

    final details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: json.encode(message.data),
    );
  }
}
