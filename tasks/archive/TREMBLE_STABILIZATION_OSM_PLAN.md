# TREMBLE Physical Device Stabilization & OSM Migration Plan
**Date:** 2026-05-09
**Status:** DRAFT (Ready for Approval)

## 1. UI & Branding Remediation

### 1.1 Splash Screen "White Box" Fix
*   **Problem:** Splash screen logo displays a white square background on physical devices.
*   **Root Cause:** `flutter_native_splash.yaml` points to `tremble_splash_source.png` which contains a baked-in white background.
*   **Solution:**
    1.  Switch to `Logo/tremble_icon_clean_transparent.png`.
    2.  Update `flutter_native_splash.yaml`:
        ```yaml
        flutter_native_splash:
          color: "#1A1A18"
          image: "Logo/tremble_icon_clean_transparent.png"
          android: true
          ios: true
          fullscreen: true
          android_12:
            color: "#1A1A18"
            image: "Logo/tremble_icon_clean_transparent.png"
            icon_background_color: "#1A1A18"
        ```
    3.  Regenerate assets: `dart run flutter_native_splash:create`

### 1.2 Radar Heart Logo Centering
*   **Problem:** Central logo in the radar button is visually off-center (too high).
*   **File:** `lib/src/shared/widgets/tremble_radar_heart.dart`
*   **Solution:**
    - Adjust `canvas.translate` in `_RadarHeartPainter.paint`.
    - Current: `canvas.translate(centerX - (3.5 * scale), centerY - (20.0 * scale))`
    - Change to: `canvas.translate(centerX - (3.5 * scale), centerY - (16.0 * scale))` (shift down by 4 units).
    - Increase base scale by 10% to make it pop: `final scale = (size.width / 220.0) * 1.25;`

### 1.3 Radar Sweep "3 o'clock" Seam Fix
*   **Problem:** A sharp red line/duplicate appears at the 3 o'clock position (0 radians).
*   **File:** `lib/src/shared/widgets/radar_painter.dart`
*   **Root Cause:** `SweepGradient` doesn't handle the wrap-around perfectly when `startAngle` goes negative.
*   **Solution:**
    - Rotate the entire canvas by `-pi/2` so 0 radians is at 12 o'clock, OR
    - Adjust `SweepGradient` to use a tiny bit of padding at the seam:
      ```dart
      colors: [Colors.transparent, brandColor.withOpacity(0.0), brandColor.withOpacity(0.3)],
      stops: [0.0, 0.05, 1.0]
      ```

---

## 2. Native Bridge Stabilization (Gym Mode)

### 2.1 Resolving `MissingPluginException`
*   **File:** `ios/Runner/AppDelegate.swift`
*   **Problem:** Custom plugin registration is failing or being wiped by Flutter lifecycle.
*   **Solution:**
    1.  Verify the `MethodChannel` name matches `app.tremble/motion` exactly in both Dart and Swift.
    2.  Ensure `GeneratedPluginRegistrant.register(with: self)` is called **first**.
    3.  Move the `TrembleNativePlugin` registration inside the `didFinishLaunchingWithOptions` block, using the explicit registrar name.
    4.  Verify that `motionMethodChannel` is properly retained in the `TrembleNativePlugin` instance.

---

## 3. Global OpenStreetMap Migration (Protomaps)

### 3.1 Infrastructure: The "Set and Forget" Worldwide Stack
We will use **Protomaps + Cloudflare R2 + Workers** to avoid recurring Google Maps API fees and high egress costs.

1.  **Map Data:** 
    - Download the **Planet PMTiles** file from [build.protomaps.com](https://build.protomaps.com). (~100GB).
    - This file contains vector data for the entire world.
2.  **Hosting (Cloudflare R2):**
    - Create a bucket: `tremble-maps-planet`.
    - Upload `planet.pmtiles`.
    - **Cost:** ~$1.50/mo for storage. $0 egress.
3.  **Tile Server (Cloudflare Worker):**
    - Deploy the Protomaps PMTiles Worker template to Cloudflare.
    - Configure it to read from your R2 bucket.
    - You now have a global vector tile endpoint: `https://maps.trembledating.com/{z}/{x}/{y}.mvt`
4.  **Flutter Map Implementation:**
    - Replace `google_maps_flutter` with `flutter_map`.
    - Add dependencies: `flutter_map`, `latlong2`, `vector_map_tiles_pmtiles`.
    - Configure `TileLayer` to use the Cloudflare Worker URL.

### 3.2 Visual Logic: Fog of War → Circles
*   **Action:** Remove heatmap/fog logic from the map screens.
*   **New Design:** 
    - Use `CircleLayer` in `flutter_map`.
    - Each "found" match displays a soft-rose circle with a 100m - 500m radius (proximity, not precision).
    - Circles should have a blurred edge or a gradient fill to maintain the "Tremble" glassmorphic feel.

---

## 4. Verification Protocol
1.  **Build Check:** `flutter build ios --flavor dev --dart-define=FLAVOR=dev`
2.  **Logo Audit:** Verification on physical device screen (Splash + Radar).
3.  **Bridge Test:** Open Gym Mode on physical iOS device; check logs for "Motion Service Started".
4.  **Map Test:** Spoof location to New York, Tokyo, and London to verify worldwide map tiles are loading from Cloudflare R2.

---
**Founder Approval Required: YES**
