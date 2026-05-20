# PLAN: Tremble Premium Upgrade Flow & Settings Integration (3D Credit-Card Shuffle Edition)

**Plan ID:** `20260518-settings-premium-upgrade-flow-v3`  
**Risk Level:** MEDIUM (Custom 3D layout, PageView stacking transforms, backdrop filter/ImageFiltered blur layers)  
**Founder Approval Required:** YES (Visual contract, layout physics, product package definitions)  
**Branch:** `feature/settings-premium-upgrade`

---

## 1. OBJECTIVE

Create an exceptionally premium, conversion-oriented in-app purchase (IAP) flow inside Tremble. Relocate or add a premium CTA button directly below the "View Profile" button on the Settings screen.
- **Non-Premium Users:** Display a visually matching, brand-identity-compliant CTA button: "Get Tremble Premium".
- **Premium Users:** Replace this button with their current plan/subscription status, accompanied by a smaller secondary "Change Plan" button.
- **Action:** Open a dedicated in-app page (`/premium`) featuring an ultra-premium, brand-compliant **3D horizontal credit-card shuffle carousel** mimicking physical credit cards stacked in layers.
- **Interactive Stacking Physics:** The front card is in full focus, while the background cards are layered, offset, scaled down, and blurred. Swiping triggers a fluid transition where cards shuffle positions with dynamic scaling, depth rotation, and real-time blur transformations.

---

## 2. THE 4 CARDS & PRICING PLANS (BRAND COMPLIANT)

The carousel contains exactly four credit-card style components matching the brand's aesthetic:

1. **Card 1: Tremble Premium**
   - **Visuals:** Deep graphite glassmorphic texture with subtle rose gradient border highlights, metallic signal/calibration logo.
   - **Content:** Title ("Tremble Premium"), price (**7,99 € / Month**), and standard upgrades/features list (50% wider radar scan, unlimited geofence pings, custom themes, advanced filtering matrix).
   - **CTA Button:** "Get the Tremble Premium Plan"

2. **Card 2: Weekend Getaway**
   - **Visuals:** Warm copper/gold glass texture, clean minimalist landscape glyph.
   - **Content:** Title ("Weekend Getaway"), price (**2,99 € / Weekend**), active window (**Friday 7:00 PM to Sunday 7:00 PM**), and upgrades/features list (same as premium tier: 50% wider radar scan, unlimited geofence pings, custom themes, advanced filtering matrix, active during the getaway window).
   - **CTA Button:** "Get the Weekend Getaway Plan"

3. **Card 3: Choices (Lifetime / Yearly / Monthly)**
   - **Visuals:** Deep graphite overlay, silver calibration badge.
   - **Content:** Plan durations (Monthly, Yearly, Lifetime) with their respective savings, pricing, and benefits.
     - *Monthly:* 7.99 € / Month
     - *Yearly:* 59.99 € / Year (~5,00 € / month, Save 37%)
     - *Lifetime:* 149.99 € / One-time
   - **CTA Button:** "Get the Duration Choice Plan" (dynamically highlights and selects active duration)

4. **Card 4: Free Tier (What you have as a free user)**
   - **Visuals:** Frosted glass sheet, minimalist graphite border.
   - **Content:** Listing of current basic features (Gym mode access, 30-min local radar, standard mutual wave limit).
   - **CTA Button:** 
     - *If user is basic:* "Current Plan" (Disabled, styled in muted graphite).
     - *If user is currently Premium:* "Want to switch back to free plan?" (Triggers confirmation/downgrade warning modal).

---

## 3. SCOPE

- **Settings Screen Integration:**
  - `lib/src/features/settings/presentation/settings_screen.dart` — Modify `_buildProfileSection` to render the compact conditional upgrade CTA or subscription status.
- **Routing Configuration:**
  - `lib/src/core/router.dart` — Register the dedicated `/premium` GoRouter path.
- **Premium Upgrade Screen (New File):**
  - `lib/src/features/settings/presentation/premium_screen.dart` — Create `PremiumUpgradeScreen` housing the custom 3D shuffle stack controller, dynamic backdrop filters, indicators, and localized package action buttons.
- **Out of Scope:**
  - Writing real StoreKit/Google Play Billing transaction logic (gated by RevenueCat legal setup `BLOCKER-003`). Transactions are simulated/mocked for UI validation.

---

## 4. DETAILED IMPLEMENTATION STEPS

### Step 1: Settings Screen Button & Status Rendering
In `_buildProfileSection(AuthUser user)` in `settings_screen.dart`, right after the `_t('profile_card_view')` outlined button, append the following elements:

```dart
// Check user's premium status
final isPremium = user.isPremium;

if (!isPremium) ...[
  const SizedBox(height: 12),
  SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: () => context.push('/premium'),
      icon: const Icon(LucideIcons.sparkles, size: 18, color: Colors.white),
      label: Text(
        _t('get_tremble_premium'),
        style: GoogleFonts.instrumentSans(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF4436C), // Brand primary rose
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
        elevation: 0,
      ),
    ),
  ),
] else ...[
  const SizedBox(height: 12),
  GlassCard(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    useGlassEffect: true,
    child: Row(
      children: [
        const Icon(LucideIcons.checkCircle, color: Color(0xFFF5C842), size: 20), // Signal Yellow
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t('active_plan'),
                style: GoogleFonts.instrumentSans(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              Text(
                "Tremble Premium",
                style: GoogleFonts.instrumentSans(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => context.push('/premium'),
          child: Text(
            _t('change_plan'),
            style: GoogleFonts.instrumentSans(
              color: const Color(0xFFF4436C), // Premium Rose link
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    ),
  ),
]
```

### Step 2: Register `/premium` Route
Add the dedicated route to `lib/src/core/router.dart` inside the `GoRouter` path declarations:

```dart
GoRoute(
  path: '/premium',
  builder: (context, state) => const GradientScaffold(
    child: PremiumUpgradeScreen(),
  ),
),
```

### Step 3: Custom Card Shuffle Engine Physics (`premium_screen.dart`)
We will build the credit-card stacked shuffle layout by using a `PageView.builder` with `viewportFraction: 0.76` and an `AnimatedBuilder` tracking the dynamic page offset. 

#### Animation Calculations (3D Stack & Blur Interpolation):
For a page at index `index` given the active controller coordinate `pageValue`:
- **Offset calculation:** `double offset = index - pageValue;`
- **Translation Shift (Stacked Cards Effect):** 
  To make background cards stack closely behind the front card rather than scrolling linearly off-screen:
  `double translationX = -offset * (screenWidth * 0.38);`
- **3D Rotation (Y-axis tilt):** `double rotY = -offset * 0.28;` (creates realistic credit-card perspective).
- **Scale contraction:** `double scale = 1.0 - (offset.abs() * 0.16);`
- **Dynamic Blur calculation:** 
  Wrap background cards with `ImageFiltered` applying a blur filter that smoothly clears as the card approaches the front:
  `double blurSigma = offset.abs() * 5.0;`
- **Opacity reduction:** Background cards use an opacity of `1.0 - (offset.abs() * 0.45)`.

#### Widget Architecture inside `PremiumUpgradeScreen`:
```dart
class PremiumUpgradeScreen extends ConsumerStatefulWidget {
  const PremiumUpgradeScreen({super.key});

  @override
  ConsumerState<PremiumUpgradeScreen> createState() => _PremiumUpgradeScreenState();
}

class _PremiumUpgradeScreenState extends ConsumerState<PremiumUpgradeScreen> {
  late PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.76)
      ..addListener(() {
        setState(() {
          _currentPage = _pageController.page ?? 0.0;
        });
      });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Render Transparent Title/Back App Bar
    // 2. Render PageView.builder containing the 4 customized Card Packages
    // 3. For each card: Apply Transform.translate, Transform.scale, Matrix4.rotationY, and ImageFiltered (for real-time blur)
    // 4. Render sleek dynamic Indicator Dots below
    // 5. Render context-specific payment/action button below the stack matching active card index
  }
}
```

---

## 5. BRAND COMPLIANCE & VISUAL CONTRACT

The screen layout MUST utilize existing design constants:
- **Default Dark Theme:** Deep graphite background (`0xFF1A1A18`) with transparent, elegant overlays.
- **Colors:** Primary Rose (`#F4436C`) for call-to-actions, Signal Yellow (`#F5C842`) for highlights, Deep Graphite (`#1A1A18`) for card body fills, and Warm Cream (`#FAFAF7`) for typography.
- **Typography:** `GoogleFonts.instrumentSans()` for interface copy and Lora/Playfair Display for headers.
- **Steep Depth Shadows:** Cards should feature dense graphite shadow elevations to make the overlapping 3D stack visually pop against the background.

---

## 6. VERIFICATION PROTOCOL

1. **Verify Screen Navigation:**
   - Tap Settings CTA -> verify `/premium` navigation matches route declarations.
2. **Shuffle Animation Quality Check:**
   - Verify that background cards are blurred and layered correctly behind the front card.
   - Verify that swiping dynamically scales down the old card, moves the new card forward, removes its blur, and translates its coordinate smoothly.
3. **Responsive Spacing Verification:**
   - Run layout tests across multiple mobile sizes (iPhone SE, iPhone 15 Pro Max) to ensure no viewport/vertical size overflows are triggered.
4. **Compile Gates (Clean Run):**
   ```bash
   flutter analyze
   flutter test
   flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev
   ```

---

## 7. RESOLVING COMPILATION & DEPRECATION PROBLEMS IN PREMIUM_SCREEN.DART

To make `/lib/src/features/settings/presentation/premium_screen.dart` compile completely error and warning free, the following updates must be made:

1. **Unused Import Removal (Line 9):**
   - Delete `import '../../../shared/ui/glass_card.dart';` since the screen handles its own container designs or uses built-in cards.
   
2. **Unused Variable 'isPremium' (Line 262):**
   - Delete the local variable `final isPremium = user.isPremium;` in the primary `build` method.

3. **BoxDecoration blurRadius Error (Lines 384, 397):**
   - `BoxDecoration` has no direct `blurRadius` parameter. Modify the background glow decoration containers to use `boxShadow`:
     ```dart
     decoration: BoxDecoration(
       shape: BoxShape.circle,
       boxShadow: [
         BoxShadow(
           color: const Color(0xFFF4436C).withValues(alpha: 0.08),
           blurRadius: 100,
           spreadRadius: 50,
         ),
       ],
     ),
     ```
     (Do the equivalent for the second glow Container with `Color(0xFFF5C842)` and a blur radius of 80).

4. **Deprecations on 'translate' and 'scale' in Matrix4 (Lines 488, 489):**
   - The overloaded `translate()` and `scale()` on `Matrix4` are deprecated. Replace them with their non-deprecated double-precision counterparts:
     ```dart
     ..translateByDouble(translationX, 0.0, -offset.abs() * 100.0)
     ..scaleByDouble(scale)
     ```

5. **Colors.white87 Compiler Error (Line 734):**
   - `Colors.white87` is not a standard member of the `Colors` class. Change this to standard white with values:
     ```dart
     color: Colors.white.withValues(alpha: 0.87),
     ```

6. **Unused Variable 'accent' (Line 755):**
   - Delete `final accent = data['accent'] as Color;` from the beginning of `_buildCTAButton` as it is not used in the button background calculations.

---

## 8. EXECUTION STATUS — 2026-05-18

**Status:** Implemented locally.

**Completed:**
- Added the conditional Settings profile-section Premium CTA/status block directly below "View profile card".
- Registered `/premium` in `lib/src/core/router.dart` using `GradientScaffold(child: PremiumUpgradeScreen())`.
- Implemented `PremiumUpgradeScreen` with a `PageView.builder` credit-card shuffle carousel, Y-axis transforms, scale contraction, translational stacking, opacity depth, and `ImageFiltered` blur.
- Mapped all four approved cards in order: Tremble Premium, Weekend Getaway, Choices, Free Tier.
- Corrected Weekend Getaway to **2,99 € / Weekend** with the **Friday 7:00 PM to Sunday 7:00 PM** window.
- Kept billing simulated/local only because BLOCKER-003 still blocks RevenueCat/legal setup; no RevenueCat keys, StoreKit config, or billing APIs were introduced.
- Resolved the active compile/deprecation issues listed in Section 7.
- Added `test/features/settings/premium_screen_test.dart` for the premium card order/pricing contract.

**Verification run in this session:**
- `flutter test test/features/settings/premium_screen_test.dart` — RED before implementation, PASS after implementation.
- `dart format lib/src/features/settings/presentation/premium_screen.dart lib/src/features/settings/presentation/settings_screen.dart lib/src/core/router.dart lib/src/core/translations.dart test/features/settings/premium_screen_test.dart` — PASS.
- `flutter analyze` — PASS.
- `flutter test` — PASS (62/62).
- `flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev` — PASS.

**Still gated outside code:**
- Real purchases/subscription state remain blocked by RevenueCat/legal setup.
- Physical iOS verification remains blocked by provisioning (BLOCKER-005).
