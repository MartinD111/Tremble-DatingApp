# Research: Phase 6 — Brand Alignment

**Date:** 2026-04-08
**Status:** Complete

---

## 1. Color Audit — BRAND-01

### Finding: Theme is already fully brand-aligned. One file has a legacy teal reference.

`lib/src/core/theme.dart` contains the complete brand palette — no teal exists:
- `rose = Color(0xFFF4436C)` — primary CTA
- `roseLight = Color(0xFFF9839E)`
- `roseDark = Color(0xFFC02048)`
- `accentYellow = Color(0xFFF5C842)` — accents only
- `successGreen = Color(0xFF2D9B6F)` — success/GDPR states
- `warmGray = Color(0xFF6B6B63)` — secondary text
- `border = Color(0xFFE2E2DC)`

**One file flagged:** `lib/src/features/auth/presentation/registration_flow.dart`
- Contains a `Color(0xFF00...)` pattern — needs manual line inspection
- Run: `grep -n "Color(0xFF" lib/src/features/auth/presentation/registration_flow.dart`
- Likely a Color(0xFF00...) other than teal, but must verify

**Action:** Audit registration_flow.dart for any hardcoded teal. All other files use TrembleTheme tokens.

---

## 2. Font System Audit — BRAND-02

### Finding: Font system is already fully implemented. No action needed at theme level.

`lib/src/core/theme.dart` has complete typography:
- `GoogleFonts.playfairDisplay()` — displayLarge/Medium/Small, headlineLarge/Medium/Small
- `GoogleFonts.lora()` — bodyLarge/Medium/Small
- `GoogleFonts.instrumentSans()` — titleLarge/Medium/Small, labelLarge/Medium/Small, all UI components
- `GoogleFonts.jetBrainsMono()` — via `TrembleTheme.telemetryTextStyle()`

Helper methods available for direct use:
- `TrembleTheme.displayFont(fontSize, fontWeight, color)` — Playfair Display
- `TrembleTheme.bodyFont(fontSize, fontWeight, color)` — Lora
- `TrembleTheme.uiFont(fontSize, fontWeight, color)` — Instrument Sans
- `TrembleTheme.telemetryTextStyle(context, color)` — JetBrains Mono

`google_fonts` is already in pubspec.yaml (confirmed by theme.dart import working).

**Action:** Audit individual screens to verify they use `Theme.of(context).textTheme.*` or `TrembleTheme.*Font()` rather than hardcoded `TextStyle(fontFamily: 'Lato')` or similar. Check especially:
- `onboarding_screen.dart` — splash/intro screens
- `registration_flow.dart` — multi-step form
- `home_screen.dart` — radar UI
- `radar_animation.dart` — telemetry text should use `jetBrainsMono`

---

## 3. Copy Audit — BRAND-03 & BRAND-04

### Critical finding: Onboarding copy is generic, verbose, and not brand voice.

Current onboarding copy (English):

| Key | Current | Brand Voice Issue |
|-----|---------|-------------------|
| `onb1_title` | "MEET PEOPLE LIKE PEOPLE" | Acceptable — all caps works |
| `onb1_body` | "A new way to meet people in the real world. When the app notices someone compatible with you it will automatically give you a notification and you can decide if you want to meet them in real life or not." | **Too long, too soft.** "compatible" is vague. "in real life or not" is weak. |
| `onb2_title` | "NO CHATS AND NO ALGORITHMS" | Good — direct |
| `onb2_body` | "We believe in real world interactions. No chats, No ghosting and No catfishing. There are 0 algorithms integrated in our app that are ruining our mental health." | **Mixed quality.** First sentence weak. "0 algorithms" phrasing is odd. Last sentence is good. |
| `onb3_title` | "MAP VIEW" | **Generic feature name, not brand.** Rename to something intentional. |
| `onb3_body` | "Try out one of our premium features. See how many people are currently searching in cities." | **Weak.** "Try out" is filler. Sounds like a feature tour. |
| `onb4_title` | "STAY IN CONTROL" | Acceptable |
| `onb4_body` | "You have full control over who you connect with. Unmatch or block at any time." | Functional, acceptable |

**Critical copy bug:** `greeting_sent` key uses "Greeting" not "Wave":
- Current: `'greeting_sent': 'Greeting sent to {name}!'`
- Should be: `'wave_sent': 'Wave sent.'` (no name — privacy) or just remove the toast
- All 3 languages have this: `en`, `sl` (Pozdrav je bil poslan osebi), `de` (Gruß gesendet an)

**Suggested rewrites (English — apply to all langs):**

```
onb1_title: "IT RUNS WHILE YOU LIVE."
onb1_body: "Tremble works in the background. When someone compatible is physically near you, you get a signal. No scrolling required."

onb2_title: "ZERO SWIPES. ONE WAVE."
onb2_body: "No feeds. No algorithms. No endless chat rooms. Just a proximity signal and one decision: wave or move on."

onb3_title: "YOUR CITY, LIVE."
onb3_body: "See who's discovering nearby in real time. The more Tremble users around you, the higher the signal."

onb4_title: "YOUR RULES."
onb4_body: "Unmatch or block at any time. Unidirectional — no one knows you waved until it's mutual."
```

**Registration CTA (BRAND-04):**
- Current `continue_btn`: 'Continue' — acceptable, keep
- `consent_subtitle`: "By continuing, you agree to our Terms of Service and Privacy Policy." — generic but functional, acceptable
- `account_created`: "Account created successfully." — too generic. Could be "You're in." but this is low priority.

**Translation scope:** Changes must be applied to all 8 language keys (en, sl, de, fr, hr, hu, it, sr). The onboarding body text is the priority — titles are already decent.

---

## 4. Maps API Key Status — BRAND-05

### Current state: Injection mechanism wired, keys are placeholders only.

**Android:** `android/local.properties`
- Contains: `MAPS_API_KEY=YOUR_MAPS_API_KEY_HERE`
- Read by: `android/app/build.gradle.kts`
- Mechanism: ✅ wired correctly

**iOS:** `ios/Flutter/Debug.xcconfig`
- Contains: `MAPS_API_KEY=YOUR_MAPS_API_KEY_HERE`
- Read by: `ios/Runner/Info.plist` → `ios/Runner/AppDelegate.swift`
- Mechanism: ✅ wired correctly

**CI/CD:** No `MAPS_API_KEY` secret in GitHub Actions yet — needs to be added to `.github/workflows/` and injected similarly to existing secrets.

**Action required (Aleksandar):**
1. Get real Google Maps API key from Google Cloud Console (project: tremble-dev)
2. Fill in `android/local.properties` → replace `YOUR_MAPS_API_KEY_HERE`
3. Fill in `ios/Flutter/Debug.xcconfig` → replace `YOUR_MAPS_API_KEY_HERE`
4. Add `MAPS_API_KEY` as a GitHub Actions secret for CI builds
5. Do NOT commit the real key value to git — local.properties is already in .gitignore

---

## 5. Theme Architecture Assessment

### Architecture: Centralized + well-structured. No major risks.

Color flow:
1. `TrembleTheme` constants (static const Color fields)
2. `ColorScheme.fromSeed()` with those constants
3. `ThemeData` built from the ColorScheme
4. Individual screens use `Theme.of(context).colorScheme.*` or `TrembleTheme.rose` directly

Risk: Some older screens may use `TrembleTheme.rose` directly (which is fine) or may have one-off hardcoded `Color(0xFF...)` values that bypass the theme system (needs audit).

The `darkTheme()` uses `roseDark` as primary instead of `rose` — this is intentional and correct for dark mode accessibility.

---

## 6. Recommended Approach for Phase 6

### Execution order:

1. **Maps API key (5 min, Aleksandar)** — Fill in both platform files. Unblocks map screen testing.

2. **Color spot-audit (30 min)** — Grep all feature files for `Color(0xFF` hardcoded values. Fix any that don't use TrembleTheme tokens. Primary suspect: `registration_flow.dart`.

3. **Font spot-audit (30 min)** — Grep all feature files for `fontFamily:`, `TextStyle(font`, or direct `GoogleFonts.*` calls that bypass the helper methods. Ensure JetBrains Mono is used in radar_animation.dart for telemetry text.

4. **Copy rewrite (1h)** — Update `translations.dart`:
   - Rewrite `onb1_body`, `onb2_body`, `onb3_title`, `onb3_body` in all 8 languages
   - Rename `greeting_sent` → `wave_sent` and update the value + all references
   - Update Slovenian and German translations (other languages can be machine-translated initially)

5. **flutter analyze + test** — Verify zero new warnings after changes.

### Files to touch:
- `lib/src/core/translations.dart` — copy rewrites
- `lib/src/features/auth/presentation/registration_flow.dart` — color audit + greeting→wave rename
- Any other files found in the spot-audits above
- `android/local.properties` + `ios/Flutter/Debug.xcconfig` — Maps key (manual, Aleksandar)

---

## 7. Gotchas

| Risk | Detail | Mitigation |
|------|--------|-----------|
| `greeting_sent` references | The key is used somewhere — grep before renaming | `grep -rn "greeting_sent" lib/` before changing |
| Onboarding copy in 8 languages | Slovene + German rewrites should be authored properly; other 6 can be auto-translated | Prioritize EN/SL/DE, machine-translate rest |
| `Color(0xFF00...)` in registration_flow.dart | Unknown — could be transparent black (0xFF000000) not teal | Verify before flagging as bug |
| Dark mode JetBrains Mono color | telemetryTextStyle falls back to `colorScheme.onSurface` — verify it reads as signal-yellow in dark mode on radar | Check radar_animation.dart context |
| Maps key in Release.xcconfig | Debug.xcconfig only — Release.xcconfig needs the key too for TestFlight builds | Add `MAPS_API_KEY` to Release.xcconfig as well |
