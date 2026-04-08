## 🧠 Learning Log — Tremble Development

### 1. Flutter + Google Maps: Safe API Key Injection (2026-04-08)
- **Problem:** Storing API keys in `AndroidManifest.xml` or `AppDelegate.swift` leaks them to version control.
- **Solution:** Multi-layered injection using platform configuration files that are excluded from `.gitignore`.
- **Pattern (Android):**
    1. `android/local.properties` -> `MAPS_API_KEY=your_key`
    2. `android/app/build.gradle.kts` -> Load properties, add to `manifestPlaceholders`.
    3. `AndroidManifest.xml` -> `<meta-data android:name="..." android:value="${MAPS_API_KEY}" />`
- **Pattern (iOS):**
    1. `ios/Flutter/Debug.xcconfig` -> `MAPS_API_KEY=your_key`
    2. `ios/Runner/Info.plist` -> Add `MAPS_API_KEY` key with value `$(MAPS_API_KEY)`.
    3. `ios/Runner/AppDelegate.swift` -> `GMSServices.provideAPIKey(Bundle.main.object(forInfoDictionaryKey: "MAPS_API_KEY") as? String ?? "")`

### 2. Auth Redirect Loops (2026-04-08)
- **Problem:** `GoRouter` redirecting `!isOnboarded` to `/login` which then logic-bounced to `/onboarding`.
- **Solution:** Always jump directly to the target state (e.g., `/onboarding`) if the user is already authenticated but data-incomplete. Avoid redundant hops through auth screens after session is established.
