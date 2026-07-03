# Plan: Gym Search UX & Premium Spotlight Tutorial Remediation

Plan ID: 20260517-gym-and-tutorial-remediation-v2
Risk Level: MEDIUM
Founder Approval Required: YES
Branch: feature/gym-tutorial-remediation

---

## 1. OBJECTIVE
Provide an intuitive, responsive on-demand Gym Search UX (adding keyboard enter action, an interactive search icon button, and local geographic bias to guarantee real API key matching in Slovenia) and expand the tutorial into a comprehensive 6-step background "set-and-forget" cinematic walkthrough, followed by archiving finished tasks.

---

## 2. SCOPE

### Files to be Modified:
1. **[places_service.dart](file:///Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/lib/src/core/places_service.dart):** Add `locationBias` (centered in Slovenia) to `gymAutocomplete` to prioritize local gyms and prevent empty results when using the real API key in dev.
2. **[gym_search_widget.dart](file:///Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/lib/src/features/gym/presentation/gym_search_widget.dart):** Wire `textInputAction: TextInputAction.search`, add `onSubmitted`, and add an interactive suffix search button inside the input decoration.
3. **[tutorial_notifier.dart](file:///Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/lib/src/features/dashboard/application/tutorial_notifier.dart):** Set `lastStep = 5` to support exactly 6 tutorial slides.
4. **[translations.dart](file:///Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/lib/src/core/translations.dart):** Inject English (`en`) and Slovenian (`sl`) localization copy for Steps 3, 4, and 5 of the tutorial, highly aligning with the "set-and-forget" brand identity.
5. **[premium_tutorial_overlay.dart](file:///Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/lib/src/features/dashboard/presentation/widgets/premium_tutorial_overlay.dart):** Implement coordinate bounds, title, and description logic for all 6 spotlight steps.
6. **[context.md](file:///Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/tasks/context.md):** Update current task.

### Files to be Archived:
* Move `tasks/PLAN_compatibility_visibility_v1.1.md`, `tasks/PLAN_premium_tutorial_flow.md`, and `tasks/TREMBLE_STABILIZATION_OSM_PLAN.md` to `tasks/archive/`.

### What does NOT change:
* Core Firestore write mechanics (`selectedGyms` payload writing).
* Core BLE/motion state restoration triggers.
* Bottom navigation layout structure.

---

## 3. STEPS

### Step 1: Real API Key Gym Search Bias
* **Action:**
  * In `places_service.dart`'s `gymAutocomplete`, inject a `locationBias` circle centered in Slovenia (`latitude: 46.1512, longitude: 14.9955` with a 2,000,000-meter radius) into the POST request body.
  * This guarantees that when a developer searches using a real API key in dev, Google returns Slovenian gyms instead of global/empty matches.
* **Verification:** Run `flutter test` or check logs to verify no syntax errors in `places_service.dart`.

### Step 2: Gym Search Input & Suffix Button
* **Action:**
  * In `gym_search_widget.dart`, implement a robust `void _triggerSearch(String value)` helper that:
    1. Cancels active debounced timer.
    2. Unfocuses the keyboard.
    3. Runs `gymAutocomplete(value)` immediately and updates state.
    4. Shows a beautiful rose SnackBar if results are empty.
  * Update `TextField` inside `gym_search_widget.dart` to have `textInputAction: TextInputAction.search` and `onSubmitted: (value) => _triggerSearch(value)`.
  * Update `suffixIcon` in `TextField` input decoration:
    * If `_isSearching` is true, show `CircularProgressIndicator` (keep existing).
    * If `_searchController.text.isNotEmpty`, show `IconButton` with a search icon linked to `_triggerSearch(_searchController.text)`.
    * Otherwise, show null.
* **Verification:** Run `flutter analyze` to ensure clean imports and widget parameter compliance.

### Step 3: Premium Walkthrough Copy Injection
* **Action:**
  * Add the following keys to `translations.dart` inside the `en` and `sl` maps:
    * **Step 3 (Traveler Mode):**
      * `en`: "Traveling or visiting another city? Enable Traveler Mode to expand your discovery radius or preview upcoming destinations. Tremble adapts dynamically to your new surroundings while maintaining extreme background efficiency."
      * `sl`: "Potuješ ali obiskuješ drugo mesto? Vklopi potovalni način, da razširiš svoj radij iskanja ali predogledaš prihodnje destinacije. Tremble se dinamično prilagodi tvoji novi lokaciji ob minimalni porabi baterije."
    * **Step 4 (Recap vs. Near Miss):**
      * `en`: "Recap shows the places you’ve visited and active events where your paths crossed with other members. Near Miss captures real-time high-fidelity BLE close encounters. Both let you discover who matches your vibe without actively swiping."
      * `sl`: "Recap (zgodovina) prikazuje mesta in dogodke, kjer so se tvoje poti križale z drugimi člani. Near Miss (bližnja srečanja) pa beleži realnočasovne, visoko natančne BLE stike v živo. Oboje brez nenehnega drsanja po ekranu."
    * **Step 5 (Set and Forget):**
      * `en`: "Tremble is designed to be closed. Complete your profile, set your matching criteria, and let the app operate quietly in the background. Go live your life, and we will notify you the moment a genuine physical connection is discovered."
      * `sl`: "Tremble je ustvarjen z namenom, da ga zapreš. Dokončaj svoj profil, določi kriterije ujemanja in pusti, da aplikacija tiho deluje v ozadju. Živi svoje življenje v živo, mi pa te obvestimo takoj, ko zaznamo pravo bližino."
* **Verification:** Verify map entry closing braces and syntactical soundness.

### Step 4: Expand Spotlight Coordinator to 6 Slides
* **Action:**
  * In `tutorial_notifier.dart`, set `static const lastStep = 5` (which makes `lastStep + 1` equal 6 steps: index 0 to 5).
  * In `premium_tutorial_overlay.dart`, implement coordinate configurations inside `_TutorialStep.forIndex`:
    * **Step 3 (Traveler Mode):** Focus on the Settings tab at the bottom right. `spotlightCenter`: `Offset(screenWidth * 0.88, screenHeight - 45 - mediaQuery.padding.bottom)`, `spotlightRadius: 45`, `showCardAtTop: true`.
    * **Step 4 (Recap vs. Near Miss):** Focus on the People/Matches tab at the bottom center-right. `spotlightCenter`: `Offset(screenWidth * 0.62, screenHeight - 45 - mediaQuery.padding.bottom)`, `spotlightRadius: 45`, `showCardAtTop: true`.
    * **Step 5 (Set and Forget):** Dynamic central visual. `spotlightCenter`: `Offset(screenWidth / 2, screenHeight * 0.44)`, `spotlightRadius: 140`, `showCardAtTop: false`.
* **Verification:** Perform build check and static analyzer checks.

### Step 5: Archive Finished Tasks
* **Action:**
  * Move `PLAN_compatibility_visibility_v1.1.md`, `PLAN_premium_tutorial_flow.md`, and `TREMBLE_STABILIZATION_OSM_PLAN.md` to `tasks/archive/`.
  * Update `tasks/context.md` with active and completed actions.
* **Verification:** Verify `/tasks` directory has clean status in git.

---

## 4. RISKS & TRADEOFFS

* **Risk:** The bottom navigation bar coordinates could shift slightly on devices with unique aspect ratios or large notches.
* **Mitigation:** Calculate coordinates dynamically by incorporating `MediaQuery.of(context).size` and `mediaQuery.padding.bottom` instead of using static hardcoded absolute heights.
* **Tradeoff:** Expanding the tutorial to 6 long steps introduces more text, but since we are providing a prominent "Skip" button, users who prefer not to read can easily dismiss it while curious users get a complete, premium understanding of Tremble's "set-and-forget" promise.

---

## 5. VERIFICATION PROTOCOL

1. **Lint/Analyze Check:**
   ```bash
   flutter analyze
   ```
2. **Unit Tests:**
   ```bash
   flutter test
   ```
3. **Build Check:**
   ```bash
   flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev
   ```
