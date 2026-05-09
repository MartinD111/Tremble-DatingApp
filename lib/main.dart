import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/app.dart';
// This import is intentionally kept even though initializeBackgroundService()
// is temporarily commented out below. Removing it would exclude the file from
// the kernel snapshot, causing Dart_LookupLibrary to fail at runtime when
// Android's foreground-service restart mechanism tries to invoke the
// @pragma('vm:entry-point') onStart function by library name.
// ignore: unused_import
import 'src/core/background_service.dart';
import 'src/core/firebase_options_dev.dart';
import 'src/core/firebase_options_prod.dart';
import 'src/core/theme_provider.dart';
import 'src/core/notification_service.dart';
import 'src/core/translations.dart';

import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure system navigation bar is transparent and consistent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Determine environment flavor, defaulting to 'dev'.
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  // Select the appropriate FirebaseOptions.
  final firebaseOptions = flavor == 'prod'
      ? ProdFirebaseOptions.currentPlatform
      : DevFirebaseOptions.currentPlatform;

  // Initialize Firebase
  await Firebase.initializeApp(
    options: firebaseOptions,
  );

  // AppCheck — prod only. Dev uses debug provider so Firebase SDK doesn't
  // inject an empty token and cause INTERNAL errors on every CF call.
  // SEC-001: full enforcement (Play Integrity / Device Check) pending paid developer accounts.
  await FirebaseAppCheck.instance.activate(
    providerAndroid: flavor == 'prod'
        ? AndroidPlayIntegrityProvider()
        : AndroidDebugProvider(),
    providerApple:
        flavor == 'prod' ? AppleDeviceCheckProvider() : AppleDebugProvider(),
  );

  if (flavor != 'prod') {
    const debugToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN_IOS');
    if (debugToken.isNotEmpty) {
      await FirebaseAppCheck.instance.activate(
        providerApple: AppleDebugProvider(),
      );
    }
  }

  // Pass all uncaught Flutter errors to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Register FCM background handler BEFORE runApp().
  // Must be called here — Firebase requires this to be registered before
  // the app is fully running, in a top-level context.
  NotificationService.registerBackgroundHandler();

  // Initialize background service for Radar scanning.
  await initializeBackgroundService();

  // Pre-load theme before first frame to prevent Dark Mode flash on navigation
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('themeMode');
  final initialTheme = isDark == true ? ThemeMode.dark : ThemeMode.light;
  final initialLang = prefs.getString('appLanguage');

  runApp(
    ProviderScope(
      overrides: [
        // Seed the ThemeModeNotifier with the already-loaded value —
        // avoids the async gap that caused the Light→Dark flash.
        themeModeProvider.overrideWith(
          (ref) => ThemeModeNotifier.withInitial(initialTheme),
        ),
        // Seed language provider to avoid 'sl' flash on startup
        appLanguageProvider.overrideWith(
          () => AppLanguageNotifier(initialLang),
        ),
      ],
      child: const TrembleApp(),
    ),
  );
}
