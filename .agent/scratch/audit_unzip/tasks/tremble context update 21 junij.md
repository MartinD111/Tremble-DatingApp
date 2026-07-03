# Tremble Cross-Platform Audit — 21 Jun 2026
**Scope:** iOS vs Android behavioral divergence  
**Health score:** 6.5/10 — Android solid, iOS carries majority of risk  
**Total effort:** ~22–27 engineering hours  
**Source:** Claude Opus parallel codebase sweep, branch: main

---

## VERIFICATION COMMANDS — RUN FIRST

Three CRITICAL findings are marked ⚠ VERIFY. Run these before creating any tasks or writing any code. If they return output, the bug is confirmed. If empty, the agent missed adjacent lines.

```bash
# C3 — Camera/Photo permissions
grep -n "UsageDescription\|READ_MEDIA\|READ_EXTERNAL\|CAMERA" \
  ios/Runner/Info.plist \
  android/app/src/main/AndroidManifest.xml

# C4 — Android location
grep -n "ACCESS_.*LOCATION" android/app/src/main/AndroidManifest.xml

# C2 — aps-environment entitlement
grep -A1 "aps-environment" ios/Runner/*.entitlements

# 4.6 — Firebase init in AppDelegate
grep -n "FirebaseApp\|configure" ios/Runner/AppDelegate.swift
```

Post verification, mark each:
- **CONFIRMED** → execute fix  
- **FALSE POSITIVE** → skip task, note in this doc

---

## CRITICAL — Fix before next App Store build (build 3+)

---

### C1 — iOS APNs token not awaited before getToken() `AUTONOMOUS`
**File:** `lib/src/core/notification_service.dart:259-271`  
**Risk:** FCM token is null on first install → push notifications silently fail → waves never delivered  
**Effort:** 0.5h

**Codex prompt:**
```
In the Tremble Flutter project (MartinD111/Tremble-DatingApp, local path /Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app), fix the iOS APNs token race condition in push notification initialization.

ISSUE: notification_service.dart:259-271 calls FirebaseMessaging.instance.getToken() directly without first awaiting getAPNSToken(). On iOS, FCM cannot issue a token until APNs has registered — result is a null FCM token on first install, silently breaking all push delivery.

FIX:
In notification_service.dart, find the token fetch section and change to:

if (Platform.isIOS) {
  await FirebaseMessaging.instance.getAPNSToken();
}
final token = await FirebaseMessaging.instance.getToken();

Ensure Platform is imported (dart:io).

REQUIREMENTS:
- Do NOT modify Info.plist, entitlements files, or AndroidManifest.xml
- Do NOT change anything outside notification_service.dart
- flutter analyze: 0 issues after change
- All existing tests must pass: flutter test
- tsc must stay clean: cd functions && npx tsc --noEmit

SCOPE: only the APNs await guard. Do not refactor surrounding token logic.
```

---

### C2 — aps-environment entitlement missing (⚠ VERIFY FIRST) `FOUNDER ACTION`
**File:** `ios/Runner/Runner.entitlements`  
**Risk:** APNs cannot register in production → zero push notifications in live app  
**Effort:** 0.5h

**Verify:**
```bash
grep -A1 "aps-environment" ios/Runner/*.entitlements
```

**If confirmed missing — step-by-step:**

1. Open `ios/Runner/Runner.entitlements` in any text editor
2. Add inside the `<dict>` block:
```xml
<key>aps-environment</key>
<string>production</string>
```
3. Verify full file now contains both `com.apple.developer.applesignin` and `aps-environment`
4. Commit: `git add ios/Runner/Runner.entitlements && git commit -m "fix(ios): add aps-environment production entitlement"`
5. Do NOT push to main — PR only

**Note:** Use `production` not `development` for TestFlight and App Store builds. Development is only for local Xcode debug runs.

---

### C3 — Camera + Photo Library permissions missing (⚠ VERIFY FIRST) `FOUNDER ACTION`
**Files:** `ios/Runner/Info.plist`, `android/app/src/main/AndroidManifest.xml`  
**Risk:** App crashes on first photo pick (iOS) or silently denies (Android 13+) — TestFlight onboarding blocked  
**Effort:** 1.5h

**Verify:**
```bash
grep -n "UsageDescription\|READ_MEDIA\|READ_EXTERNAL\|CAMERA" \
  ios/Runner/Info.plist \
  android/app/src/main/AndroidManifest.xml
```

**If confirmed missing — iOS (Info.plist), add inside `<dict>`:**
```xml
<key>NSCameraUsageDescription</key>
<string>Tremble uses your camera to take a profile photo.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Tremble needs access to your photo library to set a profile photo.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Tremble saves photos to your library.</string>
```

**If confirmed missing — Android (AndroidManifest.xml), add inside `<manifest>`:**
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<!-- Fallback for API < 33 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
```

**After editing both files:**
1. In `lib/src/features/auth/presentation/consent_service.dart` (or wherever camera permission is requested), ensure `Permission.camera` and `Permission.photos` are included in the permission request list
2. `flutter analyze` → 0 issues
3. Test manually: build dev flavor, go through onboarding, confirm photo picker opens without crash
4. Commit changes with message: `fix(permissions): add camera and photo library permissions iOS + Android`

---

### C4 — Android ACCESS_FINE_LOCATION missing (⚠ VERIFY FIRST) `FOUNDER ACTION`
**File:** `android/app/src/main/AndroidManifest.xml:24`  
**Risk:** GeoService fails on Android → no proximity detection  
**Effort:** 0.25h

**Verify:**
```bash
grep -n "ACCESS_.*LOCATION" android/app/src/main/AndroidManifest.xml
```

**If only ACCESS_BACKGROUND_LOCATION found, add:**
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

Place these BEFORE `ACCESS_BACKGROUND_LOCATION` (order matters for some Android versions).

---

### C5 — iOS BLE restoration identifier missing `FOUNDER DECISION REQUIRED`
**Files:** `ios/Runner/AppDelegate.swift:208-243`, `lib/src/core/ble_service.dart:56-75`  
**Risk:** iOS kills BLE scan within ~10s of app backgrounding → users disappear from radar passively  
**Effort:** 4–8h (or accept degradation)

**Decision needed — choose one:**

**Option A — Accept degradation for v1.0 (recommended for launch speed):**  
Document in TestFlight "What to Test" notes that background BLE requires app to be in recent apps tray. BLE restoration is a v1.1 item. The Android foreground service already handles Android side. iOS users lose passive detection when phone is idle — wave mechanic still works in foreground.

**Option B — Implement workaround (4–8h):**  
flutter_blue_plus does not expose CBCentralManagerOptionRestoreIdentifierKey natively. Requires either:
- Forking flutter_blue_plus and adding restoration identifier in swift
- Writing a MethodChannel bridge in AppDelegate.swift that initializes CBCentralManager with restoration keys and relays scan results to Flutter

If choosing Option B, create a separate task and assign to a full engineering session.

**Recommended now:** Choose Option A, document the limitation, add Option B as v1.1 task.

---

### C6 — home_screen.dart build() is 2250 lines `AUTONOMOUS`
**File:** `lib/src/features/dashboard/presentation/home_screen.dart:346-2596`  
**Risk:** Every state change rebuilds the entire screen → dropped frames on both platforms → poor UX at scale  
**Effort:** 4h

**Codex prompt:**
```
In the Tremble Flutter project (MartinD111/Tremble-DatingApp, local path /Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app), extract discrete widget classes from home_screen.dart to reduce rebuild scope.

ISSUE: home_screen.dart build() spans lines 346-2596 (~2250 lines). Any state change triggers a full rebuild of radar, overlays, navigation, notification pills, and tutorial modals simultaneously.

EXTRACT these sections into separate private widget classes in the same file (do NOT create new files yet — keep it as a single-file refactor):
1. RadarSection — the map/radar canvas and proximity dot rendering
2. OverlayStack — any conditional overlays (tutorial, prompts, modals)
3. MatchNotificationPill — the wave/match notification banner
4. BottomNavBar — bottom navigation bar

RULES:
- Each extracted widget must receive only the props it needs (no passing full parent state)
- Use const constructors where possible
- Do NOT change any business logic, navigation, or BLE/GeoService calls
- Do NOT modify any Cloud Function calls or Firestore writes
- Do NOT change test files
- After extraction: flutter analyze 0 issues, flutter test all pass
- Verify: the extracted widgets appear in Flutter DevTools widget tree as discrete nodes

SCOPE: home_screen.dart only. One file in, one file out (same file, restructured).
```

---

## HIGH — Fix before v1.1

---

### H1 — No BLE pause/resume on app lifecycle `AUTONOMOUS`
**File:** `lib/src/features/dashboard/presentation/home_screen.dart:387-411`  
**Effort:** 1h

**Codex prompt:**
```
In the Tremble Flutter project, add app lifecycle observer to BleService in home_screen.dart.

ISSUE: When the app backgrounds, BLE scanning continues burning battery but produces no useful results on iOS (no restoration). When app resumes, scan state may be stale.

FIX: In _HomeScreenState, implement WidgetsBindingObserver:

1. Add `with WidgetsBindingObserver` to _HomeScreenState
2. In initState(): WidgetsBinding.instance.addObserver(this);
3. In dispose(): WidgetsBinding.instance.removeObserver(this);
4. Override:
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused) {
    BleService().stop();
  } else if (state == AppLifecycleState.resumed) {
    BleService().start();
  }
}

REQUIREMENTS: Do not modify BleService itself. Do not change any navigation or state logic.
flutter analyze 0 issues. flutter test all pass.
```

---

### H2 — Location "Always" tier never requested `AUTONOMOUS`
**File:** `lib/src/core/consent_service.dart:40`  
**Effort:** 1.5h

**Codex prompt:**
```
In the Tremble Flutter project, add two-step location permission escalation to consent_service.dart.

ISSUE: consent_service.dart:40 only requests Permission.locationWhenInUse. Background BLE proximity requires "Always" location tier. Without it, GeoService cannot update geohash when app is backgrounded.

FIX:
After Permission.locationWhenInUse.request() resolves with granted status, add:

if (Platform.isIOS) {
  // iOS requires explicit second request after WhenInUse is granted
  await Permission.locationAlways.request();
} 
// Android: ACCESS_BACKGROUND_LOCATION in manifest handles this automatically
// when ACCESS_FINE_LOCATION is granted — no second runtime request needed

Add appropriate UX messaging before the second request explaining why Always is needed ("So Tremble can detect people nearby even when you're not looking at the app").

REQUIREMENTS:
- Do NOT modify Info.plist or AndroidManifest.xml
- Do NOT change the consent checkbox UI or GDPR consent text
- Ensure the second request is gated: only ask if WhenInUse was granted (not denied/restricted)
- flutter analyze 0 issues. flutter test all pass.
```

---

### H3 — Notification permission requested too late `AUTONOMOUS`
**File:** `lib/src/features/onboarding/.../permission_gate_screen.dart`  
**Effort:** 0.5h

**Codex prompt:**
```
In the Tremble Flutter project, move notification permission request to the onboarding permission gate.

ISSUE: Push notification permission is currently only requested when a user dismisses a wave notification (home_screen.dart:1437-1439). This means users who never receive a wave in their first session never grant notification permission → waves are silently missed.

FIX: In permission_gate_screen.dart, in the _onAccept() method (or equivalent permission grant handler), add notification permission request:

// After location + BLE permissions:
await Permission.notification.request();

// Android 13+ also requires explicit FCM channel permission:
if (Platform.isAndroid) {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
    .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    ?.requestNotificationsPermission();
}

REQUIREMENTS: Do not remove the existing notification request from home_screen — keep both as belt-and-suspenders. flutter analyze 0. flutter test all pass.
```

---

### H4 — remote-notification missing from UIBackgroundModes `FOUNDER ACTION`
**File:** `ios/Runner/Info.plist:98-104`  
**Effort:** 0.25h

Open `ios/Runner/Info.plist`, find `UIBackgroundModes` array (currently contains: location, bluetooth-central, bluetooth-peripheral, fetch), add:
```xml
<string>remote-notification</string>
```

Required for silent push / data-only delivery. Without it, background FCM messages (wave received while phone idle) are never delivered.

Commit: `fix(ios): add remote-notification to UIBackgroundModes`

---

### H5 — onTokenRefresh listener absent `AUTONOMOUS`
**File:** `lib/src/core/notification_service.dart`  
**Effort:** 0.5h

**Codex prompt:**
```
In the Tremble Flutter project, add FCM token refresh listener to notification_service.dart.

ISSUE: FCM token is written to Firestore once on home init. FCM rotates tokens periodically (OS update, app reinstall, cache clear). Stale token = push delivery failure.

FIX: In notification_service.dart, in the initialization method (after the initial token write), add:

FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null) {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'fcmToken': newToken});
  }
});

Store the StreamSubscription and cancel it in dispose() if notification_service has a lifecycle.

REQUIREMENTS: Do not change token write logic on first init. flutter analyze 0. flutter test all pass.
```

---

### H6 — profileStatusProvider non-autoDispose `AUTONOMOUS`
**File:** `lib/src/features/auth/data/auth_repository.dart:731`  
**Effort:** 0.25h

**Codex prompt:**
```
In the Tremble Flutter project, add .autoDispose to profileStatusProvider in auth_repository.dart:731.

ISSUE: profileStatusProvider is a non-autoDispose StreamProvider. It holds an open Firestore listener across navigation — leaks when the screen that owns it is popped.

FIX: Change:
final profileStatusProvider = StreamProvider<ProfileStatus>((ref) {
to:
final profileStatusProvider = StreamProvider.autoDispose<ProfileStatus>((ref) {

Then search for all consumers of profileStatusProvider and verify none use .keepAlive() or ref.read() in a way that requires persistent subscription. If a screen needs persistence, use ref.watch() correctly in a ConsumerWidget.

REQUIREMENTS: flutter analyze 0. flutter test all pass. Do not change any other providers.
```

---

### H7 — matchesStreamProvider non-autoDispose `AUTONOMOUS`
**File:** `lib/src/features/matches/data/match_repository.dart:342`  
**Effort:** 0.25h

**Codex prompt:**
```
In the Tremble Flutter project, add .autoDispose to matchesStreamProvider in match_repository.dart:342.

Same pattern as profileStatusProvider fix. Change StreamProvider to StreamProvider.autoDispose. Verify all consumers. flutter analyze 0. flutter test all pass.
```

---

### H8 — FCM stream subscriptions not cancellable `AUTONOMOUS`
**File:** `lib/src/core/notification_service.dart:140, 150`  
**Effort:** 0.5h

**Codex prompt:**
```
In the Tremble Flutter project, store FCM message stream subscriptions so they can be cancelled.

ISSUE: notification_service.dart:140, 150 — FirebaseMessaging.onMessage.listen() and onMessageOpenedApp.listen() return StreamSubscriptions that are never stored or cancelled.

FIX: Store both subscriptions as class fields:

StreamSubscription? _onMessageSub;
StreamSubscription? _onMessageOpenedAppSub;

Assign in init:
_onMessageSub = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
_onMessageOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedApp);

Add dispose() method:
void dispose() {
  _onMessageSub?.cancel();
  _onMessageOpenedAppSub?.cancel();
}

Call dispose() from wherever the notification service is torn down.

REQUIREMENTS: Do not change message handling logic. flutter analyze 0. flutter test all pass.
```

---

### H9 — Places API uses bare http.* on iOS `AUTONOMOUS`
**File:** `lib/src/core/places_service.dart:108-129, 186-200, 241-247`  
**Effort:** 1h

**Codex prompt:**
```
In the Tremble Flutter project, route Places API HTTP calls through CupertinoClient on iOS.

ISSUE: places_service.dart makes http.post/http.get calls to places.googleapis.com using the default dart:io HttpClient on iOS. This is the same TLS fragility that affected R2 uploads (already fixed in upload_service.dart with CupertinoClient).

FIX:
1. In lib/src/core/places_service.dart, add a platform-conditional client helper:

import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:cupertino_http/cupertino_http.dart';

http.Client _buildHttpClient() {
  if (Platform.isIOS) {
    final config = URLSessionConfiguration.defaultSessionConfiguration();
    return CupertinoClient.fromSessionConfiguration(config);
  }
  return http.Client();
}

2. Replace all bare http.get / http.post in places_service.dart with calls on a client instance:
final _client = _buildHttpClient();
// then: _client.get(...) instead of http.get(...)

3. Dispose _client in places_service dispose if applicable.

REQUIREMENTS: cupertino_http is already in pubspec.yaml (^2.0.0) — do not add it again. flutter analyze 0. flutter test all pass.
```

---

## MEDIUM / LOW — Post-launch

### M1 — Android FCM default channel meta-data `AUTONOMOUS`
**File:** `android/app/src/main/AndroidManifest.xml`  
Add inside `<application>`:
```xml
<meta-data android:name="com.google.firebase.messaging.default_notification_channel_id" 
    android:value="tremble_wave"/>
<meta-data android:name="com.google.firebase.messaging.default_notification_icon" 
    android:resource="@mipmap/ic_launcher"/>
```

---

### M2 — mapInitProvider autoDispose `AUTONOMOUS`
**File:** `lib/src/core/map_provider.dart:38`  
Add `.autoDispose` to mapInitProvider. Verify PMTiles provider has a dispose() that closes the tile handle.

---

### M3 — Settings deep-link on permanent denial `AUTONOMOUS`
**File:** `lib/src/features/onboarding/.../permission_gate_screen.dart`  
After 2nd denial of any permission, show "Open Settings" button calling `openAppSettings()` from permission_handler.

---

### M4 — Platform-aware SystemChrome `AUTONOMOUS`
**File:** `lib/main.dart:30-38`  
Gate `systemNavigationBarIconBrightness` behind `if (Platform.isAndroid)` and derive from active theme.

---

### M5 — iOS-native dialog wrapper `AUTONOMOUS`
Replace 40+ `showDialog + AlertDialog` instances with a `TrembleAlertDialog.show(context, …)` wrapper that branches on `Platform.isIOS` → `CupertinoAlertDialog`, else `AlertDialog`.

---

### M6 — Android onboarding step count drift `FOUNDER DECISION`
**File:** `lib/src/features/auth/presentation/registration_flow.dart:634, 1121, 1968, 1994`  
`totalSteps = Platform.isAndroid ? 29 : 28` — justify the extra Android step or remove the conditional.

---

### M7 — Image.network → CachedNetworkImage `AUTONOMOUS`
**Files:** `match_reveal_screen.dart:623`, `profile_detail_screen.dart:187` + 6 more  
Replace `Image.network` with `CachedNetworkImage`. Pass `maxWidth`/`maxHeight`. Request resized R2 variants for thumbnails.

---

## Summary

| Priority | Count | Total effort |
|---|---|---|
| CRITICAL | 6 | 11–15h |
| HIGH | 9 | 5.75h |
| MEDIUM/LOW | 8 | 6h |
| **Total** | **23** | **~22–27h** |

**Immediate sequence:**
1. Run all 4 verification commands at the top
2. Fix C2 (entitlements) + H4 (remote-notification) manually — both Info.plist/entitlement changes, 30 min total
3. Run autonomous tasks C1, C6, H1–H9 via Claude Code CLI (one at a time, verify tests pass after each)
4. Build 3: `flutter build ipa --flavor prod --dart-define-from-file=.env.prod.json --export-options-plist=ios/ExportOptions.plist --build-number=3`
5. Decide on C5 (iOS BLE restoration) — accept for v1.0 or scope for v1.1