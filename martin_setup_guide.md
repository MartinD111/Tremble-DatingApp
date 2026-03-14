# Tremble — Martin's Windows Setup Guide (S25 Ultra)

This guide is specifically for Martin to set up the Tremble development environment on **Windows** and test on the **Samsung Galaxy S25 Ultra**.

## 1. Prerequisites (Windows)

Ensure you have the following installed:
- **Flutter SDK:** [Download here](https://docs.flutter.dev/get-started/install/windows). Add the `bin` folder to your System PATH.
- **Android Studio:** [Download here](https://developer.android.com/studio). 
    - Install "Android SDK Command-line Tools" in SDK Manager.
- **Java JDK 17:** [Adoptium](https://adoptium.net) is recommended.
- **Node.js (v20+):** [Download here](https://nodejs.org).
- **Firebase CLI:** Run `npm install -g firebase-tools` in PowerShell.

## 2. Repository Setup

1.  **Clone the repo:**
    ```powershell
    git clone <repository_url>
    cd Tremble
    ```
2.  **Install dependencies:**
    ```powershell
    flutter pub get
    ```
3.  **Firebase Connection:**
    ```powershell
    firebase login
    dart pub global activate flutterfire_cli
    flutterfire configure --project=tremble-dev
    ```
    *This will generate your local `lib/src/core/firebase_options.dart`.*

## 3. Connecting the S25 Ultra

1.  **Enable Developer Options:**
    - Go to Settings > About Phone > Software Information.
    - Tap "Build Number" 7 times.
2.  **USB Debugging:** 
    - Go to Settings > Developer Options > Enable "USB Debugging".
3.  **Verify Connection:**
    ```powershell
    flutter devices
    ```

## 4. Running the Radar Test

To test the background stability of the BLE Proximity engine:

1.  **Run in Release Mode (Preferred for battery/background testing):**
    ```powershell
    flutter run --release --dart-define=FLAVOR=dev
    ```
2.  **Enable Radar:**
    - Open the app, grant Location and Bluetooth permissions.
    - Start the Radar.
3.  **Background Check:**
    - Move the app to the background.
    - Wait 30 minutes.
    - Check if the phone still pulses (look for the notification or check Firestore `proximity` collection).

## 5. Troubleshooting (Samsung Specific)

Samsung's One UI is aggressive with background processes. If the radar stops:
1.  Go to Settings > Apps > Tremble.
2.  Tap **Battery** > Select **Unrestricted**.
3.  Ensure "Remove permissions if app is unused" is **Disabled**.

---
*MPC v5 Managed | Lead: Antigravity*
