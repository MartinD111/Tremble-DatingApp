## Session State — 2026-05-04 16:45
- Active Task: iOS Radar Quick Action + Lock Screen Widget
- Environment: Dev
- Modified Files (Phase 1 complete):
  - **Dart Layer** (NEW):
    - `lib/src/core/ios_integration_service.dart` — iOS-specific radar service (mirrors Android)
    - `lib/src/core/radar_integration_service.dart` — Platform router (Android ↔ iOS)
    - `lib/src/features/dashboard/presentation/home_screen.dart` — Updated imports to use router
    - `lib/src/features/auth/presentation/widgets/registration_steps/android_system_integration_step.dart` — Updated imports
  - **iOS Native Layer** (READY FOR XCODE):
    - `ios/Runner/RadarStateBridge.swift` — Shared UserDefaults state + Darwin notifications
    - `ios/Runner/AppDelegate.swift` — Radar MethodChannel + EventChannel + quick action handler
    - `ios/Runner/Runner.entitlements` — App Group declaration
    - `ios/Runner/Info.plist` — Quick action item definition
    - `ios/TrembleRadarWidget/TrembleRadarWidget.swift` — WidgetKit lock screen widget + toggle intent
    - `ios/TrembleRadarWidget/Info.plist` — Widget extension plist
    - `ios/TrembleRadarWidget/TrembleRadarWidget.entitlements` — App Group declaration (widget)
    - `ios/Podfile` — Added TrembleRadarWidget target
- Open Problems: **XCODE TARGET CREATION PENDING** (see Next Action)
- System Status: `flutter analyze` passing.

## Session Handoff — XCODE Manual Configuration Required

**Status**: Dart code + iOS Swift files are complete. Widget extension target must be created in Xcode (UUIDs cannot be scripted).

### For Aleksandar — Exact Xcode Steps

**1. Create Widget Extension Target**
   - Open `ios/Runner.xcodeproj` in Xcode
   - Menu: File → New → Target
   - Template: "Widget Extension" (under iOS)
   - Product Name: `TrembleRadarWidget`
   - Uncheck: "Include Configuration Intent" (we implement AppIntent manually)
   - Team: (select same as Runner target)
   - Click Finish

**2. Replace Auto-Generated Widget Files**
   - Xcode auto-generates `TrembleRadarWidget.swift`, `TrembleRadarWidget.entitlements`, `Info.plist`
   - **Delete** the auto-generated `TrembleRadarWidget.swift`
   - **Use** the one from `ios/TrembleRadarWidget/TrembleRadarWidget.swift` (already created by Claude)
   - **Overwrite** auto-generated `Info.plist` with `ios/TrembleRadarWidget/Info.plist`
   - **Overwrite** auto-generated `.entitlements` with `ios/TrembleRadarWidget/TrembleRadarWidget.entitlements`

**3. Add App Group Entitlements to Both Targets**
   - Select `Runner` target → Signing & Capabilities → +Capability → App Groups
   - Add: `group.com.pulse.radar`
   - Select `TrembleRadarWidget` target → Signing & Capabilities → +Capability → App Groups
   - Add: `group.com.pulse.radar` (same group ID)

**4. Set CODE_SIGN_ENTITLEMENTS for Runner**
   - Select `Runner` target → Build Settings
   - Search: `CODE_SIGN_ENTITLEMENTS`
   - Set to: `Runner/Runner.entitlements` (for both Debug and Release)

**5. Verify Embedding**
   - Select `Runner` target → Build Phases
   - Expand "Embed Foundation Extensions"
   - Verify `TrembleRadarWidget.appex` is listed (should be auto-added; if not, add it)

**6. Update Target Membership for iOS Files**
   - In Xcode, select `ios/TrembleRadarWidget/TrembleRadarWidget.swift`
   - Inspector panel (right) → Target Membership: check both `TrembleRadarWidget` AND `Runner` (if needed for linking)
   - Same for `.entitlements` and `Info.plist` files

**7. Build & Test**
   ```bash
   flutter run --flavor dev --dart-define=FLAVOR=dev
   ```
   - Wait for app to build (first build will be slower, WidgetKit compiling)
   - On simulator/device: Long-press Tremble app icon → should see "Radar" shortcut
   - Tap shortcut → state toggles in app
   - Lock screen: Settings → Customize Lock Screen → Add Widget → TrembleRadarWidget
   - Tap widget → state syncs back to app

### Potential Issues & Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| "No such module WidgetKit" in Swift | Deployment target mismatch | Set `TrembleRadarWidget` deployment target to iOS 16.0 (Build Settings → Deployment Target) |
| Widget doesn't appear on lock screen | iOS 15 device | Lock screen widgets are iOS 16+. On iOS 15, only `.systemSmall` family (home screen) is supported. |
| "Code signature invalid" | Signing mismatch | Ensure both `Runner` and `TrembleRadarWidget` have same Team ID in Signing & Capabilities |
| Entitlements not applied | Missing CODE_SIGN_ENTITLEMENTS | Verify `CODE_SIGN_ENTITLEMENTS` build setting is set for both targets |
| Darwin notification not received | Process isolation | App Group MUST be identical in both targets — check `group.com.pulse.radar` is spelled exactly the same |

### Key Points
- `RadarStateBridge.swift` handles state persistence + Darwin notifications
- `AppDelegate.swift` has MethodChannel + EventChannel + quick action handler (already written)
- Widget reads state from App Group UserDefaults, posts Darwin notification on toggle
- Flutter receives state changes via EventChannel → updates UI
- Quick Action (long-press) calls `performActionFor` → toggles state → broadcasts to widget + Flutter

**Completed Work**: All Swift files, Dart routing, Podfile. Only target creation + signing/capabilities config remain.

- Completed:
    - **Dart routing layer**: RadarIntegrationService routes platform calls to Android or iOS
    - **iOS State Bridge**: RadarStateBridge manages shared UserDefaults + Darwin notifications
    - **AppDelegate Integration**: Radar MethodChannel (setRadarActive, getRadarActive), EventChannel (state broadcasts), Quick Action handler
    - **Lock Screen Widget (WidgetKit)**: RadarToggleIntent + TimelineProvider + SwiftUI views (systemSmall, accessoryCircular, accessoryRectangular)
    - **Info.plist**: Quick action item registered (long-press app icon → "Radar" toggle)
    - **Podfile**: TrembleRadarWidget target added
    - **All Swift source files**: RadarStateBridge.swift, AppDelegate.swift, TrembleRadarWidget.swift with full implementations
- In Progress: Awaiting Xcode target creation + signing setup
- Blocked: None (ready for Aleksandar)
- Next Session: After Xcode config, run full test cycle (cold start, widget tap, quick action, flutter state changes)


---

## Infrastructure & Constraints
- **Zero-Chat Architecture**: Tremble strictly forbids free-text chatrooms (Rule #56). All interactions are limited to atomic "Waves" and "Signal" calibration.
- **Security Update**: App Check is strictly enforced on all Cloud Functions.
- **Privacy Fix**: SEC-002 resolved. lat/lng coordinates are never permanently stored.
- **Gym Mode**: `activeGymId` + `gymModeUntil` fields added to user doc (nullable). Not in Firestore Rules yet — add before prod deploy.

