# Active Implementation Plan
Plan ID: 20260710-fix-native-splash-dependency
Risk Level: LOW
Founder Approval Required: NO
Branch: fix/flutter-native-splash-dependency-type
1. OBJECTIVE — Move flutter_native_splash from dev_dependencies to dependencies in pubspec.yaml to fix Android release build failure (GeneratedPluginRegistrant.java: package net.jonhanson.flutter_native_splash does not exist). Known upstream issue: jonbhanson/flutter_native_splash#645.
2. SCOPE — pubspec.yaml, pubspec.lock only. No app code, no native manifest, no security-relevant surface touched.
3. STEPS — Confirmed via grep that lib/ contains zero calls to FlutterNativeSplash.preserve()/.remove() (runtime API unused). Moved dependency declaration from dev_dependencies to dependencies per package maintainer guidance. Did not downgrade to 2.3.x — issue #645 shows downgrade does not reliably fix this for all reporters.
4. RISKS & TRADEOFFS — No functional change; package has no runtime code path in this app. Marginal binary size increase from including plugin's native code. Verified via full test suite and successful signed release build.
5. VERIFICATION — flutter analyze clean, flutter test 221/221 pass, functions build/lint/test clean (77/77), flutter build appbundle --release --flavor prod succeeded (67.8MB), AAB signature verified against tremble-release.jks (SHA1 0B:DF:3F:40:ED:A7:A4:A0:1D:BC:46:E9:C5:D2:80:9B:92:DC:D2:5E match confirmed).
