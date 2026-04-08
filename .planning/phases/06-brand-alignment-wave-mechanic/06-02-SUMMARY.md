---
phase: 06-brand-alignment-wave-mechanic
plan: 02
subsystem: translations
tags: [brand-voice, copy, i18n, wave-mechanic, privacy]
requirements: [BRAND-03, BRAND-04]

dependency_graph:
  requires: []
  provides: [brand-voice-onboarding-copy, wave_sent-key]
  affects: [onboarding_screen, home_screen_toast]

tech_stack:
  added: []
  patterns: [i18n-key-rename, privacy-by-design]

key_files:
  modified:
    - lib/src/core/translations.dart

decisions:
  - "Removed {name} from wave_sent toast — unidirectional privacy: recipient name not revealed to sender"
  - "Added onb4_title/onb4_body to 6 languages that were missing it (de, it, fr, hr, sr, hu)"
  - "All onboarding copy rewritten to reflect actual product mechanics (proximity, signal, background BLE)"

metrics:
  duration: "~12 minutes"
  completed: "2026-04-08T19:53:32Z"
  tasks_completed: 3
  tasks_total: 3
  files_modified: 1
---

# Phase 06 Plan 02: Onboarding Copy Rewrite and wave_sent Key Summary

Brand-voice onboarding copy rewrite across all 8 languages, plus greeting_sent renamed to wave_sent (with name variable removed for privacy).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Rewrite onboarding copy in all 8 language blocks | 9f49b49 | lib/src/core/translations.dart |
| 2 | Rename greeting_sent to wave_sent in all 8 language blocks | 9f49b49 | lib/src/core/translations.dart |
| 3 | Validate translations.dart compiles clean | (no code change) | — |

## What Was Done

### Task 1: Onboarding Copy Rewrite

All 8 language blocks (en, sl, de, it, fr, hr, sr, hu) had their onb1–onb4 copy replaced with brand-voice content.

**Old copy problems:**
- Generic: "A new way to meet people in the real world"
- Verbose and vague: "it will automatically give you a notification and you can decide"
- Self-deprecating: "0 algorithms integrated in our app that are ruining our mental health"
- Misleading: "Try out one of our premium features" (onb3 was a premium upsell, not product explanation)

**New copy characteristics:**
- Short, direct sentences with implied confidence
- Explains actual product mechanic: background BLE, proximity signal, wave gesture
- Uses Tremble brand terminology: "wave", "signal", "proximity"
- onb4 (privacy/control) now exists in all 8 languages — was missing from 6 languages

**New onb4 added to:** de, it, fr, hr, sr, hu (these blocks previously ended at onb3_body)

### Task 2: greeting_sent Renamed to wave_sent

- Key renamed from `greeting_sent` to `wave_sent` in all 8 language blocks
- `{name}` variable intentionally removed — privacy improvement: the toast confirms the wave was sent without revealing the recipient's name (unidirectional mechanic)
- No call sites outside translations.dart existed (confirmed via grep)

**wave_sent values by language:**
| Lang | Value |
|------|-------|
| en | Wave sent. |
| sl | Val poslan. |
| de | Welle gesendet. |
| it | Onda inviata. |
| fr | Vague envoyée. |
| hr | Val poslan. |
| sr | Val poslat. |
| hu | Hullám elküldve. |

### Task 3: Validation

- `flutter analyze lib/src/core/translations.dart` — 0 issues
- `flutter analyze` (full project) — 0 issues
- All apostrophes properly escaped in French and Italian strings
- Dart trailing comma conventions maintained throughout

## Verification Results

| Check | Result |
|-------|--------|
| Old copy removed | PASSED — no "Try out one", "A new way to meet", "ruining our mental health" |
| greeting_sent removed | PASSED — 0 occurrences in lib/ |
| wave_sent count | PASSED — 8 (one per language) |
| onb4 count | PASSED — 16 (onb4_title + onb4_body × 8 languages) |
| flutter analyze | PASSED — 0 errors |

## Deviations from Plan

None — plan executed exactly as written.

Task 2 changes were committed atomically within the same pre-commit cycle as Task 1 (pre-commit hook ran dart format during Task 1 commit, which staged all pending changes). Both logical tasks are represented in commit 9f49b49.

## Known Stubs

None. All 8 language blocks have complete, wired copy for onb1–onb4 and wave_sent. No placeholder text remains.

## Self-Check: PASSED

- `lib/src/core/translations.dart` — exists and contains all required keys
- Commit 9f49b49 — verified in git log
- `flutter analyze` — 0 errors confirmed
