# Tremble — Pre-Launch Manual Legal Tasks

> Ta datoteka vsebuje pomembne GDPR in ZVOP-2 naloge, ki jih ni mogoče ali smiselno rešiti v sami kodi aplikacije. Zahtevajo odločitve podjetja, pravne preglede in administrativne ukrepe, preden se aplikacijo pošlje na App Store/Play Store in pred uradnim izidom preda uporabnikom.

## 1. Pravilnik o Zasebnosti (Privacy Policy) in Pogoji Uporabe
Ti dokumenti morajo biti dosegljivi preko spleta in posredovani med registracijo. PDF formati, ki jih bere aplikacija, niso optimalna rešitev; pretvorite jih v HTML ali text in jih naložite na domeno.

### Nujno popraviti/vnesti v Privacy Policy:
* **Hramba podatkov (Retention policy):**
  - "Evidence zahtev po izbrisu in vpogledih (t.i. gdprRequests) se v naših strežnikih hranijo 2 leti za zakonsko evidenco."
  - "Fotografije in profili uporabnikov, ki zaprejo ali izbrišejo račune, so trajno pobrisane v trenutku zahtevanega izbrisa računa (takoj, hkrati v glavni Firestore bazi in Cloudflare R2 shrambi)."
* **Zasebnost lokacije:** "Osebam podajamo lokacijo v polmeru ~38 metrov (z zamegljevanjem oziroma GEOHASH 8 metodologijo). Ne hranimo nobenih natančnih koordinat (`lat`, `lng`)."
* **Starostne omejitve:** Jasno predpisati, da je aplikacija dostopna le polnoletnim (18+). Podatke vpisane s strani maloletnikov brisati takoj ko se zaznajo.

## 2. Podpisan Data Processing Agreement (DPA)
V svojem imenu ali imenu vaše pravne entitete morate imeti sklenjen pravni dogovor o procesiranju masovnih osebnih podatkov s ponudniki infrastrukture, kjer se zbirajo podatki:
- **Google Cloud/Firebase:** Lahko se elektronsko sprejme (ali avtomatsko preko Terms of Service izbire). [Data Processing Addendum lahko podpišete tukaj](https://cloud.google.com/terms/data-processing-addendum).
- **Cloudflare (R2 Bucket):** Ker gostijo in hranijo profilne datoteke (slike), morate potrditi in sprejeti njihove DPA preko Cloudflare konzole in pogojev poslovanja.

## 3. Postopek za Primer Vdora v Osebne Podatke (Breach Notification)
Po členu 33 GDPR in določilih ZVOP-2 ste zakonsko zavezani k sporočanju vdorov. V naprej določite:
- Kateri član ekipe je odgovoren za nadzor oz. poročanje? To je DPO funkcija, če obstaja, ali pa pooblaščen administrator.
- Incidenti morajo biti prijavljeni **Informacijskemu pooblaščencu (IP RS)** v roku največ 72 ur od ugotovitve in dokaza varnostnega kršitve (vdora, kraje ali razkritja).
- Vodenje interne evidence varnostnih incidentov, tudi tistih manj pomembnih in rešenih brez znatne škode, morate imeti v navadnem Excel/Google Sheets dokumentu.

## 4. Osebe z Dostopi
Preveriti, komu se dodelijo `Firebase Admin` pravice (Console pravice) do produkcijskih podatkov, saj to omogoča prebiranje obsežne baze strank. Dostop v Firebase projektu naj bo čim bolj omejen in po možnosti reguliran z MFA in strogimi IP politikami.

---
> Znotraj aplikacije in po oblaku smo namestili kodo za izbris datotek s Cloudflarea ob prenehanju profila, prepoved lokacijskih trackerjev brez potrditve (ni checka no-go), age gater (18+) z začetka in strogo minimizacijo gps koordinat v natančnost bloka namesto v milimetre. Tehničnih preprek zato trenutno ni več, ostane še birokracija.
