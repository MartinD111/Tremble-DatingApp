# Remediation Plan: iOS Stabilization & Global OSM Migration
**Date:** 2026-05-09
**Status:** Pending Approval
**Objective:** Resolve UI regressions, fix native bridge crashes, and migrate from Google Maps to a self-hosted Global OpenStreetMap (Protomaps) infrastructure.

---

## 1. UI & Branding Polish

### 1.1 Splash Screen Transparency Fix
*   **Problem:** Splash screen logo displays a white square background on physical devices.
*   **Root Cause:** `flutter_native_splash` configuration is likely missing a transparent background or the background color is forced to white instead of the brand graphite (#1A1A18).
*   **Solution:** 
    1.  Verify `tremble-logo-master.png` transparency.
    2.  Update `flutter_native_splash.yaml`:
        ```yaml
        color: "#1A1A18"
        color_dark: "#1A1A18"
        ```
    3.  Run `dart run flutter_native_splash:create`.

### 1.2 Radar Central Logo Centering & Scaling
*   **Problem:** Heart/Fingerprint logo is visually off-center and too small.
*   **Root Cause:** Mathematical center of the `Path` in `TrembleRadarHeart` doesn't match the visual weight.
*   **Solution:**
    1.  Locate `_RadarHeartPainter` in `tremble_radar_heart.dart`.
    2.  Apply a `canvas.translate(dx, dy)` with small values (e.g., -2, -2) to manually center.
    3.  Increase the scale factor by ~15% (from current e.g., 0.8 to 0.95).

### 1.3 Radar Animation "3 o'clock" Seam Fix
*   **Problem:** A duplicate or sharp red line appears at the 0/360 degree mark (3 o'clock).
*   **Root Cause:** `SweepGradient` in `radar_background.dart` has a non-matching start/end color transition at the wrap-around point.
*   **Solution:**
    1.  Modify `SweepGradient` stops.
    2.  Ensure the first stop (0.0) and last stop (1.0) both approach 0.0 opacity or match the background perfectly to hide the seam.

---

## 2. Native Bridge Stabilization

### 2.1 Gym Mode Crash (MissingPluginException)
*   **Problem:** `MissingPluginException` for `app.tremble/motion`.
*   **Root Cause:** Native `MethodChannel` registration in `AppDelegate.swift` is not being hit or is misconfigured for the current app lifecycle.
*   **Solution:**
    1.  Refactor `AppDelegate.swift` to ensure `GeneratedPluginRegistrant.register(with: self)` is called before custom channel setups.
    2.  Verify the channel name matches exactly between `NativeMotionService.dart` and `AppDelegate.swift`.
    3.  Ensure the `FlutterMethodChannel` is retained as a class property in `AppDelegate`.

---

## 3. Global OpenStreetMap Migration (Protomaps)

### 3.1 Infrastructure Setup (The "Set and Forget" World)
*   **Step 1: Get the Data**
    -   Download the **Planet PMTiles** file (approx. 100GB) from `protomaps.com`. This file contains the entire world's vector data.
*   **Step 2: Cloudflare R2 Upload**
    -   Create a new bucket (e.g., `tremble-maps`).
    -   Upload the `planet.pmtiles` file.
*   **Step 3: Worker Deployment**
    -   Deploy a Protomaps-compatible Cloudflare Worker (standard open-source template).
    -   This Worker will transform XYZ tile requests from the app into bytes served directly from the PMTiles file on R2.
    -   **Cost:** ~$1.50/mo for storage. $0/mo for bandwidth/egress.

### 3.2 Flutter Map Implementation
*   **Replace Dependency:** Swap `google_maps_flutter` for `flutter_map` + `latlong2`.
*   **Config:**
    1.  Remove Google Maps API keys from `Info.plist` and `AndroidManifest.xml`.
    2.  Set up `FlutterMap` widget with a `TileLayer`.
    3.  Point `urlTemplate` to your new Cloudflare Worker URL.
*   **Visuals:**
    1.  Remove heatmap/fog code.
    2.  Implement `CircleLayer` for proximity indicators.
    3.  Style with brand colors: Rose (#F4436C) for the circle border, pro-transparent for the fill.

---

## 4. Verification Protocol
1.  **Visual Audit:** Check splash screen on both Light/Dark iOS system settings.
2.  **Animation Audit:** Record radar sweep at 120fps to ensure the 3 o'clock seam is gone.
3.  **Functional Audit:** Activate Gym Mode; monitor log for `MissingPluginException`.
4.  **Map Audit:** Verify global map loading by spoofing location to different continents. Confirm circles are rendered sharply.

```bash
# Verification commands
flutter analyze
flutter test
flutter run --flavor dev --dart-define=FLAVOR=dev
```
