Dobro. Na podlagi celotne kode analize bom zdaj napisal direkten pregled — stanje projekta brez olepševanja.

---

## Kje smo: Zaprta alfa, 1–2 sprinta od odprte bete

Nismo blizu lansiranja. Smo blizu **TestFlight internega testa z 5–10 ljudmi.** To je zaprta alfa. Do odprte bete (50–200 testnih uporabnikov, zunanje napake ti ne ugonobijo reputacije) manjkajo še konkretni koraki.

---

## Kar imamo — in deluje

**Jedro aplikacije je funkcionalno.** To ni trivialno za produkt vaše kompleksnosti.

Registracija gre skozi 27 korakov, od e-pošte do fotografij, shrani vse na Firebase, vrne prijavnega uporabnika z vsemi preferencami. Auth flow z Google Sign-in, email verifikacijo, in router ki pametno preusmeri — deluje. BLE advertizira prisotnost in skeniraj v ozadju, real-time RSSI stream teče, background service se ne ubije pri krogu, Run Club state machine zaznava tek in pošilja notifikacije. F13 Safe Zones blokira lokacijo preden jo sploh pošlje. F12 Pulse Intercept — Send Phone + Send Photo — je napisan, vezak do Redisa, 10-minutni TTL, view-once delete — vse deluje. Safety: block, report, SHA-256 anonimizacija kontaktov — implementirano. Zaščita zaslona (screenshot block) je narejena in vklopljena na štirih zaslonih.

Na backendu: 30 Cloud Functions v europe-west1, App Check enforce za prod, rate limiting na vsaki poti, GDPR export + delete z paginated batchom. Geohash p7 namesto GPS koordinat — privacy-by-architecture res drži v kodi, ni samo marketinška trditev.

**Skratka: kar je core produkt, to obstaja.**

---

## Kar nimamo ali je pokvarjeno

### Kritično — pred vsakim TestFlight buildom

**Firestore pravila imajo luknje.** Klient bere `active_run_crosses`, `run_encounters`, `gyms` — nobena od teh zbirk nima pravila. Vse pade na default `deny`. Run Club v resnici ne deluje na produkcijskem okolju. Zgodovinska lista sreč po teku: prazna. Telovadnice za Gym Mode fallback: prazne. To je tiha napaka — nič ne pokaže, nič ne javlja, samo ne dela. **Ta stvar gre v Claude Code takoj, preden karkoli drugega.**

**Mapa. Prod tile URL kaže na `maps.trembledating.com` ki ne obstaja.** Martin mora naložiti planet.pmtiles (126 GB) na Cloudflare R2, deploy Worker — brez tega mapa v prod buildu prikaže prazen zaslon.

**Event Recap zaslon ima hard-coded fictivne profile** (Lina, Mia, Hana). Ko real user odpre event recap, vidi izmišljene ljudi. To ne sme iti v TestFlight.

### Kritično — pred monetizacijo

**Paywall ni vezan na nič.** Gumb "Naroči se zdaj" pokaže SnackBar "Kmalu na voljo." RevenueCat ni v `pubspec.yaml`, ni integriran, ni niti začet. AMS Solutions je registriran, torej BLOCKER-003 je odprt — zdaj je na vas da kupite Apple Developer Account ($99) in Google Play Console ($25) in začnete RevenueCat integracijo.

~~Poleg tega: cena v paywall widgetu je **7,99 €**. V strategiji piše **4,99 €**. Nekdo se mora odločiti in eno spremeniti.~~ ✅ **Odločeno: 7,99 €.** `tremble-brand-identity.html` posodobljen.

### Kar je narobe ampak ne ubije alfe

Prevodi so napol prazni. Slovenščina in angleščina sta OK (~580 ključev). Nemščina ima 329, francoščina, srbščina, madžarščina okrog 220. User ki izbere Hungarian vidi večinoma angleščino. Za Ljubljano/Koper/Zagreb to ni blocker za alfó — je pa sramota pred beto.

`watchMatches` kliče Cloud Function vsake 30 sekund za vsakega prijavljenega userja. Pri 500 aktivnih userjih = 1.000 klicev/minuto = strošek. Firestore ima real-time listener za to — je 3-urni fix ki prihrani mesečne stroške. Ne ubije alfe, bo bolel pri beti.

185 hard-coded barvnih HEX vrednosti po kodi namesto `TrembleTheme.*` konstant. Vizualni drift. Ne ubije ničesar danes, bo problem ko boš hotel spremeniti "rose" en dan.

Paywall je zgrajen iz `GlassCard` — kar je izrecno prepovedano v brand dokumentu za content cards. Nasprotje ni kritično za delovanje, je pa first impression novega plačljivega userja.

En test je rdeč (`router_redirect_test.dart:212`). Ne ubije builda, ampak zeleni CI ki ima rdeč test je enako neuporaben CI.

---

## Navodila za Claude Code — v prioritetnem vrstnem redu

### Sprint 1 — pred TestFlight interno (naredite najprej)

**✅ Naloga 1: Firestore rules — luknje za F6 in Gym**

`firestore.rules` — pravila za `active_run_crosses`, `run_encounters`, `gyms`, `proximity_notifications` so implementirana. 56/56 testov zelenih.

---

**✅ Naloga 2: Event Recap — odstrani mock profile**

`event_recap_screen.dart` — `_RecapProfile`, `_mockProfiles` in vsi mrtvi widget razredi (`_ProfileCard`, `_PhotoSlot`, `_BlurredName`, `_PulseButton`) odstranjeni. Prikazuje se empty state z `no_encounters` prevodnim ključem.

---

**✅ Naloga 3: Popravi rdeč test**

`router_redirect_test.dart:212` — test je bil že popravljen v prejšnji seji (router guard za stale email session). 23/23 router testov zelenih.

---

**✅ Naloga 4: `watchMatches` → Firestore real-time listener**

`match_repository.dart` — `while(true)/Future.delayed(30s)` polling loop zamenjan s Firestore `.snapshots().asyncMap(getMatches)`. `matchesStreamProvider` dobi uid iz `authStateProvider`, `kReleaseMode` guard varuje dev mock merge logiko.

---

**✅ Naloga 5: Počisti repo root**

Zbrisano: `connect_script.dart`, `temp_script.dart`, `patch_registration.dart`, `patch_app_delegate.swift`, `update_modals.py`, `test_output.txt`, `desktop.ini`. Dodano v `.gitignore`: `test_output.txt`, `desktop.ini`, `*.orig`.

---

### Sprint 2 — pred odprto beto

**Naloga 6: RevenueCat integracija (F8)**

Pogoj: Apple Developer Account kupljen, Google Play Console kupljen.

Dodaj `purchases_flutter: ^6.x.x` v `pubspec.yaml`. Inicializiraj v `main.dart` za oba flaverja z ločenima API ključema. Zamenjaj TODO komentar in SnackBar v `premium_paywall.dart` z `Purchases.purchasePackage(...)`. Odloči se za ceno (4,99 ali 7,99) in posodobi oboje — `premium_paywall.dart` in `Master_Strategy_v6.html`.

---

**Naloga 7: Paywall redesign — brand compliance**

`premium_paywall.dart` mora iti ven iz `GlassCard`. Solid ozadje (`TrembleTheme.textColor` ali `surface`), rose akcenti, Playfair Display za naslov, Lora za podpis cene. Vse besedilne nize premakni v `translations.dart` z ključi `paywall_title`, `paywall_cta`, `paywall_feature_*`. Dodaj vsaj EN + SL + HR.

---

**Naloga 8: Protomaps (Martin)**

To je Martinova naloga:
1. Naloži `planet.pmtiles` na Cloudflare R2 bucket `tremble-maps`
2. Deploy `worker.js` na `maps.trembledating.com`
3. Verificiraj tile loading na fizičnem iOS napravci

Dokler to ni narejeno, `tremble_map_screen.dart` prod grana kaže prazen zaslon.

---

## Memory posodobitve

Treba posodobiti ker je zastarelo:

**D-44** — ZAPRTO. `background_service.dart` že uporablja `NativeMotionService` EventChannel. Ni mock timerja za proximity.

**Screen protection** — IMPLEMENTIRANO. `screen_protection_service.dart` obstaja in je vklopljen na `ProfileDetailScreen`, `MatchRevealScreen`, `RunRecapScreen`, `EventRecapScreen`.

**ADR-001** — ZAPRTO per `tasks/blockers.md`. BLE background state restoration je rešen z NativeMotionService integracijo.

**Open debt** — doda tri nove:
- Firestore rules: manjkajo za `active_run_crosses`, `run_encounters`, `gyms` (HIGH, pred prod)
- `watchMatches` polling loop — zamenjaj s Firestore listener (MEDIUM, pred beto)
- Paywall cena: 7,99 € v kodi vs 4,99 € v strategiji — odloči se (HIGH, pred monetizacijo)Memory posodobljen. Povzetek navodil v enem mestu:

---

**Za Claude Code — prioritetni vrstni red:**

| # | Naloga | Datoteka | Nujnost |
|---|--------|----------|---------|
| # | Naloga | Datoteka | Nujnost | Status |
|---|--------|----------|---------|--------|
| 1 | Firestore rules za `active_run_crosses`, `run_encounters`, `gyms` | `firestore.rules` | **Pred TestFlight** | ✅ Končano |
| 2 | Event Recap — odstrani mock profile (Lina/Mia/Hana) | `event_recap_screen.dart` | **Pred TestFlight** | ✅ Končano |
| 3 | Popravi rdeč test | `router_redirect_test.dart:212` | **Pred TestFlight** | ✅ Končano |
| 4 | `watchMatches` → Firestore listener | `match_repository.dart` | Pred beto | ✅ Končano |
| 5 | `kReleaseMode` guard na dev mock merge | `match_repository.dart` | Pred beto | ✅ Končano |
| 6 | Počisti repo root (5 patch scriptov + test_output.txt) | root | Kadarkoli | ✅ Končano |
| 7 | RevenueCat integracija | `pubspec.yaml`, `main.dart`, `premium_paywall.dart` | Ko kupiš Apple/Play account | 🔴 Blokirano (BLOCKER-003) |
| 8 | Paywall — odloči se za ceno + brand fix | `premium_paywall.dart` | Pred monetizacijo | ⏳ Sprint 2 |
| 9 | Protomaps tile server | R2 + worker.js | Pred TestFlight | ⏳ Martin |

**Za Martina:** planet.pmtiles → R2 → Worker deploy → iOS test. Brez tega mapa ne dela v produkciji.

