# StoffScan – Deploy auf Cloudflare Pages (kostenlos, ohne Build-Limit)

Ersetzt Netlify als Static-Host. Der Code bleibt unverändert; Cloudflare Pages
liefert die statischen Dateien aus und deployt automatisch bei jedem Git-Push.

## 1. Cloudflare Pages Projekt anlegen (einmalig)

1. https://dash.cloudflare.com → **Workers & Pages** → **Create** → **Pages** →
   **Connect to Git**.
2. GitHub autorisieren, Repo **`fs1911/Gefahrstoffe`** wählen, Branch **`main`**.
3. Build-Einstellungen (wichtig – es gibt keinen Build):
   - **Framework preset:** `None`
   - **Build command:** *(leer lassen)*
   - **Build output directory:** `/`  (Repo-Wurzel; App liegt unter `/live/`, `/app/`)
4. **Save and Deploy.** Nach ~1 Min ist die Seite unter
   `https://<projektname>.pages.dev` erreichbar (z. B. `stoffscan.pages.dev`).

Die Datei **`_headers`** (Repo-Wurzel) setzt CSP/HSTS/X-Frame-Options usw. –
identisch zur bisherigen `netlify.toml`. Cloudflare Pages liest sie automatisch.

## 2. Nach dem ersten Deploy: neue Domain überall eintragen

Die neue Domain (`https://<projektname>.pages.dev`) muss an drei Stellen bekannt
sein, sonst brechen KI-Scan und Login:

- **Supabase → Authentication → URL Configuration**
  - *Site URL* auf die neue Domain setzen.
  - *Redirect URLs* um die neue Domain ergänzen (für Passwort-Reset).
- **Edge Function `validate-substance`** – Env `ALLOWED_ORIGINS` um die neue
  Domain ergänzen (CORS-Allowlist).
- **Edge Function `parse-sdb`** – Env `PRIMARY_ORIGIN` um die neue Domain
  ergänzen (CORS-Allowlist).

→ Sobald der Projektname feststeht, kann Claude die beiden Edge-Function-Envs
und (per Anleitung) die Supabase-Auth-URLs aktualisieren.

## 3. Eigene Domain (optional, später)

In Cloudflare Pages → **Custom domains** eine eigene Domain (z. B.
`app.stoffscan.ch`) verbinden. Danach dieselben drei Stellen aus Schritt 2 auf
die finale Domain umstellen.

## Kostenrahmen

- **Cloudflare Pages:** kostenlos, unbegrenzte Bandbreite, kein Build-Minuten-Limit.
- **Supabase:** Free-Tier reicht für Test + erste Kunden (Projekt pausiert nach
  längerer Inaktivität – Pro `$25/Mo` erst bei echten Kunden nötig).
- **Anthropic API:** Pay-per-use (~Rappen pro SDB-Scan), kein Abo.
