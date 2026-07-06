# TREMBLE — MASTER COMPLIANCE & LAUNCH READINESS REPORT
**Pripravljeno kot pregled zunanjega svetovalca · 6. julij 2026**
**Upravljavec: AMS Solutions d.o.o. (Slovenija, reg. 7. maj 2026)**
**Predmet: Tremble — proximity dating aplikacija (Flutter + Firebase)**

---

## Kako brati ta dokument

Ta report združuje pet ločenih auditov, opravljenih 6. julija 2026: pravna skladnost (GDPR/DSA/ZVOP-2), analiza občutljivih vprašalnikov, App Store/Play skladnost, produktna funkcionalnost, in produktni tier-ji. Vsaka najdba je preverjena proti dejanski kodi iz `Tremble-DatingApp-main.zip` (svež main snapshot, 6 jul 07:58) — ne proti dokumentaciji ali agentskih poročil.

Vsaka tehnična najdba je zapisana dvakrat, kjer je to potrebno: **za founderja** (kaj to pomeni za posel in tveganje) in **za razvijalca** (kje v kodi, kaj popraviti). Popravljena dva ponavljajoča se napačna fakta iz kroženega konteksta: `brand-identity.html` in "Master Strategy Document" ne obstajata (v repu sta `tremble-brand-identity.html` in `Tremble_Master_Strategy_v9.html`); RevenueCat ni "pending" — dashboard je DONE.

**Trenutni verdikt: Tremble ni pripravljen za javni launch.** Ni zaradi enega velikega problema, ampak zaradi grozda srednjih, od katerih vsak posamič ne bi ustavil launcha, skupaj pa pomenijo, da bi (a) obe trgovini zavrnili submission, in (b) v primeru regulatornega pregleda obstajajo dokazljiva neskladja med podpisanimi pravnimi dokumenti in dejanskim delovanjem produkta.

---

## DEL I — POVZETEK ZA VODSTVO

### Tri stvari, ki morajo biti razrešene pred karkoli drugim

**1. Podpisani pravni dokumenti opisujejo produkt, ki ne obstaja.**
DPIA (podpisan 12 maj) trdi, da profilni endpoint ne razkriva občutljivih podatkov — koda jih razkriva vsakemu ujemanju. DPIA trdi, da politična opredelitev teče na privolitvi — v kodi ni nobenega mehanizma privolitve zanjo. Za nepravnika: to je slabše kot dokument, ki bi priznal problem. Če pride do pregleda Informacijskega pooblaščenca, je razlika med "napisali smo, da počnemo X, a počnemo Y" oteževalna okoliščina pri odmeri globe, ne olajševalna.

**2. Jedro produkta obdeluje najbolj občutljivo kategorijo podatkov brez pravne podlage.**
Vsak dating produkt ima ta problem, a večina ga eksplicitno reši. Kombinacija spola in preference partnerja razkriva spolno usmerjenost — pravno enako varovano kot vera. Dva dni sta bila porabljena na religijo in etničnost (opcijski polji); jedrni matching podatek, ki je pravno resnejši, je bil spregledan.

**3. Objava na Androidu je vezana na Google-ov pregledni postopek, ki traja tedne, ne na to, kdaj je koda pripravljena.**
Background lokacija in foreground service tipi zahtevajo posebno deklaracijo v Play Console z demo videom. Če se ta postopek začne teden pred launchom, launch zamakne za mesec. Ta postopek se mora začeti ta teden, ne glede na ostalo.

### Strateško priporočilo o zaporedju launcha

iOS in Android nista simetrična. Apple obravnava background lokacijo med običajnim reviewom; Google zahteva vnaprejšnjo deklaracijo z večtedenskim pregledom. TestFlight že deluje. Racionalna poteza: **iOS-first launch, Android sledi, ko Play deklaracije preidejo.** Ni pravega razloga za čakanje Android pregleda pred iOS objavo. Če je bil skupni launch datum privzeta predpostavka, jo preveri — verjetno te po nepotrebnem upočasnjuje.

---

## DEL II — PRAVNA SKLADNOST (GDPR / DSA / ZVOP-2)

### A. Posebne kategorije podatkov (GDPR čl. 9)

**Za founderja:** Zakon posebej varuje pet vrst podatkov — vera, etnično poreklo, politično prepričanje, spolna usmerjenost, zdravje. Za vsako potrebuješ izrecno, ločeno privolitev, ali podatka sploh ne smeš obdelovati. Tremble se dotika štirih od petih.

Religija in etničnost sta zdaj dobro urejeni v kodi: ločena privolitev, možnost preskoka, ohranjena razlika med "nikoli vprašan" in "zavrnil". To je bilo popravljeno in drži.

Spolna usmerjenost je problem. Izhaja iz kombinacije spola in tega, koga uporabnik išče — to ni opcijsko polje, je jedro delovanja. Sodišče EU je razsodilo (C-184/20), da tudi posredno razkritje šteje. Norveški regulator je Grindr kaznoval s 65 milijoni kron prav zaradi tega. **Za razvijalca:** `gender` + `lookingFor` (users.functions.ts, compatibility hard filter) sta Art. 9 podatka; PP §2.2 ju napačno označuje kot "voluntarily provided", čeprav sta obvezni polji brez skip opcije, in v `consent_step.dart` nimata ločenega togglea.

Kanabis je pravno najbolj negotov. **Za founderja:** v državah, kjer je raba prekršek ali kaznivo dejanje, tak podatek morda ne spada pod "občutljive podatke" (kjer privolitev deluje), ampak pod "podatke o kaznivih dejanjih" (kjer privolitev ni veljavna podlaga za zasebno podjetje sploh). Ne vem odgovora zate — in to je natanko razlog, da ga ne smeš uganiti. Liability waiver ("nismo odgovorni, če te ujamejo") tega ne reši, ker naslavlja povsem drugo pravno vprašanje. **Za razvijalca:** `nicotineUse` združuje 'cannabis' z 'vape'/'iqos' v enem polju z eno (nobeno) privolitvijo — to onemogoča različno pravno obravnavo znotraj seznama; loči cannabis v svoje polje ne glede na izid pravne presoje.

*Taski: 6h3j9q65vh3mG64P (spolna usmerjenost), 6h3jHjr7Hf58G8pw (kanabis), 6h3JCC8m76XQPQ4P (umbrella pravni pregled), 6h3JCCG8pC38rJhP + 6h3jHjhfQ2vH2wMP (politika), 6h3jHm6rgRW49GPP (consent copy).*

### B. Obvezni pravni dokumenti — stanje

Za founderja, dobra novica: DPIA, DPA in Privacy Policy že obstajajo in so solidno napisani. To je več, kot ima večina startupov ob launchu. Slaba novica: vsebujejo napake, ki jih moraš popraviti, ne ustvariti od začetka.

**DPIA (čl. 35)** obstaja, a vsebuje dve napačni trditvi (getPublicProfile razkritje, politična privolitev) in napačen TTL (24h namesto dejanskih 2h). **Za razvijalca:** uskladi §3.2/§4.2/§8 z dejanskim stanjem kode. *Task 6h3jFhxVHpRmph9P.*

**ROPA (čl. 30)** obvezna kljub majhni ekipi, ker obdeluješ posebne kategorije. Vsebina obstaja raztresena po DPA/DPIA/PP — nalogo preusmeri v konsolidacijo v en dokument, dodaj PostHog. *Task 6h3j9qG7pC7jVX5P.*

**DPO odločitev (čl. 37 / ZVOP-2 čl. 45)** — verjetno obvezen zaradi sistematičnega spremljanja lokacije + posebnih kategorij. Če ga imenuješ, moraš kontakt objaviti in javiti IP v 8 dneh. Co-founder v konfliktu interesov ne more biti DPO; zunanji je najčistejši. *Task 6h3j9qH3m3p543QP.*

**Breach postopek (čl. 33/34)** — DPA že ureja smer procesor→upravljavec (24h). Manjka smer upravljavec→IP (72h) + register kršitev. *Task 6h3j9qhmmhXjHPPP.*

### C. DSA — pravilno umerjen obseg

**Za founderja, to je mesto, kjer te lahko nekdo prestraši po nepotrebnem.** AMS je mikropodjetje, kar te izključuje iz velike večine DSA obveznosti. NE potrebuješ internega pritožbenega sistema, transparentnostnih poročil, trusted flaggerjev, izvensodnega reševanja sporov. Če ti kdorkoli reče, da rabiš karkoli od tega, se moti glede člena 19.

Kar velja ne glede na velikost: kontaktni točki (čl. 11/12 — email v ToS §15 že obstaja, samo eksplicitno ju označi), notice-and-action mehanizem (čl. 16 — preveri, ali report flow pošlje potrdilo), postopek za prijavo kaznivega dejanja (čl. 18). *Taski 6h3j9qQVcqwXQjfP, 6h3j9qR73JFM6Gmw, 6h3j9qfCPj9VM4Qw.*

### D. Dokumentacijska neskladja (najdena pri pregledu priloženih dokumentov)

Weekend Getaway: ToS §7 obljublja avtomatsko časovno okno (pet 19h–ned 19h), koda ga ne izvaja. Ni več le App Store tveganje — je netočna pogodbena obljuba potrošniku (nepoštena poslovna praksa). *Task 6h332RFRW946QWXw.*

ToS §16 trdi, da je izvirnik slovenski, dokument pa je v celoti angleški brez slovenske različice — notranje protislovje in kršitev lastnega EN+SL pravila. *Task 6h3jFj7ppxRM7pWP.*

DPA ima nepopolnjeno matično številko. *Task 6h3jFj5pQhxpm9xw.* PostHog ni naveden kot procesor. *Task 6h3jFj2jfrw6VmVP.*

---

## DEL III — APP STORE / PLAY SKLADNOST

**Za founderja:** trenutno bi obe trgovini zavrnili submission. Blokerji so razdeljeni na tehnične (popraviš v kodi) in procesne (čakaš na pregled trgovine).

### Kritični tehnični blokerji (iOS)
- Manjka privacy manifest (PrivacyInfo.xcprivacy) — avtomatska zavrnitev od iOS 17.4. *Task 6h3grHhjVXFhMRJP.*
- Manjka deklaracija enkripcije v Info.plist. *Task 6h3grHqC22mCcccP.*
- Info.plist ima podvojene ključe in kontradiktorno izjavo o kontaktih: string pravi "ne dostopamo do kontaktov", Privacy Policy §2.5 pa opisuje funkcijo, ki bere imenik. **Za razvijalca:** reviewer opazi permission string, ki zanika funkcijo — Apple 5.1.1 zavrnitev. *Task 6h3p8gWpxpq7rWXw.*

### Kritični procesni blokerji (Android — začni ta teden)
- Background lokacija zahteva Prominent Disclosure zaslon + demo video + deklaracijo, pregled 2-4 tedne. *Task 6h3p8gWG7WHWV7JP.*
- Foreground service tipi (location/connectedDevice/dataSync) zahtevajo ločeno deklaracijo. *Task 6h3p8gc78572RF9P.*

### High
- Data Safety + Apple Privacy Labels morata deklarirati vse občutljive kategorije vključno s spolno usmerjenostjo. Neskladje = zavrnitev IN GDPR kršitev hkrati. *Task 6h3p8gg65JvGh8Ww.*

**Kar je dobro:** UGC safety (report/block/24h), Sign in with Apple, in-app account deletion, permission usage stringi za lokacijo/BLE. Ti so pri dating appih pogosti razlogi zavrnitve — pri tebi pokriti.

---

## DEL IV — PRODUKTNA FUNKCIONALNOST

### Gym / Run / Event Mode
**Za founderja:** arhitektura je dobra (native geofencing, 0% baterije v ozadju), a Gym Mode ima logično napako, ki jo je founder pravilno ujel: backend zavrne ročno aktivacijo, če nisi fizično v telovadnici. To izniči smisel ročne aktivacije — ne moreš se pripraviti vnaprej. **Za razvijalca:** `gym.functions.ts:66-70` vrže napako pri `distance > radiusMeters`; odstrani distance gate, ohrani dwell service kot auto-enhancement. Aktivacija = izjava konteksta; zaznava = živ GPS/BLE. *Task 6h3pjGP2jHCgcgWw.*

### Mapa — edini pravi design problem
**Za founderja:** heatmap na mapi so lažni podatki, ki se v produkciji sploh ne prikažejo — mapa je prazna. Event pini prav tako. Če reviewer odpre to funkcijo, vidi prazen zaslon.

**Za razvijalca — priporočena arhitektura:** ne rabiš clustering algoritma. Geohash je hierarhičen, agregacija po prefiksu JE clustering. Nov CF `getHeatmapDensity(precision, boundingBox)` s tremi zaščitami: k-anonymity gate (celica se vrne samo pri ≥5 uporabnikih — matematično zagotovilo proti re-identifikaciji, ne "upamo, da je dovolj ljudi"), bucketiziran count (nikoli točno število), Upstash cache TTL 60s (Firestore je per-document pricing). Zoom mapira na geohash precision 5/6/7. *Task 6h3pjGRx7rmV6hcw.*

Tile rendering (voda/ceste): nisem našel dokaza o napačnem renderju v statični kodi. Če imaš screenshot, pošlji — sicer je najverjetnejši vzrok Protomaps style layer ordering, ne projekcija. Ne bom ugibal.

### Lokalizacija — hobby zaslon
**Za founderja:** hobbiji mešajo slovenščino in angleščino ne glede na izbran jezik, ker so imena shranjena kot fiksni tekst v enem seznamu (pomešano), ne kot prevodljivi ključi. Skriti drugi problem: matching primerja tekst, torej "Hiking" in "Pohodništvo" se za isti hobi NE ujemata. **Za razvijalca:** `hobby_data.dart` uporablja display imena kot ključe; preidi na jezikovno-nevtralne ID-je + lokalizacijsko tabelo + migracijsko preslikavo starih imen. *Task 6h3pjGcGJPpWGrpw.*

### Registracijsko lokacijsko polje
KP/LJ/ZG selektor → navadni tekst. Polje nima funkcije (ni v matchingu). GDPR: manj podatka = skladno. Če odstraniš Places API tu in se ne uporablja drugje, počisti ga tudi iz PP §6. *Task 6h3pjGjHpGwq9vCP.*

### Event Mode
Hardcoded 3 ljubljanske lokacije, prazno v prod. Prestavi koordinate v Firestore. *Task 6h3pjGpMqrpVHqFw.*

---

## DEL V — PRODUKTNI TIER-JI (Free vs Premium)

**Za founderja — to ti pušča denar na mizi vsak dan.** Tvoj paywall prodaja šibke funkcije in molči o močnih.

Grep pokaže, da koda zaklepa šest stvari; paywall oglašuje štiri, in seznama se komaj prekrivata. Dve oglaševani funkciji ("unlimited geofence pings", "advanced filtering matrix") nimata pokritja v kodi — oglašuješ, kar ne obstaja (Apple 3.1.2 + potrošniško zavajanje). Hkrati koda zaklepa "kdo ti je pomahal" in "near-miss recap" — najmočnejša konverzijska trigger-ja v vsakem dating produktu — in paywall ju sploh ne omeni. To je kot da bi Tinder skril "See who likes you".

**Za razvijalca:** uskladi `premium_screen.dart` features z dejanskimi gate-i v `proximity.functions.ts`/`matches_screen.dart`; premakni see-who-waved v ospredje. *Taski 6h3pmrF84Cf6JVQP, 6h3pmrHP7C6j6Cfw.*

**Tri odločitve, ki jih koda ne more sprejeti zate:** ali je 5 wavov/mesec namerna redkost ali nepremišljena številka (vpliva na retention pred konverzijo); ali je Pulse Intercept Free ali Premium (koda ne odloči — *task 6h3pmrQ5wgFxRrCw*); ali Lifetime 149,99 € sploh ponuditi ob launchu nepreverjenega produkta (prodaš najzavzetejše uporabnike po fiksni ceni, preden veš, koliko so vredni — ToS ga tako ali tako označuje "coming soon").

---

## DEL VI — REGISTER TVEGANJ (konsolidiran)

| # | Tveganje | Pravo | Resnost | Verjetnost | Prio |
|---|---|---|---|---|---|
| R1 | Podpisani DPIA opisuje neobstoječe zaščite (getPublicProfile, politika) | GDPR čl. 5, 9, 35 | High | Confirmed | P1 |
| R2 | Kanabis morda pod čl. 10 brez veljavne podlage | GDPR čl. 9/10 | High | Medium | P1 |
| R3 | Spolna usmerjenost brez consent gate | GDPR čl. 9; C-184/20; Grindr | High | Confirmed | P1 |
| R4 | Android background location zamik launcha | Google Play policy | High | High | P1 |
| R5 | iOS privacy manifest + encryption manjkata | Apple 5.1.1 | Critical | Confirmed | P1 |
| R6 | Info.plist Contacts string zanika funkcijo | Apple 5.1.1 | Medium | Medium | P1 |
| R7 | ToS obljublja Weekend okno brez enforcementa | ZVPot-1/UCPD; Apple 3.1.2 | Medium | Confirmed | P1 |
| R8 | Paywall oglašuje neobstoječe funkcije | Apple 3.1.2; UCPD | Medium | Confirmed | P1 |
| R9 | DPIA/PP 24h TTL vs 2h koda | GDPR čl. 5(1)(e) | Medium | Confirmed | P2 |
| R10 | PostHog nerazkrit; website cookie consent | ePrivacy; GDPR | Medium | Medium | P2 |
| R11 | Foreground service nedeklariran | Google Play FGS | High | High | P1 |
| R12 | DPO/ROPA/breach formalnosti | GDPR čl. 30/33/37 | Medium | Confirmed | P2 |
| R13 | Prazna mapa/Event v prod (App Completeness) | Apple 2.1 | Medium | Confirmed | P2 |
| R14 | MCP prod dostop ni potrjeno zaprt | GDPR čl. 32 (interno) | Medium | Low | P2 |
| R15 | DPA re-sign ×4 pending | GDPR čl. 28 | Medium | Confirmed | P2 |

---

## DEL VII — LAUNCH CHECKLIST

### CRITICAL — pred submissionom (blokira)
Store tehnično: privacy manifest, encryption key, Info.plist čiščenje, Data Safety/Privacy Labels.
Store procesno (začni ta teden): Android background location + FGS deklaracije.
Legal: getPublicProfile fix, kanabis pravno mnenje, spolna usmerjenost podlaga, ToS Weekend uskladitev, paywall uskladitev.

### REQUIRED — pred javno objavo
DPIA popravki, ROPA konsolidacija, DPO odločitev, DSA kontaktni točki + notice-and-action, breach postopek, DPA ×4 + matična št., PostHog cookie consent, ToS SL različica, politična privolitev, nov build, live smoke test.

### RECOMMENDED — po launchu
DSA čl. 18 postopek, MCP test, branch protection, PII redaction sweep, Zod strict, App Check hardening, hex tokenizacija.

### NICE TO HAVE
GlassCard razrešitev, print guard sweep, dead trigger cleanup, home_screen refactor.

---

## DEL VIII — VIRI

GDPR (EU 2016/679): čl. 5, 6, 9, 10, 30, 32-37, 83. DSA (EU 2022/2065): čl. 11, 12, 14, 16, 18, 19. ZVOP-2 (Ur. l. RS 163/22): čl. 8, 23, 43, 45, 46. CJEU C-184/20 (posredno razkritje Art. 9). Datatilsynet Grindr NOK 65M (jan 2021). Apple App Store Review Guidelines (1.2, 2.1, 3.1.2, 4.8, 5.1.1, 5.1.2). Google Play: Location Permissions, Prominent Disclosure, Foreground Services, Data Safety policies. Slovenski IP: ip-rs.si (DPIA seznam, breach obrazec).

---

*Vsak task v tem reportu je izvedljiv v Todoistu (Legal, App, Infra sekcije) s samostojnim opisom in acceptance kriteriji. Nobena najdba ne temelji na agentskem poročilu — vse so preverjene proti dejanski kodi.*
