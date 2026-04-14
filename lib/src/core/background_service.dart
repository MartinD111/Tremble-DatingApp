import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options_dev.dart';
import 'firebase_options_prod.dart';

// BleService intentionally NOT imported here.
// flutter_blue_plus requires an Android Activity and must only be used
// from the main isolate. The background isolate spawned by
// flutter_background_service has no Activity, which causes:
//   NullPointerException: ActivityPluginBinding.getActivity() on null
// BleService is started/stopped from home_screen.dart in the main isolate.
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
  // DartPluginRegistrant registers non-UI plugins (Firebase, GeoService, etc.)
  // in this background isolate.
  DartPluginRegistrant.ensureInitialized();

  // Re-initialize Firebase in the background isolate
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  final firebaseOptions = flavor == 'prod'
      ? ProdFirebaseOptions.currentPlatform
      : DevFirebaseOptions.currentPlatform;
  await Firebase.initializeApp(options: firebaseOptions);

  // Initialize notifications for background isolate
  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  await notificationsPlugin.initialize(
    const InitializationSettings(android: androidSettings, iOS: iosSettings),
  );

  final geoService = GeoService();
  final battery = Battery();
  final prefs = await SharedPreferences.getInstance();

  // Update foreground notification IMMEDIATELY to prevent double-initialization sync issues on Android
  if (service is AndroidServiceInstance) {
    if (await service.isForegroundService()) {
      final level = await battery.batteryLevel;
      service.setForegroundNotificationInfo(
        title: 'Tremble Radar',
        content: geoService.isLowPowerMode
            ? 'Power-saving mode — Geo matching active ($level%)'
            : 'Scanning for nearby matches... ($level%)',
      );
    }
  }

  // GDPR consent gate
  final hasConsent = prefs.getBool('gdpr_ble_location_consent') ?? false;
  if (hasConsent) {
    await geoService.start();
  }

  // Listen for radar mode commands from UI.
  service.on('stopService').listen((_) async {
    geoService.stop();
    service.stopSelf();
  });

  service.on('pauseRadar').listen((_) async {
    geoService.stop();
  });

  service.on('resumeRadar').listen((_) async {
    final consentAtResume = prefs.getBool('gdpr_ble_location_consent') ?? false;
    if (consentAtResume) {
      await geoService.start();
    }
  });

  // Update the persistent notification and emit radarState to UI every 60s
  Timer.periodic(const Duration(seconds: 60), (_) async {
    final isLowPower = geoService.isLowPowerMode;
    final level = await battery.batteryLevel;

    // Check for "Idle" status (no BLE proximity seen recently)
    final int lastProximity = prefs.getInt('last_ble_encounter_time') ??
        DateTime.now().millisecondsSinceEpoch;
    final timeSinceEncounter = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(lastProximity));

    if (timeSinceEncounter.inHours >= 6) {
      final hour = DateTime.now().hour;
      if (hour >= 8 && hour < 22) {
        const messages = [
          'Mogoče se kaj dogaja v bližini.',
          'Radar je aktiven. Pojdi vživo.',
        ];
        final body = (messages.toList()..shuffle()).first;
        
        await notificationsPlugin.show(
          1,
          'Tremble',
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'tremble_proximity',
              'Tremble — V bližini',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
          ),
          payload: 'idle',
        );
        await prefs.setInt(
            'last_ble_encounter_time', DateTime.now().millisecondsSinceEpoch);
      }
    }

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

    // Emit radar state to UI
    service.invoke('radarState', {
      'mode': isLowPower ? 'degraded' : 'full',
      'batteryLevel': level,
    });
  });
}
