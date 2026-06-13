import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_fonts/google_fonts.dart';
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

  await GoogleFonts.pendingFonts([
    GoogleFonts.playfairDisplay(),
    GoogleFonts.lora(),
    GoogleFonts.instrumentSans(),
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  final firebaseOptions = flavor == 'prod'
      ? ProdFirebaseOptions.currentPlatform
      : DevFirebaseOptions.currentPlatform;

  await Firebase.initializeApp(
    options: firebaseOptions,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  await FirebaseAppCheck.instance.activate(
    providerAndroid: flavor == 'prod'
        ? AndroidPlayIntegrityProvider()
        : AndroidDebugProvider(),
    providerApple:
        flavor == 'prod' ? AppleDeviceCheckProvider() : AppleDebugProvider(),
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
