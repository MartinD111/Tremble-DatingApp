import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'background_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Background Message Handler — MUST be a top-level function.
//
// Message receipt is not user intent. This handler only refreshes proximity for
// the two silent proximity wake types; notification actions are dispatched in
// the foreground isolate from an explicit OS action identifier.
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await processBackgroundNotificationData(
    message.data,
    refreshProximity: () async {
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      if (myUid != null) {
        try {
          await FirebaseFirestore.instance
              .collection('proximity')
              .doc(myUid)
              .update({'updatedAt': FieldValue.serverTimestamp()});
          if (kDebugMode) {
            debugPrint('[NOTIFY] Proximity updatedAt refreshed for $myUid');
          }
        } catch (error) {
          if (kDebugMode) {
            debugPrint(
              '[NOTIFY] Proximity updatedAt refresh failed: $error',
            );
          }
        }
      }
    },
  );
}

@visibleForTesting
Future<void> processBackgroundNotificationData(
  Map<String, dynamic> data, {
  required Future<void> Function() refreshProximity,
}) async {
  final type = data['type'];
  if (type == 'CROSSING_PATHS' || type == 'SECOND_ENCOUNTER') {
    await refreshProximity();
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

enum NotificationActionDispatchStatus {
  ignored,
  sent,
  alreadyProcessed,
  inFlight,
  failed,
}

class NotificationActionDispatchResult {
  const NotificationActionDispatchResult(this.status, {this.actionKey});

  final NotificationActionDispatchStatus status;
  final String? actionKey;

  bool get canAcknowledgeNativeAction =>
      status == NotificationActionDispatchStatus.sent ||
      status == NotificationActionDispatchStatus.alreadyProcessed;
}

/// Converts an OS-provided action identifier into one callable wave operation.
/// Notification payload metadata is deliberately never interpreted as intent.
class NotificationActionDispatcher {
  NotificationActionDispatcher({
    required SharedPreferences preferences,
    required Future<void> Function(String targetUid) sendWave,
    this.maxProcessedActions = 100,
  })  : _preferences = preferences,
        _sendWave = sendWave,
        _processedKeys = LinkedHashSet<String>.of(
          preferences.getStringList(processedKeysKey) ?? const <String>[],
        );

  static const String processedKeysKey =
      'notification.processed_explicit_action_keys';

  final SharedPreferences _preferences;
  final Future<void> Function(String targetUid) _sendWave;
  final int maxProcessedActions;
  final LinkedHashSet<String> _processedKeys;
  final Set<String> _inFlightKeys = <String>{};

  Future<NotificationActionDispatchResult> dispatch({
    required String? actionIdentifier,
    required Map<String, dynamic> data,
  }) async {
    final action = _parseValidAction(actionIdentifier, data);
    if (action == null) {
      return const NotificationActionDispatchResult(
        NotificationActionDispatchStatus.ignored,
      );
    }

    if (_processedKeys.contains(action.key)) {
      return NotificationActionDispatchResult(
        NotificationActionDispatchStatus.alreadyProcessed,
        actionKey: action.key,
      );
    }
    if (!_inFlightKeys.add(action.key)) {
      return NotificationActionDispatchResult(
        NotificationActionDispatchStatus.inFlight,
        actionKey: action.key,
      );
    }

    try {
      await _sendWave(action.targetUid);
      _processedKeys
        ..remove(action.key)
        ..add(action.key);
      while (_processedKeys.length > maxProcessedActions) {
        _processedKeys.remove(_processedKeys.first);
      }
      await _preferences.setStringList(
        processedKeysKey,
        _processedKeys.toList(growable: false),
      );
      return NotificationActionDispatchResult(
        NotificationActionDispatchStatus.sent,
        actionKey: action.key,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[NOTIFY] Explicit notification action failed: $error');
      }
      return NotificationActionDispatchResult(
        NotificationActionDispatchStatus.failed,
        actionKey: action.key,
      );
    } finally {
      _inFlightKeys.remove(action.key);
    }
  }

  _ExplicitNotificationAction? _parseValidAction(
    String? actionIdentifier,
    Map<String, dynamic> data,
  ) {
    final type = _nonEmptyString(data['type']);
    final messageId = _nonEmptyString(data['gcm.message_id']) ??
        _nonEmptyString(data['waveId']);
    if (messageId == null) return null;

    String? targetUid;
    if (actionIdentifier == 'WAVE_BACK_ACTION' &&
        type == TrembleNotificationType.incomingWave) {
      targetUid = _nonEmptyString(data['senderId']);
    } else if (actionIdentifier == 'NEARBY_WAVE_ACTION' &&
        type == TrembleNotificationType.crossingPaths) {
      targetUid =
          _nonEmptyString(data['senderId']) ?? _nonEmptyString(data['fromUid']);
    }
    if (targetUid == null) return null;

    final key = '$actionIdentifier|$messageId|$targetUid';
    return _ExplicitNotificationAction(key: key, targetUid: targetUid);
  }

  String? _nonEmptyString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _ExplicitNotificationAction {
  const _ExplicitNotificationAction({
    required this.key,
    required this.targetUid,
  });

  final String key;
  final String targetUid;
}

class NativeNotificationActionBridge {
  NativeNotificationActionBridge({
    MethodChannel channel = const MethodChannel(
      'app.tremble/notification_actions',
    ),
  }) : _channel = channel;

  final MethodChannel _channel;

  Future<void> start(NotificationActionDispatcher dispatcher) async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'pendingActionsChanged') {
        await drainPendingActions(dispatcher);
      }
    });
    await drainPendingActions(dispatcher);
  }

  Future<void> drainPendingActions(
    NotificationActionDispatcher dispatcher,
  ) async {
    final pending = await _channel.invokeMethod<List<dynamic>>(
          'getPendingActions',
        ) ??
        const <dynamic>[];
    for (final rawAction in pending) {
      if (rawAction is! Map) continue;
      final action = Map<String, dynamic>.from(rawAction);
      final result = await dispatcher.dispatch(
        actionIdentifier: action['actionIdentifier'] as String?,
        data: action,
      );
      await acknowledgeHandledAction(
        result,
        nativeActionId: action['id'] as String?,
      );
    }
  }

  Future<void> acknowledgeHandledAction(
    NotificationActionDispatchResult result, {
    String? nativeActionId,
  }) async {
    if (!result.canAcknowledgeNativeAction) return;
    final id = nativeActionId ?? result.actionKey;
    if (id == null || id.isEmpty) return;
    await _channel.invokeMethod<void>(
      'acknowledgeAction',
      <String, dynamic>{'id': id},
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NotificationService
// ─────────────────────────────────────────────────────────────────────────────

class NotificationService {
  static final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  /// Subscription to FCM token rotations. Rotations happen on OS update, app
  /// reinstall, or notification-cache clear; a stale token silently breaks
  /// push delivery, so the new token must be persisted to Firestore.
  static StreamSubscription<String>? _tokenRefreshSubscription;

  /// Foreground FCM message subscription.
  static StreamSubscription<RemoteMessage>? _onMessageSub;

  /// App-opened-from-background notification subscription.
  static StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;

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

    /// Invokes the authenticated sendWave callable for a verified OS action.
    required Future<void> Function(String targetUid) onExplicitWaveAction,

    /// Called when an INCOMING_WAVE or CROSSING_PATHS message arrives while the
    /// app is in the foreground. Use this to show [WavePillService.show].
    ///
    /// Fields guaranteed non-empty when this fires:
    ///   name, imageUrl, targetUid — age may be 0 if Cloud Function omits it.
    void Function({
      required String name,
      required int age,
      required String imageUrl,
      required String targetUid,
      required bool isIncomingWave,
    })? onForegroundWave,

    /// Called when a MUTUAL_WAVE message arrives in the foreground — meaning
    /// someone accepted a wave the current user sent. Triggers confetti + haptic.
    VoidCallback? onForegroundMatch,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final actionDispatcher = NotificationActionDispatcher(
      preferences: preferences,
      sendWave: onExplicitWaveAction,
    );
    final nativeActionBridge = NativeNotificationActionBridge();

    Future<void> dispatchExplicitAction(
      String? actionIdentifier,
      Map<String, dynamic> data,
    ) async {
      final result = await actionDispatcher.dispatch(
        actionIdentifier: actionIdentifier,
        data: data,
      );
      if (Platform.isIOS) {
        try {
          await nativeActionBridge.acknowledgeHandledAction(result);
        } on MissingPluginException {
          // Older app binary without the native bridge; leave retry state intact.
        }
      }
    }

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
      DarwinNotificationCategory(
        'RUN_CLUB_ACTIVATION_CATEGORY',
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain('RUN_CLUB_ACTIVATE', 'Vklopi',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground
              }),
          DarwinNotificationAction.plain('RUN_CLUB_IGNORE', 'Prezri'),
        ],
      ),
      DarwinNotificationCategory(
        'RUN_CLUB_DEACTIVATION_CATEGORY',
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain('RUN_CLUB_DEACTIVATE', 'Izklopi'),
          DarwinNotificationAction.plain(
              'RUN_CLUB_KEEP_ACTIVE', 'Pusti aktivno'),
        ],
      ),
    ];

    final iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      notificationCategories: categories,
    );

    await notifications.initialize(
      InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveBackgroundNotificationResponse:
          runClubNotificationTapBackground,
      onDidReceiveNotificationResponse: (details) async {
        if (details.actionId != null &&
            details.actionId!.startsWith('RUN_CLUB_')) {
          runClubNotificationTapBackground(details);
          return;
        }

        if (details.payload != null) {
          try {
            final data =
                Map<String, dynamic>.from(json.decode(details.payload!));
            // If an action button was pressed, add the actionId to the data map
            if (details.actionId != null) {
              data['actionId'] = details.actionId;
            }
            await dispatchExplicitAction(details.actionId, data);
            onNotificationTap?.call(data);
          } catch (e) {
            if (kDebugMode)
              debugPrint('[NOTIFY] Error decoding notification payload: $e');
            onNotificationTap?.call({'type': details.payload});
          }
        }
      },
    );

    if (Platform.isIOS) {
      try {
        await nativeActionBridge.start(actionDispatcher);
      } on MissingPluginException {
        // Allows a rolling upgrade from app binaries without this bridge.
      }
    }

    // ── Foreground FCM messages ───────────────────────────
    // Haptic throttle: suppress duplicate vibrations within 2 seconds.
    // Protects against BLE + FCM race conditions arriving near-simultaneously.
    DateTime? _lastHapticAt;

    // Guard against re-subscription if initialize() is called twice.
    await _onMessageSub?.cancel();
    _onMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
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

      // Mutual wave (someone accepted our wave) → confetti + suppress OS banner.
      if (type == TrembleNotificationType.mutualWave &&
          onForegroundMatch != null) {
        onForegroundMatch();
        return;
      }

      // In-app pill for wave / proximity events — suppresses the OS banner.
      // Invariant: the Cloud Function now attaches a `notification` block to
      // CROSSING_PATHS (plan 20260712-fix-crossing-paths-visibility) so the OS
      // renders it when the app is background/killed. In foreground we MUST
      // early-return after showing the pill, otherwise the user sees both the
      // pill and the system banner for the same event.
      final isPillEvent = type == TrembleNotificationType.incomingWave ||
          type == TrembleNotificationType.crossingPaths;
      if (isPillEvent && onForegroundWave != null) {
        final senderUid = (message.data['senderId'] ??
            message.data['fromUid'] ??
            '') as String;
        final senderName = (message.data['senderName'] ?? '') as String;
        final senderPhoto = (message.data['senderPhotoUrl'] ?? '') as String;
        final senderAge = int.tryParse(message.data['senderAge'] ?? '') ?? 0;
        if (senderUid.isNotEmpty && senderName.isNotEmpty) {
          onForegroundWave(
            name: senderName,
            age: senderAge,
            imageUrl: senderPhoto,
            targetUid: senderUid,
            isIncomingWave: type == TrembleNotificationType.incomingWave,
          );
          return; // pill replaces the OS banner for these event types
        }
      }

      if (notification != null) {
        _showForegroundNotification(message);
      }
    });

    // ── App opened from background notification ───────────
    await _onMessageOpenedAppSub?.cancel();
    _onMessageOpenedAppSub =
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (onNotificationTap != null) {
        onNotificationTap(message.data);
      }
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null && onNotificationTap != null) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      onNotificationTap(initialMessage.data);
    }

    // ── FCM token refresh ─────────────────────────────────
    // Persist rotated tokens so pushes keep landing on the active install.
    // Guard against re-subscription if initialize() is called twice.
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription =
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'fcmToken': newToken});
        if (kDebugMode) debugPrint('[NOTIFY] FCM Token refreshed for $uid');
      } on FirebaseException catch (e) {
        if (kDebugMode)
          debugPrint('[NOTIFY] Error persisting refreshed FCM token: $e');
      }
    });
  }

  /// Cancels long-lived stream subscriptions owned by the service.
  /// Safe to call multiple times.
  static Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    await _onMessageSub?.cancel();
    _onMessageSub = null;
    await _onMessageOpenedAppSub?.cancel();
    _onMessageOpenedAppSub = null;
  }

  /// Saves the FCM token to the user's Firestore document.
  /// Must be called after the user is authenticated.
  static Future<void> saveToken(String userId) async {
    try {
      // iOS: FCM cannot issue a token until APNs registration completes.
      // Without this await, getToken() returns null on first install.
      if (Platform.isIOS) {
        await FirebaseMessaging.instance.getAPNSToken();
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'fcmToken': token});
        if (kDebugMode) debugPrint('[NOTIFY] FCM Token saved for $userId');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[NOTIFY] Error saving FCM token: $e');
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

    final payloadData = <String, dynamic>{...message.data};
    final messageId = message.messageId;
    if (messageId != null && messageId.isNotEmpty) {
      payloadData.putIfAbsent('gcm.message_id', () => messageId);
    }

    await notifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: json.encode(payloadData),
    );
  }
}
