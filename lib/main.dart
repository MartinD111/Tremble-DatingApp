import 'dart:io';
import 'dart:isolate';
import 'dart:ui' show PlatformDispatcher;

import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter/foundation.dart'
    show kDebugMode, LicenseEntry, LicenseEntryWithLineBreaks, LicenseRegistry;
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
import 'src/core/crash_report_throttle.dart';
import 'src/core/firebase_options_dev.dart';
import 'src/core/firebase_options_prod.dart';
import 'src/core/theme_provider.dart';
import 'src/core/notification_service.dart';
import 'src/core/translations.dart';

import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// OFL requires the licence text to travel with the fonts we ship, and the
/// about-box reads this registry.
Stream<LicenseEntry> _bundledFontLicenses() async* {
  for (final family in const [
    'instrumentsans',
    'playfairdisplay',
    'lora',
    'jetbrainsmono',
  ]) {
    final text = await rootBundle.loadString('assets/fonts/OFL-$family.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts', family], text);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Brand typefaces ship in assets/fonts/, so refuse to reach for the network.
  // The old runtime fetch awaited an HTTP download before runApp: a slow
  // connection stalled first launch and a bad one threw "Failed to load font
  // with url". Assets are matched by filename, so every GoogleFonts.* call site
  // keeps working — it just resolves locally now.
  //
  // This must be set before the first GoogleFonts.* call, or that call races the
  // config and can still fetch.
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(_bundledFontLicenses);

  try {
    // Now an asset read rather than a download. Kept so the first frame paints
    // in brand type instead of swapping after a fallback.
    await GoogleFonts.pendingFonts([
      GoogleFonts.playfairDisplay(),
      GoogleFonts.lora(),
      GoogleFonts.instrumentSans(),
      GoogleFonts.jetBrainsMono(),
    ]);
  } catch (e) {
    // allowRuntimeFetching = false makes a missing variant throw. Never fatal:
    // Flutter falls back to a system face, which is a cosmetic regression, not
    // a crashed launch.
    if (kDebugMode) debugPrint('Failed to preload bundled fonts: $e');
  }

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
    providerAndroid: flavor == 'dev'
        ? const AndroidDebugProvider(
            debugToken: String.fromEnvironment('APP_CHECK_DEBUG_TOKEN_ANDROID'),
          )
        : AndroidPlayIntegrityProvider(),
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

  // Recording is expensive: Crashlytics runs on the main thread and walks every
  // thread in the process, and this app has dozens. An unbounded stream of
  // reports stalls the main thread and, in 1.0.0+23, overflowed the stack from
  // inside the reporter. Every path below is therefore throttled.
  final crashThrottle = CrashReportThrottle();

  FlutterError.onError = (details) {
    if (CrashFilter.shouldSuppressFlutterError(details)) {
      // Debug only. In release this dumps to os_log on every failed tile, and
      // offline that is thousands of writes — the log pressure visible at the
      // base of the 1.0.0+23 crash stack.
      if (kDebugMode) FlutterError.presentError(details);
      return;
    }
    if (!crashThrottle.allow(DateTime.now())) return;

    // Not fatal: a FlutterError is caught by the framework and the app keeps
    // running. Reporting these as fatal filed benign tile failures as crashes
    // and forced the costlier on-demand recording path.
    FirebaseCrashlytics.instance.recordFlutterError(details);
    Sentry.captureException(
      details.exception,
      stackTrace: details.stack,
    );
  };

  // Catch unhandled async errors that escape all zones — e.g.
  // StateError: "Cannot use ref after the widget was disposed"
  // from background callbacks. FlutterError.onError misses these.
  PlatformDispatcher.instance.onError = (error, stack) {
    if (!crashThrottle.allow(DateTime.now())) return true;
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
    if (!crashThrottle.allow(DateTime.now())) return;
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
      // Drop benign vector-tile cancellation noise that escapes
      // FlutterError.onError and otherwise floods prod Sentry as errors
      // (TREMBLE-FUNCTIONS-13/14/15). See CrashFilter.
      options.beforeSend = (event, hint) =>
          CrashFilter.shouldSuppressSentryEvent(event) ? null : event;
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
