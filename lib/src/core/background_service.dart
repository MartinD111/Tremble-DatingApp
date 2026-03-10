import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'notification_service.dart';
import 'ble_service.dart';
import 'geo_service.dart';

/// Configure and register the background service.
/// Call once in main() before runApp().
Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'tremble_background',
    'Tremble Background Service',
    description: 'Tremble Radar is active and looking for nearby matches.',
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
      autoStart: false, // Started explicitly when user enables Radar
      isForegroundMode: true,
      notificationChannelId: 'tremble_background',
      initialNotificationTitle: 'Tremble Radar',
      initialNotificationContent: 'Looking for nearby matches...',
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
  WidgetsFlutterBinding.ensureInitialized();

  // Re-initialize Firebase in the background isolate
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.initialize();

  final bleService = BleService();
  final geoService = GeoService();
  final battery = Battery();

  // Start both engines
  await geoService.start();
  await bleService.start();

  // Listen for radar mode commands from UI
  service.on('stopService').listen((_) async {
    bleService.stop();
    geoService.stop();
    service.stopSelf();
  });

  service.on('pauseRadar').listen((_) async {
    bleService.stop();
    geoService.stop();
  });

  service.on('resumeRadar').listen((_) async {
    await geoService.start();
    await bleService.start();
  });

  // Update the persistent notification and emit radarMode to UI every 60s
  Timer.periodic(const Duration(seconds: 60), (_) async {
    final isLowPower = geoService.isLowPowerMode;
    final level = await battery.batteryLevel;

    // Update Android foreground notification content
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: 'Tremble Radar',
          content: isLowPower
              ? 'Power-saving mode — Geo matching active ($level%)'
              : 'Scanning for nearby matches... ($level%)',
        );
      }
    }

    // Emit radar state to UI so it can show the amber battery pill
    service.invoke('radarState', {
      'mode': isLowPower ? 'degraded' : 'full',
      'batteryLevel': level,
    });
  });
}
