# StoffScan – Launch-Testliste (Live-Klickpfad)

**Zweck:** Vor dem Aufschalten echter Kunden einmal die **ganze App eingeloggt gegen die Live-Datenbank** durchklicken. Diese Liste geht Schritt für Schritt jeden kritischen Ablauf durch, mit **konkreter Aktion** und **erwartetem Ergebnis**. Haken setzen, was funktioniert; Abweichungen unten unter „Fehler-Notizen" festhalten.

> Warum manuell: Der Kamera-QR-Scan, die echten Signed-URLs für SDB-Downloads und die Mandantentrennung (RLS) lassen sich nur **auf der deployten HTTPS-Seite mit echtem Login** verlässlich prüfen – nicht im Code-Test.

**Live-App:** `https://gefahrstoffe-neu.filip-subara.workers.dev/live/`
**Getestet am:** ________  **Getestet von:** ________  **Gerät/Browser:** ________

Legende: `[ ]` offen · `[x]` ok · `[!]` Fehler (unten notieren)

---

## 0. Vorbereitung

- [ ] Zwei Test-E-Mail-Adressen bereit (für Mandantentrennung in Abschnitt 9). Tipp: `deinname+test1@gmail.com` und `deinname+test2@gmail.com` – beide landen in deinem Postfach.
- [ ] Eine Beispiel-PDF bereit, die als Sicherheitsdatenblatt hochgeladen wird (irgendein PDF genügt für den Test).
- [ ] Live-URL im Browser geöffnet, Seite lädt ohne Fehlermeldung.

## 1. Registrierung & Login

- [ ] **Neu registrieren** mit Test-Adresse 1 → Bestätigungs-E-Mail kommt an.
- [ ] Bestätigungslink geöffnet → Login möglich.
- [ ] Nach Login erscheint der **Plan-Auswahl-Schritt** (Onboarding). Starter/Pro sichtbar, Preise 129 / 349 CHF.
- [ ] Plan gewählt → man landet im Dashboard.
- [ ] **Falsches Passwort** wird sauber abgewiesen (klare Fehlermeldung, kein Absturz).
- [ ] **Passwort-zurücksetzen**-Link funktioniert (E-Mail kommt an).

## 2. Onboarding-Leitfaden (Ersteinrichtung)

- [ ] Dashboard zeigt oben die Karte **„Willkommen bei StoffScan"** mit Fortschritt **0/3** (nicht die grüne „100% prüfbereit"-Karte!).
- [ ] Drei Schritte sichtbar: Betrieb erfassen · Lagerort anlegen · Ersten Gefahrstoff aufnehmen. **Schritt 1 ist hervorgehoben** („Jetzt →").
- [ ] Shortcuts **„Branchen-Starterkatalog öffnen"** und **„Team einladen (optional)"** vorhanden.
- [ ] Klick auf **Schritt 1** springt in die Firmen-Verwaltung.

## 3. Betrieb & Lagerort anlegen

- [ ] **Firma hinzufügen** (Verwaltung → Firmen): Name eingeben, speichern → Firma erscheint in der Liste.
- [ ] Zurück zum Dashboard: Onboarding-Fortschritt jetzt **1/3**, Schritt 1 abgehakt.
- [ ] **Lagerort hinzufügen** (Verwaltung → Lagerorte): Name/Bereich/Typ + Firma wählen, speichern → erscheint in der Liste.
- [ ] Dashboard-Fortschritt jetzt **2/3**, Schritt 3 hervorgehoben.

## 4. Gefahrstoff aufnehmen

- [ ] **Starterkatalog** öffnen → eine Branche wählen (z. B. Maler) → Vorschau zeigt typische Stoffe → **übernehmen** → Toast „X Stoffe übernommen".
- [ ] Alternativ **„Gefahrstoff aufnehmen"** → Lagerort setzen → **„Unbekannter Artikel – neu erfassen"** → Formular ausfüllen (Name, Hersteller, GHS, H/P-Sätze, Menge) → speichern.
- [ ] Neuer Bestand erscheint in **Bestände** und auf dem Dashboard (KPI „Datensätze" > 0).
- [ ] Onboarding-Karte ist jetzt **verschwunden**, stattdessen erscheint die **Compliance-Lotse**.

## 5. Sicherheitsdatenblatt (SDB) & Versionierung

- [ ] Stoffkarte öffnen → **SDB** → Beispiel-PDF **hochladen** → Toast „SDB verknüpft".
- [ ] SDB **öffnen** → PDF öffnet sich (Signed-URL funktioniert, kein 403).
- [ ] **Zweite** SDB-Version hochladen → Abschnitt **„SDB-Versionen"** listet beide, neueste trägt Badge **„aktuell"**.
- [ ] Hinweis „Bei neuer Version Mitarbeitende neu instruieren" erscheint bei >1 Version.
- [ ] Ältere Version über **„öffnen"** ist weiterhin abrufbar.

## 6. QR-Codes & Etiketten

- [ ] **Interner Artikel-QR** (Stoffkarte → QR): QR wird angezeigt, Code lesbar.
- [ ] **Etikette drucken** → Druckansicht zeigt Signalwort, GHS-Piktogramme, UN-Nummer.
- [ ] **Lagerort-QR** erzeugen und Etikette drucken.
- [ ] **QR mit dem Handy scannen** (siehe Abschnitt 15): öffnet die richtige Stoffkarte / setzt den Lagerort.

## 7. Anonymer Scan (Öffentlichkeit)

- [ ] Artikel-QR **ohne eingeloggt zu sein** (privates Browserfenster) scannen → es erscheint nur die **Sicherheits-Kurzkarte** (Signalwort, GHS, Sofortmassnahmen) – **keine** internen Bestände/Mengen/Firmendaten.

## 8. Freigabe-Workflow

- [ ] Einen neu erfassten Stoff, der auf Freigabe wartet, im Dashboard/Handlungsbedarf finden.
- [ ] **Freigeben** → Status wechselt auf freigegeben, Eintrag im Audit-Log.
- [ ] **Ablehnen** (anderer Stoff) → Status wechselt, Begründung wird protokolliert.

## 9. Rollen & Mandantentrennung (RLS) – der wichtigste Sicherheitstest

- [ ] **Person einladen** (Verwaltung → Personen) mit Test-Adresse 2, Rolle z. B. „Mitarbeitend" → Einladung erscheint als „wartet auf Registrierung".
- [ ] In **privatem Fenster** mit Adresse 2 registrieren/einloggen.
- [ ] Adresse 2 sieht **nur** die Daten der eingeladenen Firma/Gruppe – **nicht** die eines fremden Mandanten.
- [ ] Als „Mitarbeitend": **kein** Zugriff auf die Verwaltung (klare „Kein Zugriff"-Meldung).
- [ ] Admin kann Rolle einer Person ändern und Personen entfernen (ausser sich selbst).

## 10. Compliance-Lotse & Handlungsbedarf

- [ ] Lotse zeigt einen **Prozent-Score** und die **wichtigsten offenen Punkte** (SDB fehlt, Menge fehlt, Zusammenlagerung).
- [ ] Klick auf einen Punkt springt zur richtigen Stelle.
- [ ] Ein **Zusammenlagerungs-Konflikt** (zwei unverträgliche Lagerklassen am selben Lagerort) wird als Warnbanner angezeigt.

## 11. Prüf-Dossier & Audit-Log

- [ ] **Prüf-Dossier** exportieren (Verwaltung → Export) → PDF/Druckansicht mit allen Seiten inkl. Audit-Log-Seite.
- [ ] **Audit-Log** (Verwaltung → Audit-Log) zeigt lückenlose Einträge mit Zeitstempel und Person.

## 12. Betriebsanweisung & Unterweisung (mehrsprachig)

- [ ] Stoffkarte → **Betriebsanweisung** wird generiert (PSA, Erste Hilfe, H/P-Sätze).
- [ ] Sprache auf **FR** und **IT** umschalten → H-/P-Sätze erscheinen in offizieller Formulierung.
- [ ] Unterweisung/Instruktion für eine Person erfassen und protokollieren.

## 13. KI-Assistent

- [ ] **„Frag StoffScan"** öffnen, eine Fachfrage stellen → Antwort kommt, **Disclaimer** sichtbar.
- [ ] Assistent erfindet keine Rechtsauskunft (Hinweis auf betriebliche Unterstützung).

## 14. Rechtstexte & Kontakt

- [ ] Fusszeile-Links **Impressum / Datenschutz / AGB** öffnen und laden korrekt.
- [ ] In den Rechtstexten steht **kein Stripe** mehr (Zahlung per Rechnung).
- [ ] Kontakt-E-Mail einheitlich `kontakt@stoffscan.ch` (Platzhalter bis eigene Domain).

## 15. Preise & Anfrage

- [ ] Marketing-Startseite → Preise: **zwei** Pakete (Starter 129 / Pro 349).
- [ ] Klick auf ein Paket öffnet eine **vorbefüllte E-Mail** (mailto) an `kontakt@stoffscan.ch`.

## 16. Mobil (Handy)

- [ ] Live-URL am **Handy** öffnen, einloggen → Layout ohne horizontales Scrollen, Buttons gut erreichbar.
- [ ] **Kamera-Scan** starten → Kamerafreigabe erlauben → echten QR scannen → richtige Karte öffnet sich.
- [ ] Etikette am Handy erzeugen und mit einem **zweiten** Handy scannen (Praxistest Lagerort).

## 17. Sicherheits-Spot-Checks

- [ ] **Abmelden** → geschützte Seiten sind ohne Login nicht erreichbar.
- [ ] **Passwort ändern** (Konto) funktioniert, danach Login mit neuem Passwort.
- [ ] Direkter Aufruf einer fremden Stoff-/Firmen-ID (falls URL manipulierbar) liefert **keine** fremden Daten.

---

## Fehler-Notizen

| # | Abschnitt | Was ist passiert | Erwartet | Priorität |
|---|-----------|------------------|----------|-----------|
|   |           |                  |          |           |
|   |           |                  |          |           |
|   |           |                  |          |           |

**Gesamturteil:** ⬜ launch-bereit ⬜ kleine Fixes nötig ⬜ Blocker gefunden
