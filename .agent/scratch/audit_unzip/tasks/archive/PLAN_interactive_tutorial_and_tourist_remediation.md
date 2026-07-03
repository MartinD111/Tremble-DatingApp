# Plan: Interactive Tutorial Flow & Passive Tourist Icon Remediation

Plan ID: 20260517-interactive-tutorial-and-tourist-remediation
Risk Level: MEDIUM
Founder Approval Required: YES
Branch: feature/interactive-tutorial-remediation

---

## 1. OBJECTIVE
Implement a highly engaging, action-driven "Quick Tutorial" flow where users must click active flashing UI coordinates to advance through the app features (with a strictly transparent, non-blurred overlay), and convert the legacy "Traveler Mode" into a purely passive visual "Tourist" badge with zero functional side-effects, strictly matching the premium Tremble visual identity.

---

## 2. SCOPE

### Files Affected:
1. **lib/src/core/translations.dart:** Update English and Slovenian translation blocks to match the new interactive tutorial stages. Convert the old Traveler Mode text to the passive "Tourist Badge" tooltip explanation.
2. **lib/src/features/dashboard/application/tutorial_notifier.dart:** Redesign the state machine to include a `showOptIn` state, and handle the sequential 6-step triggers based on user interaction.
3. **lib/src/features/dashboard/presentation/widgets/premium_tutorial_overlay.dart:** Remove `BackdropFilter` background blurring. Implement a custom hit-test override (`RenderProxyBox`) to allow pointer clicks to pass directly through the spotlight circle to the underlying buttons, while blocking clicks everywhere else.
4. **lib/src/features/dashboard/presentation/widgets/spotlight_painter.dart:** Ensure the overlay is a solid semi-transparent color (e.g., `0xCC1A1A18`) without image blur, and ensure the pulse ring uses the brand Rose (`#F4436C`).
5. **lib/src/features/dashboard/presentation/home_screen.dart:** Inject the startup "Opt-In" bottom sheet logic. Attach glowing/pulsing animation states to the Dumbbell, Clock, Navigation Bar items, and Central Radar Button when their corresponding step is active. Add programmatic tab-switching callbacks for the Matches and Settings popup steps.
6. **lib/src/features/settings/presentation/settings_screen.dart:** Completely remove the legacy manual "Traveler Mode" switch tile.
7. **lib/src/features/profile/presentation/widgets/profile_card_preview.dart:** Add logic to render a subtle Tourist badge (✈️ or 🌴) next to the age if `user.currentCountry != user.homeCountry`.

### What does NOT change:
* The core BLE scanning and Proximity geofencing engines (no functional changes to discovery radius based on the tourist badge).
* Firebase Auth or complex database schemas.

---

## 3. STEPS

### Step 1: Startup "Quick Tutorial" Opt-In Sheet
- **Action:** 
  - Update `TutorialNotifier` to emit an initial "opt-in" state instead of automatically starting.
  - In `home_screen.dart`, when this state is active, present a premium glassmorphic bottom dialog asking: *"Želiš kratek vodič?"* / *"Want a quick tutorial?"*.
  - Buttons: **Da, pokaži mi** / **Ne, hvala**.
  - If "No", mark the tutorial as permanently completed in `SharedPreferences` and exit. If "Yes", begin Step 1 of the interactive flow.
- **Verification:** Clear preferences, launch app, and verify the bottom sheet appears. Click "No" and verify it does not appear on subsequent launches.

### Step 2: Transparent Spotlight Overlay & Click-Through Hit Testing
- **Action:** 
  - Remove `ImageFilter.blur(sigmaX: 5, sigmaY: 5)` from `premium_tutorial_overlay.dart`.
  - Wrap the `CustomPaint` overlay in a custom `SingleChildRenderObjectWidget` that overrides `hitTest()`.
  - Logic: If `(tapPosition - spotlightCenter).distance <= spotlightRadius`, return `false` (let the tap pass through to the real button below). Otherwise, return `true` (absorb the tap).
- **Verification:** Run the app. Verify the background is darkened but perfectly sharp (not blurred). Verify clicking inside the highlighted circle presses the button underneath, but clicking outside does nothing.

### Step 3: Interactive Flashing Sequence State Machine
- **Action:** Implement the 6 steps sequentially, highlighting the specific `home_screen.dart` element:
  - **Step 1 (Dumbbell - Top Left):** Pulse dumbbell. Tap opens Gym Mode sheet. Display card: *"Common grounds: Switch to Gym Mode or Run Mode..."*. Advance on interaction.
  - **Step 2 (Clock - Top Right):** Pulse schedule clock. Tap opens schedule modal. Display: *"You can set a schedule..."*. Advance on interaction.
  - **Step 3 (Map Tab - Nav Bar):** Pulse Map tab. Tap switches to Map view. Display: *"Tu imaš vidno kje so single..."*. Advance on interaction.
  - **Step 4 (Matches Tab - Nav Bar):** Pulse Matches tab. Tap switches view and shows a center popup: *"Tu se ti prikažejo ljudje..."*. Clicking the "Got it!" button inside the popup programmatically returns the user to the Radar (Index 0) and advances the step.
  - **Step 5 (Settings Tab - Nav Bar):** Pulse Settings tab. Tap switches view and shows popup: *"Nastavitve: Tu si nastavljaš varnostne cone..."*. "Got it!" returns to Radar.
  - **Step 6 (Radar Scan - Center):** Pulse the central radar button. Clicking it starts scanning, shows: *"That's it! Now put your phone away..."* and finishes the tutorial.
- **Verification:** Step through the entire flow manually on a device/simulator. Ensure the state advances correctly upon real UI interaction.

### Step 4: Purely Passive Tourist Badge Remediation
- **Action:** 
  - Open `settings_screen.dart` and delete the `SwitchListTile` for Traveler Mode.
  - Open `profile_card_preview.dart` and `profile_detail_screen.dart`.
  - Add logic: `final isTourist = user.currentCountry != null && user.homeCountry != null && user.currentCountry != user.homeCountry;`
  - If `isTourist` is true, render a Rose-accented (`#F4436C`) ✈️ or 🌴 icon next to the user's age.
  - Wrap it in a `Tooltip` or `GestureDetector` that shows a micro-popup: *"Na obisku"* / *"Visiting"*.
- **Verification:** Mock a user with a different current country. Open their profile card and verify the icon appears and has zero impact on BLE discovery range.

### Step 5: Visual Brand Compliance
- **Action:** 
  - Ensure all newly added UI elements strictly adhere to `tremble-brand-identity.html`.
  - Fonts: Lora for headings, Instrument Sans for body text.
  - Colors: Deep Graphite (`#1A1A18`) for backgrounds, exact Rose (`#F4436C`) for glowing pulses.
  - No default Material blue (`#2196F3`).
- **Verification:** Visual inspection of all tutorial cards against the brand guide.

---

## 4. RISKS & TRADEOFFS
- **Risk:** Calculating the exact dynamic coordinates for the Spotlight (especially for the Navigation Bar tabs) across different screen sizes (iPhone SE vs Pro Max) might cause misalignment.
- **Mitigation:** Use global keys (`GlobalKey`) attached to the target widgets to dynamically calculate their exact screen coordinates via `RenderBox.localToGlobal` rather than hardcoding offsets.
- **Tradeoff:** Forcing programatic tab navigation and modal popping inside the tutorial creates tight coupling between `TutorialNotifier` and the routing/navigation layer.

---

## 5. VERIFICATION
- **Static Analysis:** `flutter analyze` must pass with zero warnings.
- **Unit Tests:** `flutter test` - write test inside `tutorial_notifier_test.dart` to verify state transitions (OptIn -> Step 1 -> ... -> Complete).
- **Compilation:** `flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev` must compile successfully.
- **Device Test:** Run on physical device/simulator to verify hit-test pass-through logic functions correctly without jank.
