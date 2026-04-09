## Session State — 2026-04-09 10:15
- Active Task: Phase 7.5 — iOS Native Polish ✅ COMPLETE
- Environment: Dev (tremble-dev)
- Branch: main
- System Status: `flutter analyze` → No issues ✅ | `pod install` → Clean ✅ | Firebase deploy → 19 functions ✅

## Interaction System v2.1 — Live ✅

| Trigger | Notifikacija | Status |
|---|---|---|
| BLE zaznava (onBleProximity) | "Nekdo je blizu. Boš pomahal-a?" (anonimno, 15-min cooldown) | ✅ Live |
| 1. val (onWaveCreated) | "[Ime] ti je pomahal-a. Pomahaš nazaj?" (Rich Push: ime + slika) | ✅ Live |
| Mutual wave | "[Ime] ti je pomahal-a nazaj! Odpremo radar?" + deep link /radar | ✅ Live |
| Background "Pomahaj nazaj" | Silent wave v Firestore brez odpiranja app | ✅ Flutter ready |
| Deep link cold-start | Notification tap → MatchRevealScreen | ✅ Flutter ready |

## Phase 7.5 — iOS Notification Service Extension ✅

### Kar je narejeno:
- `ios/ImageNotification/NotificationService.swift` — downloads image from FCM payload, attaches to notification
- `ios/ImageNotification/Info.plist` — NSExtensionPointIdentifier = com.apple.usernotifications.service
- Xcode target `ImageNotification` linked in project.pbxproj
- Bundle IDs: `com.pulse.ImageNotification` (Debug), `tremble.dating.app.ImageNotification` (Release/Profile)
- `ios/Podfile` — `target 'ImageNotification'` with `pod 'Firebase/Messaging'`
- .xcconfig (Debug/Release/Profile) include `#include?` Pods references
- `CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = $(inherited)` in ImageNotification build settings
- Deployment target: iOS 15.0 on all targets
- `pod install` → clean ✅

### KRITIČNO — ne smeš spremeniti:
- `objectVersion` v `project.pbxproj` mora ostati **63** (ne 70!)
  Xcode 26.3 + CocoaPods 1.16.2 zahteva 63. Sprememba na 70 = `pod install` fail.
- Bundle ID hierarhija mora ostati: parent app ID + `.ImageNotification`

### Kaj ostaja za test:
- Fizična naprava + TestFlight build — preveriti, da se slika pošiljatelja prikaže v iOS push notifikaciji
- Android rich push že deluje ✅

## Session Handoff
- **Completed:** Phase 7 + Phase 7.5 — Interaction System v2.1 + iOS Extension infrastructure
- **In Progress:** Phase 9/10 — GDPR Deletion Pipeline fix (plan written, awaiting founder decision on `reports` deletion strategy)
- **Blocked:** GDPR plan Step 2b — founder must decide: Option A (full delete reports) vs Option B (anonymise reportedId, keep for Art. 17(3)(e) legal defence)
- **Phase 8 (RevenueCat):** Deliberately deferred — both founders must be present
- **Next Action:** Founder answers reports question → execute `feature/gdpr-deletion-fix` → then Phase 8

Staleness rule: if this block is >48h old, re-validate before executing.
