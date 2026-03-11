---
paths:
  - "**/*.dart"
---
# Dart/Flutter Security

> This file extends common/security.md with Dart, Flutter, and Firebase specific content.

## Secret Management

Flutter apps are decompilable — never embed secrets in Dart source code.

```dart
// NEVER: Hardcoded secrets in Dart
const apiKey = 'AIzaSy...';           // visible in APK
const serviceAccountJson = '{ ... }'; // catastrophic

// CORRECT: Firebase config is handled by google-services.json / GoogleService-Info.plist
// Additional secrets → Firebase Remote Config (non-sensitive) or backend Functions only
```

**Rule**: Any secret that would cause a security breach if exposed belongs in Cloud Functions environment variables, not in the Flutter app.

## BLE Security

Bluetooth Low Energy scanning exposes device presence — handle with care:

```dart
// ALWAYS: Request permissions before scanning
Future<bool> requestBlePermissions() async {
  final statuses = await [
    Permission.bluetooth,
    Permission.bluetoothScan,
    Permission.bluetoothAdvertise,
    Permission.locationWhenInUse, // required for BLE on Android
  ].request();

  return statuses.values.every((s) => s.isGranted);
}

// ALWAYS: Stop scanning when app goes to background (unless intentional background mode)
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused) {
    bleService.stopScan();
  }
}

// NEVER: Log full device MAC addresses or UUIDs to console in production
// Use truncated identifiers for debugging: uid.substring(0, 8)
```

## Firebase Auth

Always verify server-side — never trust client-side auth claims alone:

```dart
// CORRECT: Check auth state before any sensitive UI
final user = FirebaseAuth.instance.currentUser;
if (user == null) {
  Navigator.pushReplacementNamed(context, '/login');
  return;
}

// CORRECT: Re-verify token freshness for sensitive operations
final token = await user.getIdToken(true); // forceRefresh: true
// Pass token to Cloud Function — function calls requireAuth() internally
```

Token is verified server-side in every Cloud Function via `requireAuth()` and App Check via `requireAppCheck()`.

## App Check

App Check token is activated in `main.dart`. Rules:

```dart
// CORRECT: Debug provider only in debug builds
await FirebaseAppCheck.instance.activate(
  androidProvider: kDebugMode
      ? AndroidProvider.debug
      : AndroidProvider.playIntegrity,
  appleProvider: kDebugMode
      ? AppleProvider.debug
      : AppleProvider.deviceCheck,
);

// NEVER: Use debug provider in release builds
// NEVER: Log App Check tokens to external services
if (kDebugMode) {
  debugPrint('[AppCheck] token: $token'); // local only
}
```

## Firestore Client-Side

Never rely on client-side validation alone — Firestore Security Rules are the real gate:

```dart
// WRONG: Trusting client-side userId construction
final docRef = firestore.collection('users').doc(buildUserId());

// CORRECT: Use authenticated UID from FirebaseAuth
final uid = FirebaseAuth.instance.currentUser?.uid;
if (uid == null) throw const AuthException('Not authenticated');
final docRef = firestore.collection('users').doc(uid);
```

Firestore Rules must enforce `request.auth.uid == resource.data.userId` — client-side checks are defence-in-depth only.

## Data Storage

```dart
// NEVER: Store sensitive data in SharedPreferences (not encrypted)
prefs.setString('auth_token', token); // plaintext on disk

// CORRECT: Use flutter_secure_storage for tokens/secrets
const storage = FlutterSecureStorage();
await storage.write(key: 'auth_token', value: token);

// User profile data → Firestore (server-enforced)
// App preferences (theme, language) → SharedPreferences (fine)
```

## Input Validation (Cloud Functions boundary)

The Flutter app is untrusted input to Cloud Functions. All validation happens server-side with Zod. Client-side validation is UX only:

```dart
// Client-side: UX feedback only
String? validateBio(String? value) {
  if (value == null || value.isEmpty) return 'Bio cannot be empty';
  if (value.length > 500) return 'Max 500 characters';
  return null;
}

// Server-side (functions/src/): Zod schema is the real enforcement
// const BioSchema = z.string().min(1).max(500)
```

## Location / Geofencing

```dart
// ALWAYS: Request precise location only when needed, coarse otherwise
// ALWAYS: Explain why location is needed before requesting (iOS requirement)
// NEVER: Store raw GPS coordinates in Firestore user documents
// CORRECT: Store geohash only, recalculate on device
final geohash = Geohash.encode(lat, lng, precision: 6); // ~1.2km precision
```

## Pre-Release Security Checklist

- [ ] No hardcoded API keys, tokens, or secrets in Dart files
- [ ] `kDebugMode` guards on all debug-only logs
- [ ] App Check using production providers (PlayIntegrity / DeviceCheck) in release
- [ ] BLE scan stops on app background
- [ ] Sensitive data in `flutter_secure_storage`, not `SharedPreferences`
- [ ] Firebase UID used for all user document paths (not client-constructed IDs)
- [ ] Location permission rationale shown before request
- [ ] No raw GPS coordinates stored — geohash only
- [ ] `google-services.json` and `GoogleService-Info.plist` in `.gitignore` for any keys beyond the default Firebase config
