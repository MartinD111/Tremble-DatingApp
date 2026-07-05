# TREMBLE — MASTER IMPLEMENTATION PLAN (V5 — 2026-07-05)
**Status:** Production stabilization + Phase E (Pulse Intercept / F12)
**Single Source of Truth** for the Tremble Mobile App (Flutter).

---

## 🛠 Tech Stack (Final)
- **Frontend:** Flutter 3 + Riverpod 2 + GoRouter
- **Maps:** `flutter_map` + `latlong2` + Protomaps/PMTiles
- **Infrastructure:** Cloudflare R2 (`tremble-maps`) + Cloudflare Worker (`maps.trembledating.com`)
- **Backend:** Firebase Auth, Firestore, Cloud Functions `europe-west1` on Node.js 22
- **Media:** Cloudflare R2 (`tremble-avatars` / `tremble-avatars-dev`)
- **Email:** Resend (`info@trembledating.com`)
- **Caching:** Redis (Upstash)
- **Security:** App Check (Enforced on all Functions)
- **Branding:** Tremble Rose (`#F4436C`), Deep Graphite (`#1A1A18`)

---

## 📋 Non-Negotiable Rules
1. **Zero-Chat Policy:** Never implement real-time chat. Matches are proximity-based "Pulses" and "Waves" only.
2. **Environment Separation:** 
   - Dev: `tremble-dev` | Prod: `am---dating-app`
   - Build: `--flavor dev --dart-define=FLAVOR=dev`
3. **80% Context Rule:** When AI memory reaches 80%, update `tasks/context.md` and rotate the session.
4. **App Check:** New callable Cloud Functions must use `enforceAppCheck: true` unless explicitly unauthenticated by design.
5. **Branding:** Use `GlassCard` for HUD feel. No Material defaults.
6. **Local commit gate:** `.git/hooks/pre-commit` runs Flutter format/analyze/tests and backend lint/build/tests.

---

## 🗺 Feature Roadmap (Status 2026-05-25)

| Phase | Feature | Status | Tech Note |
|---|---|---|---|
| F1 | **Global Maps** | ✅ DONE | Protomaps/OSM Worker live at `maps.trembledating.com`; physical-device tile verification remains a QA item. |
| F2 | **Event Mode** | ✅ DONE | 0.55 match threshold, quiet lists. |
| F3 | **Match Categories** | ✅ DONE | Event/Activity/Gym tabs + History filters. |
| F4 | **Hot/Cold Nav** | ✅ DONE | RSSI-based proximity indicators. |
| F6 | **Run Club** | ✅ DONE | Native motion bridge, 10-min TTL handshake. |
| F7 | **Valentine Promo** | ⏸ ON HOLD | Gated on store launch. |
| F8 | **Pricing / Paywall** | ✅ CODE DONE | RevenueCat SDK integrated & wired. Sandbox/device testing gated on `BLOCKER-005` provisioning. |
| F9 | **Radius Logic** | ✅ DONE | 100m (Free) / 250m (Pro) Geohash filtering. |
| F10| **Gym Mode** | ✅ DONE | Native Geofencing + Places API (Search only). |
| F13| **Stealth & Safety**| ✅ DONE | Safe Zones + SHA-256 Contact Anonymity. |
| E | **Pulse Intercept (F12)** | 🟡 IN PROGRESS | Zero-chat, button-triggered, 10-minute `expiresAt` interactions. |

---

## 🛰 Maps Infrastructure: Protomaps / OSM
Instead of Google Maps SDK map rendering, Tremble hosts its own global map.

1. **Storage (R2):** `planet.pmtiles` is hosted in the `tremble-maps` bucket.
2. **CDN (Worker):** `maps.trembledating.com` serves PMTiles/vector tiles from Cloudflare edge.
3. **Flutter:** `TrembleMapScreen` uses `VectorTileLayer` with `PmTilesVectorTileProvider`.
4. **Remaining QA:** verify worldwide tile loading on physical iOS once `BLOCKER-005` is resolved.

---

## 🛡 Security Policy
- **App Check:** Enforced for backend callable functions unless a flow is intentionally pre-auth (for example `verifyGoogleToken`).
- **MethodChannels:** 
  - `app.tremble/motion` -> Gym/Run detection.
  - `app.tremble/proximity` -> BLE scanning background logic.

---

## 🎨 Branding Guidelines
- **Primary Rose:** `#F4436C`
- **Graphite:** `#1A1A18`
- **Logo:** Always use `tremble_icon_clean.png` for opaque icons and `tremble_icon_clean_transparent.png` for splash/HUD.

---
*End of Document*
