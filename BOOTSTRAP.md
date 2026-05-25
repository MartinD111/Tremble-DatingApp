# Tremble App Project Bootstrap

This guide explains how to get the Tremble application running on a completely fresh machine. 
The repository is completely portable and OS-agnostic. 

> [!IMPORTANT]
> This project is governed by the **MPC (Master Project Controller)** system. 
> All development is tracked in the `/tasks` directory. 
> NEVER code without reading `tasks/context.md` and `tasks/blockers.md` first.

## 1. Prerequisites
Ensure you have the following installed on your machine (macOS, Windows, or Linux):
- **Flutter SDK** (`>=3.2.0 <4.0.0`)
- **Node.js** (v22; Cloud Functions declare `engines.node = 22`)
- **Firebase CLI** (`npm install -g firebase-tools`)
- **CocoaPods** (if building for iOS on macOS)

## 2. Clone and Setup
1. Clone the repository:
   ```bash
   git clone <repository_url>
   cd "Pulse---Dating-app"
   ```
2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Install Cloud Functions dependencies:
   ```bash
   cd functions
   npm ci
   cd ..
   ```

## 3. Environment & Secrets
No secrets are committed to the repository. You must coordinate with the team to get the correct keys.

### Cloud Functions (`functions/.env`)
Navigate to the `functions` directory and create your `.env`:
```bash
cd functions
cp .env.example .env
npm ci
cd ..
```
Edit the `functions/.env` file to include the correct Cloudflare R2 and Resend keys.

### Firebase Credentials
The Firebase config files are excluded from Git for security. You must acquire and place them manually:
- `google-services.json` ➔ Place in `android/app/`
- `GoogleService-Info.plist` ➔ Place in `ios/Runner/`
- `android/local.properties` ➔ Contains `MAPS_API_KEY` for Android.
- `ios/Flutter/Debug.xcconfig` ➔ Contains `MAPS_API_KEY` for iOS.
- `firebase_options.dart` ➔ Place in `lib/src/core/` (generated via `flutterfire configure`)

## 4. Run the Application
Start the Firebase emulators (Optional depending on your testing mode):
```bash
cd functions
npm run serve
```

Run the Flutter app in the dev flavor:
```bash
# Return to the root directory
cd ..
flutter run --flavor dev --dart-define=FLAVOR=dev
```

Never run unflavored `flutter run` or `flutter build` in this repository.

## 5. Local Pre-Commit Hook
Set up the local Git hook so commits run the same minimum checks locally:

```bash
cat > .git/hooks/pre-commit <<'EOF'
#!/bin/sh
set -e

echo "▶ Flutter pub get..."
flutter pub get --offline 2>/dev/null || flutter pub get

echo "▶ Flutter format check..."
dart format --set-exit-if-changed .

echo "▶ Flutter analyze..."
flutter analyze --no-fatal-infos

echo "▶ Flutter tests..."
flutter test --coverage --dart-define=FLAVOR=dev

echo "▶ Backend setup..."
cd functions
npm ci --silent

echo "▶ Backend lint..."
npm run lint

echo "▶ Backend build..."
npm run build

echo "▶ Backend tests..."
npm test -- --passWithNoTests

cd ..
echo "✅ All checks passed. Proceeding with commit."
EOF

chmod +x .git/hooks/pre-commit
```

Verify it directly before relying on it:

```bash
.git/hooks/pre-commit
```

## OS-Independence Guarantees
- **No Absolute Paths**: The codebase uses relative paths and Dart's `path_provider` for dynamic directory resolution.
- **Dependency Locking**: `pubspec.yaml` and `package.json` use versioned dependencies. Do not use local machine path dependencies.
- **Cross-platform Safety**: File path separators (`/` vs `\`) are handled via the `path` package or inherent Flutter abstraction. 

You are now ready to develop on Tremble.
