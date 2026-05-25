# Tremble - Project TODOs (V5)

## Active Focus: Production Stabilization + Phase E

### 1. Infrastructure (Maps) ✅ COMPLETE, QA REMAINS
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
- [x] ADR-001 BLE background restoration resolved via NativeMotionService.

### 4. Current Open Blockers
- [ ] **BLOCKER-003:** Legal/company registration blocks RevenueCat, paywall, and Valentine promo activation.
- [ ] **BLOCKER-005:** iOS dev provisioning for `com.pulse` blocks physical iPhone deploy and iOS tile verification.
- [ ] **BLOCKER-006:** Real photo upload / onboarding E2E still needs device verification on `tremble-dev`.
- [ ] **BLOCKER-007:** Live Privacy Policy, Terms, and Erasure URLs must be verified on `trembledating.com`.

### 5. Backend Follow-Up
- [ ] Verify in Firebase Console that functions newly created by the latest prod deploy are intentional.
- [ ] Review remaining 9 moderate npm audit findings; do not use `npm audit fix --force` unless intentionally accepting Firebase SDK downgrades.

### 6. Local Workflow
- [x] Local `.git/hooks/pre-commit` created and verified directly on 2026-05-25.
- [x] Agent/bootstrap docs updated to include the local pre-commit gate.

---
*Last Updated: 2026-05-25*
