# TREMBLE — PROJECT CONTEXT
**Stanje: 20. junij 2026, 02:00**

---

## PRODUKT

**Tremble** — proximity dating app. Pasivno BLE + GPS zaznavanje. Brez swipanja, brez chata, brez shranjenih GPS koordinat.

Core mechanic: Wave → Mutual Wave → 30-min radar okno → srečanje v resničnem svetu.

**Ekosistem:**
- Flutter/Firebase mobilna app (iOS + Android)
- trembledating.com (Next.js 16, Cloudflare Pages) — marketing + waitlist
- Firebase: `tremble-dev` (dev) | `am---dating-app` (prod) — NIKOLI ne mešaj
- Cloudflare R2: `media.trembledating.com` (app media prod), `media.dev.trembledating.com` (dev), `tremble-maps` (planet.pmtiles)
- Upstash Redis EU, Resend, RevenueCat

**Pravna entiteta:** AMS Solutions d.o.o. (Slovenija, registrirana 07 maj 2026)
**Email:** info@amssolutions.biz
**GDPR controller:** AMS Solutions d.o.o.

**Co-founderja:** Aleksandar Bojić (GitHub: unfab) + Martin (GitHub: MartinD111). Oba delata vse. Martin je na Samsungu (Android), Aleksandar na iPhonu (+ ženin iPhone za iOS↔iOS test).

---

## TRENUTNO STANJE (20 jun 2026)

### ZAKLJUČENO DANES — iOS prvi TestFlight upload

| Kaj | Status |
|---|---|
| Faza 11 — App Store Connect listing | DONE |
| Faza 12 — RevenueCat produkti + dashboard | DONE |
| Faza 13 — flutter build ipa prod + upload | DONE (build 2) |
| Extension bundle ID konflikt rešen | DONE |
| App Store Connect API key nastavljen | DONE |

Build 2 uspešno uploadan na App Store Connect. Delivery UUID: `2ed84925-21de-4219-8fdf-8cf8fe6384f7`.

### IN PROGRESS / PENDING

| Kaj | Status |
|---|---|
| Apple processing build 2 → TestFlight | čaka 10-30 min |
| TestFlight External Testing setup (Aleksandar + žena) | NASLEDNJE |
| BLE proximity matrix test (6 scenarijev) | KRITIČNI BLOCKER pred submitom |
| Android internal testing za Martina (Google Play) | PENDING |

---

## KRITIČNA REŠITEV DANES — EXTENSION BUNDLE IDs

**Problem:** Prod build je failiral na uploadu ker extension bundle IDja `tremble.dating.app.radar` in `tremble.dating.app.notifications` Apple zavrača z "not available" — zasedena sta pod tujim Apple accountom (verjetno star osebni account iz com.pulse dni). Ne moreta se registrirati na AMS teamu, ne moreta se zbrisati.

**Rešitev:** Prod extensiona preimenovana na PROSTA imena:
- `tremble.dating.app.radar` → **`tremble.dating.app.RadarWidget`**
- `tremble.dating.app.notifications` → **`tremble.dating.app.NotificationService`**

Oba registrirana prek App Store Connect API (App Manager key zadošča za `POST /v1/bundleIds`).

**pbxproj sprememba:** Prod konfiguracije popravljene po številki vrstice (ne slepi sed, ker so dev/prod nizi enaki):
- Release-prod (vrstica ~1381), Profile-prod (~1748), Debug-prod (~2081) → NotificationService
- RadarWidget prod vrstice → RadarWidget
- Dev vrstice (`.dev.ImageNotification`, `.dev.TrembleRadarWidget`) NEDOTAKNJENE

**Entitlements:** Runner = samo Apple Sign-In. TrembleRadarWidget = prazen. NotificationService = brez. Nobenih App Groups → nič za uskladiti.

**ZASTARELO:** Stari sed fix iz prejšnjih kontekstov (`.TrembleRadarWidget`→`.radar`, `.ImageNotification`→`.notifications`) je ZASTAREL. NE poganjaj več za prod build. Dev uporablja `.dev.` verzije in ne potrebuje tega prevoda.

---

## iOS BUILD & UPLOAD — TOČNI UKAZI

### App Store Connect API key (CI-ready)

| Kaj | Vrednost |
|---|---|
| Key ID | `V24BM2VRC2` |
| Issuer ID | `752b6022-1929-42dd-b8a4-c894cd4f131d` |
| Pot | `~/.appstoreconnect/private_keys/AuthKey_V24BM2VRC2.p8` |

`altool` in Xcode key najdeta avtomatsko iz te poti.

### ios/ExportOptions.plist (FINALNO)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>teamID</key>
    <string>LB6LS532CV</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
```

### Build (build number MORA rasti z vsakim uploadom)

```bash
flutter build ipa \
  --flavor prod \
  --dart-define-from-file=.env.prod.json \
  --export-options-plist=ios/ExportOptions.plist \
  --build-number=N
```

### Preveri extensiona PRED uploadom

```bash
for appex in build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app/PlugIns/*.appex; do
  echo "=== $appex ==="
  /usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$appex/Info.plist"
done
```

Pričakovano: `tremble.dating.app.RadarWidget` + `tremble.dating.app.NotificationService`.

### Upload

```bash
xcrun altool --upload-app --type ios \
  -f build/ios/ipa/*.ipa \
  --apiKey V24BM2VRC2 \
  --apiIssuer 752b6022-1929-42dd-b8a4-c894cd4f131d
```

---

## NASLEDNJI VSTOP — TOČEN VRSTNI RED

### 1. TestFlight External Testing (ko je build "Ready to Test")

- App Store Connect → Tremble Dating → TestFlight → External Testing
- Create New Group: "Founders + Family"
- Dodaj: svoj Apple ID + ženin Apple ID
- Attach build 2 → izpolni "What to Test"
- Prvi external build → beta review (nekaj ur do 1 dan)
- Po approvalu: oba namestita TestFlight app → sprejmeta povabilo → namestita Tremble

Martin NE more na iOS TestFlight (Samsung). Ločen Android kanal spodaj.

### 2. BLE PROXIMITY MATRIX — KRITIČNI BLOCKER

Core produkt. Service UUID: `73a9429f-fd01-4ac9-9e5a-eabd0d31438e`.

Predpriprava vsake naprave: Bluetooth ON, lokacija "Always" (NE "While Using"), dva ločena računa, telefona 1-5m narazen.

| Scenarij | Naprave | Foreground | Background |
|---|---|---|---|
| iOS ↔ iOS | tvoj + ženin iPhone | test | test |
| Android ↔ Android | Martin + 2. Samsung | test | test |
| iOS ↔ Android | tvoj iPhone + Martin Samsung | test | test |

Za vsak: A oddaja → B skenira → po 1-2 min (scanProximityPairs teče 1x/min) zaznava → wave → mutual → 30-min radar okno.

iOS↔Android testiraj OBE smeri ločeno (iOS oddaja→Android skenira IN obratno). Samsung: izklopi battery optimization (Settings→Apps→Tremble→Battery→Unrestricted) sicer background scan ne dela.

Zabeleži: smer, FG/BG, čas do zaznave, wave prišel?, mutual odprl radar?, PASS/FAIL.

PRAVILA: FG FAIL = hard blocker. iOS BG FAIL = oceni ali launch blocker ali dokumentirana omejitev. Tveganje: v6.1 changelog pravi "BLE iOS redesign zahtevan (manufacturerData ne deluje)".

### 3. Android internal testing (Martin)

- Google Play Console → Tremble → Testing → Internal testing
- Upload Android prod build (AAB) → dodaj Martinov Google račun
- Pogoj: Android prod build mora obstajati (`flutter build appbundle --flavor prod`)

### 4. Po prestani matrix → App Store submit + Google Play submit

---

## MONETIZACIJA (DONE v App Store Connect + RevenueCat)

| Produkt | Cena | Product ID |
|---|---|---|
| Signal Prime Monthly | €7.99/mo | monthly |
| Signal Prime Yearly | €59.99/yr | yearly |
| Signal Prime Lifetime | €149.99 | lifetime |
| Weekend Getaway | €2.99/vikend | weekly |

App pricing = Free (freemium). Apple Silicon Mac disabled (dating app, BLE — nesmiselno na Macu).

RevenueCat: produkti monthly/yearly/weekly/lifetime, P8 IAP key (V24BM2VRC2) naložen, iOS bundle ID `tremble.dating.app`. Status "Could not check" je normalen dokler binary ni v review. `.env.prod.json` + `.env.json` imata `REVENUECAT_APPLE_API_KEY` + `REVENUECAT_GOOGLE_API_KEY`.

Apple yearly opomba: monthly-price pri yearly subscription nastavljen na €5.99 (×12 = €71.88), ker Apple zahteva da je 12-mesečni total ≥ upfront €59.99. Upfront ostane €59.99 — to je kar user dejansko plača za leto.

---

## BUNDLE IDs & KONFIGURACIJA

| Kaj | Vrednost |
|---|---|
| Bundle ID dev (lokalno) | `tremble.dating.app.dev` |
| Bundle ID prod (App Store) | `tremble.dating.app` |
| Prod RadarWidget extension | `tremble.dating.app.RadarWidget` |
| Prod NotificationService extension | `tremble.dating.app.NotificationService` |
| Dev TrembleRadarWidget extension | `tremble.dating.app.dev.TrembleRadarWidget` |
| Dev ImageNotification extension | `tremble.dating.app.dev.ImageNotification` |
| Team ID | `LB6LS532CV` |
| App Store Connect App ID | `6782018915` |
| Signal Prime Subscription Group | `22169519` |
| iPhone 15 UDID (Aleksandar) | `00008120-001618402604201E` |
| App Check debug token (iOS) | `26697195-D797-4FFE-ADEA-9631258A1C88` |
| Firebase iOS App ID (dev) | `1:442962390280:ios:0a018f353ebc44d084d0bd` |
| Provisioning profile UUID | `2c612e50-119a-4ecb-be94-43f640e30601` |

### flutter run (dev na napravi)

```bash
security unlock-keychain ~/Library/Keychains/login.keychain-db && \
flutter run --flavor dev \
  --dart-define-from-file=.env.json \
  --dart-define=FLAVOR=dev \
  -d 00008120-001618402604201E
```

OPOMBA: Flutter resetira `project.pbxproj` ob `flutter pub get`. Preveri prod extension bundle IDje po vsakem pub get (morajo biti `.RadarWidget` + `.NotificationService`, ne dev verzije). Če se resetirajo, glej sekcijo "iOS BUILD" za popravek po številki vrstice.

---

## FIREBASE

| Projekt | Namen |
|---|---|
| `tremble-dev` | Development |
| `am---dating-app` | Production — NIKOLI brez founder approval |

CF functions prod: 36 funkcij live (europe-west1). scanProximityPairs (1 min), processWeekendPasses (hourly), expiry schedulers (60 min). Sentry potrjen. Cloudflare WAF live. TTL aktiven na proximity_events + run_encounters.

`functions/.env` (gitignored) mora biti ročno deljen z Martinom.

---

## ⚠️ KRITIČNE OPOMBE

- **NIKOLI:** push direktno na main · prod deploy avtonomno · sprememba AndroidManifest/Info.plist/google-services.json brez soglasja obeh.
- Extension bundle IDja `.radar` in `.notifications` sta zasedena pod tujim accountom — NE poskušaj ju uporabiti.
- App Check iOS debug token mora biti pod Firebase entry `tremble.dating.app.dev`, NE `com.pulse`.
- R2 upload na iOS zahteva `cupertino_http` CupertinoClient (package:http ne uporablja NSURLSession).
- GPS koordinate samo v CF RAM, nikoli v Firestore — core privacy garancija.

---

## TODOIST

| Sekcija | ID |
|---|---|
| Blockers | `6gj5rPJfRwPCfMGw` |
| App | `6ggWg86gP3qF3Hfw` |
| Website | `6ggWg86XHJp37fjw` |
| Marketing | `6ghmF6Gxjc9FP9rP` |
| Legal | `6ggWg85rFC7jqXcP` |
| Infra | `6gj5rPP2hwh8WmfP` |

Project ID: `6fxxh6MXfmh2q3FP`

Posodobljeni taski (20 jun):
- Faza 11/12/13 → označeni DONE (p4)
- "iOS Faza 14 — TestFlight External Testing setup" → p1
- "BLE proximity matrix test — 6 scenarijev" → p1, KRITIČNI BLOCKER
- "Android internal testing setup (Martin)" → p2

---

## REPO & LOKALNA POT

- Repo: `MartinD111/Tremble-DatingApp` (Aleksandar nima admin pravic)
- Lokalno: `/Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app`
- Notion: project page `315b7419-2f1e-80a1-999e-fdeb5b425aea`

---

## BRAND NON-NEGOTIABLES

- Barve: Rose #F4436C, Yellow #F5C842, Green #2D9B6F, Graphite #1A1A18, Cream #FAFAF7
- Fonti: Playfair Display (display), Lora (body), Instrument Sans (UI)
- Glas: kratke povedi, direktno, brez hype, brez emoji v naslovih
- Prepovedano: glassmorphism na content cards, 3D telefon mockupi, stock couple photos
- Prepovedane fraze: revolutionary, seamless, game-changing, "find love today"
- Privacy copy: NE "Zero location stored" (geohash ~150m JE shranjen). Uporabi "GPS computed in CF RAM only, never stored".
