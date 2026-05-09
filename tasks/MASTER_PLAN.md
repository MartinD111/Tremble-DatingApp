# TREMBLE — MASTER IMPLEMENTATION PLAN (V3 — 2026-05)
**Status:** 🚀 PRODUCTION STABILIZATION
**Single Source of Truth** for the Tremble Mobile App (Flutter).

---

## 🛠 Tech Stack (Final)
- **Frontend:** Flutter 3 + Riverpod 2 + GoRouter
- **Maps:** `flutter_map` + `latlong2` + **Protomaps (PMTiles)**
- **Infrastructure:** Cloudflare R2 (`tremble-maps`) + Cloudflare Workers (`maps.trembledating.com`)
- **Backend:** Firebase (Auth, Firestore, Cloud Functions europe-west1)
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
4. **App Check:** No Firestore/Function calls without valid App Check tokens.
5. **Branding:** Use `GlassCard` for HUD feel. No Material defaults.

---

## 🗺 Feature Roadmap (Status 2026-05)

| Phase | Feature | Status | Tech Note |
|---|---|---|---|
| F1 | **Global Maps** | 🟡 In Progress | Migrated to Protomaps/OSM. Tiles pending R2 upload. |
| F2 | **Event Mode** | ✅ DONE | 0.55 match threshold, quiet lists. |
| F3 | **Match Categories** | ✅ DONE | Event/Activity/Gym tabs + History filters. |
| F4 | **Hot/Cold Nav** | ✅ DONE | RSSI-based proximity indicators. |
| F6 | **Run Club** | ✅ DONE | Native motion bridge, 10-min TTL handshake. |
| F7 | **Valentine Promo** | ⏳ READY | RevenueCat 7-day free trial logic. |
| F8 | **Pricing** | ⏳ BLOCKED | Gated on Legal/Company registration. |
| F9 | **Radius Logic** | ✅ DONE | 100m (Free) / 250m (Pro) Geohash filtering. |
| F10| **Gym Mode** | ✅ DONE | Native Geofencing + Places API (Search only). |
| F13| **Stealth & Safety**| ✅ DONE | Safe Zones + SHA-256 Contact Anonymity. |

---

## 🛰 Infrastructure Plan: Protomaps Migration
Instead of Google Maps ($15k+ scaling risk), we host our own global map.

1. **Storage (R2):** `planet.pmtiles` hosted in `tremble-maps` bucket.
2. **CDN (Worker):** `maps.trembledating.com` serves vector tiles from R2 using `protomaps-worker`.
3. **Flutter:** `TrembleMapScreen` uses `VectorTileLayer` (Maptiler-style) or `TileLayer` (Raster-fallback).

---

## 🛡 Security Policy
- **App Check:** Enforced globally. Debug tokens strictly managed in `main.dart`.
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
