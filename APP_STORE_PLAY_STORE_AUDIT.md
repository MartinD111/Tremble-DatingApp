# App Store & Google Play Policy Audit — Tremble

*Audit Date: 2026-03-10*

This audit compares Tremble's current codebase against the official [Apple App Store Review Guidelines (Section 1.2 — User Generated Content)](https://developer.apple.com/app-store/review/guidelines/#user-generated-content) and [Google Play Developer Policies for User Generated Content](https://support.google.com/googleplay/android-developer/answer/9876937).

Dating apps are heavily scrutinized under **User Generated Content (UGC)** policies because they facilitate interaction between strangers.

## ✅ Phase 4 Outcomes & Compliance Matrix

1. **Age Rating / Kids Safety:** Tremble correctly implements a hard 18+ age gate during registration. Neither Apple nor Google allow dating apps for minors.
2. **Account Deletion (GDPR Art. 17 / Apple 5.1.1):** 
   - Users can trigger full account deletion from Settings.
   - **Backend:** `deleteUserAccount` Cloud Function performs a hard delete of Auth records, Firestore profiles, and **Cloudflare R2 photos** (via `deleteR2UserFiles` helper).
3. **Location Privacy & Minimization (GDPR Art. 5):** 
   - **Minimization:** `geo_service.dart` stores only a **Geohash 8 (~38m)**; raw coordinates are NEVER written to Firestore.
   - **Retention (TTL):** Proximity data includes a `ttl` field set to **+2 hours**, triggered by Firestore TTL to auto-delete stale location data.
4. **UGC Safety (Apple 1.2 / Google Play DDA):**
   - **Block:** Users can block abusives. Match documents are deleted, and IDs added to `blockedUserIds`.
   - **Report:** Users can report content/profile with specific reasons and optional details. Reporting initiates an auto-block.
   - **Filtering:** `getMatches` and `findNearby` Cloud Functions filter out blocked IDs on the server-side to prevent interaction.

## 📄 Google Play Developer Distribution Agreement (DDA) Audit

Tremble adheres to the DDA (Effective Sept 2025):
- **4.8 Privacy:** We provide a legally adequate privacy notice and only use info (location) for the limited purpose of proximity matching.
- **4.1 Policies:** Our UGC system (Block/Report) satisfies the mandatory Developer Program Policies required by DDA 4.1.
- **4.7 Support:** Reporting logs are stored in Firestore for admin review, supporting the required user complaint handling timeline.
