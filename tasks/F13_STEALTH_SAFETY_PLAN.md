# Plan ID: 20260508-F13-STEALTH-SAFETY
Risk Level: MEDIUM (Privacy sensitive, contact hashing complexity)
Founder Approval Required: YES
Branch: feature/f13-stealth-safety

## 1. OBJECTIVE
Implement "Anonymity Mode" (contact matching filter via local SHA-256 hashing) and "Geofencing Safe Zones" with a radical "Zero-Data" philosophy. Your privacy is the product.

## 2. SCOPE
- **Affected:** `lib/src/features/settings`, `lib/src/features/profile`, `lib/src/core`, Cloud Functions.
- **Out of Scope:** persistent logging of safe zone usage, contact invitations, naming of safe zones.

## 3. STEPS

### 3.1. Foundation & Localization ✅
- Add translations to `lib/src/core/translations.dart` for SLO, EN, DE.
- Use direct, raw, and stoic tone of voice:
  - "Tukaj smo, da te varujemo, ne da te sprašujemo."
  - "Tvoja stvar je tvoja stvar."
  - "No logs. No history."

### 3.2. Anonymity Mode (Contact Hashing) ✅
- **Client-Side:**
  - Implement `ContactService` using `flutter_contacts`.
  - Normalize to E.164 format.
  - Hash using `crypto` package (SHA-256) locally.
- **Backend:**
  - Create Cloud Function `onContactAnonymityCheck`.
  - Input: `List<String> contactHashes`.
  - Logic: In-memory comparison with user database hashes.
  - Return: List of internal User IDs to exclude from discovery.
  - **Security:** Do NOT store hashes. Purge immediately after processing.

### 3.3. Geofencing Safe Zones ✅
- **Data Model:**
  - `SafeZone` { lat, lng, radius (100|250|500), isActive }.
  - Neutral naming: "Cona 1", "Cona 2".
- **Discovery Logic:**
  - Update `DiscoveryService` to check if the user is currently within any of their *active* safe zones.
  - If YES -> set `isDiscoveryHidden: true` temporarily.
- **Settings UI:**
  - New "Zasebnost in anonimnost" sub-section in Settings.
  - Map picker for safe zones.
  - Radius selector (Fixed options: 100m, 250m, 500m).
  - Confirmation modal when toggling OFF: "Are you sure? This will make you visible at this location again."

### 3.4. Privacy Policy & Compliance ✅
- Update `tasks/policies/auth.yaml` if needed.
- Ensure zero raw phone numbers reach the server.

## 4. RISKS & TRADEOFFS
- **Risk:** High CPU usage during local hashing of 1000+ contacts. 
- **Mitigation:** Use `compute()` or worker isolate to prevent UI jank.
- **Tradeoff:** No custom radii for safe zones to maintain simplicity and prevent finger-printing.

## 5. VERIFICATION
- [x] `flutter analyze` (Zero issues).
- [x] Unit tests for SHA-256 normalization and hashing logic.
- [x] Integration test: Verify user profile is hidden when location enters a safe zone (Simulated via unit tests; Field testing required).
- [x] Security Audit: Confirm no raw contacts or hashes are persisted on server.
