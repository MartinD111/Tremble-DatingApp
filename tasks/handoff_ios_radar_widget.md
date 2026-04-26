# Handoff — Aleksandar: iOS Radar Widget + Control Center Toggle

**Date:** 2026-04-26
**From:** Martin
**To:** Aleksandar
**Plan ID:** 20260426-ios-radar-widget
**Risk Level:** HIGH (native iOS targets, entitlements, App Group, App Intents)
**Founder Approval Required:** YES (Martin) — pridobi pred Step 1
**Branch:** `feature/ios-radar-widget`

---

## Kontekst

Android stran je narejena: QS Tile (`RadarTileService.kt`) + home-screen widget (`RadarWidgetProvider`) + state bridge (`RadarStateBridge` → SharedPreferences, ključ `radar_active`).

Naloga: ekvivalent na iOS, dva surface-a:
1. **Lock Screen accessory widget** (iOS 16.1+, krog)
2. **Control Center toggle** (iOS 18.0+, `ControlWidget`)

State mora biti shared med Flutter app, Lock Screen widget in Control Center → **App Group + UserDefaults**.

ADR-001 (BLE wiring) je še vedno odprt — to delo je **neodvisno**: widget samo flippa flag in deep-linka v app. End-to-end QA pride šele po ADR-001 resolu.

---

## OBJECTIVE

iOS uporabnik lahko vklopi/izklopi Tremble Radar iz (a) Lock Screen circular widgeta in (b) iOS 18 Control Center toggla. Stanje je sinhrono med oboje + Flutter UI prek App Group `UserDefaults`.

---

## SCOPE

**Novo (dodaj):**

- `ios/TrembleRadarWidget/` — Widget Extension target (deployment iOS 16.1)
- `ios/TrembleRadarWidget/RadarStateStore.swift` — App Group `UserDefaults` reader/writer (target membership: Runner **in** TrembleRadarWidget)
- `ios/TrembleRadarWidget/RadarToggleIntent.swift` — `AppIntent`
- `ios/TrembleRadarWidget/RadarLockScreenWidget.swift` — `accessoryCircular` widget
- `ios/TrembleRadarWidget/RadarControlWidget.swift` — iOS 18 `ControlWidget` + `SetValueIntent`
- `ios/TrembleRadarWidget/Info.plist`, `TrembleRadarWidget.entitlements`
- `ios/Runner/Runner.entitlements` — dodaj App Group
- `lib/src/core/radar_state_bridge_ios.dart` — Dart writer prek MethodChannel
- `ios/Runner/AppDelegate.swift` — registriraj MethodChannel + URL handler

**NE spreminjaj:**

- `lib/src/core/background_service.dart` (radar lifecycle ostane v main isolate)
- Firebase config, Cloud Functions, security rules
- Android tile / widget kodo
- `flutter_blue_plus` wiring (ADR-001)

---

## STEP 1 — Xcode setup checklist

V `ios/Runner.xcworkspace`. Vsako točko atomarno.

1. **Capabilities → Runner target:**
   - Signing & Capabilities → `+ Capability` → **App Groups**
   - Dodaj **dva** group ID-ja (per-flavor isolation, glej Risk #1):
     - `group.com.pulse.radar` (Debug-dev)
     - `group.tremble.dating.app.radar` (Release-prod)
   - Preveri da je `Runner.entitlements` updated.

2. **Create Widget Extension target:**
   - File → New → Target → **Widget Extension**
   - Product Name: `TrembleRadarWidget`
   - Bundle ID per-config:
     - Debug-dev: `com.pulse.TrembleRadarWidget`
     - Release-prod: `tremble.dating.app.TrembleRadarWidget`
   - Include Live Activity: **No**
   - Include Configuration App Intent: **Yes**
   - Embed in Application: `Runner`
   - Activate scheme: **No**

3. **Capabilities → TrembleRadarWidget target:**
   - Dodaj iste App Group ID-je kot Runner.
   - Preveri `TrembleRadarWidget.entitlements`.

4. **Deployment targets:**
   - TrembleRadarWidget: iOS **16.1** minimum
   - Runner: pusti kot je

5. **Build settings (TrembleRadarWidget):**
   - Swift version match z Runner
   - `PRODUCT_BUNDLE_IDENTIFIER` per-config (glej zgoraj)
   - **NE** dodajaj v Podfile — extension naj ostane Pod-free

6. **Info.plist (TrembleRadarWidget):**
   - `NSExtension → NSExtensionPointIdentifier = com.apple.widgetkit-extension`
   - `NSSupportsLiveActivities = NO`
   - **Brez** Bluetooth/Location keys

7. **Target Membership:** `RadarStateStore.swift` mora biti checked za **OBA** targeta (Runner + TrembleRadarWidget).

---

## STEP 2 — App Group state contract

| Key | Type | Owner | Read by |
|-----|------|-------|---------|
| `radar_active` | `Bool` | Flutter (main isolate) on toggle, AppIntent on widget tap | Lock Screen Widget, Control Widget, Flutter at boot |
| `radar_last_changed` | `Double` (epoch s) | Isto | Widget za "since 19:42" subtitle |

Group ID izberi runtime z `#if DEBUG`:

```swift
enum RadarStateStore {
    static var appGroup: String {
        #if DEBUG
        return "group.com.pulse.radar"
        #else
        return "group.tremble.dating.app.radar"
        #endif
    }
    // ...
}
```

---

## STEP 3 — Swift reference koda

### `RadarStateStore.swift` (skupen Runner + Widget target)

```swift
import Foundation
import WidgetKit

enum RadarStateStore {
    static var appGroup: String {
        #if DEBUG
        return "group.com.pulse.radar"
        #else
        return "group.tremble.dating.app.radar"
        #endif
    }
    static let activeKey = "radar_active"
    static let changedKey = "radar_last_changed"

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroup)
    }

    static var isActive: Bool {
        defaults?.bool(forKey: activeKey) ?? false
    }

    static func setActive(_ value: Bool) {
        defaults?.set(value, forKey: activeKey)
        defaults?.set(Date().timeIntervalSince1970, forKey: changedKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
```

### `RadarToggleIntent.swift` (Lock Screen)

```swift
import AppIntents
import WidgetKit

struct RadarToggleIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Tremble Radar"
    static var description = IntentDescription("Turn the Tremble proximity radar on or off.")
    static var openAppWhenRun: Bool = true   // glej Risk #2

    @Parameter(title: "Turn on")
    var turnOn: Bool

    init() {}
    init(turnOn: Bool) { self.turnOn = turnOn }

    func perform() async throws -> some IntentResult {
        RadarStateStore.setActive(turnOn)
        return .result(opensIntent: OpenURLIntent(
            URL(string: "tremble://radar?active=\(turnOn ? 1 : 0)")!
        ))
    }
}
```

### `RadarLockScreenWidget.swift`

```swift
import WidgetKit
import SwiftUI
import AppIntents

struct RadarEntry: TimelineEntry {
    let date: Date
    let isActive: Bool
}

struct RadarProvider: TimelineProvider {
    func placeholder(in context: Context) -> RadarEntry {
        RadarEntry(date: .now, isActive: false)
    }
    func getSnapshot(in context: Context, completion: @escaping (RadarEntry) -> Void) {
        completion(RadarEntry(date: .now, isActive: RadarStateStore.isActive))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<RadarEntry>) -> Void) {
        let entry = RadarEntry(date: .now, isActive: RadarStateStore.isActive)
        completion(Timeline(entries: [entry], policy: .never))
    }
}

struct RadarLockScreenView: View {
    let entry: RadarEntry

    var body: some View {
        Button(intent: RadarToggleIntent(turnOn: !entry.isActive)) {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: entry.isActive
                    ? "dot.radiowaves.left.and.right"
                    : "antenna.radiowaves.left.and.right.slash")
                    .font(.system(size: 18, weight: .semibold))
            }
            .widgetAccentable()
        }
        .buttonStyle(.plain)
    }
}

struct RadarLockScreenWidget: Widget {
    let kind = "RadarLockScreenWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RadarProvider()) { entry in
            RadarLockScreenView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Tremble Radar")
        .description("Toggle radar from your lock screen.")
        .supportedFamilies([.accessoryCircular])
    }
}
```

### `RadarControlWidget.swift` (iOS 18)

```swift
import AppIntents
import WidgetKit
import SwiftUI

@available(iOS 18.0, *)
struct RadarControlWidget: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "RadarControlWidget") {
            ControlWidgetToggle(
                "Tremble Radar",
                isOn: RadarStateStore.isActive,
                action: RadarSetActiveIntent()
            ) { isOn in
                Label(
                    isOn ? "Radar On" : "Radar Off",
                    systemImage: isOn
                        ? "dot.radiowaves.left.and.right"
                        : "antenna.radiowaves.left.and.right.slash"
                )
            }
        }
        .displayName("Tremble Radar")
        .description("Quickly toggle proximity radar.")
    }
}

@available(iOS 18.0, *)
struct RadarSetActiveIntent: SetValueIntent {
    static var title: LocalizedStringResource = "Set Tremble Radar"
    static var openAppWhenRun: Bool = true   // Risk #2

    @Parameter(title: "Active")
    var value: Bool

    init() {}

    func perform() async throws -> some IntentResult {
        RadarStateStore.setActive(value)
        return .result(opensIntent: OpenURLIntent(
            URL(string: "tremble://radar?active=\(value ? 1 : 0)")!
        ))
    }
}
```

### Widget Bundle entry point

```swift
@main
struct TrembleWidgetBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        RadarLockScreenWidget()
        if #available(iOS 18.0, *) { RadarControlWidget() }
    }
}
```

---

## STEP 4 — AppDelegate: MethodChannel + URL handler

V `ios/Runner/AppDelegate.swift`:

```swift
override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
        name: "tremble.dating.app/radar_state",
        binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
        if call.method == "setRadarActive",
           let args = call.arguments as? [String: Any],
           let active = args["active"] as? Bool {
            RadarStateStore.setActive(active)
            result(nil)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
}

override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
) -> Bool {
    // Forward `tremble://radar?active=…` v Flutter (app_links plugin pickta).
    return super.application(app, open: url, options: options)
}
```

> Pomembno: `RadarStateStore.swift` mora imeti **Target Membership** Runner + TrembleRadarWidget (oboje).

---

## STEP 5 — Flutter / Dart bridge

`shared_preferences_foundation` ne piše v App Group suite. Uporabi MethodChannel.

### `lib/src/core/radar_state_bridge_ios.dart`

```dart
import 'dart:io';
import 'package:flutter/services.dart';

class RadarStateBridgeIos {
  static const _channel = MethodChannel('tremble.dating.app/radar_state');

  static Future<void> write(bool active) async {
    if (!Platform.isIOS) return;
    await _channel.invokeMethod('setRadarActive', {'active': active});
  }
}
```

### Wire up v radar toggle controllerju

Kjerkoli se v Flutter app pokliče Android `RadarStateBridge` (MethodChannel za Android), dodaj **vzporedno** še `RadarStateBridgeIos.write(active)`. Oba klica naj bosta v isti tranzakciji ko user flippa toggle v UI.

### Deep link handler (Dart)

Kjer obstaja app_links / uri listener:

```dart
if (uri.scheme == 'tremble' && uri.host == 'radar') {
  final active = uri.queryParameters['active'] == '1';
  await RadarStateBridgeIos.write(active);
  if (active) {
    await ref.read(radarControllerProvider).start();
  } else {
    await ref.read(radarControllerProvider).stop();
  }
}
```

Če app_links handlerja še ni → preveri `lib/src/core/` ali router; če manjka, dodaj minimalno listener v `main.dart` (vprašaj Martina).

---

## RISKS & TRADEOFFS — preberi pred kodiranjem

**Risk #1 — App Group per-flavor isolation.**
Po CLAUDE.md "no cross-contamination": dva ID-ja, dev/prod ločena. Implementirano prek `#if DEBUG` v `RadarStateStore`. Entitlements morajo vsebovati **oba** ID-ja na obeh targetih.

**Risk #2 — iOS background execution iz Intenta.**
Za razliko od Androida iOS extension **ne sme** držati BLE scana ali Firebase write-a. AppIntent ne more direktno startati CoreLocation/BLE — **mora** zbudit host app. Zato `openAppWhenRun = true` + deep link `tremble://radar?active=…`. To je nujno; ni workaround-a.

**Risk #3 — Tap latenca.**
Lock Screen Button-with-Intent na cold launch traja 1–3s. View naj flippa state takoj iz `entry.isActive` po `setActive`, da percepcija ostane snappy.

**Risk #4 — Control Widget je iOS 18+.**
`@available(iOS 18.0, *)` gate. Lock widget pokriva 16.1+. Brez fallback breme.

**Risk #5 — Privacy review.**
"Radar on/off" tekst je viden na lock screenu. Android tile že uporablja "Radar" — verjetno OK, ampak označi v PR opisu za Martin/legal sign-off.

**Risk #6 — TestFlight gated by ADR-001.**
Merge je možen neodvisno, ampak end-to-end test (BLE actually scanning) šele po ADR-001. To dokumentiraj v PR.

---

## VERIFICATION (preden odpreš PR)

```bash
flutter analyze                                                        # 0 issues
flutter test                                                            # green
flutter build ipa --flavor dev --dart-define=FLAVOR=dev                # success
```

**Manual on physical iPhone (dev flavor):**

1. Install dev build, toggle radar v app → Lock Screen widget reflectira state v ≤2s.
2. Add widget na lock screen → tap → app foregrounda, radar starta; tap ponovno → stop.
3. iOS 18 device: dodaj Control Center toggle → toggle → state sync med UI/widget/CC.
4. Force-quit Tremble → toggle iz lock widgeta → cold launch + radar start.
5. Switch flavor dev↔prod → preveri da App Group ni shared (state separate).

**Rule #1:** vsak `flutter build` / `flutter run` mora imeti `--flavor`. Brez izjem.

---

## Plan execution order (eden commit per komponento)

1. Branch `feature/ios-radar-widget` iz `main`.
2. Xcode setup (Step 1) → commit: `chore(ios): add TrembleRadarWidget extension target + App Groups`
3. Swift files (Step 3) → commit: `feat(ios): RadarStateStore + AppIntent + Lock Screen widget`
4. Control Widget (iOS 18) → commit: `feat(ios): Control Center toggle (iOS 18 ControlWidget)`
5. AppDelegate channel + URL forward (Step 4) → commit: `feat(ios): MethodChannel + URL handler for radar state`
6. Dart bridge + toggle wire-up (Step 5) → commit: `feat(flutter): RadarStateBridgeIos + deep-link handler`
7. Update `tasks/context.md` handoff blok + dodaj morebitne nove `lessons.md` rule-e.
8. Open PR proti `main`, taggaj Martina za sign-off (HIGH risk per CLAUDE.md).

---

## Vprašanja preden začneš

- [ ] Martin OK z dvema App Group ID-jema (dev/prod) ali enim?
- [ ] Obstaja že app_links listener v Dart kodi? (preveri `lib/src/core/`, router)
- [ ] Ali naj widget kaže "Radar" v slovenščini ali angleščini? (Android trenutno uporablja `R.string.qs_tile_label`)

Ko končaš → posodobi `tasks/context.md` z handoff blokom in pingaj Martina za review.
