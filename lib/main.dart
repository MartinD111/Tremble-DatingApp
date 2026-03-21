import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'src/app.dart';
import 'src/core/background_service.dart';
import 'src/core/firebase_options_dev.dart';
import 'src/core/firebase_options_prod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // AppCheck — prevents unauthorized apps from hitting Firebase services
  // Switch androidProvider to AndroidProvider.debug for local emulator testing
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.deviceCheck,
  );

  // Pass all uncaught Flutter errors to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  await initializeBackgroundService();

  runApp(
    const ProviderScope(
      child: TrembleApp(),
    ),
  );
}
