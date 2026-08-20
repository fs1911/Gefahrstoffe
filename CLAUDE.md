# CLAUDE.md – Projektkontext StoffScan

## Was ist das
**StoffScan** – mobile-first Web-App zur Erfassung und Verwaltung gefährlicher
Stoffe für Bau-, Werkhof- und Gewerbebetriebe (Werkhof, Baustelle, Magazin,
Werkstatt, Containerlager, Sonderabfall). Kernidee: **zuerst Lagerort scannen,
dann Artikel scannen** – danach Stoffinformationen erfassen oder abrufen.

Ziel: aus dem Prototyp ein **verkaufbares Mehrmandanten-SaaS** machen. Der
frühere Kundenbezug (tozzo) ist entfernt; Demo-Daten sind generisch.

Charakter: betriebliche Unterstützung, **ersetzt keine Beurteilung vor Ort**.

> **Immer zuerst `ROADMAP.md` lesen** – dort stehen Phasen, Entscheidungen und
> offene Punkte.

## Aktueller Stand
- Marketing-Landingpage: `index.html` (Root).
- Produkt-Demo: `app/index.html` – ein in sich geschlossenes File
  (HTML/CSS/Vanilla-JS), kein Build.
- Externe CDN-Skripte in der App: `qrcodejs` (QR erzeugen) und `html5-qrcode`
  (Kamera-Scan); Google Fonts (IBM Plex Sans/Mono).
- Daten in der App: **Mock-Daten im JS**, im Browser via `localStorage`
  gespeichert. **Kein Backend** (geplant: Supabase, siehe ROADMAP Phase 1).

## Architektur / harte Regeln (nicht brechen)
- **Trennung Stoffstamm ↔ Bestand ist zwingend:**
  - `substances` (Stoffstamm): produktbezogen, einmalig (Name, Hersteller, GHS,
    H/P-Sätze, UN-Nr, SDB, optional Barcode/Infoseite-Link).
  - `substance_instances` / `DB.instances` (Vorkommen/Bestand): Firma + Lagerort
    + Menge + Gebinde + Status + interner QR. Menge/Lagerort gehören IMMER hierhin,
    nie auf den Stoffstamm. Ein Stoff kann in mehreren Firmen/Lagerorten vorkommen.
- **Scan-first-Flow:** Lagerort setzt den Kontext; Artikel-Scan danach.
  Artikel-Scan ohne Lagerort ist erlaubt, aber klar als Ausnahme markiert.
- **Rollen ohne Login (Prototyp):** Verwaltung (Admin) nur sichtbar bei
  Admin-Rolle (Firmenadmin / Gruppenadmin / IMS). In echt kommt die Rolle aus
  dem Benutzerkonto; im Prototyp per Demo-Umschalter.
- **QR-Logik:** App-QRs kodieren einen Deep-Link `…#open=INST-xxxx` bzw.
  `…#open=LOC-<id>`; scannen öffnet direkt den Datensatz. Fremde URL hinter
  QR/Barcode → als **Link hinterlegen**. Reiner Barcode → bekannten Stoff öffnen
  oder Neuerfassung mit übernommenem Barcode.
- **Mehrmandantenfähigkeit:** generisch bleiben – keine kundenspezifischen Namen
  im Code. Demo-Firmen sind fiktiv (Muster Gruppe AG etc.).
- **Produktname zentral:** «StoffScan» im Header von `app/index.html` und in
  `index.html`. Bei Umbenennung dort ändern.
- **CH-Schreibweise:** «ss» statt «ß». UI-Texte in professionellem CH-Deutsch.
- Piktogramme sind selbstgezeichnete SVG im offiziellen GHS-Stil (rote Raute).

## Wie ausführen / testen
- Lokal: `index.html` bzw. `app/index.html` im Browser öffnen (Kamera-Scan geht
  so NICHT).
- Kamera-Scan (QR + 1D-Barcodes) braucht **HTTPS**: z. B. Netlify Drop
  (siehe `docs/Anleitung_Live-Test.md`) oder localhost.
- Einen angezeigten QR nicht auf demselben Gerät scannen – ausdrucken oder auf
  zweitem Bildschirm anzeigen.

## Konventionen beim Arbeiten
- Bestehende Struktur/Benennung beibehalten; lieber vereinfachen als verkomplizieren.
- Bei UI-Änderungen: mobile-first prüfen, grosse Touch-Ziele, ruhige, sachliche
  (industrielle) Optik – kein verspieltes/SaaS-/KI-Design.
- Vor grösseren Schritten: `ROADMAP.md` prüfen und aktuell halten.
