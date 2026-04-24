# Tremble — Store Submission Master Plan
Date: April 2026
Target: TestFlight internal beta → App Store + Play Store submission

## ZAPOREDJE

KORAK 1 — Privacy Fix (dev)          ✅ DONE 2026-04-24
KORAK 2 — Privacy Fix (prod)         ✅ DONE 2026-04-24
KORAK 3 — Docs update                ✅ DONE 2026-04-24
KORAK 4 — iOS BLE background         🔴 NEXT (Ti + Martin, 3–5 dni)
KORAK 5 — Android BLE background     🔴 PENDING (Martin, 1–2 dni)
KORAK 6 — D-37 Map toggle test       🔴 PENDING (Martin, 1 dan)
KORAK 7 — App Store metadata rewrite 🔴 PENDING (Ti, 2 uri)
KORAK 8 — TestFlight internal beta   🔴 PENDING (oba, po 4+5)
KORAK 9 — Store submission           🔴 PENDING (oba)

## KORAK 4 — iOS BLE Background State Restoration
Claude CLI prompt:

Read CLAUDE.md fully. Then read tasks/context.md, tasks/blockers.md, tasks/lessons.md, and tasks/decisions/ folder. Also read lib/src/core/ble_service.dart and lib/src/core/background_service.dart in full.

TASK: Plan iOS CoreBluetooth background state restoration for ADR-001.

CONTEXT:
- flutter_blue_plus 2.2.1 is in pubspec.yaml
- BleService is correctly implemented for foreground scanning
- background_service.dart explicitly does NOT import BleService — correct, BLE must run on main isolate
- iOS requires UIBackgroundModes bluetooth-central in Info.plist
- flutter_blue_plus 2.x supports state restoration but requires explicit configuration

REQUIRED:
1. Read ios/Runner/Info.plist — report existing UIBackgroundModes entries
2. Read pubspec.lock — confirm exact flutter_blue_plus version
3. Produce a 5-step plan per CLAUDE.md orchestral loop format
4. Risk level: HIGH — Info.plist changes require founder approval before any code is written
5. Do not modify any files — plan only

## KORAK 5 — Android BLE Background
Claude CLI prompt:

Read CLAUDE.md fully. Then read tasks/context.md and lib/src/core/background_service.dart.

TASK: Verify Android BLE background scanning on physical device.

REQUIRED:
1. Read android/app/src/main/AndroidManifest.xml — report all bluetooth and location permissions
2. Verify foreground service configuration in background_service.dart
3. Produce test checklist for Martin (Samsung S25 Ultra)
4. Risk level: HIGH for any AndroidManifest.xml changes — founder approval required
5. Do not modify any files — audit and checklist only

## KORAK 6 — D-37 Map Toggle Test
Martin: Run dev flavor on Samsung S25 Ultra. Navigate to map screen. Test all 3 states of the toggle. Report in tasks/debt.md D-37.

## KORAK 7 — App Store Metadata Rewrite
Claude CLI prompt:

Read CLAUDE.md fully. Then read tasks/metadata_draft.md and tasks/store_submission_plan.md.

TASK: Rewrite App Store and Google Play metadata for store submission.

CONSTRAINTS:
- Apple subtitle max 30 chars — descriptive, not brand language
- Apple description must be clear to a reviewer who has never heard of Tremble
- Google Play short description max 80 chars
- Brand voice rules apply: no hype, no revolutionary, no emoji in headlines
- Privacy claims must reflect SEC-002 fix: location is architecturally never stored

PRODUCE:
1. iOS: Title (30 chars), Subtitle (30 chars), Promotional Text (170 chars), Description (800–1000 words)
2. Google Play: Title (50 chars), Short Description (80 chars), Full Description
3. Keywords list for both stores
4. App Store privacy nutrition label answers

Save to tasks/metadata_draft_v2.md

## KORAK 8 — TestFlight Internal Beta
Predpogoji pred začetkom:
- iOS BLE background works on physical device ✅
- Android BLE background verified on Samsung S25 Ultra ✅
- Apple Developer Account ($99) purchased ✅
- App Store Connect app record created ✅

Claude CLI prompt:

Read CLAUDE.md deploy pipeline section and tasks/context.md.

TASK: Prepare TestFlight internal beta build checklist.

1. Run flutter analyze — must be zero issues
2. Run flutter test — must pass
3. Produce exact build command for iOS release build
4. List all App Store Connect pre-submission checklist items
5. Do NOT trigger any deployment — checklist only. Founder executes.

## FOUNDER ACTION ITEMS (blokirajo napredek)
| Akcija | Kdaj | Zakaj |
|--------|------|-------|
| Apple Developer Account ($99) | Pred Korakom 8 | Brez tega ni TestFlight |
| AMS Solutions d.o.o. registracija | ASAP | Unblocks Phase 8 RevenueCat |

## REALNI TIMELINE
| Teden | Naloge |
|-------|--------|
| Teden 1 (zdaj) | Koraki 1–3 ✅ DONE |
| Teden 2 | Korak 4 iOS BLE + Korak 5 Android BLE |
| Teden 3 | Korak 6 map test + Korak 7 metadata |
| Teden 4 | Korak 8 TestFlight — če Apple account kupljen |
| Teden 5–6 | Beta perioda |
| Maj/Junij 2026 | Store submission |
