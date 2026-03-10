import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(initializationSettings);

    // Request FCM permission
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Listen to foreground FCM messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showMatchNotification(
          message.notification!.title ?? 'Tremble',
          message.notification!.body ?? 'Nekaj se dogaja!',
        );
      }
    });
  }

  /// Retrieves the FCM token and saves it to the user's Firestore document
  static Future<void> getAndSaveToken(String userId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'fcmToken': token});
        debugPrint('FCM Token secured: ${token.substring(0, 5)}...');
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Randomly selects a neutral idle notification message and displays it
  static Future<void> showIdleNotification() async {
    const messages = [
      "Okoli tebe je mirno, mogoče se kaj dogaja v bližini.",
      "Trenutno ni posebnosti, a morda se kaj zanimivega dogaja drugje.",
      "Situacija je mirna, vedno pa lahko odkriješ kaj novega."
    ];
    final String body = (messages.toList()..shuffle()).first;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'tremble_idle',
      'Tremble Background Idle',
      channelDescription: 'Notifications for background radar inactivity',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notifications.show(
      1,
      'Tremble',
      body,
      platformChannelSpecifics,
      payload: 'idle',
    );
  }

  /// Mock function to test the future Hotspot functionality
  static Future<void> showMockHotspotNotification() async {
    const AndroidNotificationDetails androidSpecifics =
        AndroidNotificationDetails(
      'tremble_hotspots',
      'Tremble Hotspots',
      channelDescription: 'Notifications for high activity areas',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformSpecifics =
        NotificationDetails(android: androidSpecifics);

    await _notifications.show(
      2,
      '🔥 Vroča točka blizu tebe!',
      'Opažamo povišano aktivnost v tvoji bližini. Odpri Radar!',
      platformSpecifics,
      payload: 'hotspot',
    );
  }

  static Future<void> showMatchNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'tremble_matches', // channel id
      'Tremble Matches', // channel name
      channelDescription: 'Notifications for new matches found nearby',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notifications.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'match_found',
    );
  }
}
