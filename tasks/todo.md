# Tremble - Project TODOs (V3)

## 🚀 Active Focus: OSM Infrastructure & Production Stabilization

### 1. Infrastructure (Maps) ⏳ IN PROGRESS
- [ ] Martin: Upload `planet.pmtiles` (126GB) to Cloudflare R2 bucket `tremble-maps`.
- [ ] Deploy Cloudflare Worker (`worker.js`) to `maps.trembledating.com`.
- [ ] Verify worldwide tile loading on physical iOS device.

### 2. Branding & UI ✅ COMPLETE
- [x] Fix Splash Screen "white box" regression.
- [x] Regenerate all app icons with correct Tremble Rose (#F4436C).
- [x] Center Radar Heart icon (1.25x scale).
- [x] Fix Radar Sweep gradient seam at 3 o'clock.

### 3. Native & Security ✅ COMPLETE
- [x] Remove Google Maps SDK native dependencies (Info.plist, AndroidManifest).
- [x] Clean up Background Modes (remove remote-notification for free dev accounts).
- [x] Verify App Check enforcement on all Cloud Functions.

### 4. Remaining Features & Blockers
- [ ] **LEGAL:** Company registration (Blocks RevenueCat/F8).
- [ ] **F7 (Valentine):** Activate promo logic for next release.
- [ ] **ADR-001:** Physical device testing of BLE background restoration.

---
*Last Updated: 2026-05-09*
