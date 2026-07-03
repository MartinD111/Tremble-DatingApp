import 'dart:io';
import 'dart:isolate';
import 'dart:ui' show PlatformDispatcher;

import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/app.dart';
import 'src/core/background_service.dart';
import 'src/core/crash_filter.dart';
import 'src/core/firebase_options_dev.dart';
import 'src/core/firebase_options_prod.dart';
import 'src/core/theme_provider.dart';
import 'src/core/notification_service.dart';
import 'src/core/translations.dart';

import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

// await GoogleFonts.pendingFonts([
//   GoogleFonts.playfairDisplay(),
//   GoogleFonts.lora(),
//   GoogleFonts.instrumentSans(),
// ]);

  if (Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  final firebaseOptions = flavor == 'prod'
      ? ProdFirebaseOptions.currentPlatform
      : DevFirebaseOptions.currentPlatform;

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: firebaseOptions,
    );
  }

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  await FirebaseAppCheck.instance.activate(
    providerAndroid: flavor == 'prod'
        ? AndroidPlayIntegrityProvider()
        : AndroidDebugProvider(),
    // Dev: pin the registered Firebase console debug token so App Check
    // bypass works consistently. AppleDebugProvider() without debugToken
    // generates a random token each run — it never matches the console entry.
    // This token is dev-only and revocable; safe to commit.
    // Prod: App Attest provides hardware-backed attestation (iOS 14+).
    providerApple: kDebugMode
        ? AppleDebugProvider(
            debugToken: '26697195-D797-4FFE-ADEA-9631258A1C88',
          )
        : AppleAppAttestProvider(),
  );

  FlutterError.onError = (details) {
    if (CrashFilter.shouldSuppressFlutterError(details)) {
      FlutterError.presentError(details);
      return;
    }
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    Sentry.captureException(
      details.exception,
      stackTrace: details.stack,
    );
  };

  // Catch unhandled async errors that escape all zones — e.g.
  // StateError: "Cannot use ref after the widget was disposed"
  // from background callbacks. FlutterError.onError misses these.
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    Sentry.captureException(error, stackTrace: stack);
    return true;
  };

  // Low-level isolate error listener — catches errors that bypass
  // PlatformDispatcher (e.g. spawned isolate crashes).
  Isolate.current.addErrorListener(RawReceivePort((dynamic pair) async {
    final List<dynamic> errorAndStack = pair as List<dynamic>;
    final stack = errorAndStack.length > 1 && errorAndStack[1] != null
        ? StackTrace.fromString(errorAndStack[1].toString())
        : StackTrace.current;
    await Sentry.captureException(
      errorAndStack[0],
      stackTrace: stack,
    );
    await FirebaseCrashlytics.instance.recordError(
      errorAndStack[0],
      stack,
      fatal: true,
    );
  }).sendPort);

  NotificationService.registerBackgroundHandler();

  await initializeBackgroundService();

  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('themeMode');
  final initialTheme = isDark == true ? ThemeMode.dark : ThemeMode.light;
  final initialLang = prefs.getString('appLanguage');

  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.environment = flavor;
      options.tracesSampleRate = flavor == 'prod' ? 0.1 : 0.0;
      options.attachStacktrace = true;
    },
    appRunner: () => runApp(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith(
            (ref) => ThemeModeNotifier.withInitial(initialTheme),
          ),
          appLanguageProvider.overrideWith(
            () => AppLanguageNotifier(initialLang),
          ),
        ],
        child: const TrembleApp(),
      ),
    ),
  );
}
