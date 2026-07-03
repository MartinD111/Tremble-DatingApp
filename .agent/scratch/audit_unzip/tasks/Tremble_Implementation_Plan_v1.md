# Tremble — Implementation Plan v1
**Datum:** 29. maj 2026
**Vir:** celotna analiza Flutter codebase-a (160 Dart datotek, ~53k LOC, 21 CF) + map performance debata
**Cilj:** App Store submission-ready build, brez lažnih trditev, z delujočim core mechanic-om in tekočo mapo

---

## 0. Realno stanje v eni povedi

Koda je bolj dozorela kot stari blocker seznam: **B007 in B009 sta v kodi rešena, B005 in B008 sta rešena na ravni configa/pravil.** Realni nerešeni problemi so trije: **mrtve pravne povezave (B010), lažna trditev "Zero location stored", in BLE advertising, ki na iOS fizikalno ne deluje.** Mapa je počasna zaradi re-inicializacije ob vsakem odprtju in network-per-tile fetchanja.

---
## FAZA 0 - Dodajanje funkcionalnosti
---
---
Safe Zones — limit na število con
Ugotovitev: Koda ne pozna omejitve. safe_zone_repository.dart:27 addSafeZone() doda brez preverjanja dolžine — ni max, ni canAdd, ni disabled stanje v UI. Če je bila trica načrtovana, ni bila implementirana.
Odločitev pred implementacijo (founder): Koliko con dovoliti in za kateri tier?
Predlog: Free = 3 cone (dom, služba, ena extra), Pro = neomejeno. To ustvari razliko, ki jo večina userjev razume intuitivno — in je lahka upsell točka.
Implementacija (če se odločiš za limit):
safe_zone_repository.dart — dodaj pred zones.add(zone):
dartstatic const int maxFreeZones = 3;

Future<void> addSafeZone(SafeZone zone, {required bool isPremium}) async {
  final zones = await getSafeZones();
  if (!isPremium && zones.length >= maxFreeZones) {
    throw SafeZoneLimitReachedException();
  }
  zones.add(zone);
  await _saveLocalAndSync(zones);
}
safe_zones_screen.dart — pri FAB / "dodaj cono" gumbu preveri pred odprtjem forme. Če zones.length >= 3 && !isPremium → PremiumPaywallBottomSheet.show(context) namesto forme.
isPremium prihaja iz ref.read(effectiveIsPremiumProvider) — dostopen prek Riverpod, ni potrebe po dependency injection v repository.
Če se odločiš za neomejeno za vse: ne naredi nič. Koda je funkcionalna, samo brez limita.

---
## FAZA 1 — App Store Blockers (pred submissionom, nič od tega ni opcijsko)

### 1.1 — B010: Funkcionalne ToS / PP povezave `[DONE]` `[founder + dev]`
**Problem:** `consent_step.dart:124,146` — povezavi imata `onTap: () {}`. User sprejme dokumenta, ki ju ne more odpreti. Hkrati `:166` zbira privolitev za posebne kategorije (vera, etničnost, GDPR čl. 9). Garantirana App Store zavrnitev + neveljavna privolitev.

**Founder pred mergeom:** potrdi, da so live strani `trembledating.com/tos` in `/privacy` deployane (EN + SL).

**Dev koraki:**
1. `pubspec.yaml` → dodaj `url_launcher: ^6.3.0` (trenutno ga sploh ni).
2. `consent_step.dart` — zamenjaj oba no-op-a:
```dart
import 'package:url_launcher/url_launcher.dart';

// ToS link (:124)
onTap: () => launchUrl(
  Uri.parse('https://trembledating.com/tos'),
  mode: LaunchMode.externalApplication,
),

// PP link (:146)
onTap: () => launchUrl(
  Uri.parse('https://trembledating.com/privacy'),
  mode: LaunchMode.externalApplication,
),
```
3. Lokaliziraj URL glede na `appLanguage` (sl/en) če imata strani ločene poti.

**Acceptance:** tap odpre brskalnik z live stranjo; oba checkboxa ostaneta funkcionalna; consent gate (`_canProceed`) deluje.

---

### 1.2 — Privacy copy: "Zero location stored" je NERESNICA `[DONE]` `[dev autonomous]`
**Problem:** `translations.dart:656` trdi "Zero location stored." Geohash p7 JE shranjen v Firestore (`geo_service.dart:186-189`), reverzibilen na ~150m×76m celico (tvoj komentar `:167` to prizna). Pravna izpostavljenost + kršitev brand pravila "describe mechanics, don't promise".

**Fix (EN + SL):**
- EN: `"No precise coordinates are stored — only a coarse ~150m grid cell, discarded on a short TTL."`
- SL: `"Natančnih koordinat ne shranjujemo — le grobo celico ~150m, ki se kmalu izbriše."`
- Audit: preveri marketing site (`trembledating.com/privacy`) za isti overclaim in poravnaj.

**Acceptance:** nikjer v app/web copy ne piše "zero location" / "nič lokacije".

---

### 1.3 — B005: Poravnaj applicationId / bundleId `[founder]`
**Stanje:** iOS migriran na `tremble.dating.app` / `.dev` (`project.pbxproj:1306,1329`). Ostanka:
1. Android dev še `applicationId = "com.pulse"` (`build.gradle:39`) — odloči: obdrži ali migriraj na `tremble.dating.app.dev`. Mora se ujemati s Firebase Android registracijo + dev `google-services.json`.
2. iOS config-swap skripta matcha `com.pulse` / `com.pulse.dev.aleks` (`project.pbxproj:566`) — počisti.

**Founder dejanje:** dotika se Firebase registracij + Apple provisioning profilov. Ne autonomno.

---

### 1.4 — B008: Deploy Firestore pravil na prod `[DONE]` `[founder]`
Pravili obstajata v repu: `firestore.rules:185` (active_run_crosses), `:195` (proximity_events). Niso potrjeno deployana na prod (`am---dating-app`).
```bash
firebase deploy --only firestore:rules --project prod
```
Preveri v konzoli, da prod ruleset ustreza repu.

---

### 1.5 — B006 + B009: Verifikacija (koda je gotova) `[DONE]` `[founder/dev]`
- **B006 (photo upload):** `upload_service.dart` + `uploads.functions.ts` sta produkcijska. Preveri: R2 CORS dovoli PUT, prod env ima R2 ključe, `media.trembledating.com` mapira na public URL, run camera→R2→Firestore na S25 Ultra + iOS.
- **B009 (WavePill FCM):** wiring je narejen (`home_screen.dart:91-130`). Preveri, da FCM payload (`type`/`clickAction`, `notification_service.dart:25,200`) ustreza temu, kar pošlje CF. Test push E2E.

---

## FAZA 2 — Map Performance (vzporedno s Fazo 1, čisto autonomno)

### 2.1 — Premakni init iz `initState` v globalni Riverpod provider `[DONE]`
**Vzrok počasnosti:** `tremble_map_screen.dart:74` kliče `_initializeMap()` v `initState` → `PmTilesVectorTileProvider.fromSource()` dela HTTP fetch headerja/indexa ob VSAKEM odprtju tabice. Tab switch = re-fetch.

**Korak 1 — nova datoteka `lib/src/core/map_provider.dart`:**
```dart
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_map_tiles_pmtiles/vector_map_tiles_pmtiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;

const _pmtilesUrl = 'https://maps.trembledating.com/planet.pmtiles';

class MapInitData {
  final vtr.Theme theme;
  final PmTilesVectorTileProvider tileProvider;
  MapInitData({required this.theme, required this.tileProvider});
}

/// Inicializira se ENKRAT per app session. Riverpod cacheа rezultat,
/// zato je vsako naslednje odprtje map tabа instantno.
final mapInitProvider = FutureProvider<MapInitData>((ref) async {
  final styleString =
      await rootBundle.loadString('assets/map/tremble_dark_style.json');
  final theme = vtr.ThemeReader(logger: const vtr.Logger.console())
      .read(jsonDecode(styleString) as Map<String, dynamic>);
  final tileProvider = await PmTilesVectorTileProvider.fromSource(_pmtilesUrl);
  return MapInitData(theme: theme, tileProvider: tileProvider);
});
```

**Korak 2 — `tremble_map_screen.dart`:** zbriši `_MapInitData`, `_mapInitFuture`, `_initializeMap()`. V `build()` zamenjaj `FutureBuilder` z:
```dart
final mapInit = ref.watch(mapInitProvider);
return mapInit.when(
  loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
  error: (e, _) => Center(child: Text('Error loading map: $e')),
  data: (initData) => FlutterMap( /* obstoječi children */ ),
);
```

**Acceptance:** prvo odprtje inicializira, drugo+ je instantno; baterija se ne troši v ozadju (vector_map_tiles fetcha samo ob interakciji).

---

### 2.2 — On-disk tile cache `[DONE]` (KONČNA odločitev: caching, NE lokalni extract)
**Vzrok jitter-ja:** vsak tile je HTTP range request na `maps.trembledating.com`. Pan/zoom = round-trip + decode + render per tile. Brez persistence med sejami.

**Zakaj caching in ne lokalni extract:** lokalni regionalni extract se ne skalira čez ~20 mest — postaneš distributer map podatkov, obvladovati moraš file verzioniranje. Caching deluje enako pri 3 mestih kot pri 200.

**Korak — dodaj `path_provider`, ovij provider z disk cacheom:**
```dart
final docs = await getApplicationDocumentsDirectory();
// konfiguriraj VectorTileLayer / tileProvider z file cacheom:
//   root:    '${docs.path}/map_cache'
//   maxSize: ~200 MB
//   TTL:     ~30 dni
```
Prvi ogled območja zadane omrežje; vsak ponovni ogled bere z diska (brez latency, brez jitter). 200MB cap sam izloča najstarejše. Ljubljana center @ z13-16 ≈ 5-15MB → po prvem scrollu vse cached. Remote R2 ostane source of truth.

**Acceptance:** drugi pan čez isto območje nima network requestov (preveri v profiler/network log); scroll je gladek.

---

### 2.3 — Cleanup map prod path `[DONE]` `[dev]`
- `tremble_map_screen.dart:62` generira dev mock proximity kroge; v prod je `const []`. Skrij "active people count" pill (`:230`) v prod, da ne kaže "0", ali poveži realni stream (Phase 3 heatmap, PRO only — šele po F1 device testu).
- Tile provider lifecycle: `MapController` je disposed (`:116`); ko init živi v `mapInitProvider`, namerno traja celo sejo. `ref.invalidate(mapInitProvider)` samo ob memory pressure, ne ob vsakem izhodu.

---

## FAZA 3 — BLE Core Redesign (najresnejši tehnični dolg)

### 3.1 — iOS advertising redesign `[founder review → dev]`
**Problem:** `ble_service.dart:107-115` oglašuje UID v `manufacturerData`. iOS CoreBluetooth to ignorira — backgrounded app lahko oglašuje samo service UUID-je. Core mechanic na iPhonu tiho odpove.

**Nova arhitektura (dokumentiraj pred kodiranjem):**
- BLE oglašuje **fiksni Tremble service UUID** kot signal "tukaj je Tremble uporabnik" — NE identitete.
- Identiteta se razreši **server-side** prek geohash proximity seta: GPS geohash pre-filter (`proximity.functions.ts:287-312` `findNearby`) najde kandidate v isti celici; BLE RSSI potrdi "ista soba/blizu".
- Klient ne kodira UID v advertisement in ne piše surovih device ID-jev v Firestore.

**Founder review na arhitekturo pred implementacijo.**

### 3.2 — Fix UID truncation + napačen identifier `[DONE]` `[dev]`
- `:112` `uid.codeUnits.take(20)` reže 28-znakovni UID → `:172` dobi odrezan UID, ki ne matcha nikogar.
- `:209` shrani `toDeviceId: result.device.remoteId.str` = rotirajoč BLE naslov, ne UID.
- Reši kot del 3.1 — nehaj kodirati identiteto v advertisement.

### 3.3 — Logiraj namesto tihega požiranja `[DONE]` `[dev]`
`:223` `catch (_) {}` požre Firestore write failure. Dodaj `debugPrint` + Crashlytics non-fatal.

### 3.4 — Device test na realni strojni opremi `[founder/Martin]`
Dvo-naprava test (S25 Ultra + drugа): advertise+scan v foregroundu, background pod foreground-service, RSSI pragovi (Free −75 / Pro −85, `:165`), proximity_events se zapišejo + matchajo + potečejo. **F1 gate pred vsakim Phase 3 heatmap delom.**

---

## FAZA 4 — Billing / RevenueCat (koda gotova, manjka konfiguracija)

SDK je popolnoma wired: `revenuecat_subscription.dart` (configure :177, paywall :271, customer center, gating prek `effectiveIsPremiumProvider` `auth_repository.dart:1061`). Stara teza "mock billing" je zastarela.

**4.1 Dashboard + store `[founder]`:** ustvari produkte v App Store Connect + Google Play (monthly €7.99, weekly €2.99, yearly €59.99, lifetime €149.99); identifikatorji se morajo ujemati z `:11-14`. Zgradi `default` offering (`:285` ga zahteva). Mapiraj vse na `premium` entitlement (`:9`).

**4.2 API ključ `[founder]`:** `--dart-define=REVENUECAT_API_KEY=...` (`:497`). Brez njega gre controller v `disabled` (`:174`).

**4.3 Sandbox test `[founder]`:** purchase na iOS + Android; `purchaseProduct` (`:251`) preklopi `revenueCatIsPremiumProvider`; PRO UI se odklene (250m radius `tremble_map_screen.dart:110`); `restorePurchases` deluje; `syncAppUserId` (`:209`) veže nakup na Firebase UID.

---

## FAZA 5 — Privacy & Legal Integrity (poleg 1.1/1.2)

**5.1 TTL field mismatch `[DONE]` `[founder]`:** komentar `proximity.functions.ts:590` pravi policy na `ttl`, vsi pisci uporabljajo `expiresAt` (`ble_service.dart:219`, `proximity.functions.ts:843,948`, `rateLimit.ts:54`). Če je deployana policy na `ttl`, podatki nikoli ne potečejo. Preveri policy na `proximity_events` + `run_encounters` da targeta `expiresAt`. Popravi komentar.

**5.2 "Encrypted" trditev `[DONE]` `[founder/legal]`:** `consent_step.dart:166` pravi, da so občutljivi podatki "encrypted". V kodi ni field-level enkripcije — samo Firestore at-rest (infra). Kvalificiraj wording ali implementiraj field-level enkripcijo za posebne kategorije.

**5.3 Safe Zones erasure `[DONE]` `[dev]`:** `safe_zone_repository.dart:42` hrani home/work lat-lng v SharedPreferences (local-only, nešifrirano). Potrdi, da se počisti ob logout + GDPR erasure flow.

---

## FAZA 6 — Tech Debt & Refactor (PO submissionu)

- **README:** `[DONE]` dokumentiraj gitignored `firebase_options_*.dart` + `google-services.json` (fresh clone se ne prevede). `[dev]`
- **main.dart cleanup:** `[DONE]` zbriši zastarel komentar `:10-14`; združi dvojni App Check activate `:62/:78`. `[dev]`
- **D32:** `[DONE]` zamenjaj deprecated `LocalBroadcastManager` (`MainApplication.kt:7,38`). Nizka prioriteta. `[dev]`
- **Refactor:** `edit_profile_screen.dart` (2677), `home_screen.dart` (2535) → pod-widgeti + controller. PO submissionu. `[dev]`
- **Testi:** `[DONE]` ~4% coverage; dodaj widget teste za wave→mutual-wave→30min window in photo upload (mocked R2). `[dev]`

---

## Vrstni red izvajanja

1. **Faza 1** (blockers) + **Faza 2** (mapa) vzporedno — oboje pred submissionom.
2. **Faza 3** (BLE redesign) — founder review arhitekture, nato implementacija, nato F1 device test.
3. **Faza 4 + 5** — konfiguracija + verifikacija, lahko vzporedno s Fazo 3.
4. **Faza 6** — šele po uspešni submission, da ne destabiliziraš launch builda.

**Submission gate:** Faza 1 v celoti + Faza 2.1/2.2 + Faza 3.1 (iOS BLE deluje ali je core mechanic dokazano funkcionalen na iOS) + Faza 4.1/4.2.

---

## Ocene (iz analize)

| Metrika | Ocena (1–10) |
|---|---|
| Kakovost kode | 7 |
| Arhitektura | 8 |
| Produkcijska pripravljenost | 4 |

**Top 3 tveganja pred submissionom:** (1) mrtve ToS/PP povezave + lažna "Zero location stored"; (2) BLE advertising ne deluje na iOS; (3) TTL field mismatch → neomejeno kopičenje proximity podatkov.
