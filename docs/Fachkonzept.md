# Fachkonzept & Prototyp-Briefing
## Gefahrstoff-Erfassung und -Verwaltung – tozzo gruppe ag und Tochterfirmen

**Dokumenttyp:** Fachkonzept + Umsetzungsbriefing für klickbaren Web-Prototyp
**Geltungsbereich:** tozzo gruppe ag, Tozzo AG SO/BS/BL/Aargau, habö AG, PNT AG, Etraxa AG, RS Nordwest AG, schüttbox ag, tozzo immobilien ag
**Charakter:** Betriebliche Unterstützung. Ersetzt keine Rechtsberatung und keine objektspezifische Beurteilung vor Ort.

> **Hinweis zu Annahmen:** Annahmen sind im Text durchgehend als *Annahme* gekennzeichnet. Sie sind vor der Umsetzung mit SIBE/IMS zu bestätigen.

---

# TEIL A – FACHKONZEPT

## 1. Produktvision

Eine mobile-first Web-App, mit der Mitarbeitende vor Ort gefährliche Stoffe schnell erfassen und abrufen können – nach dem Prinzip **«Zuerst Lagerort scannen, dann Artikel scannen»**. Ziel ist eine gruppenweite, jederzeit aktuelle Übersicht über gefährliche Stoffe, deren Mengen, Lagerorte und Sicherheitsdatenblätter (SDB), gegliedert nach Firma.

**Nutzen:**
- Eine einzige, mobile verfügbare Quelle für Stoffinformationen und SDB.
- Sehr schnelle Erfassung mit wenigen Klicks direkt auf Baustelle, Werkhof, Magazin oder in der Werkstatt.
- Transparenz pro Firma und gruppenweit für SIBE und IMS.
- Sofortiger Zugriff auf Gefahrenhinweise (GHS-Piktogramme, H-/P-Sätze) beim Scan.

**Zielgruppen und ihr Hauptnutzen:**

| Zielgruppe | Hauptnutzen |
|---|---|
| SIBE (Sicherheitsbeauftragte) | Gesamtübersicht, Hinweise, Export, Lückenkontrolle |
| IMS-Verantwortliche | Gruppenweite Sicht, Auswertung, Audit-Vorbereitung |
| Bauführer / Polier | Schnellüberblick je Baustelle, Verfügbarkeit SDB |
| Werkhof-/Magazin-/Werkstattverantwortliche | Bestandsführung, Lagerorte, Mengen |
| Baustellenpersonal | Schneller Scan, Stoffkarte abrufen, einfache Erfassung |

**Einsatzzweck:** Erfassung, Pflege und mobiler Abruf von Stoff- und Bestandsdaten in Bau- und Infrastrukturbetrieben (Baustellen, Werkhöfe, Magazine, Werkstätten, Containerlager, Zwischenlager, Sonderabfall-Sammelstellen, allgemeine Lagerbereiche).

---

## 2. Kernprobleme (Ist-Zustand)

| Problem | Auswirkung in der Praxis |
|---|---|
| Fehlende Gesamtübersicht | Niemand weiss verlässlich, welche Stoffe wo und in welcher Menge lagern. |
| Verteilte SDB | SDB liegen in Ordnern, Mailpostfächern, auf verschiedenen Laufwerken – vor Ort oft nicht greifbar. |
| Unklare Lagermengen | Bestände werden geschätzt, nicht erfasst; Reststände bleiben unbemerkt. |
| Unklare Lagerorte | Stoffe stehen in Containern/Schränken ohne klare Zuordnung. |
| Fehlende Transparenz pro Firma | Bei mehreren Tochterfirmen ist unklar, wer welche Stoffe führt. |
| Keine einfache mobile Erfassung | Erfassung scheitert an aufwändigen Listen und Excel-Dateien. |
| Kein direkter Zugriff vor Ort | Mitarbeitende finden Gefahrenhinweise/SDB nicht im richtigen Moment. |

---

## 3. Zielprozess (Soll)

### Standardprozess (scan-first)

1. **Lagerort-QR scannen** (oder Lagerort manuell wählen).
2. **Firma und Lagerort werden automatisch gesetzt** (Kontext aktiv).
3. **Artikel / Stoff scannen** (interner QR oder externer Barcode).
4. **Stoff wird erkannt** (Treffer im Stoffstamm) **oder neu angelegt**.
5. **Minimaldaten bestätigen oder ergänzen** (v.a. Menge, Gebinde).
6. **SDB verknüpfen oder hochladen** (Datei oder Link).
7. **Interner QR-Code wird erzeugt** (für den Bestandsdatensatz).
8. **Stoffkarte wird angezeigt** (Piktogramme, H-/P-Sätze, Menge, Lagerort, SDB).

### Fallbacks

- **Ohne Lagerort-QR:** Lagerort manuell auswählen oder neu erfassen, dann weiter ab Schritt 3.
- **Ohne automatische Stofferkennung:** manuelle Stoffsuche oder Neuanlage mit Minimaldatensatz.
- **Manuelle Nachbearbeitung:** Mengen, SDB, verantwortliche Person, Foto jederzeit ergänzbar.

```
[Lagerort-QR] --> Kontext: Firma + Lagerort gesetzt
      |                         (Fallback: Lagerort manuell)
      v
[Artikel-Scan] --> Treffer? --> ja --> Bestandsdatensatz aktualisieren/anlegen
      |                      \-- nein --> Stoffstamm suchen / neu anlegen
      v
[Minimaldaten bestätigen] --> [SDB verknüpfen] --> [interner QR] --> [Stoffkarte]
```

---

## 4. Rollen und Rechte

| Funktion | Viewer | Mitarbeitender | Lagerverantwortlicher | Firmenadmin | Gruppenadmin / IMS-Admin |
|---|:--:|:--:|:--:|:--:|:--:|
| Lesen (eigene Firma) | ✓ | ✓ | ✓ | ✓ | ✓ |
| Scannen | – | ✓ | ✓ | ✓ | ✓ |
| Bestand bearbeiten | – | ✓ (eigene Erfassung) | ✓ | ✓ | ✓ |
| SDB hochladen / verknüpfen | – | ✓ | ✓ | ✓ | ✓ |
| Datensätze freigeben / prüfen | – | – | ✓ | ✓ | ✓ |
| Lagerorte anlegen/verwalten | – | – | ✓ | ✓ | ✓ |
| Benutzer/Rollen verwalten | – | – | – | ✓ (eigene Firma) | ✓ (alle Firmen) |
| Exportieren | – | – | ✓ | ✓ | ✓ |
| Firmenübergreifend sehen | – | – | – | – | ✓ |

*Annahme:* Mitarbeitende sehen und bearbeiten standardmässig nur Daten ihrer eigenen Firma. Gruppenadmin/IMS-Admin hat die einzige firmenübergreifende Sicht.

---

## 5. Hauptfunktionen

- **Lagerort-QR-Scan:** setzt Firma + Lagerort als Kontext für alle folgenden Erfassungen.
- **Artikel-QR-/Barcode-Scan:** interner QR öffnet die Stoffkarte direkt; externer Barcode startet die Stoffsuche bzw. Neuanlage.
- **Automatische Stoffsuche:** Match über internen QR, externen Barcode oder Produktname/Hersteller.
- **Manuelle Ergänzung:** alle Felder jederzeit nachpflegbar (Menge, SDB, Foto, verantwortliche Person).
- **Manuelle Neuerfassung:** Stoffstamm und Bestandsdatensatz ohne Scan anlegbar.
- **Suchfunktion:** Volltext über Produktname, Hersteller, UN-Nummer, interner QR, Lagerort.
- **Firmenfilter / Tochterfirmenfilter:** Sicht auf einzelne Firma oder Gruppe.
- **Lagerortfilter / Stofffilter:** nach Lagerort, Gefahrenmerkmal, Status, fehlendem SDB.
- **Gruppenansicht:** aggregierte Sicht über alle Firmen (nur Gruppenadmin/IMS).
- **SDB-Upload / SDB-Link:** Datei (PDF) oder externer Link, mit Revisionsdatum.
- **GHS-Piktogrammanzeige:** als klar erkennbare Badges auf der Stoffkarte.
- **H-/P-Sätze:** Gefahren- und Sicherheitshinweise je Stoff.
- **Mengen- und Gebindeverwaltung:** Gebindeart, Gebindegrösse, Anzahl, aktuelle Menge, Einheit.
- **Änderungsprotokoll:** wer, wann, was geändert hat (Audit-Log).
- **Exportfunktion:** Bestandsliste je Firma/Lagerort als CSV/Excel und PDF.
- **QR-Code-Generierung pro Artikel** (Bestandsdatensatz) und **pro Lagerort**.
- **Warnhinweise** bei fehlenden Pflichtangaben, fehlendem SDB, potenziell veraltetem SDB.

---

## 6. Lagerortlogik

**Hierarchie (oben → unten):**

| Ebene | Beispiel |
|---|---|
| Firma | Tozzo AG BL |
| Standort | Werkhof Liestal |
| Bereichstyp | Werkhof / Baustelle / Magazin / Werkstatt / Containerlager / Zwischenlager / Sonderabfall-Sammelstelle |
| Gebäude / Container / Bereich | Container 2, Gefahrstofflager |
| Raum / Schrank / Regal / Zone | Regal A3 |

**Regeln:**
- **Standardprozess = zuerst Lagerort scannen.** Der Lagerort-QR setzt Firma und vollständigen Lagerort-Pfad.
- **Lagerort alternativ manuell** auswählbar (Baumstruktur) oder neu erfassbar.
- **GPS nur optional** als Zusatzinformation (z.B. mobile Baustelle), nie als Hauptlogik. Der Lagerort bleibt führend.

---

## 7. Firmenlogik

- **Firmenspezifische Datensicht:** Standard ist die Sicht auf die eigene Firma.
- **Gruppenweite Datensicht:** nur für Gruppenadmin/IMS-Admin; Aggregation über alle Firmen.
- **Identische Stoffe in mehreren Firmen:** Ein Stoffstamm (z.B. ein bestimmtes Reinigungsmittel) existiert genau einmal, kann aber in mehreren Firmen und an mehreren Lagerorten als **Vorkommen (Bestandsdatensatz)** geführt werden.
- **Mengen- und lagerortbezogene Bestandsführung:** Menge, Status und Lagerortbezug liegen immer auf dem konkreten Vorkommen, nicht auf dem Stoffstamm.
- **Zentrale Gruppenadministration:** Stoffstamm und SDB können zentral gepflegt und gruppenweit genutzt werden.

---

## 8. QR-Code-Logik

| Aktion | Verhalten |
|---|---|
| QR je Lagerort scannen | Setzt Kontext: Firma + Lagerort. App wechselt direkt in den Artikel-Scan. |
| Interner Artikel-QR scannen | Öffnet die Stoffkarte des Bestandsdatensatzes (Menge, Lagerort, SDB) sofort. |
| Externer Barcode scannen | Sucht Match im Stoffstamm; bei Treffer Vorkommen anlegen/aktualisieren, sonst Neuanlage anstossen. |

**Druck- und Etikettierungslogik:**
- Lagerort-Etiketten: QR + Klartext (Firma, Standort, Bereich) zum Aufkleben am Schrank/Container/Regal.
- Artikel-Etiketten: interner QR + Produktname + Gebinde zum Aufkleben am Gebinde.
- *Annahme:* Etikettengrösse A6/57×32 mm, Druck als PDF-Bogen mehrerer Etiketten.

---

## 9. Minimaldatensatz je Stoff

> **Wichtig:** Felder gehören entweder zum **Stoffstamm (S)** oder zum **Vorkommen/Bestand (V)**. Diese Trennung ist zwingend.

| Feld | Pflicht / empfohlen / optional | Ebene |
|---|---|:--:|
| Stoff-ID | Pflicht | S |
| Produktname | Pflicht | S |
| Interner QR-Code | Pflicht (autom.) | V |
| Firma | Pflicht | V |
| Lagerort | Pflicht | V |
| Menge aktuell | Pflicht | V |
| Mengeneinheit | Pflicht | V |
| Stoffstatus | Pflicht | V |
| GHS-Piktogramme | empfohlen | S |
| Signalwort | empfohlen | S |
| H-Sätze | empfohlen | S |
| P-Sätze | empfohlen | S |
| Hersteller | empfohlen | S |
| Lieferant | empfohlen | S |
| Gebindeart | empfohlen | V |
| Gebindegrösse | empfohlen | V |
| Anzahl Gebinde | empfohlen | V |
| SDB-Link | empfohlen | S |
| SDB-Datei | empfohlen | S |
| SDB-Revisionsdatum | empfohlen | S |
| Standort (Klartext) | empfohlen | V |
| Verantwortliche Person | empfohlen | V |
| Externer Barcode | optional | S |
| UN-Nummer | optional | S |
| Wassergefährdend (ja/nein) | optional | S |
| Brennbar (ja/nein) | optional | S |
| Lagerhinweis / Lagerklasse | optional | S |
| Zusammenlagerungshinweis | optional | S |
| Foto | optional | V |
| Zeitstempel | optional (autom.) | V |
| Letzte Änderung | optional (autom.) | V |
| Änderungsverlauf | optional (autom.) | V |
| GPS-Koordinate | optional | V |

---

## 10. Mobile UX / UI

**Screens:**
- **Startscreen:** zwei grosse Buttons «Lagerort scannen» und «Artikel scannen», darunter «Suche» und «Bestand».
- **Lagerort-Scan-Flow:** Kamera öffnet sofort; nach Scan Bestätigung des Kontexts (Firma + Lagerort) und direkter Übergang zum Artikel-Scan.
- **Artikel-Scan-Flow:** Kamera öffnet sofort; Treffer → Stoffkarte; kein Treffer → Schnellerfassung.
- **Manueller Erfassungs-Flow:** reduzierte Maske, nur Pflichtfelder zuerst, Rest aufklappbar.
- **Stoffdetailseite (Stoffkarte):** Piktogramme oben, Menge/Lagerort/Firma, SDB-Button, interner QR, Verlauf.
- **Lagerortdetailseite:** Lagerort-Pfad, Liste der Bestände, QR des Lagerorts, Export.
- **Firmenübersicht:** Filter, Bestandsliste, Warnhinweise (fehlendes/altes SDB).
- **Adminansicht:** Firmen, Benutzer/Rollen, Stoffstamm, Lagerorte, Export, offene Hinweise.

**UX-Prinzipien:** grosse Buttons, reduzierte Eingabemasken, sofortige Kameraöffnung, gute Bedienbarkeit auf Handy und Tablet, klare Piktogramme, wenige Klicks, robust für Baustelle/Werkhof/Magazin (auch mit Handschuhen, schlechtem Licht, einer Hand bedienbar).

---

## 11. Schweizer Fachlogik (betrieblich, nicht juristisch)

Die App arbeitet mit **Hinweisen statt harten Rechtsautomatismen**. Sie unterstützt die betriebliche Organisation, ersetzt aber keine Beurteilung vor Ort und keine Instruktion.

**Visuelle Markierung** (Farb-/Icon-Logik) für:

| Merkmal | Farb-/Icon-Hinweis |
|---|---|
| Entzündbar | rot/orange, Flammen-Icon |
| Ätzend | schwarz/weiss, Ätzwirkung-Icon |
| Giftig | schwarz/weiss, Totenkopf-Icon |
| Oxidierend | rot/orange, Flamme-über-Kreis-Icon |
| Umweltgefährlich | grün, Umwelt-Icon |
| Druckgas | grau/blau, Gasflaschen-Icon |

**Hinweise (Beispiele):**
- Hinweis bei **fehlendem SDB**: «Kein SDB hinterlegt – bitte ergänzen.»
- Hinweis bei **potenziell veraltetem SDB**: SDB-Revisionsdatum älter als 3 Jahre → «SDB prüfen» (*Annahme:* Schwellwert 3 Jahre, konfigurierbar).
- Hinweis **«bitte prüfen»** bei auffälligen Konstellationen (z.B. brennbar + oxidierend am selben Lagerort).
- Dauerhafter Footer-Hinweis: «Beurteilung vor Ort und Instruktion bleiben erforderlich.»

---

## 12. Datenbankschema

> Kerntrennung: **`substances` (Stoffstamm)** vs. **`substance_instances` (Vorkommen/Bestand)**.

| Tabelle | Zweck | Wichtigste Felder | Beziehungen |
|---|---|---|---|
| **companies** | Firmen der Gruppe | id, name, parent_id, kanton, typ, aktiv | parent_id → companies (Selbstbezug für tozzo gruppe ag) |
| **users** | Benutzer und Rollen | id, name, email, rolle, company_id, aktiv | company_id → companies |
| **storage_locations** | Lagerorte hierarchisch | id, company_id, typ, parent_location_id, name, pfad, gps_lat, gps_lng, qr_code_id | company_id → companies; parent_location_id → storage_locations; qr_code_id → qr_codes |
| **substances** | Stoffstamm (produktbezogen) | id, produktname, hersteller, lieferant, signalwort, ghs_piktogramme[], h_saetze[], p_saetze[], un_nummer, wassergefaehrdend, brennbar, lagerklasse, zusammenlagerung_hinweis, externer_barcode | 1:n zu substance_instances; 1:n zu sds_documents |
| **substance_instances** | Vorkommen an einem Lagerort einer Firma | id, substance_id, company_id, storage_location_id, gebindeart, gebindegroesse, anzahl_gebinde, menge_aktuell, mengeneinheit, status, responsible_user_id, foto_url, internal_qr_code_id, created_at, updated_at | substance_id → substances; company_id → companies; storage_location_id → storage_locations |
| **sds_documents** | Sicherheitsdatenblätter | id, substance_id, datei_url, externer_link, revisionsdatum, sprache, hochgeladen_von, hochgeladen_am, version | substance_id → substances |
| **stock_movements** | Mengenbewegungen | id, substance_instance_id, typ (Zugang/Abgang/Korrektur/Umlagerung), menge_delta, einheit, user_id, zeitstempel, notiz | substance_instance_id → substance_instances |
| **qr_codes** | QR-Verwaltung | id, code_wert, target_typ (storage_location/substance_instance/substance), target_id, erstellt_am, gedruckt | polymorph auf storage_locations / substance_instances / substances |
| **alerts** | Hinweise/Warnungen | id, bezug_typ, bezug_id, typ (SDB_fehlt/SDB_veraltet/Menge_fehlt/Firma_fehlt/Lagerort_fehlt/Zusammenlagerung_pruefen), schwere, status (offen/erledigt), erstellt_am, erledigt_am | bezug_id → substance_instances / substances |
| **audit_logs** | Änderungsprotokoll | id, entity_typ, entity_id, aktion, user_id, zeitstempel, alt_wert, neu_wert | user_id → users |

**Beziehungsüberblick:**
```
companies 1---n storage_locations
companies 1---n users
companies 1---n substance_instances
substances 1---n substance_instances
substances 1---n sds_documents
substance_instances 1---n stock_movements
qr_codes 1---1 (storage_location | substance_instance | substance)
```

---

## 13. Automatisierungen

| Automation | Wirkung |
|---|---|
| Firmenzuordnung über Lagerort | Lagerort-QR setzt automatisch die zugehörige Firma. |
| Lagerortübernahme per QR | Gescannter Lagerort wird für alle folgenden Erfassungen vorbelegt. |
| Stoffsuche nach Scan | Externer Barcode/interner QR → automatischer Match im Stoffstamm. |
| Automatische QR-Code-Generierung | Neuer Bestandsdatensatz erhält automatisch internen QR. |
| Warnung bei fehlender Menge/Firma/Lagerort | Pflichtfeld-Prüfung erzeugt Hinweis. |
| Markierung bei fehlendem SDB | Bestand ohne SDB wird sichtbar markiert. |
| Markierung bei altem SDB | Revisionsdatum > Schwellwert (*Annahme:* 3 J.) → Hinweis. |
| Zeitstempel | Erstellung/Änderung automatisch protokolliert. |
| User-Logging | Jede Änderung mit Benutzer im Audit-Log. |
| GPS als Zusatz | Optional bei Erfassung erfasst, nie steuernd. |

---

## 14. MVP-Abgrenzung

| Stufe | Inhalt |
|---|---|
| **Version 1 (zwingend)** | Lagerort scannen, Artikel scannen, manuelle Ergänzung, Firma zuordnen, Filter pro Firma, SDB hinterlegen (Datei/Link), Piktogramme anzeigen, interner QR pro Artikel, Suche, Export. |
| **Version 2 (sinnvoll)** | Stock_movements/Mengenhistorie, Hinweise-Dashboard, Lagerort-Hierarchie mit Druck-Etiketten, Rollen/Rechte vollständig, Audit-Log-Ansicht, Foto-Upload. |
| **Spätere Ausbaustufen** | Zusammenlagerungs-Prüflogik, Schnittstellen (z.B. Lieferanten-SDB-Import), Push-Erinnerungen für SDB-Prüfung, Offline-Modus, Mehrsprachigkeit (DE/FR/IT). |

---

## 15. Praxisbeispiele

**1) Werkhof Tozzo AG BL**
- *Ausgangslage:* Gefahrstoffschrank mit diversen Reinigern, kein Überblick über Mengen.
- *Scan-Ablauf:* Lagerort-QM «Werkhof Liestal / Schrank A3» scannen → Reiniger-Barcode scannen → Treffer im Stoffstamm.
- *Erfasste Daten:* Menge 4 × 5 l, Status «im Einsatz», SDB verknüpft.
- *Nutzen:* Bestand und SDB sofort dokumentiert und abrufbar.

**2) Baustelle Tozzo AG SO**
- *Ausgangslage:* Mobile Baustelle, kein fester Lagerort-QR.
- *Scan-Ablauf:* Lagerort manuell «Baustelle Olten Süd / Container 1» erfassen → Bauschaumdose scannen.
- *Erfasste Daten:* Menge 12 Dosen, GPS optional erfasst.
- *Nutzen:* Erfassung auch ohne vorhandenes Lagerort-Etikett.

**3) Magazin habö AG**
- *Ausgangslage:* Neuer Stoff (Spezialkleber) ohne Eintrag.
- *Scan-Ablauf:* Lagerort-QR scannen → Barcode scannen → kein Treffer → Neuanlage Stoffstamm + Minimaldaten.
- *Erfasste Daten:* Produktname, Hersteller, Piktogramme, SDB-Link, Menge.
- *Nutzen:* Neuer Stoff sauber im Stamm, sofort gruppenweit nutzbar.

**4) Werkstatt PNT AG**
- *Ausgangslage:* Altölbestand und Bremsenreiniger zu prüfen.
- *Scan-Ablauf:* interner Artikel-QR scannen → Stoffkarte öffnet direkt.
- *Erfasste Daten:* Hinweis «SDB älter als 3 Jahre – prüfen» erscheint.
- *Nutzen:* Fällige SDB-Prüfung wird sichtbar.

**5) Containerlager Etraxa AG**
- *Ausgangslage:* Sonderabfall-Sammelstelle, mehrere Gebinde.
- *Scan-Ablauf:* Lagerort-QR «Containerlager / Sonderabfall» → mehrere Artikel nacheinander scannen.
- *Erfasste Daten:* Mengen je Gebinde, wassergefährdend ja, Status «zur Entsorgung».
- *Nutzen:* Übersicht über Sonderabfall mit Mengen und Gefahrenmerkmalen.

---

## 16. Beispiel-User-Flow (Alltagssprache)

> Marco, Polier bei der Tozzo AG BL, kommt morgens in den Werkhof. Am Gefahrstoffschrank klebt ein QR-Code. Er öffnet die App auf dem Handy, tippt auf «Lagerort scannen» und hält die Kamera auf den Code. Die App zeigt sofort: «Tozzo AG BL – Werkhof Liestal – Schrank A3». Er tippt auf «Artikel scannen» und scannt den Barcode eines Kanisters Frostschutz. Die App erkennt den Stoff, zeigt die Piktogramme und das SDB an und fragt nur noch nach der Menge. Marco gibt «3 Kanister à 5 l» ein und bestätigt. Die App erzeugt einen internen QR-Code, den Marco ausdruckt und auf den Kanister klebt. Eine Woche später scannt ein Kollege diesen internen QR – und sieht sofort alle Infos, das SDB inklusive.

---

## 17. Informationsarchitektur (Sitemap)

```
Start
├── Lagerort scannen
│     └── Artikel scannen
│           ├── Stoffkarte (Treffer)
│           └── Schnellerfassung (kein Treffer)
├── Artikel scannen (direkt)
│     └── Lagerort nachtragen
├── Suche
│     └── Stoffkarte
├── Bestand
│     ├── Filter (Firma / Lagerort / Stoff / Status / SDB)
│     ├── Lagerortdetail
│     └── Stoffkarte
├── Hinweise (Alerts)
└── Admin
      ├── Firmen
      ├── Benutzer & Rollen
      ├── Stoffstamm
      ├── Lagerorte (inkl. QR-Druck)
      └── Export
```

---

## 18. UI-Komponentenliste

Startbuttons (gross), Lagerort-Kontextleiste, Scan-Kamera-Ansicht, Stoffkarte, Piktogramm-Badges, Mengenfeld (Stepper), Status-Badge, Warnhinweis-Box, SDB-Linkmodul/Button, interner QR-Code-Panel, Filterleiste, Bestandsliste (Karten/Tabelle), Lagerortdetail-Liste, Suchfeld, Schnellerfassungs-Formular, Verlaufsdarstellung (Timeline), Export-Button, Admin-Tabellen, Toast/Bestätigung, Leerzustand-Box.

---

## 19. Beispieltexte / Microcopy

**Buttons:**
- «Lagerort scannen»
- «Artikel scannen»
- «Stoff manuell erfassen»
- «SDB verknüpfen»
- «Internen QR-Code anzeigen»
- «Bestand exportieren»

**Fehlermeldungen:**
- «Kein Lagerort gewählt. Bitte zuerst Lagerort scannen oder auswählen.»
- «Stoff nicht erkannt. Manuell erfassen?»
- «Menge fehlt. Bitte Menge und Einheit angeben.»

**Warnhinweise:**
- «Kein SDB hinterlegt – bitte ergänzen.»
- «SDB ist älter als 3 Jahre – bitte prüfen.»
- «Bitte prüfen: brennbar und oxidierend am selben Lagerort.»

**Bestätigungen:**
- «Bestand erfasst. Interner QR-Code wurde erstellt.»
- «Lagerort gesetzt: {Firma} – {Standort} – {Bereich}.»
- «SDB erfolgreich verknüpft.»

**Leere Zustände:**
- «Noch keine Stoffe an diesem Lagerort erfasst. Jetzt ersten Artikel scannen.»
- «Keine Treffer. Suchbegriff anpassen oder Stoff neu anlegen.»

**Footer-Hinweis (dauerhaft):**
- «Diese App unterstützt die betriebliche Organisation. Beurteilung vor Ort und Instruktion bleiben erforderlich.»

---

## 20. Priorisierung und Risiken

**10 priorisierte Anforderungen:**
1. Lagerort-QR-Scan setzt Firma + Lagerort.
2. Artikel-Scan mit Stoffstamm-Match.
3. Trennung Stoffstamm / Vorkommen im Datenmodell.
4. Mengen-/Gebindeerfassung auf dem Vorkommen.
5. SDB als Datei oder Link, mit Revisionsdatum.
6. GHS-Piktogramme + H-/P-Sätze auf der Stoffkarte.
7. Interner QR-Code pro Bestandsdatensatz.
8. Firmenfilter und gruppenweite Sicht.
9. Warnhinweise (SDB fehlt/veraltet, Pflichtfelder).
10. Suche und Export.

**5 Risiken / Stolpersteine:**
1. Datenqualität bei manueller Erfassung (unvollständige Datensätze).
2. Pflege des Stoffstamms (Doppelerfassungen identischer Stoffe).
3. Akzeptanz vor Ort (App muss schneller sein als Excel/Papier).
4. Etiketten-Handling auf Baustelle (Haltbarkeit, Lesbarkeit der QR).
5. Verwechslung Stoffstamm vs. Vorkommen durch Anwender.

**5 Empfehlungen für Einführung und Rollout:**
1. Mit einer Pilotfirma starten (z.B. Tozzo AG BL Werkhof).
2. Stoffstamm vorab zentral mit häufigen Stoffen befüllen.
3. Lagerorte vorab definieren und Etiketten drucken.
4. Kurzinstruktion (1 Seite) + Vor-Ort-Schulung für Polier/Magazinverantwortliche.
5. Schrittweiser Rollout je Firma, mit IMS als zentralem Ansprechpartner.

---

## 21. Abschluss Teil A

**3 Produktnamen:**
- **StoffScan** – schlicht, beschreibt scan-first.
- **GefaStoff Mobil** – klar, betont Gefahrstoff + mobil.
- **LagerLog** – betont Lagerort und Protokoll.

**Empfohlener Produktname:** **StoffScan** (kurz, eindeutig, spiegelt das Kernprinzip «scan-first»).

**MVP-Scope (klar):** Lagerort scannen → Artikel scannen → Stoff erkennen/anlegen → Minimaldaten + SDB → interner QR → Stoffkarte; plus Firmenfilter, Suche, Export, Piktogramm-/Warnanzeige. Datenmodell mit Trennung Stoffstamm/Vorkommen.

**Management-Zusammenfassung:** StoffScan schafft eine mobile, scan-first nutzbare Übersicht über gefährliche Stoffe in der tozzo gruppe und ihren Tochterfirmen. Mitarbeitende scannen zuerst den Lagerort, dann den Artikel, und erfassen oder rufen in wenigen Klicks alle relevanten Stoffinformationen inkl. SDB ab. Die strikte Trennung von Stoffstamm und lagerortbezogenem Bestand sorgt für saubere Daten über mehrere Firmen und Lagerorte hinweg. Die App ist als betriebliche Unterstützung konzipiert und ersetzt weder Rechtsberatung noch die Beurteilung vor Ort.

---

# TEIL B – UMSETZUNGSBRIEFING FÜR EINEN KLICKBAREN WEB-APP-PROTOTYP

## 1. Ziel des Prototyps

Der Prototyp soll die **Benutzerführung, Informationsarchitektur und Kernlogik** von StoffScan erlebbar machen – ohne echtes Backend, ohne Bezahlplattform, mit Mock-Daten. Klickbar sein müssen mindestens:
- Lagerort scannen (simuliert) → Artikel scannen (simuliert) → Stoffkarte.
- Manuelle Erfassung eines neuen Stoffs.
- Bestand nach Firma filtern.
- Internen QR-Code und SDB-Link anzeigen.

## 2. Prototyp-Umfang (Pflicht-Screens)

1. Startscreen
2. Lagerort scannen
3. Artikel scannen
4. Manueller Erfassungsdialog
5. Stoffdetailseite (Stoffkarte)
6. Lagerortdetailseite
7. Firmenfilter / Bestandsliste
8. Admin-/Verwaltungsansicht
9. QR-Code-Anzeige pro Artikel
10. SDB-Anzeige / SDB-Link

## 3. Screen-by-Screen-Beschreibung

| Screen | Zweck | Sichtbare Infos | Primäre Aktion | Sekundäre Aktionen | Navigation | Mobile Verhalten |
|---|---|---|---|---|---|---|
| **Startscreen** | Einstieg | 2 grosse Buttons, aktive Firma | «Lagerort scannen» | Artikel scannen, Suche, Bestand | zu allen Hauptbereichen | Vollflächige Buttons, Daumenzone |
| **Lagerort scannen** | Kontext setzen | simulierte Kamera, Lagerort-Liste | «Scan simulieren» | Lagerort manuell wählen | → Artikel scannen | Kamera-Platzhalter füllt Screen |
| **Artikel scannen** | Stoff erfassen | Kontextleiste (Firma+Lagerort), Kamera | «Scan simulieren» | manuell erfassen | → Stoffkarte oder Erfassung | Kontextleiste sticky oben |
| **Manueller Erfassungsdialog** | Neuanlage | reduzierte Felder | «Speichern» | abbrechen | → Stoffkarte | Felder gestapelt, grosse Eingaben |
| **Stoffkarte** | Stoffinfo | Piktogramme, H/P, Menge, Lagerort, SDB, QR | «SDB öffnen» | QR anzeigen, bearbeiten | zurück / zu Lagerort | Karten-Layout, scrollbar |
| **Lagerortdetail** | Bestand je Lagerort | Pfad, Bestandsliste, QR | «Lagerort-QR anzeigen» | exportieren | → Stoffkarten | Liste als Karten |
| **Firmenfilter/Bestandsliste** | Übersicht | Filterleiste, Liste, Warn-Badges | Filter setzen | exportieren | → Stoffkarten | Filter als Chips |
| **Adminansicht** | Verwaltung | Firmen, Stoffstamm, Lagerorte | (Demo) | QR drucken (simuliert) | Tabs | Tabs/Akkordeon |
| **QR-Anzeige** | QR pro Artikel | QR-Platzhalter, interner Code | «Schliessen» | drucken (simuliert) | Overlay | Modal vollflächig |
| **SDB-Anzeige** | SDB | PDF-Platzhalter/Link, Revisionsdatum | «Link öffnen» | zurück | Overlay/Seite | Modal/Seite |

## 4. Klickpfade (User Journeys)

1. **Lagerort zuerst, dann Artikel:** Start → Lagerort scannen → Scan simulieren → Artikel scannen → Scan simulieren → Stoffkarte.
2. **Artikel direkt, Lagerort nachtragen:** Start → Artikel scannen → Scan simulieren → Hinweis «Lagerort fehlt» → Lagerort wählen → Stoffkarte.
3. **Bestehenden Stoff suchen:** Start → Suche → Treffer → Stoffkarte.
4. **Stoff manuell ergänzen:** Artikel scannen → kein Treffer → manueller Erfassungsdialog → Speichern → Stoffkarte.
5. **Internen QR anzeigen:** Stoffkarte → «Internen QR-Code anzeigen» → Modal.
6. **Bestände nach Firma filtern:** Start → Bestand → Firmenfilter → gefilterte Liste.

## 5. Mock-Daten

**Firmen:** tozzo gruppe ag (Gruppe), Tozzo AG BL, Tozzo AG SO, habö AG, PNT AG, Etraxa AG.

**Lagerorte (Beispiele):**
- Tozzo AG BL – Werkhof Liestal – Schrank A3
- Tozzo AG SO – Baustelle Olten Süd – Container 1
- habö AG – Magazin – Regal R2
- PNT AG – Werkstatt – Schrank W1
- Etraxa AG – Containerlager – Sonderabfall

**Beispielstoffe (Stoffstamm):**

| Produktname | Hersteller | Piktogramme | Signalwort | SDB-Revision | Menge-Beispiel |
|---|---|---|---|---|---|
| Frostschutz blau | MusterChem | entzündbar, gesundheitsschädlich | Achtung | 2024-03 | 3 × 5 l |
| Bremsenreiniger | KFZ-Tech | entzündbar | Gefahr | 2021-06 (alt → Hinweis) | 12 Dosen |
| Spezialkleber X | BauKleb | reizend | Achtung | – (fehlt → Hinweis) | 6 Tuben |
| Altöl (Sonderabfall) | – | umweltgefährlich | Achtung | 2023-11 | 2 × 200 l |
| Bauschaum | FoamPro | entzündbar, Druckgas | Gefahr | 2025-01 | 12 Dosen |

**QR-Codes:** Platzhalter-Grafiken; interner Code z.B. `INST-000123`. **SDB-Links:** Platzhalter (`#`-Link oder Beispiel-PDF). **Warnhinweise:** wie in Tabelle (SDB fehlt/alt) sichtbar als Badge.

## 6. UI-/Designvorgaben

Sachlich, professionell, robust, funktional. Keine verspielte Optik. Gute Lesbarkeit auf Mobilgeräten (grosse Schrift, hoher Kontrast). Klare Farblogik für Gefahrhinweise (rot = Gefahr/entzündbar, orange = Achtung, grün = umweltgefährlich, grau = neutral/Status). Einfache Karten, Listen und Formulare. Fokus auf Bedienbarkeit statt Showeffekte. *Annahme:* Systemfont, Akzentfarbe dezent (z.B. dunkles Blau/Anthrazit), Gefahrenfarben nur für Badges.

## 7. Komponentenlogik (Prototyp)

- **Scan-Kachel:** grosser Button mit Icon, öffnet Scan-Screen (Kamera-Platzhalter).
- **Lagerort-Kontextleiste:** sticky Leiste mit Firma + Lagerort, immer sichtbar nach Lagerort-Scan.
- **Stoffkarte:** Kopf mit Produktname + Piktogramm-Badges, darunter Menge/Lagerort/Firma, SDB- und QR-Button.
- **QR-Code-Panel:** Modal mit QR-Platzhalter + internem Code + Druck-Button (simuliert).
- **Piktogramm-Badges:** kleine Icons mit Beschriftung, einheitliche Grösse.
- **Mengenfeld:** Stepper (− / Zahl / +) + Einheit-Dropdown.
- **Status-Badge:** farbig (z.B. «im Einsatz», «zur Entsorgung», «Restbestand»).
- **Warnhinweis-Box:** farbige Box mit Icon und Klartext.
- **SDB-Linkmodul:** Button «SDB öffnen» + Revisionsdatum + Statushinweis.
- **Filterleiste:** Chips für Firma/Lagerort/Status/«ohne SDB».
- **Verlaufsdarstellung:** einfache Timeline (Datum, Benutzer, Aktion).

## 8. Interaktionslogik

- **Klick «Lagerort scannen»:** Scan-Screen öffnet (Kamera-Platzhalter) → «Scan simulieren» wählt einen Mock-Lagerort → Kontextleiste wird gesetzt → Wechsel zu «Artikel scannen».
- **Klick «Artikel scannen»:** Scan-Screen öffnet → «Scan simulieren» → Match in Mock-Stoffstamm → Stoffkarte; bei «unbekannt simulieren» → Hinweis + manueller Dialog.
- **Unbekannter Artikel:** Meldung «Stoff nicht erkannt. Manuell erfassen?» → öffnet Erfassungsdialog mit Pflichtfeldern.
- **Fehlendes SDB:** rote/orange Warn-Box auf der Stoffkarte: «Kein SDB hinterlegt – bitte ergänzen.»
- **Unvollständiger Datensatz:** Pflichtfeld-Hinweis (z.B. «Menge fehlt»); Speichern erst nach Eingabe oder als Entwurf markiert.
- **Interner QR öffnen:** Modal mit QR-Platzhalter und internem Code; «Drucken» zeigt nur eine simulierte Bestätigung.

## 9. Technische Empfehlung für den Prototyp

- **Statische Web-App**, mobile-first, responsive für Handy und Tablet.
- **HTML/CSS/JavaScript** (einseitige App / SPA-artig, ohne Framework-Pflicht; React optional, aber nicht nötig).
- **Mock-Daten lokal** als JavaScript-Objekt/JSON im Code (kein echtes Backend, kein localStorage erforderlich – State im Speicher).
- **Kein echtes Login**, aber Rolle simulierbar über einen Umschalter (z.B. «Mitarbeitender» / «IMS-Admin»).
- **Keine echte Scanner-Integration**: Scan über Button «Scan simulieren» mit Auswahl aus Mock-Daten.
- **QR-Codes** als Platzhalter-Grafik oder einfach generierter Beispielcode darstellen.
- Keine externen Bezahldienste, keine Bibliotheken zwingend nötig.

## 10. Artefakt für Claude

Der folgende Block ist als direkter Folgeprompt formuliert und kann unverändert eingesetzt werden, um den klickbaren Prototyp zu erzeugen.

---

## FOLGEPROMPT FÜR DEN PROTOTYP

```
Erstelle einen klickbaren, mobile-first Web-App-Prototyp für die Gefahrstoff-App
"StoffScan" der tozzo gruppe ag als EINE einzelne HTML-Datei mit eingebettetem
CSS und JavaScript (kein externes Framework nötig, kein Backend, keine
Bezahldienste, kein localStorage – State nur im Speicher). Responsive für Handy
und Tablet, robust und sachlich gestaltet (keine verspielte Optik), grosse
Buttons, hoher Kontrast, klare Gefahren-Farblogik (rot = Gefahr/entzündbar,
orange = Achtung, grün = umweltgefährlich, grau = neutral).

KERNPRINZIP: "Zuerst Lagerort scannen, dann Artikel scannen." Scans werden über
einen Button "Scan simulieren" nachgestellt (keine echte Kamera).

DATENMODELL (zwingend trennen):
- Stoffstamm (substances): produktbezogen, einmalig.
- Vorkommen/Bestand (instances): Firma + Lagerort + Menge + Status + interner QR.
Ein Stoff kann in mehreren Firmen und Lagerorten vorkommen; Menge/Status/Lagerort
liegen auf dem Vorkommen.

MOCK-DATEN (im Code hinterlegen):
- Firmen: tozzo gruppe ag (Gruppe), Tozzo AG BL, Tozzo AG SO, habö AG, PNT AG,
  Etraxa AG.
- Lagerorte: Tozzo AG BL/Werkhof Liestal/Schrank A3; Tozzo AG SO/Baustelle Olten
  Süd/Container 1; habö AG/Magazin/Regal R2; PNT AG/Werkstatt/Schrank W1;
  Etraxa AG/Containerlager/Sonderabfall.
- Stoffe (mit Piktogrammen, Signalwort, H-/P-Sätzen, SDB-Revision, Menge):
  Frostschutz blau (entzündbar, SDB 2024-03), Bremsenreiniger (entzündbar,
  SDB 2021-06 -> "SDB prüfen"), Spezialkleber X (reizend, KEIN SDB ->
  "SDB fehlt"), Altöl Sonderabfall (umweltgefährlich), Bauschaum (entzündbar,
  Druckgas).
- Interne QR-Codes als Platzhaltergrafik + Code (z.B. INST-000123).
- SDB als Platzhalter-Link/PDF.

SCREENS (alle klickbar, Navigation untereinander):
1. Startscreen: grosse Buttons "Lagerort scannen" und "Artikel scannen",
   darunter "Suche" und "Bestand"; aktive Firma + Rollen-Umschalter
   (Mitarbeitender / IMS-Admin) sichtbar.
2. Lagerort scannen: Kamera-Platzhalter, Button "Scan simulieren" (wählt Mock-
   Lagerort), Alternative "Lagerort manuell wählen". Setzt Kontextleiste.
3. Artikel scannen: sticky Kontextleiste (Firma + Lagerort), Button
   "Scan simulieren" (Treffer -> Stoffkarte) und "Unbekannt simulieren"
   (-> manueller Dialog).
4. Manueller Erfassungsdialog: reduzierte Pflichtfelder (Produktname, Menge,
   Einheit, Status), optionale Felder aufklappbar; "Speichern" -> Stoffkarte.
5. Stoffkarte: Piktogramm-Badges, Signalwort, H-/P-Sätze, Menge/Gebinde,
   Lagerort, Firma, Warn-Box bei fehlendem/altem SDB, Buttons "SDB öffnen" und
   "Internen QR-Code anzeigen", Verlauf (Timeline).
6. Lagerortdetail: Lagerort-Pfad, Bestandsliste, Button "Lagerort-QR anzeigen",
   "Exportieren" (simuliert).
7. Bestandsliste mit Firmenfilter: Filter-Chips (Firma, Lagerort, Status,
   "ohne SDB"), Liste mit Warn-Badges, Klick -> Stoffkarte.
8. Adminansicht: Tabs Firmen / Stoffstamm / Lagerorte; QR-Druck simuliert.
9. QR-Anzeige: Modal mit QR-Platzhalter + internem Code + "Drucken" (simuliert).
10. SDB-Anzeige: Modal/Seite mit Platzhalter-Link + Revisionsdatum + Statushinweis.

KLICKPFADE, die funktionieren müssen:
- Lagerort scannen -> Artikel scannen -> Stoffkarte.
- Artikel direkt scannen -> Hinweis "Lagerort fehlt" -> Lagerort wählen ->
  Stoffkarte.
- Suche -> Treffer -> Stoffkarte.
- Unbekannter Artikel -> manueller Dialog -> Speichern -> Stoffkarte.
- Stoffkarte -> internen QR anzeigen.
- Bestand -> nach Firma filtern.

MICROCOPY (Deutsch, CH-Schreibweise mit "ss" statt "ß"):
- "Kein Lagerort gewählt. Bitte zuerst Lagerort scannen oder auswählen."
- "Stoff nicht erkannt. Manuell erfassen?"
- "Kein SDB hinterlegt – bitte ergänzen."
- "SDB ist älter als 3 Jahre – bitte prüfen."
- "Bestand erfasst. Interner QR-Code wurde erstellt."
- Dauerhafter Footer: "Diese App unterstützt die betriebliche Organisation.
  Beurteilung vor Ort und Instruktion bleiben erforderlich."

WICHTIG: Alles in einer Datei, ohne externe Abhängigkeiten, sofort im Browser
lauffähig. Fokus auf nachvollziehbare Benutzerführung, nicht auf Perfektion der
Daten. Kennzeichne Demo-/Mock-Charakter dezent im UI.
```
