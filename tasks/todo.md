# Tremble - Project TODOs (V4)

## 🚀 Active Focus: Maps Infrastructure — Cloudflare Worker Deploy

### 1. Infrastructure (Maps) ⏳ IN PROGRESS
- [x] Design Protomaps dark style (`tremble_dark_style.json`) — Apple Maps aesthetic.
- [x] Bundle `tremble_dark_style.json` as a local Flutter asset for zero-latency load.
- [x] Integrate `VectorTileLayer` + `PmTilesVectorTileProvider` in `tremble_map_screen.dart`.
- [x] Fix Cloudflare Worker TypeScript errors (`R2ObjectBody` type guard, `R2GetOptions` typing).
- [x] Pass `npm run biome-check` and `npx tsc` with zero errors on Worker codebase.
- [x] **Martin:** Upload `planet.pmtiles` (126 GB) to Cloudflare R2 bucket `tremble-maps`.
- [x] Deploy Cloudflare Worker (`wrangler deploy`) to `maps.trembledating.com`.
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
- [ ] **BLOCKER-005:** iOS Dev provisioning for `com.pulse` — physical iPhone deploy blocked.

---
*Last Updated: 2026-05-20*
