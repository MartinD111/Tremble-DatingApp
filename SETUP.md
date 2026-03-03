# Tremble — Developer Setup Guide

## Prerequisites

Install these tools on your machine:

| Tool | Version | Link |
|------|---------|------|
| Flutter SDK | ≥ 3.10 | https://flutter.dev/docs/get-started/install |
| Dart SDK | ≥ 3.2.0 | (bundled with Flutter) |
| Android Studio / SDK | Latest | https://developer.android.com/studio |
| Java JDK | 17 | https://adoptium.net |
| VS Code | Latest | + Flutter + Dart extensions |

---

## First-time setup (after `git clone` or `git pull`)

```bash
# 1. Get Flutter packages
flutter pub get

# 2. Add your Firebase config files (NOT in git — each dev has their own):
#    - android/app/google-services.json   ← get from Firebase Console
#    - lib/src/core/firebase_options.dart ← generate with FlutterFire CLI
```

### Generate firebase_options.dart

```bash
# Install FlutterFire CLI (once)
dart pub global activate flutterfire_cli

# Generate options (needs Firebase project access)
flutterfire configure
```

---

## Running the app

```bash
# List connected devices
flutter devices

# Run on Android device/emulator
flutter run -d <device_id>

# Run on Chrome (web)
flutter run -d chrome

# Run on Windows
flutter run -d windows
```

---

## Files that are NOT in git (each developer manages locally)

| File | Why |
|------|-----|
| `android/app/google-services.json` | Firebase secrets |
| `lib/src/core/firebase_options.dart` | Firebase secrets |
| `android/local.properties` | Local SDK paths |
| `android/.project`, `.classpath`, `.settings/` | IDE auto-generated |
| `.idea/`, `.vscode/` | IDE workspace (personal) |

> These are all in `.gitignore`. Your IDE regenerates them automatically.

---

## Troubleshooting

### "Missing google-services.json"
Download from Firebase Console → Project Settings → Your Apps → Android app → Download config.
Place at: `android/app/google-services.json`

### "Missing firebase_options.dart"
Run `flutterfire configure` (see above).

### Gradle sync fails / "Workspace already contains project with name app"
This is usually an IDE issue, not a build issue. Run from terminal:
```bash
cd android
./gradlew clean
cd ..
flutter pub get
flutter run
```

### `flutter pub get` dependency error
Make sure your Flutter SDK is up to date:
```bash
flutter upgrade
flutter pub get
```
