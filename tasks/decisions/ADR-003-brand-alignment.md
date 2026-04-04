# ADR-003 — Brand Identity Alignment Plan

**Date:** 2026-04-04  
**Status:** APPROVED  
**Reference:** tremble-brand-identity.html (project root)

---

## Context

Brand Identity System (v1.0) defines Tremble's visual language. Current app implementation was built before this document existed — significant divergence found between app UI and brand spec.

---

## Gap Analysis: App vs Brand Identity

### 🔴 Critical Gaps (break brand coherence)

| Element | Current App | Brand Spec |
|---------|------------|------------|
| Primary color | `#00D9A6` (teal) | `#F4436C` (Tremble Rose) |
| Display font | `Outfit` (bold) | `Playfair Display 900` |
| Body/subtitle font | `Outfit` | `Lora` |
| UI/button font | `Outfit` | `Instrument Sans` |
| Intro title casing | `ALL CAPS` | Mixed case, sentence-style |
| CTA button style | Teal pill | Rose pill (#F4436C, 100px radius) |

### 🟡 Medium Gaps (copy + voice)

| Element | Current | Brand Spec |
|---------|---------|------------|
| Onboarding slide 1 title | `MEET PEOPLE LIKE PEOPLE` | `Meet people in real life` |
| Onboarding slide 2 title | `NO CHATS AND NO ALGORITHMS` | `Real connections, no algorithms` |
| Onboarding slide 3 title | `MAP VIEW` | `See who's nearby` |
| Onboarding body copy | Generic | Use brand key copy lines (doc §02.2) |
| Registration CTA | `Create account` | `Start Discovering` (brand §02.3) |
| Continue button label | `Continue` | `Continue` ← ok |

### 🟢 AppCheck Status — OK

```
main.dart AppCheck setup is correct:
- prod: AndroidPlayIntegrityProvider / AppleDeviceCheckProvider ✅
- dev:  AndroidDebugProvider / AppleDebugProvider ✅
```

**⚠️ One action needed for iOS simulator testing:**
- First run on iOS simulator will print a debug token to Xcode console
- Must register that token in: Firebase Console → App Check → iOS app → Debug tokens
- Without this, Cloud Function calls will return UNAUTHENTICATED on simulator

---

## Implementation Plan

### Task A — Font System Update (Aleksandar)
**File:** `lib/src/core/theme.dart` or wherever TextTheme is defined  
**What:**
1. Add to `pubspec.yaml`:
   ```yaml
   google_fonts: ^6.x  # already present
   ```
   Fonts to add via `GoogleFonts`:
   - `playfairDisplay` — display/H1
   - `lora` — body text
   - `instrumentSans` — UI labels, buttons, forms
   - Keep `outfit` as fallback only (or remove)

2. Update `TextTheme` in theme:
   ```dart
   displayLarge: GoogleFonts.playfairDisplay(fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -0.04)
   displayMedium: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.03)
   headlineLarge: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.02)
   bodyLarge: GoogleFonts.lora(fontSize: 17, height: 1.75)
   bodyMedium: GoogleFonts.lora(fontSize: 15, height: 1.6)
   labelLarge: GoogleFonts.instrumentSans(fontSize: 15, fontWeight: FontWeight.w600)
   labelMedium: GoogleFonts.instrumentSans(fontSize: 13, fontWeight: FontWeight.w500)
   ```

### Task B — Primary Color Token Update (Aleksandar)
**Files:** `lib/src/core/theme.dart`, registration_flow.dart, and any file with `#00D9A6` / `teal`  
**What:**
```dart
// Replace:
const teal = Color(0xFF00D9A6);
// With:
const trembleRose = Color(0xFFF4436C);
const trembleRoseLight = Color(0xFFF9839E);
const trembleRoseDark = Color(0xFFC02048);
const signalYellow = Color(0xFFF5C842);
const confirmGreen = Color(0xFF2D9B6F);
const deepGraphite = Color(0xFF1A1A18);
```
**Scope:** Replace teal `#00D9A6` with rose `#F4436C` everywhere — CTA buttons, selected states, checkmarks, icons.

### Task C — Onboarding Copy Update (Aleksandar)
**File:** `lib/src/core/translations.dart`  
**What (English):**
```dart
'onb1_title': 'Meet people in real life',
'onb1_body': 'It runs while you live. You get a nudge when someone compatible is near. No scrolling required.',
'onb2_title': 'Real connections, no algorithms',
'onb2_body': 'Zero swipes. Zero chat rooms. One wave. If they send one back — that\'s a match.',
'onb3_title': 'See who\'s nearby',
'onb3_body': 'See how many people are searching around you right now. A premium view of your proximity world.',
'onb4_title': 'You\'re always in control',
'onb4_body': 'Your location is never stored. Not policy. Architecture. Unmatch or block at any time.',
```
**Also update SLO translations (lines ~646-656) with equivalent Slovenian.**

### Task D — Registration CTA Copy (Aleksandar)
**File:** `lib/src/features/auth/presentation/registration_flow.dart` line ~650  
**What:**
```dart
// Replace:
_stepHeader('Create account'),
// With:
_stepHeader('Create your account'),
// And the final onboarding CTA after photos/consent:
// Currently: 'Continue' → keep as is (brand: Continue is fine for flow steps)
// Final CTA on last page: change to 'Start Discovering'
```

### Task E — AppCheck Debug Token (Aleksandar)
**Manual step before simulator testing:**
1. Run app in iOS simulator: `flutter run --flavor dev --dart-define=FLAVOR=dev`
2. In Xcode console look for line: `[AppCheck] Debug token: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX`
3. Go to: Firebase Console → am---dating-app → App Check → Apps → Tremble iOS (dev)
4. Add debug token
5. Repeat for Android emulator if needed (token printed in Android Studio Logcat)

---

## Priority Order

1. **Task E** — AppCheck debug token (unblocks all simulator testing)
2. **Task C** — Onboarding copy (quick win, no code risk)
3. **Task D** — Registration CTA copy (quick win)
4. **Task B** — Color token (medium effort, high visual impact)
5. **Task A** — Font system (highest effort, most polish)

---

## Scope Note

Tasks A & B together = full brand alignment. Tasks C & D = copy alignment.  
Martin can do C+D as touch-ups. A+B recommended for Aleksandar (deeper theme work).

