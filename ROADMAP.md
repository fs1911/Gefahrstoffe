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
3. [ ] **Barcode → crowdsourced Schweizer Katalog** (9) — wird mit jedem Betrieb schlauer
4. [x] Zusammenlagerungs-Warnung (9) — *bereits gebaut*
5. [ ] **Instruktionsnachweis per QR** (9) — „gelesen" → Schulungsnachweis
6. [ ] **Mehrsprachige Betriebsanweisung & Instruktion** (9) — DE/FR/IT (+PT/SQ/EN)
7. [ ] **„Frag StoffScan" – KI-Chat auf eigenen Daten** (9)
8. [ ] **„Kontrolle-morgen"-Knopf** (9) — komplettes prüffertiges Dossier als PDF
9. [ ] **Gefährdungsbeurteilung generieren** (8)
10. [ ] **Feuerwehr-Einsatzkarte pro Lager** (8) — QR am Eingang, auch für die Feuerwehr
11. [ ] **Notfall-Modus** (8) — offline: Löschmittel, Erste Hilfe, „was tun bei Austritt"
12. [ ] **Proaktiver Compliance-Lotse** (8)
13. [ ] **Branchen-Starterkataloge** (8) — Maler/Sanitär/Werkhof, nicht bei null starten
14. [ ] **Offline auf der Baustelle** (8) — PWA
15. [ ] **Compliance-Ampel je Standort** (8) — der Chef-Hook
16. [ ] **Beschäftigungsbeschränkungen** (7) — Schwangere/Stillende/Jugendliche, auto abgeleitet
17. [ ] **Mengenschwellen-Frühwarnung (StFV)** (7)
18. [ ] **PSA punktgenau je Stoff** (7) — welcher Handschuh-/Filtertyp
19. [ ] **GHS-Eigenetikett beim Umfüllen** (7)
20. [ ] **Lieferschein/Rechnung (PDF) → Bestand** (7)
21. [ ] **VeVA-Entsorgungsbeleg** (7) — Abfallcode + Sonderabfall-Begleitschein
22. [ ] **Revisionssicheres Audit-Log** (7)
23. [ ] **Wareneingangs-Check** (7) — SDB aktuell? hier lagerbar?
24. [ ] **Prüffristen – schlanke Erinnerung** (7) — kein Wartungsmodul; fliesst ins Audit-Dossier
25. [ ] **Substitution – nur Flag „CMR: Ersatz prüfen"** (7) — keine Alternativen-Datenbank

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
