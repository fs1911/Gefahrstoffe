# StoffScan – Stripe-Anbindung (Block B)

Diese beiden Edge Functions bereiten die Online-Bezahlung vor. **Ohne gesetzte
Stripe-Secrets sind sie inaktiv** – die App merkt sich dann nur den gewählten
Plan (`set_org_plan`) und zeigt keinen Fehler. Sobald die Secrets gesetzt sind,
läuft die echte Bezahlung.

| Funktion | Zweck |
|---|---|
| `create-checkout-session` | erzeugt eine Stripe-Checkout-Session für den gewählten Plan → gibt die Bezahl-URL zurück |
| `stripe-webhook` | empfängt Stripe-Ereignisse und schreibt `plan` / `subscription_status` zurück in `organizations` |
| `parse-sdb` | liest ein Sicherheitsdatenblatt (PDF/Foto) per Claude aus → Produktname, Signalwort, GHS, H-/P-Sätze, UN-Nr., Lagerklasse |
| `ask-stoffscan` | «Frag StoffScan» – beantwortet Fragen (wo steht ein Stoff, Erste Hilfe, fehlende SDB, Zusammenlagerung) geerdet auf die mitgeschickten Betriebsdaten |

### `ask-stoffscan` aktivieren (KI-Chat auf den eigenen Daten)
```bash
supabase secrets set ANTHROPIC_API_KEY=sk-ant-...   # (falls noch nicht gesetzt)
supabase functions deploy ask-stoffscan
```
Ohne Key liefert die Funktion `{ configured:false }` – die App fällt dann auf die
lokale, regelbasierte Antwort-Engine zurück (funktioniert offline, ohne Kosten). Der
Client schickt die Frage plus einen kompakten JSON-Kontext der eigenen Organisation
(Stoffe, Bestände, Lagerorte); Claude antwortet ausschliesslich daraus. Modell in
`index.ts`: `claude-opus-5` (z. B. auf `claude-sonnet-5`/`claude-haiku-4-5` umstellbar
für weniger Kosten).

### `parse-sdb` aktivieren (SDB → Stoffkarte per KI)
```bash
supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
supabase functions deploy parse-sdb
```
Ohne Key liefert die Funktion `{ configured:false }` – die App füllt die Stoffkarte
dann wie bisher manuell aus. Die öffentliche Demo (`/app/`) zeigt den KI-Ablauf als
Simulation mit Beispiel-SDB (kein Key nötig).

Das Datenmodell dazu liegt in `supabase/migrations/0005_subscriptions.sql`
(Felder auf `organizations` + RPC `set_org_plan`).

## Einrichtung (einmalig, wenn Stripe-Konto bereit)

1. **Produkte & Preise** in Stripe anlegen – je ein wiederkehrender Preis
   (jährlich) für **Starter** und **Betrieb**. Preis-IDs (`price_…`) notieren.
   *Gruppe* bleibt «auf Anfrage» (kein Self-Checkout).

2. **Secrets setzen** (Test-Keys zum Ausprobieren, danach Live-Keys):
   ```bash
   supabase secrets set \
     STRIPE_SECRET_KEY=sk_test_xxx \
     STRIPE_WEBHOOK_SECRET=whsec_xxx \
     STRIPE_PRICE_STARTER=price_xxx \
     STRIPE_PRICE_BETRIEB=price_xxx \
     SITE_URL=https://stoffscan.ch
   ```
   `SUPABASE_URL`, `SUPABASE_ANON_KEY` und `SUPABASE_SERVICE_ROLE_KEY` sind in
   Edge Functions automatisch verfügbar.

3. **Deployen:**
   ```bash
   supabase functions deploy create-checkout-session
   supabase functions deploy stripe-webhook --no-verify-jwt
   ```

4. **Webhook in Stripe** anlegen mit Ziel
   `https://<project-ref>.supabase.co/functions/v1/stripe-webhook` und den
   Events `checkout.session.completed`, `customer.subscription.updated`,
   `customer.subscription.deleted`. Das `whsec_…` in die Secrets übernehmen.

5. **Testen:** In der App als Admin → Konto → «Abo & Plan» → Plan wählen.
   Ist Stripe konfiguriert, öffnet sich der Checkout; sonst wird der Plan nur
   vorgemerkt. Nach erfolgreicher Zahlung setzt der Webhook den Status auf
   `active`.

## Sicherheit

- `create-checkout-session` prüft das Benutzer-JWT und erlaubt die Buchung nur
  Rollen `firmenadmin` / `gruppenadmin`.
- `stripe-webhook` verifiziert die Stripe-Signatur und schreibt mit dem
  Service-Role-Key – deshalb `--no-verify-jwt` und niemals im Browser aufrufen.
