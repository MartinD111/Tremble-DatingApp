import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_service.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'tremble_background', // id
    'Tremble Background Service', // title
    description: 'This channel is used for important notifications.',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final androidPlugin =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  if (androidPlugin != null) {
    await androidPlugin.createNotificationChannel(channel);
  }

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false, // Start only when Radar is active
      isForegroundMode: true,
      notificationChannelId: 'tremble_background',
      initialNotificationTitle: 'Tremble Radar',
      initialNotificationContent: 'Looking for matches...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Initialize notifications in the background isolate
  await NotificationService.initialize();

  // Listen for stop event
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Mock Scanning Loop
  Timer.periodic(const Duration(seconds: 15), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        // Update notification if needed
        // service.setForegroundNotificationInfo(...)
      }
    }

    // SIMULATION: 20% chance to find a match every 15 seconds
    if (DateTime.now().second % 5 == 0) {
      // Trigger Notification
      await NotificationService.showMatchNotification("Ana", 24);
    }

    // print('FLUTTER BACKGROUND SERVICE: Scanning...');
  });
}
