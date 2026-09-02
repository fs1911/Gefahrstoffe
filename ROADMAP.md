# StoffScan – Masterplan & Roadmap

> Lebendes Steuerungsdokument. Stand: 2026-08-20. Hier steht, **wo wir stehen**,
> **wohin wir gehen** und **was wir entschieden haben**. Bei jeder grösseren
> Änderung aktualisieren.

---

## 1. Vision

**StoffScan** ist das mobile Gefahrstoff-Kataster für Bau-, Werkhof- und
Gewerbebetriebe. Prinzip: **«Zuerst Lagerort scannen, dann Artikel scannen».**
Ziel ist eine jederzeit aktuelle Übersicht über gefährliche Stoffe – Menge,
Lagerort, Sicherheitsdatenblatt (SDB), Gefahrenmerkmale – pro Betrieb und über
Firmengruppen hinweg.

**Charakter:** betriebliche Unterstützung. Ersetzt keine Rechtsberatung, keine
Gefährdungsbeurteilung und keine Instruktion vor Ort.

---

## ⚠️ KRITISCH VOR LAUNCH – Datenqualität UN-Nummern & VeVA-Codes (MUSS)

> Entscheid Kunde (2026-09): Das Produkt ist gut und verkäuflich – **aber** die
> **UN-Nummern und VeVA-/Abfallcodes müssen zu 100 % korrekt sein**, sonst sind
> alle darauf aufbauenden Funktionen (Feuerwehr-Karte, Notfall, Entsorgungsbeleg,
> Transport) wertlos. Vor dem Verkauf zwingend abzusichern.

**Problemlage (ehrlich):**
- **UN-Nummern** lassen sich NICHT aus GHS ableiten – sie sind produkt-/gemisch-
  spezifisch und stehen rechtsverbindlich in **SDB Abschnitt 14** des Herstellers.
- **VeVA-/LVA-Abfallcodes** sind aktuell nur **heuristische Vorschläge** (Block 21).

**Lösungsweg (vor Launch umzusetzen):**
1. **Validierte Referenzlisten einbetten** (beide sind endlich & öffentlich):
   - **ADR/SDR-Gefahrgutliste** (UN-Nr → offizieller Stoffname → Klasse/VG). Jede
     eingegebene UN-Nr wird gegen die amtliche Liste geprüft (Tippfehler/ungültig →
     Warnung; Name/Klasse werden angezeigt).
   - **LVA/VeVA-Abfallverzeichnis** (amtliche Code-Liste inkl. Sonderabfall-Stern).
     Abfallcode wird zum **validierten Picker** statt Freitext-Heuristik.
2. **SDB-Abschnitt-14-Parsing per KI** (Edge Function) → UN-Nr/Klasse/Verpackungs-
   gruppe vorschlagen, dann **gegen ADR-Liste validieren** und vom Nutzer bestätigen.
3. **Quelle & Status je Feld** anzeigen: „aus SDB bestätigt" vs. „Vorschlag, ungeprüft".
   Ungeprüfte sicherheits-/transportrelevante Felder klar kennzeichnen.

→ Dies gehört mit der **CAS-Anreicherung** in die Datenqualitäts-Phase (nach den
  offenen Blöcken). Kein Verkauf, solange UN/VeVA nicht validiert sind.

**Entscheid 2026-09:** Reihenfolge = zuerst Blöcke 23–25 fertig, danach die
komplette UN/VeVA/CAS-Validierung in einem Zug mit offizieller Datenanbindung.

**Vom Kunden gelieferte Quellen (in dieser Phase 1:1 einspielen):**
- **UN-Nummern / Stoffdaten:** GESTIS-Stoffdatenbank – https://gestis.dguv.de/list
- **VeVA-/Abfallcodes (CH):** VeVA-online amtliches Abfallverzeichnis –
  https://www.veva-online.admin.ch/veva/selectionImpl/showWasteCodeTreeOriginCH.cmd?selectedMenuItem=2.1
- Hinweis: beide sind aus der Build-Sandbox NICHT erreichbar (Egress-Proxy 403).
  Import daher über: (a) manueller Export/CSV vom Kunden, oder (b) Fetch aus einer
  Umgebung mit Egress (Supabase Edge Function / einmaliges Import-Skript beim Deploy).

**Stand 2026-09 – Edge Function `validate-substance` LIVE (deployed & getestet):**
- Projekt StoffScan (`pvzjxzunhhbgfimirbkl`), `supabase/functions/validate-substance/`.
- Input `{cas?, name?, un?, veva?}` → validiert UN-Nr & VeVA-Code gegen eine Referenz
  und reichert per CAS **live aus PubChem PUG-REST** an (GHS/H-Sätze, Signalwort, CID).
- End-to-End verifiziert: CAS 67-64-1 → CID 180, H-Sätze H225/H319/H335/H336/…, „Gefahr";
  UN 1090 → Aceton, Klasse 3, VG II; VeVA 14 06 03* → gültig, Sonderabfall. Ungültige
  UN/Code werden als `valid:false` mit Hinweis erkannt. Bestätigt: **PubChem ist aus dem
  Edge-Runtime erreichbar** (die Build-Sandbox nicht).
- **UN-Nummern: ERLEDIGT (2026-09).** Tabelle `public.un_reference` (Migration 0009) mit
  **~2365 UN-Nummern** (0004–9006, Benennung/Klasse/Gefahrenzahl), importiert per Edge
  Function `import-un-reference` aus der dt. Wikipedia „Liste der UN-Nummern". Die Function
  `validate-substance` fragt jetzt diese Tabelle ab (nicht mehr den Auszug). Verifiziert:
  UN 1223 → Kerosin/Klasse 3, UN 1202 → Diesel/Heizöl, ungültige → `valid:false`.
  Refresh jederzeit per erneutem Aufruf von `import-un-reference` (idempotenter Upsert).
- **VeVA-/Abfallcodes: ERLEDIGT (2026-09).** Tabelle `public.waste_codes` (Migration 0010) mit
  **860 amtlichen Codes** aus dem VeVA/LVA-Abfallverzeichnis (SR 814.610.1, UVEK-Verordnung),
  geparst aus dem Fedlex-PDF: Code, Beschreibung, Sonderabfall-Flag (`special`, 421 Sonderabfälle),
  Klassierung (S/ak) und **StFV-Mengenschwelle** (`schwelle_kg`, 99 Werte aus Anhang 3).
  Seed-Daten versioniert in `supabase/data/waste_codes.json`. `validate-substance` (v3) prüft
  VeVA-Codes jetzt gegen diese Tabelle (Beschreibung + Sonderabfall + Mengenschwelle).
  Verifiziert: `14 06 03* → „Andere Lösungsmittel…", Sonderabfall, 20 000 kg`; ungültige → invalid.
- **Datenqualität UN + VeVA erledigt.**
- **UI-Anbindung ERLEDIGT (2026-09-02):** Button „Daten prüfen / anreichern" auf der Stoffkarte
  (Demo **und** Live) öffnet ein Modal (CAS/Name/UN/VeVA vorbefüllt) und ruft `validate-substance`
  auf. Zeigt UN-Benennung/Klasse/Gefahrnummer, VeVA-Beschreibung + Sonderabfall + StFV-Schwelle
  und die PubChem-H-Sätze als **Ampel** (grün = auch im SDB, orange = zusätzlich bei PubChem).
  `validate-substance` auf `verify_jwt=false` (nur öffentliche Regulierungsdaten) → Demo und Live
  zeigen identisch echte Daten. CAS-Feld ist im Modal integriert.
- **Block 17 auf echte StFV-Schwellen umgestellt (2026-09-02):** siehe Punkt 17 – die groben
  „Richtwerte" sind durch die amtliche Tabelle StFV Anhang 1.1 (SR 814.012) ersetzt. Quelle
  dokumentiert in `reference/stfv_anhang_1_1.json`.

**Von tozzo zum Produkt:** Ursprung war ein Prototyp für die tozzo gruppe. Ziel
jetzt: ein **generisches, verkaufbares Mehrmandanten-SaaS** ohne Kundenbezug.

---

## 2. Wo wir stehen (Ist-Stand)

| Baustein | Stand |
|---|---|
| Fachkonzept | ✅ ausgereift, backend-fähiges Datenmodell (`docs/Fachkonzept.md`) |
| Prototyp-App | ✅ funktionsfähig: echter QR/Scan, Stoffkarten, Rollen, Alerts – **aber Daten nur lokal (localStorage)** |
| Entbranding | ✅ tozzo-Bezug entfernt, generische Demo-Daten, Name **StoffScan** |
| Marketing-Seite | ✅ v1 als Landingpage (`index.html`) – Entwurf, deploybar |
| Backend | ❌ existiert noch nicht – **das ist der nächste Wertsprung** |
| Billing / Onboarding | ❌ offen |

---

## 3. Das Kernproblem (was uns vom Verkaufen trennt)

> Ein aufgeklebter QR-Code öffnet auf einem **anderen** Handy nichts, solange es
> **kein gemeinsames Backend** gibt. localStorage ist pro Gerät isoliert.

**Das ist der eine entscheidende Sprung von „Demo" zu „Produkt".** Alles Übrige
(Export, Billing, Mehrsprachigkeit …) ist Ausbau darauf.

---

## 4. Entscheidungen (getroffen)

| Thema | Entscheidung | Datum |
|---|---|---|
| Produktname | **StoffScan** | 2026-08-20 |
| Backend-Stack | **Supabase** (Postgres + Auth + Storage + Row-Level-Security) | 2026-08-20 |
| Datenstandort | **Supabase EU-Region** (Datenschutz + Tempo; CH-Option später) | 2026-08-20 |
| Zielgruppe | **Breit** – Bau, Werkhof/Gemeinde, Recycling, Industrie/Gewerbe (kein enger Fokus) | 2026-08-20 |
| Vorgehen | Erst planen (dieses Dokument), dann bauen | 2026-08-20 |

## 5. Offene Entscheidungen (brauchen Input)

| # | Frage | Optionen / Notiz |
|---|---|---|
| O3 | **Domain** | z. B. stoffscan.ch / .app – Verfügbarkeit prüfen. |
| O4 | **Rechtsträger / AGB** | Verkauf an Fremdfirmen braucht AGB, Datenschutzerklärung, Haftungsgrenzen. |
| O5 | **Preismodell final** | Aktuell Richtpreise (49 / 149 / Anfrage). Nach Pilot validieren. |
| O6 | **Konkreter erster Pilotkunde** | Zielgruppe ist breit – für den *ersten* Piloten hilft **ein** benannter Betrieb als Referenz. |

---

## 6. Phasenplan

### Phase 0 – Produktidentität  *(fast fertig)*
**Ziel:** aus tozzo-Prototyp wird ein vorzeigbares Produkt.
- [x] Entbranding, generische Demo-Daten
- [x] Produktname StoffScan, zentral im Header
- [x] Marketing-Landingpage v1
- [x] Deploy-fertig: `netlify.toml` (Root = Seite, `/app/` = Demo), Struktur geprüft
- [x] **Live auf Netlify** – Site `gefahrstoff`, Auto-Deploy vom Repo (`main`) aktiv
  - Marketing: https://gefahrstoff.netlify.app
  - Demo: https://gefahrstoff.netlify.app/app/
- [ ] Domain sichern (O3) → später eigene Domain in Netlify verbinden

> **Deploy:** läuft automatisch bei jedem `git push` auf `main` (Netlify ↔ GitHub
> verbunden). Kein manueller Schritt mehr nötig.

### Phase 1 – Backend / MVP  *(der Wertsprung)*
**Ziel:** geräteübergreifende, echte, mandantengetrennte Daten.
- [x] Supabase-Projekt (Org ShiftProof, EU-Region) + Datenmodell (0001_schema.sql)
- [x] **Row-Level-Security** = Mandantentrennung (0002_rls.sql, angewendet)
- [x] Onboarding-Funktion + Storage-Bucket SDB (0003_onboarding_storage.sql)
- [x] Live-App mit Login unter `/live/` (Auth, Org-Onboarding, Bestand, Erfassen, Verwaltung)
- [x] QR-Deep-Link (`#open=INST-…`) öffnet Datensatz geräteübergreifend (angemeldet, gleiche Org)
- [x] 0003-SQL angewendet (Storage-Bucket `sds` + Policies live, geprüft)
- [x] **Echter SDB-Datei-Upload** ins Storage (Erfassen + Stoffkarte); Öffnen via Signed-URL
- [x] **Personen per Einladung** (`invitations`-Tabelle + `redeem_invite()`, 0004) – Admin lädt E-Mail+Rolle+Firma ein, Person tritt beim ersten Login automatisch bei (kein SMTP/Service-Key nötig)
- [x] Tote Mock-Daten aus `live/index.html` entfernt
- [ ] Demo-Seed für `/live/` (optional, Beispiel-Org mit Daten)
- **Definition of Done:** QR am Schrank aufkleben → jedes berechtigte Handy sieht denselben Bestand inkl. SDB.

> **Block B (Backend-Feinschliff) – erledigt:** SDB-Upload, Einladungs-Flow, Aufräumen.
> **Block A (Design-Upgrade) – erledigt:** Richtung **C „Signal"** gewählt und in `/app/`
> + `/live/` umgesetzt (Tannengrün, Schibsted Grotesk / Hanken Grotesk, kräftige
> Kennzahlen, heller Kopf, weiche Radien; GHS/Ampel konstant). Umsetzung als
> Theme-Layer + Token-Reskin (keine Struktur-/Logikänderung).
> Offen/optional: **Dark-Mode** der App (kleiner Folgeblock).
> Nächster Schritt: **Marketing-Website** im selben Stil aufwerten (weg vom KI-Look).

> **Architektur:** `/app/` bleibt die Login-freie Verkaufs-Demo (localStorage).
> `/live/` ist das echte, Supabase-gestützte Produkt mit Login und Mandantentrennung.

### Phase 2 – Produktreife
**Ziel:** ein Betrieb kann eigenständig sauber arbeiten.
- [x] Rollen/Rechte serverseitig durchgesetzt (RLS, Block 1)
- [x] Firmen- & Benutzerverwaltung (Admin) inkl. Einladungen (Block B)
- [x] Export CSV / PDF je Firma & Lagerort (Verwaltung → Export & Druck)
- [x] Etiketten-Druckbogen (Lagerort- + Artikel-QR als A4-Bogen)
- [x] Demo-Seed für `/live/` (Beispiel-Org mit Firmen/Lagerorten/Stoffen/Beständen)
- [x] **Zusammenlagerungs-Prüfung** (Leitfaden 2018, Beilage 2): Lagerklasse wird automatisch aus
  H-Sätzen/GHS abgeleitet (Ablaufschema Beilage 1, „Auto + überschreibbar"), Konflikte werden an
  Lagerorten geprüft (grün/gelb/rot) und gewarnt – im Erfassen-Formular (Live-Check), auf der
  Stoffkarte, im Lagerort-Detail, im Dashboard-Banner und in der Verwaltung → Handlungsbedarf.
- [x] **Wissensdatenbank** („Wissen"): Lagerklassen, interaktive Zusammenlagerungsmatrix,
  durchsuchbarer H-Sätze-Katalog (CLP), Praxis-Grundsätze – Quellen: Leitfaden 2018 & SUVA.
- [🟡] Warnhinweis-Dashboard: „Handlungsbedarf" (SDB/Menge/Zusammenlagerung) vorhanden; serverseitige Alerts-Tabelle noch offen

### Phase 3 – Kommerziell
**Ziel:** Kunde kann selbst buchen & bezahlen.
- [x] Registrierung / Tenant-Onboarding (Self-Service) — Signup + `create_org_and_profile`, Onboarding mit Planwahl & 14-Tage-Trial (2026-08-27)
- [x] AGB, Datenschutzerklärung, Impressum (O4) — Rechtstexte-Seiten mit Musterangaben + Auftragsbearbeiter-Übersicht (2026-08-27)
- 🟡 Billing (Stripe), Abo-Logik nach Betriebsgrösse — vorbereitet: Abo-Datenmodell (`0005_subscriptions.sql`), Abo-/Upgrade-Screen in der App, Edge-Function-Gerüst (`create-checkout-session`, `stripe-webhook`). **Offen:** Stripe-Konto + Keys/Produkte → Live-Schaltung (2026-08-27)

### Phase 4 – Go-to-Market
**Ziel:** erste zahlende Referenzkunden.
- [ ] Pilotbetrieb (O2), Preis validieren (O5)
- [ ] Landing → Signup-Funnel, Analytics
- [ ] SEO / Content (Suchbegriffe: Gefahrstoffkataster, SDB-Verwaltung …)

### Phase 5 – Skalierung
- [ ] Offline-Modus (schlecht abgedeckte Baustellen)
- [ ] Mehrsprachig DE / FR / IT
- [x] Zusammenlagerungs-Prüflogik (in Phase 2 vorgezogen umgesetzt)
- [ ] SDB-Import von Lieferanten
- [ ] Push-Erinnerungen für SDB-Prüfung

---

## Phase «Differenzierung» – der Wow-Effekt

**Leitsatz:** *Erfasst deine Gefahrstoffe in Sekunden, schreibt deine
Pflicht-Dokumente selbst und macht dich mit einem Klick kontrollbereit – in
jeder Sprache deiner Leute.* Ein Produkt, eine Aussage – kein EHS-Bauchladen.
Jedes Feature muss drei Tests bestehen: (1) zahlt auf die Kernaussage ein,
(2) der normale Nutzer (Polier/Chef) braucht es, (3) ein Handgriff, kein
eigenes Modul. Bewertung 1–10 nach Wow × KMU-Nutzen × gesetzliche Relevanz.
Parallel zu jedem Block wird die **Marketing-Seite interaktiv** erweitert,
damit Kunden den Nutzen sehen (Ziel: Wow-Demo direkt auf der Website).

**Baureihenfolge (von oben nach unten, immer eins nach dem anderen):**

1. [x] **SDB → Stoffkarte füllt sich per KI selbst** (10) — Demo-Simulation + Live-Edge-Function `parse-sdb` (Claude) + interaktive Marketing-Demo (2026-08-27). **Offen:** `ANTHROPIC_API_KEY` setzen → Live-Schaltung
2. [x] **Betriebsanweisung auf Knopfdruck** (10) — aus H-/P-Sätzen + GHS erzeugte, druck-/aushängefertige Betriebsanweisung (Gefahren, Schutz, Erste Hilfe, Entsorgung) direkt aus der Stoffkarte; Print/PDF; interaktive Marketing-Sektion (2026-08-27)
3. [x] **Barcode → crowdsourced Schweizer Katalog** (9) — mandantenübergreifende `product_catalog`-Tabelle (0006); Barcode-Scan trifft den gemeinsamen Katalog → Stoffkarte kommt vorausgefüllt zurück, jeder Speichern-Vorgang gibt anonym zurück (`catalog_find`/`catalog_contribute`, RPC-only, Beitragende nie exponiert). Demo-Simulation im `/app/`, Live an Supabase, kuratierte CH-Grunddaten, interaktive Marketing-Sektion „Einmal erfasst. Von allen erkannt." (2026-08-28)
4. [x] Zusammenlagerungs-Warnung (9) — *bereits gebaut*
5. [x] **Instruktionsnachweis per QR** (9) — QR beim Gefahrstoff → Betriebsanweisung im Bestätigen-Modus (`#instr=<id>`) → „gelesen & verstanden" erzeugt Nachweis (Name + Datum). Stoffkarte zeigt Status (instruiert / fällig nach 12 Monaten), Nachweis-Liste, Instruktions-QR. Live: Tabelle `instructions` (0007, RLS pro Org), Demo mit Seed, interaktive Marketing-Sektion „Instruktion. Ein Scan, ein Nachweis." (2026-08-28)
6. [x] **Mehrsprachige Betriebsanweisung & Instruktion** (9) — DE/FR/IT-Umschalter direkt in der Betriebsanweisung; H-/P-Sätze in offizieller CLP-Formulierung, Fixtexte/PSA/GHS-Namen/Signalwort/Notfall/Entsorgung (VeVA→OMoD/OTRif) übersetzt; Instruktions-Dialog ebenfalls mehrsprachig. Nicht übersetzte Sätze fallen auf den international gültigen Code zurück. Interaktive Marketing-Sektion „Betriebsanweisung in der Sprache der Mannschaft." (2026-08-28). **Offen:** vollständiger offizieller ECHA-CLP-Katalog FR/IT verbatim für Produktion; weitere Sprachen (PT/SQ/EN); LK-Bezeichnung bleibt vorerst DE.
7. [x] **„Frag StoffScan" – KI-Chat auf eigenen Daten** (9) — schwebender «Frag»-Button öffnet Chat-Panel; beantwortet Fragen geerdet auf die eigenen Daten (wo steht ein Stoff, Erste Hilfe, fehlende SDB, Zusammenlagerung LK×LK, Mengen) mit Aktions-Buttons (Stoffkarte/Betriebsanweisung öffnen). Live: Edge-Function `ask-stoffscan` (Claude `claude-opus-5`, geerdet auf Kontext-JSON) mit Fallback auf die lokale Engine; Demo nutzt die lokale Engine. Interaktive Marketing-Sektion „Frag StoffScan. Antwort aus deinen Daten." (2026-08-28). **Offen:** `ANTHROPIC_API_KEY` + `deploy ask-stoffscan` für die Live-KI.
8. [x] **Prüf-Dossier** (9) — Knopf in der Verwaltung erzeugt das komplette prüffertige PDF-Dossier: Deckblatt (firmengebrandet mit Logo), Kennzahlen, priorisierte Mängelliste (offene Punkte), Gefahrstoffliste, SDB-Status, Zusammenlagerung je Lagerort, Instruktionsnachweise, Betriebsanweisungs-Checkliste. Alles aus dem bestehenden Kataster, mit Seitenumbrüchen. Interaktive Marketing-Sektion „Kontrolle angekündigt? Ein Klick." (2026-08-28)
9. [x] **Gefährdungsbeurteilung generieren** (8) — Knopf auf der Stoffkarte → Tätigkeit wählen (Verarbeiten/Sprühen/Umfüllen/Mischen/Reinigen/Lagern) → prüffertige Gefährdungsbeurteilung nach STOP-Prinzip als PDF. Aus der Einstufung abgeleitet: Gefährdungen (CMR, akute Tox, ätzend, Sensibilisierung, Brand …), Expositionswege, Risikobewertung (Schweregrad × Wahrscheinlichkeit → Ampel), Massnahmen S/T/O/P, Restrisiko, Beschäftigungsbeschränkungen (Schwangere/Jugendliche), Notruf, Überprüfungsdatum + Unterschriftszeile. Firmengebrandet. Interaktive Marketing-Sektion „Gefährdungsbeurteilung – ohne leeres Blatt." (Risiko sinkt sichtbar Hoch→Tragbar, während die STOP-Massnahmen greifen) (2026-08-28). **Hinweis:** DE-only (Fachdokument); H-Satz-Katalog für Einstufung heuristisch nach CLP-Code-Bereichen.
10. [x] **Feuerwehr-Einsatzkarte pro Lager** (8) — Knopf auf dem Lagerort → prüffertige Einsatzkarte für Rettungskräfte (PDF/aushängbar), erreichbar auch per Feuerwehr-QR am Eingang (`#einsatz=<locId>`). Aggregiert je Lager: GHS-Piktogramme, Lagerklassen, Mengen/Gebinde, empfohlene **Löschmittel** (inkl. „kein Wasser-Vollstrahl / kein Wasser"), **besondere Gefahren** (Ex, BLEVE bei Druckgas, ätzend, giftige Brandgase, Löschwasser zurückhalten), Notruf 118/144/145 und die Stoffliste. Interaktive Marketing-Sektion „Ein QR am Lager – auch für die Feuerwehr." (Scan enthüllt die Einsatzkarte) (2026-08-28)
11. [x] **Notfall-Modus** (8) — roter „Notfall"-Knopf immer im Kopfbereich → Vollbild-Notfallpanel: Notruf 144/145/118/1414 als Tap-to-Call (`tel:`), Stoff-Auswahl (Suche + Chips) und pro Stoff sofort Erste Hilfe (Augen/Haut/Einatmen/Verschlucken), Löschmittel (mit Warnungen) und Massnahmen bei Austritt – aus GHS/H-Sätzen abgeleitet, ohne Nachladen (in-memory, funktioniert bei Verbindungsabbruch). Aus der Stoffkarte vorbelegt. Interaktive Marketing-Sektion „Der Notfall-Knopf. Immer griffbereit." (2026-08-28). **Hinweis:** echtes Offline (Service-Worker/PWA) folgt in Block 14.
12. [x] **Proaktiver Compliance-Lotse** (8) — Dashboard-Karte oben: Bereitschafts-Score (grün/gelb/rot) + priorisierte offene Punkte (SDB fehlt/veraltet, Zusammenlagerungs-Konflikt, Instruktion fällig, Menge offen), der wichtigste als „Nächster Schritt" mit direktem Fix-Button (öffnet Stoffkarte/Bestand/Lagerort). Ersetzt die passive Handlungsbedarf-Liste durch eine geführte Reihenfolge; Score steigt mit jeder Erledigung. Interaktive Marketing-Sektion „Die App sagt dir, was als Nächstes dran ist." (Score-Ring klettert auf 100 %) (2026-08-28)
13. [x] **Branchen-Starterkataloge** (8) — Karte in der Verwaltung → Branche wählen (Maler/Gipser, Sanitär/Heizung, Werkhof/Gemeinde, Reinigung/Hauswartung, Bau/Beton) → Vorschau der typischen Gefahrstoffe (GHS, Signal, UN, LK) → auf einen Klick in den Stoffstamm übernehmen. Bereits erfasste Stoffe werden erkannt und übersprungen (Dedupe nach Name). Demo pusht in `DB.substances`, Live insert in Tabelle `substances`. Interaktive Marketing-Sektion „Nicht bei null anfangen." (Branchen-Tabs füllen den Stoffstamm) (2026-08-28). **Hinweis:** Grunddaten branchenüblich/heuristisch – produktgenaue Werte kommen aus SDB/CAS-Anreicherung.
14. [x] **Offline auf der Baustelle** (8) — PWA: `manifest.webmanifest` + `icon.svg` + Service-Worker (`sw.js`) je App (`/app/`, `/live/`). Service-Worker cached die App-Shell + CDN-Libs (cache-first, Navigation network-first mit Fallback, Supabase nie gecacht) → Stoffkarten, Betriebsanweisungen, Notfall & Kataster funktionieren offline. Installierbar (iPhone/Android/Desktop): Install-Knopf im Kopf (bei `beforeinstallprompt`) + Anleitungs-Karte in der Verwaltung (iOS/Android/Desktop). Offline-Balken unter dem Kopf, wenn kein Netz. Interaktive Marketing-Sektion „Funktioniert auch ohne Netz." (2026-08-28). **Hinweis:** Echte Offline-Wirkung greift auf der HTTPS-Seite (Netlify), nicht bei `file://`; im Sandbox-Test verifiziert: Manifest/Icons, Offline-Balken (echter Netz-Toggle), Install-Flow.
15. [x] **Compliance-Ampel je Standort** (8) — der Chef-Hook: neuer „Ampel"-Tab in der Verwaltung zeigt je Firma und je Standort eine grün/gelb/rote Ampel, nach Dringlichkeit sortiert (rot vor gelb vor grün), mit Anzahl offener Punkte; Antippen eines Standorts führt direkt zur Lagerort-Ansicht. Rot = SDB fehlt oder Zusammenlagerung «getrennt lagern»; gelb = SDB veraltet / Menge offen / Instruktion fällig / bedingte Zusammenlagerung. Firmen-Rollup = schlechtester Standort. Tab-Badge zeigt Anzahl roter Standorte. Zusätzlich farbige Marker in den Listen Lagerorte/Firmen. Interaktive Marketing-Sektion „Grün heisst: erledigt." (rot wird grün, sobald erledigt) (2026-08-28)
16. [x] **Beschäftigungsbeschränkungen** (7) — aus H-Sätzen/GHS abgeleitet, welche Stoffe für Schwangere/Stillende und Jugendliche (<18) eingeschränkt/verboten sind. Karte auf der Stoffkarte (zwei Zeilen mit grün/gelb/rot-Badge + Begründung + H-Codes + Gesetzesbezug), kompakter Hinweis in der Betriebsanweisung (DE/FR/IT), und die Gefährdungsbeurteilung nutzt dieselbe Ableitung. Logik: Schwangere → Verbot bei CMR1 (H340/H350/H360…), «nur nach Beurteilung» bei CMR2/STOT/akut tox, Stillverbot bei H362; Jugendliche → verboten bei CMR/akut tox/ätzend H314/Atemwegssens. H334/STOT, «nur unter Aufsicht» bei Sensibilisierung/Reizung/entzündbar. Grundlage Mutterschutzverordnung + ArGV 5, mit Lernenden-Ausnahme. Interaktive Marketing-Sektion „Wer darf womit arbeiten?" (2026-08-28). **Hinweis:** heuristische Zuordnung – im Einzelfall arbeitsmedizinisch beurteilen.
17. [x] **Mengenschwellen-Frühwarnung (StFV)** (7) — App summiert die gelagerten Mengen je Stoff (l ≈ kg) im gewählten Bereich und vergleicht sie mit den **amtlichen** Mengenschwellen der Störfallverordnung **StFV Anhang 1.1 (SR 814.012)**: Ziffer 3 (benannte Stoffe, CAS bzw. Name → Schwelle) und Ziffer 4 (Kriterien nach GHS-Gefahrenklasse, H-Satz → Schwelle); massgebend ist die **tiefste** zutreffende Schwelle. Nur echt StFV-relevante Stoffe werden erfasst (z. B. H412 → keine Schwelle). Ampelstufen: ab 50 % erhöht, ab 80 % Frühwarnung (gelb), ab 100 % Schwelle erreicht (rot). Karte „Mengenschwellen (StFV)" in der Verwaltung als **Übersicht + Frühwarnung** (relevante Stoffe mit Balken, kg/Schwelle, %, Basis „benannt"/„Kriterium Hxxx"; Rest-Zeile für die weit darunter liegenden), Frühwarn-Hinweis auf der Stoffkarte. Umgestellt am **2026-09-02** (vorher grobe Richtwerte je Kategorie). Quelle versioniert in `reference/stfv_anhang_1_1.json`. Demo-Seed: Natriumhypochlorit-IBC 1700 kg gegen die H400-Schwelle 2000 kg → 85 % Frühwarnung. Interaktive Marketing-Sektion „Mengenschwellen im Blick." (Balken füllt bis zur Schwelle) (2026-08-28). **Hinweis:** l≈kg-Näherung; Footnote 3 (nicht inhalativ/dermal toxisch) und Ziffer 5 (hochaktive Stoffe, 20 kg) sind Einzelfallbeurteilungen und bewusst nicht automatisch angewendet.
18. [x] **PSA punktgenau je Stoff** (7) — welcher Handschuh-/Filtertyp
    → `psaProfile(s)` leitet aus GHS/H-Sätzen konkrete PSA je Stoff ab: Handschuh-
      Material (Nitril/Butyl/Viton je nach Lösemittel vs. Säure, EN ISO 374 Typ/Durchbruchzeit),
      Atemfilter-Typ (A/AX/E/B/ABEK, P2/P3 bei Aerosolen, umluftunabhängig bei giftig/Druckgas),
      Augen-/Gesichts- und Körperschutz mit Norm (EN 166/14605). Karte `psaCard(s)` auf der
      Stoffkarte (Level: Erforderlich/Empfohlen/Bei Bedarf), Hinweis „massgeblich SDB Abschnitt 8".
      Marketing-Slide „PSA punktgenau" mit Lösemittel/Säure-Umschalter. Beide Apps synchron.
19. [x] **GHS-Eigenetikett beim Umfüllen** (7)
    → `modalUmfuell(subId)` + `umfuellLabelHtml(s,opts)`: erzeugt aus dem Stoffstamm ein
      GHS-konformes Umfüll-/Eigenetikett (Produktname, GHS-Piktogramme, Signalwort, H-/P-Sätze
      im Volltext, Lieferant/Hersteller, Umfüll-Datum & Person). Live-Vorschau im Modal,
      Grösse wählbar (A7/A6/A5), druckfertig via `doPrint` (eigene `.lbl-*` Print-CSS in mm).
      Button auf der Stoffkarte, Hinweis „innerbetriebliche Kennzeichnung nach CLP/GHS –
      Originaletikett & SDB massgeblich". Marketing-Slide „Umfüll-Etikett". Beide Apps synchron.
20. [x] **Lieferschein/Rechnung (PDF) → Bestand** (7)
    → `modalLieferschein()` + `parseLieferschein(text)`: erkennt aus eingefügtem Lieferschein-/
      Rechnungstext die Positionen (Menge, Gebinde, Gebindegrösse, Artikel-Nr), ordnet sie per
      `lsMatch` automatisch dem Stoffstamm zu (Token-Score + Artikel-Nr/Barcode-Abgleich) und bucht
      sie mit `lsApply` als Bestand ein – neue Produkte werden als Stoffstamm angelegt. Editierbare
      Vorschau je Position, Ziel-Lagerort wählbar, Textdatei-Upload, Verlaufseintrag „Wareneingang".
      Demo: `DB.instances.push`; Live: Insert in `substances`/`substance_instances`. Marketing-Slide
      „Lieferschein". PDF-KI-Extraktion (Edge Function) als Cloud-Erweiterung vorgemerkt.
21. [x] **VeVA-Entsorgungsbeleg** (7) — Abfallcode + Sonderabfall-Begleitschein
    → `vevaSuggest(s)` leitet aus GHS/Name einen Abfallcode-Vorschlag (LVA/VeVA, z. B. 14 06 03*
      Lösemittel, 13 07 01* Heizöl, 06 01 06* Säuren, 16 05 04* Druckgase) und die Sonderabfall-
      Kennzeichnung ab. `modalVeVA(subId)` sammelt Menge, Empfänger/Entsorger, VeVA-Betriebsnummern
      und Datum; `vevaBelegHtml` erzeugt einen druckfertigen Entsorgungsbeleg/Begleitschein mit
      Abfall-Tabelle, UN-Nummer, Abgeber-/Empfänger-/Transporteur-Unterschriftenfeldern und VeVA-
      Rechtshinweis (SR 814.610, Begleitschein via veva-online.ch). Button auf der Stoffkarte,
      Marketing-Slide „Entsorgungsbeleg". Beide Apps synchron.
22. [x] **Revisionssicheres Audit-Log** (7)
    → Jede Aktion (addHistory) wird mit Zeitstempel/Person/Detail protokolliert und über eine
      **Hash-Kette** (`cyrb53`, `auditCanon`) versiegelt: jeder Eintrag enthält eine Prüfsumme über
      den vorherigen → nachträgliches Ändern/Löschen bricht die Kette. `auditVerify` findet den
      Bruchpunkt, `auditBoard` (Admin-Tab „Audit-Log") zeigt Siegel + Einträge + Prüfsummen,
      Verifizieren/PDF-Export (`auditReportPdf`) und einen Demo-Tamper. Demo persistiert Hashes
      (localStorage); Live rechnet die Kette über das append-only `audit_logs` (Server-seitige
      Unveränderlichkeit ist die Produktions-Härtung). Marketing-Slide „Audit-Log" mit Live-Tamper.
23. [x] **Wareneingangs-Check** (7) — SDB aktuell? hier lagerbar?
    → `weCheck(subId,locId)` prüft beim Einbuchen automatisch: SDB vorhanden & aktuell (fehlt/alt),
      Zusammenlagerung am Ziel-Lagerort (neue Lagerklasse vs. vorhandene LKs → rot/gelb via ZL-Matrix)
      und zeigt die Lagerklasse. `weCheckCard` erscheint auf der Stoffkarte („Hier lagerbar / Bedingt /
      Nicht empfohlen"), `weLieferBanner` fasst den Check im Lieferschein-Import je Ziel-Lagerort
      zusammen (Positionen ohne SDB + Zusammenlagerungs-Konflikte, dedupliziert). Marketing-Slide
      „Wareneingang". Beide Apps synchron.
24. [x] **Prüffristen – schlanke Erinnerung** (7) — kein Wartungsmodul; fliesst ins Audit-Dossier
    → `CHECK_TYPES` (Auffangwanne, Not-/Augendusche, Feuerlöscher, Lagerkontrolle, SDB-Bestand) mit
      Intervall; `checkStatus` berechnet aktuell/bald fällig/überfällig. Admin-Tab „Prüffristen" mit
      Fällig-Zähler und Board; `checkConfirm` setzt das Datum und schreibt einen Audit-Log-Eintrag
      („Prüffrist bestätigt") → landet im Prüf-Dossier. Persistenz client-seitig pro Org
      (localStorage, offline-tauglich) – bewusst schlank, kein Wartungsmodul. Marketing-Slide
      „Prüffristen". Beide Apps synchron.
25. [x] **Substitution – nur Flag „CMR: Ersatz prüfen"** (7) — keine Alternativen-Datenbank
    → `cmrFlag(s)` erkennt CMR-Stoffe aus den H-Sätzen (Kat 1: H340/H350/H360*, Kat 2: H341/H351/
      H361*). Stoffkarte: CMR-Badge im Kopf + Hinweis „Substitution prüfen (Ersatzpflicht)" +
      `substCard` mit Erklärung der Substitutionspflicht (SUVA/EKAS) und Button
      „Substitutionsprüfung dokumentieren" (schreibt Audit-Log-Eintrag + Datum, client-seitig pro
      Org). `substAdminCard` listet alle CMR-Stoffe mit Prüfstatus (offen/geprüft). Keine
      Alternativen-Datenbank – bewusst nur Flag + Dokumentation. Demo-Seed: CMR-Stoff
      „Dieselkraftstoff" (H351) ergänzt. Marketing-Slide „CMR / Substitution". Beide Apps synchron.

### Separat behandeln (Vertrieb/GTM, kein App-Feature)
- [ ] Berater / Sicherheitsbeauftragte als Multiplikatoren (Mandanten-Ansicht)
- [ ] Lieferanten-Portal für SDB-Updates
- [ ] White-Label für Branchenverbände
- [ ] Versicherungs-Nachweis (Argument für tiefere Prämien)

### Später (gute Ideen, jetzt Ballast)
- [ ] Visueller Lagerplan / Heatmap
- [ ] Haltbarkeit / FIFO
- [ ] Micro-Quiz statt „gelesen"
- [ ] Sprach-Erfassung
- [ ] Regal-Foto → Gebinde zählen
- [ ] Verbrauch → Nachbestell-Schwelle
- [ ] Benchmarking (anonymisiert, braucht Skala)
- [ ] Freigabe-Workflow neuer Stoff
- [ ] Vorfall-/Beinahe-Unfall-Meldung

### Gestrichen (würde die App überladen / Gimmick)
Auffangvolumen-/Löschwasser-Rechner · Standortübergreifend „wer hat X" ·
Kostentransparenz pro Baustelle · Schulungs-/Ausweisverwaltung · ADR/Gefahrgut ·
AR-Brille · Blockchain · IoT-Füllstandsensoren · VOC-Bilanz · ESG/CO₂-Report ·
Leergebinde-/Retouren-Handling

---

## 7. Ziel-Architektur (Supabase)

**Mandantenmodell:** `organization` = Kunde (ein Einzelbetrieb *oder* eine
Firmengruppe). Darunter `companies` (Firmen), darunter `storage_locations`.
Jede Zeile trägt `org_id`; **RLS** erzwingt: Nutzer sehen nur ihre Organisation,
Firmen-Rollen nur ihre Firma, Gruppen-/IMS-Rolle die ganze Organisation.

**Tabellen (aus Fachkonzept, Trennung Stamm ↔ Bestand bleibt zwingend):**

```
organizations        (Mandant / Kunde)
 └─ companies         (Firmen; parent_id für Gruppe)
     └─ storage_locations (hierarchisch)
substances           (Stoffstamm – produktbezogen, einmalig)
 ├─ substance_instances (Vorkommen: Firma+Lagerort+Menge+Status+interner QR)
 │   └─ stock_movements  (Mengenbewegungen)
 └─ sds_documents        (Sicherheitsdatenblätter, Storage-Datei/Link)
users                (↔ company, Rolle)
qr_codes             (polymorph: location | instance | substance)
alerts               (SDB fehlt/veraltet, Pflichtfeld …)
audit_logs           (wer/wann/was)
```

- **Auth:** Supabase Auth (E-Mail/Passwort; später SSO für Gruppen).
- **Storage:** Bucket für SDB-PDFs + Fotos, Zugriff via RLS.
- **QR-Deep-Link:** `https://app.stoffscan.ch/#open=INST-xxxx` / `#open=LOC-xxx`.

---

## 8. Risiken

| Risiko | Gegenmassnahme |
|---|---|
| Datenqualität bei manueller Erfassung | Pflichtfeld-Prüfung, Alerts, vorbefüllter Stoffstamm |
| Doppelerfassung identischer Stoffe | Match über Barcode/Name, zentraler Stoffstamm |
| Akzeptanz vor Ort (muss schneller als Excel sein) | scan-first, grosse Touch-Ziele, wenige Klicks |
| Mandanten-Datenleck | RLS von Beginn an, Tests pro Rolle |
| Rechtliche Haftung | klarer Disclaimer, AGB, „unterstützt ≠ ersetzt" |

---

## 9. Repo-Struktur

```
/index.html        Marketing-Landingpage (Root = Domain-Startseite)
/app/index.html    Produkt-Demo (Prototyp, aktuell localStorage)
/docs/             Fachkonzept, Live-Test-Anleitung
/ROADMAP.md        dieses Dokument
/README.md         Kurzüberblick
/CLAUDE.md         Projektkontext für Claude Code
```
