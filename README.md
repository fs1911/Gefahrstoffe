# StoffScan – Gefahrstoff-Kataster

Mobile-first Web-App zur Erfassung und Verwaltung gefährlicher Stoffe für Bau-,
Werkhof- und Gewerbebetriebe. Kernidee: **zuerst Lagerort scannen, dann Artikel
scannen.** Betriebliche Unterstützung – ersetzt keine Beurteilung vor Ort.

## Inhalt

| Pfad | Zweck |
|---|---|
| `index.html` | Marketing-Landingpage (Domain-Startseite) |
| `app/index.html` | Produkt-Demo (komplette App, HTML/CSS/JS, kein Build) |
| `ROADMAP.md` | Masterplan, Phasen, offene Entscheidungen – **hier startet man** |
| `docs/Fachkonzept.md` | vollständiges Fachkonzept + Prototyp-Briefing |
| `docs/Anleitung_Live-Test.md` | App online stellen und am Handy testen |
| `CLAUDE.md` | Projektkontext für die Arbeit mit Claude Code |

## Schnell starten

1. `index.html` öffnen → Marketing-Seite. Button **«Demo öffnen»** führt zu `app/`.
2. `app/index.html` doppelklicken → Demo mit Musterdaten.
3. Für echten **Kamera-Scan** (QR + Barcode) muss die App über **HTTPS** laufen
   → siehe `docs/Anleitung_Live-Test.md`.

## Wichtiger Stand

- **Prototyp:** Daten liegen nur lokal im Browser (localStorage). Für
  geräteübergreifend gemeinsame Daten ist ein Backend nötig – das ist der
  nächste Schritt (siehe `ROADMAP.md`, Phase 1: Supabase).
- **Datenmodell-Regel:** Stoffstamm und Bestand **strikt trennen** (Details in
  `CLAUDE.md`).
