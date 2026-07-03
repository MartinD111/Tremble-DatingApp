# PLAN: On-Device Bug Fixes
**Plan ID:** 20260517-device-bug-fixes  
**Risk Level:** MEDIUM  
**Founder Approval Required:** NO  
**Branch:** `fix/device-bug-fixes`
**Status:** ✅ Completed locally — 2026-05-17

**Verification completed:**
- `dart format lib/main.dart lib/src/features/dashboard/presentation/home_screen.dart lib/src/features/auth/presentation/login_screen.dart lib/src/features/auth/presentation/widgets/registration_steps/intro_slide_step.dart lib/src/features/auth/presentation/radar_background.dart`
- `flutter analyze`
- `flutter test` (60/60)
- `flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev`
- `plutil -lint ios/Runner.xcodeproj/project.pbxproj ios/Runner/Info.plist`
- `flutter build ios --debug --flavor dev --dart-define=FLAVOR=dev --no-codesign`

**Remaining manual check:** physical iPhone verification is still blocked by Apple provisioning (BLOCKER-005).

---

## 1. OBJECTIVE

Fix all 5 bugs discovered during first physical device run on iPhone 15, so the app is stable and visually correct for TestFlight distribution.

---

## 2. BUGS IDENTIFIED

### BUG-001 — Bottom Overflow 15px (ON-DEVICE ARCHITECTURE screen)
**File:** `lib/src/features/auth/presentation/widgets/registration_steps/intro_slide_step.dart`  
**Root cause:** The screen uses `SafeArea` at the top but the pinned "Continue" button at the bottom has a fixed `EdgeInsets.fromLTRB(24, 8, 24, 24)` padding. When the **software keyboard** appears (e.g., on the previous name-entry step and user quickly swipes), it doesn't account for `viewInsets.bottom`. The layout overflows by exactly the keyboard-safe-area delta (~15px on iPhone 15 dynamic island).  
**Fix:** Wrap the outermost widget in `Scaffold` with `resizeToAvoidBottomInset: true`, or add `MediaQuery.of(context).viewInsets.bottom` to the bottom padding of the Continue button container. The simplest fix is adding `bottom: SafeArea` wrapping on the bottom padding.

```dart
// BEFORE (line 237)
padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),

// AFTER
padding: EdgeInsets.fromLTRB(24, 8, 24, 
  MediaQuery.of(context).padding.bottom + 24),
```

---

### BUG-002 — Font Not Loading on First Cold Boot (Splash screen)
**File:** `lib/main.dart`  
**Root cause:** Google Fonts are fetched asynchronously over the network on first boot. The first frames render before the font assets are cached locally, resulting in the system fallback font being shown until fonts download. This is visible as "Tremble" / "DELUJE, MEDTEM KO ŽIVIŠ." rendering in the wrong typeface for ~0.5-1s on first launch.  
**Fix:** Pre-cache fonts in `main()` before `runApp()` using `GoogleFonts.pendingFonts()` (Flutter caches them after first download). For offline safety, also bundle fonts as local assets in `pubspec.yaml` instead of relying on CDN.

Short-term fix (main.dart):
```dart
// After WidgetsFlutterBinding.ensureInitialized()
await GoogleFonts.pendingFonts([
  GoogleFonts.playfairDisplay(),
  GoogleFonts.lora(),
  GoogleFonts.instrumentSans(),
]);
```

Long-term fix: Add font files to `assets/fonts/` and declare them in `pubspec.yaml` so they load from the bundle, not the network.

---

### BUG-003 — White Border + Language Selector Cutoff on Login Screen
**File:** `lib/src/features/auth/presentation/login_screen.dart`  
**Root cause:** The `SingleChildScrollView` wrapping the login content has `padding: const EdgeInsets.all(30)`. On iPhone 15 with the Dynamic Island, the scroll content ends near the home indicator, and the language selector pill (line 344-393) is positioned at the very bottom with only `SizedBox(height: 30)` above it. In light mode, the `RadarBackground` renders a whitish surface behind the scroll area, creating a visual "white border" effect. The language pill is partially obscured/cut off by the system home indicator area.  
**Fix:**
1. Change the `SingleChildScrollView` bottom padding to account for safe area: `padding: EdgeInsets.fromLTRB(30, 30, 30, MediaQuery.of(context).padding.bottom + 30)`
2. Remove the white/light background artifact from `RadarBackground` in light theme — ensure it uses `Colors.transparent` or the brand cream `#FAFAF7` with no solid white border.

---

### BUG-004 — On-Device Pixel Rounding Issue
**Affected screens:** Various (observed generally on physical device)  
**Root cause:** Physical device (iPhone 15, 3x pixel density) renders fractional pixel values differently from the simulator. Widgets using `const EdgeInsets` with odd values (e.g., `SizedBox(height: 15)`) can cause sub-pixel rendering artifacts. The `edgeToEdge` system UI mode (`SystemUiMode.edgeToEdge` in `main.dart`) can also create unexpected layout shifts when combined with non-adaptive padding.  
**Fix:** 
1. Audit all fixed pixel values in onboarding screens — replace odd numbers with even values.
2. Where `SafeArea` is used, ensure it wraps the entire `Scaffold` body, not just the Column.
3. For the `edgeToEdge` mode: ensure all screens that use it also handle `MediaQuery.of(context).padding.bottom` for bottom-anchored elements.

---

### BUG-005 — Tutorial Crash: "Cannot use ref after widget was disposed" (**CRITICAL**)
**File:** `lib/src/features/dashboard/presentation/home_screen.dart` line 135  
**Root cause:** Confirmed by LLDB stack trace. The crash happens when:
1. User completes onboarding → Router redirects to `/` (HomeScreen mounts)
2. `_showTutorialOptInSheet()` is called and presents the bottom sheet
3. The router fires again (profile reloads) → HomeScreen rebuilds or unmounts briefly  
4. User taps "Yes, show me" — the `onPressed` callback fires **after** the widget has been disposed
5. `ref.read(tutorialProvider.notifier)` throws: `"Bad state: Cannot use ref after the widget was disposed"`

**Root cause in code (line 153-158):**
```dart
onPressed: () {
  ref.read(navIndexProvider.notifier).state = 0;        // ← CRASH HERE
  ref.read(selectedRadarModeProvider.notifier).state = RadarModeKind.gym;
  ref.read(tutorialProvider.notifier).startTutorial();
  if (ctx.mounted) Navigator.pop(ctx);
},
```
The callback captures `ref` from the outer `ConsumerStatefulElement`, which is disposed by the time the user taps.

**Fix:** Use the bottom sheet's own `ctx` context to read providers, OR capture the notifier references **before** showing the sheet (outside the `async` gap):
```dart
void _showTutorialOptInSheet(String lang) {
  // Capture notifiers BEFORE showing sheet — safe from disposal
  final tutorialNotifier = ref.read(tutorialProvider.notifier);
  final navNotifier = ref.read(navIndexProvider.notifier);
  final radarNotifier = ref.read(selectedRadarModeProvider.notifier);

  showModalBottomSheet(
    context: context,
    ...
    builder: (ctx) {
      ...
      onPressed: () {
        navNotifier.state = 0;
        radarNotifier.state = RadarModeKind.gym;
        tutorialNotifier.startTutorial();
        if (ctx.mounted) Navigator.pop(ctx);
      },
    }
  );
}
```

Also: for the "No, thanks" path (line 133-138):
```dart
// BEFORE
onPressed: () async {
  await ref.read(tutorialProvider.notifier).completeTutorial(); // ← disposed ref
  if (ctx.mounted) Navigator.pop(ctx);
},

// AFTER — capture before sheet opens
final tutorialNotifier = ref.read(tutorialProvider.notifier);
onPressed: () async {
  await tutorialNotifier.completeTutorial();
  if (ctx.mounted) Navigator.pop(ctx);
},
```

---

### BUG-006 — Firebase Bundle ID Mismatch Warning (from LLDB logs)
**File:** `ios/Runner.xcodeproj/project.pbxproj` (Firebase build script, line 545)  
**Root cause:** The Firebase build phase shell script checks for:
- `"com.pulse.dev.aleks" | "com.pulse"` → copies Dev plist  
- `"tremble.dating.app"` → copies Prod plist

But now that the Dev bundle ID is `tremble.dating.app.dev`, **neither branch matches**, so the old `GoogleService-Info.plist` (with `com.pulse`) from the root Runner folder is used. Firebase logs: `"Bundle ID is inconsistent with GoogleService-Info.plist"`.  
**Fix:** Update the shell script to also match `tremble.dating.app.dev`:
```bash
# BEFORE
"com.pulse.dev.aleks" | "com.pulse")

# AFTER  
"com.pulse.dev.aleks" | "com.pulse" | "tremble.dating.app.dev")
```

---

## 3. IMPLEMENTATION ORDER

| Priority | Bug | Effort | Impact |
|----------|-----|--------|--------|
| 🔴 P0 | BUG-005 Tutorial Crash | 15 min | Crash on every new install |
| 🔴 P0 | BUG-006 Firebase mismatch | 5 min | All Firebase calls broken in dev |
| 🟡 P1 | BUG-001 Overflow 15px | 10 min | Visual defect on device |
| 🟡 P1 | BUG-003 White border + language cutoff | 15 min | Visual defect + UX issue |
| 🟢 P2 | BUG-002 Font first load | 20 min | Minor visual flicker |
| 🟢 P2 | BUG-004 Pixel rounding | 30 min | Minor visual artifacts |

---

## 4. VERIFICATION

After each fix:
```bash
flutter analyze
flutter test
flutter run -d [device_id] --flavor dev --dart-define=FLAVOR=dev
```

Manual device checks:
- [ ] Tap "Yes, show me" on tutorial opt-in — no crash
- [ ] Firebase logs: no "Bundle ID inconsistent" warning  
- [ ] ON-DEVICE ARCHITECTURE screen: no overflow warning with keyboard open
- [ ] Login screen: language pill fully visible, no white border
- [ ] Cold boot: fonts load correctly on first frame

---

## 5. FILES TO MODIFY

| File | Bug |
|------|-----|
| `lib/src/features/dashboard/presentation/home_screen.dart` | BUG-005 |
| `ios/Runner.xcodeproj/project.pbxproj` | BUG-006 |
| `lib/src/features/auth/presentation/widgets/registration_steps/intro_slide_step.dart` | BUG-001 |
| `lib/src/features/auth/presentation/login_screen.dart` | BUG-003 |
| `lib/main.dart` | BUG-002 |
| Various onboarding screens | BUG-004 |
