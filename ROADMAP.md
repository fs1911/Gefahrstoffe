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
- [ ] Demo + Seite deploybar (Netlify/Cloudflare Pages) & getestet
- [ ] Domain sichern (O3)

### Phase 1 – Backend / MVP  *(der Wertsprung)*
**Ziel:** geräteübergreifende, echte, mandantengetrennte Daten.
- [ ] Supabase-Projekt + Datenmodell aus Fachkonzept (siehe §7)
- [ ] Auth (E-Mail-Login), Benutzer ↔ Firma ↔ Organisation
- [ ] **Row-Level-Security** = Mandantentrennung (Kern des Geschäftsmodells)
- [ ] App an Supabase anbinden (statt localStorage)
- [ ] Echter SDB-Datei-Upload (Storage) statt Platzhalter-Link
- [ ] QR-Deep-Link öffnet denselben Datensatz auf jedem Gerät
- **Definition of Done:** QR am Schrank aufkleben → jedes berechtigte Handy sieht denselben Bestand inkl. SDB.

### Phase 2 – Produktreife
**Ziel:** ein Betrieb kann eigenständig sauber arbeiten.
- [ ] Rollen/Rechte serverseitig durchgesetzt
- [ ] Firmen- & Benutzerverwaltung (Admin)
- [ ] Export CSV / PDF je Firma & Lagerort
- [ ] Etiketten-Druckbogen (Lagerort- + Artikel-QR als PDF)
- [ ] Warnhinweis-Dashboard (SDB fehlt/veraltet, Pflichtfelder)

### Phase 3 – Kommerziell
**Ziel:** Kunde kann selbst buchen & bezahlen.
- [ ] Registrierung / Tenant-Onboarding (Self-Service)
- [ ] Billing (Stripe), Abo-Logik nach Betriebsgrösse
- [ ] AGB, Datenschutzerklärung, Impressum (O4)

### Phase 4 – Go-to-Market
**Ziel:** erste zahlende Referenzkunden.
- [ ] Pilotbetrieb (O2), Preis validieren (O5)
- [ ] Landing → Signup-Funnel, Analytics
- [ ] SEO / Content (Suchbegriffe: Gefahrstoffkataster, SDB-Verwaltung …)

### Phase 5 – Skalierung
- [ ] Offline-Modus (schlecht abgedeckte Baustellen)
- [ ] Mehrsprachig DE / FR / IT
- [ ] SDB-Import von Lieferanten, Zusammenlagerungs-Prüflogik
- [ ] Push-Erinnerungen für SDB-Prüfung

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
