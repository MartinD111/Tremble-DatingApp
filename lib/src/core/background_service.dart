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
import 'native_motion_service.dart';

/// Configure and register the background service.
/// Call once in main() before runApp().
Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  // NOTE: Channel `tremble_radar_v2` is created synchronously in
  // MainApplication.onCreate (RadarNotificationBuilder.ensureChannel).
  // We deliberately do NOT create it here — channel importance is immutable
  // after first creation and Kotlin owns the canonical definition.
  //
  // The plugin's native onStartCommand calls startForeground(888, basic)
  // BEFORE the Dart isolate boots. Pointing it at the same channel + ID our
  // native RadarNotificationBuilder uses means the rich notification posted
  // later via the RadarStateBridge MethodChannel atomically replaces the
  // placeholder on the same ID — no flicker, no second notification, and the
  // 5-second ForegroundServiceDidNotStartInTime deadline is satisfied
  // entirely from native code.

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false, // Started explicitly when user enables Radar
      isForegroundMode: true,
      notificationChannelId: 'tremble_radar_v2',
      initialNotificationTitle: 'Tremble Radar',
      initialNotificationContent: 'Starting…',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  // ── Ghost-state shutdown ─────────────────────────────────────────────
  // After a crash the plugin can leave its internal "running" flag set
  // and SharedPrefs `radar_active=true` persisted, causing a phantom
  // notification to appear at next cold start before the user touches
  // anything. We are the source of truth for whether radar should be
  // running at process boot: if no user gesture has authorised it, force
  // the plugin off and clear the persisted flag.
  //
  // We only run this on the FIRST boot of each process — once the user
  // toggles the radar on, this function is not called again until the
  // process dies and respawns.
  final prefs = await SharedPreferences.getInstance();
  final wasActive = prefs.getBool('radar_active') ?? false;
  final isRunning = await service.isRunning();
  if (!wasActive && isRunning) {
    // Plugin is running but our state-of-truth says it shouldn't be.
    // Tell its onStart handler to gracefully stop (cancels notif).
    service.invoke('stopService', null);
  }
  // Always reset persisted active flag at cold start. The user must
  // re-enable radar after a process death — matches the ghost-free
  // expectation and avoids any auto-start leakage from prior sessions.
  if (wasActive) {
    await prefs.setBool('radar_active', false);
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void runClubNotificationTapBackground(NotificationResponse response) async {
  final action = response.actionId;
  if (action == null) return;
  final prefs = await SharedPreferences.getInstance();

  if (action == 'RUN_CLUB_ACTIVATE') {
    await prefs.setBool('run_club_active', true);
    FlutterBackgroundService()
        .invoke('onRunClubStateChanged', {'active': true});
  } else if (action == 'RUN_CLUB_DEACTIVATE') {
    await prefs.setBool('run_club_active', false);
    FlutterBackgroundService()
        .invoke('onRunClubStateChanged', {'active': false});
  }
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

  final List<DarwinNotificationCategory> categories = [
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
        DarwinNotificationAction.plain('RUN_CLUB_KEEP_ACTIVE', 'Pusti aktivno'),
      ],
    ),
  ];

  final iosSettings = DarwinInitializationSettings(
    notificationCategories: categories,
  );

  await notificationsPlugin.initialize(
    InitializationSettings(android: androidSettings, iOS: iosSettings),
    onDidReceiveBackgroundNotificationResponse:
        runClubNotificationTapBackground,
    onDidReceiveNotificationResponse: (response) {
      runClubNotificationTapBackground(response);
    },
  );

  final geoService = GeoService();
  final battery = Battery();
  final prefs = await SharedPreferences.getInstance();

  // The rich DecoratedCustomViewStyle notification is posted natively by
  // RadarStateBridge → RadarNotificationReceiver on the same ID (888) the
  // plugin used for the placeholder startForeground call. We do NOT call
  // setForegroundNotificationInfo here — it would overwrite the rich
  // notification with a plain-text one on the same ID.

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

  // ── Run Club: Smart Activation & Deactivation ──────────────────────────
  DateTime? lastRunningStart;
  DateTime? lastStationaryStart;
  bool runClubActive = prefs.getBool('run_club_active') ?? false;
  bool askedToActivate = false;
  bool askedToDeactivate = false;

  importNativeMotion() {
    NativeMotionService.instance.motionStateChanges.listen((state) async {
      // Reload active state from prefs in case it was changed via notification action
      runClubActive = prefs.getBool('run_club_active') ?? false;
      final now = DateTime.now();

      if (state == MotionState.running) {
        lastStationaryStart = null;
        askedToDeactivate = false;
        lastRunningStart ??= now;

        if (!runClubActive &&
            !askedToActivate &&
            now.difference(lastRunningStart!).inMinutes >= 5) {
          askedToActivate = true;

          await notificationsPlugin.show(
            2,
            '🔔 Zaznali smo tek',
            'Želiš vklopiti Run Club?',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'tremble_run_club',
                'Tremble Run Club',
                importance: Importance.high,
                priority: Priority.high,
                actions: [
                  AndroidNotificationAction('RUN_CLUB_ACTIVATE', 'Vklopi',
                      showsUserInterface: false),
                  AndroidNotificationAction('RUN_CLUB_IGNORE', 'Prezri',
                      showsUserInterface: false),
                ],
              ),
              iOS: DarwinNotificationDetails(
                  categoryIdentifier: 'RUN_CLUB_ACTIVATION_CATEGORY'),
            ),
            payload: 'run_club_prompt',
          );
        }
      } else if (state == MotionState.stationary) {
        // We only reset the running timer if stationary (not walking)
        lastRunningStart = null;
        askedToActivate = false;
        lastStationaryStart ??= now;

        final stationaryMinutes =
            now.difference(lastStationaryStart!).inMinutes;

        if (runClubActive) {
          if (stationaryMinutes >= 20) {
            runClubActive = false;
            await prefs.setBool('run_club_active', false);
            service.invoke('onRunClubStateChanged', {'active': false});

            await notificationsPlugin.show(
              3,
              '💤 Run Club izklopljen',
              'Upamo, da je bil dober tek.',
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'tremble_run_club',
                  'Tremble Run Club',
                  importance: Importance.defaultImportance,
                  priority: Priority.defaultPriority,
                ),
                iOS: DarwinNotificationDetails(),
              ),
              payload: 'run_club_deactivated',
            );
          } else if (stationaryMinutes >= 15 && !askedToDeactivate) {
            askedToDeactivate = true;

            await notificationsPlugin.show(
              3,
              '⏸️ Si končal s tekom?',
              'Run Club je še vedno aktiven.',
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'tremble_run_club',
                  'Tremble Run Club',
                  importance: Importance.defaultImportance,
                  priority: Priority.defaultPriority,
                  actions: [
                    AndroidNotificationAction('RUN_CLUB_DEACTIVATE', 'Izklopi',
                        showsUserInterface: false),
                    AndroidNotificationAction(
                        'RUN_CLUB_KEEP_ACTIVE', 'Pusti aktivno',
                        showsUserInterface: false),
                  ],
                ),
                iOS: DarwinNotificationDetails(
                    categoryIdentifier: 'RUN_CLUB_DEACTIVATION_CATEGORY'),
              ),
              payload: 'run_club_prompt',
            );
          }
        }
      } else if (state == MotionState.walking) {
        // Brief walking doesn't reset either timer
      }
    });
    NativeMotionService.instance.startMonitoring();
  }

  importNativeMotion();

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

    // The rich foreground notification (DecoratedCustomViewStyle, ID 888,
    // channel `tremble_radar_v2`) is owned and refreshed natively by
    // RadarNotificationReceiver. We deliberately do NOT call
    // setForegroundNotificationInfo from here — it would post a plain-text
    // notification on the same ID and overwrite the rich one. Battery /
    // power-mode is surfaced to the UI via the radarState invoke below.

    // Emit radar state to UI
    service.invoke('radarState', {
      'mode': isLowPower ? 'degraded' : 'full',
      'batteryLevel': level,
    });
  });
}
