# App live testen mit Netlify Drop

Damit der **Kamera-Scan** (QR + Barcode) funktioniert, muss die App über eine **HTTPS-Adresse** laufen – nicht als lokal geöffnete Datei. Netlify Drop ist dafür kostenlos und ohne Pflicht-Konto.

## In 5 Schritten online

1. **Datei bereitlegen:** Du brauchst nur `stoffscan-prototyp.html`. Tipp: Datei in `index.html` umbenennen – dann ist die Adresse kürzer (sonst musst du `…/stoffscan-prototyp.html` anhängen).
2. **Seite öffnen:** Im Browser `https://app.netlify.com/drop` aufrufen.
3. **Hochladen:** Die Datei (oder einen Ordner mit der Datei) per Drag & Drop in das Feld ziehen.
4. **Link erhalten:** Nach wenigen Sekunden erscheint eine HTTPS-Adresse, z. B. `https://zufallsname-12345.netlify.app`. Diese ist sofort öffentlich erreichbar.
5. **Am Handy öffnen:** Adresse am Handy eingeben (oder dir per Mail/Chat schicken). Beim ersten Kamera-Scan **Kamerafreigabe erlauben**.

> Ohne Konto bleibt die Seite einige Zeit bestehen. Wenn sie dauerhaft bleiben soll, im erscheinenden Dialog ein kostenloses Konto anlegen («Claim site»).

## QR-Code richtig testen

- Du kannst **nicht** den QR-Code scannen, der auf **demselben** Gerät angezeigt wird.
- Zum Test: In der App einen QR-Code öffnen (Stoffkarte → «QR-Code anzeigen») und entweder **ausdrucken** oder auf einem **zweiten Bildschirm** anzeigen, dann mit dem Handy scannen.
- Scan eines **App-QR** (Lagerort/Artikel) → öffnet direkt den richtigen Datensatz.
- Scan eines **fremden Barcodes/QR mit Internetseite** → die App bietet an, die Seite als **Link** zu hinterlegen (statt alles selbst zu speichern).
- Scan eines **unbekannten Barcodes** → öffnet die Erfassung mit übernommenem Barcode.

## Wichtig zur Datenhaltung (Prototyp)

- Die Daten liegen aktuell **nur lokal im Browser** des jeweiligen Geräts (localStorage). Ein QR, den du am Werkhof aufklebst, öffnet auf einem **anderen** Handy nur dann denselben Datensatz, wenn dort dieselben Daten vorhanden sind.
- Für **geräteübergreifend gemeinsame Daten** braucht es später ein kleines Backend (Datenbank + Hosting). Das ist der Schritt vom Prototyp zum Produkt – die Oberfläche bleibt dabei gleich.

## Andere kostenlose Hosting-Wege (Alternativen)

- **Cloudflare Pages** oder **GitHub Pages**: ebenfalls gratis, HTTPS, etwas mehr Einrichtung (Konto/Repo nötig).
- **Lokal im WLAN** (nur zum schnellen Probieren am eigenen Rechner, Kamera meist nur über localhost):
  im Ordner der Datei `python3 -m http.server 8000`, dann am Rechner `http://localhost:8000` öffnen.
