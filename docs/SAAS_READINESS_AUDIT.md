# StoffScan – SaaS-Readiness-Audit

**Stand:** 2026-09-04 · **Methode:** code-gestützt (Migrationen, RLS, Edge Functions, Billing, `netlify.toml`, Enforcement-Suche im Live-Client)
**Auslöser:** Abgleich der Codebasis gegen den Perplexity-Leitfaden *„SaaS Pricing, Produktumbau, Härtung"*.
**Verkaufsziel (entschieden):** offener Verkauf an **fremde zahlende Kunden** → der volle P0-Block ist Pflicht.

> **Kernaussage:** Die **Feature-Breite** ist da; die **Produktreife-/Sicherheits-Schicht** ist teils solide (RLS, Checkout-Session, Audit-Tabelle), teils nur Gerüst (Billing-Enforcement), teils offen (SDB-Freigabe-Lifecycle, Infra-Härtung, Betrieb). Der Leitfaden liegt in der Sache richtig, **unterschätzt aber, was schon existiert** — deshalb nicht blind neu bauen.

Scope-Hinweis: **`/live/`** (Supabase, echte Mandanten) ist das Produkt und Gegenstand der Härtung. **`/app/`** ist die Login-freie localStorage-Verkaufsdemo und braucht weder RLS noch Entitlements.

---

## 1. Management-Summary (Ampel je Bereich)

| Bereich | Status | Kurzbefund |
|---|---|---|
| Mandantentrennung / RLS | 🟡 gut, **1 kritischer Bug** | Sauber gebaut; `prof_update_self` erlaubt Selbst-Hochstufung (P0). Keine Cross-Tenant-Tests. |
| Auth / Account-Schutz | 🟡 | Supabase-Auth + Einladungen vorhanden; **keine MFA, keine Rate-Limits**. |
| SDB-Lifecycle & KI-Governance | ❌ **grösste Lücke** | Kein Freigabe-Status, kein Datei-Hash/Malware-Scan, keine Confidence/Quelle, kein Freigabe-Gate, kein Prompt-Injection-Schutz. |
| Betriebsanweisung / Instruktion | 🟡 | Funktion da; **keine eingefrorene, freigegebene Version** (BA wird on-the-fly erzeugt). |
| Audit-Log | 🟡 | Tabelle + insert-only-Policy vorhanden; Export-/Download-Protokollierung und DB-seitige Unveränderlichkeit fehlen. |
| Audit-Dossier | ✅/🟡 | PDF-Dossier vorhanden; XLSX-Export mit Zeitraum + Auditor-Read-only fehlen. |
| Entitlements / Billing | 🟡 **Gerüst** | Checkout-Session sauber; **Limits werden nirgends erzwungen**, Webhook nicht idempotent, nicht live. |
| Security-Härtung (Infra) | ❌ | Keine CSP/HSTS/Clickjacking-Header; CORS `*`; `verify_jwt=false` ohne Rate-Limit; keine CI/Secret-Scanning. |
| Datei-/Upload-Sicherheit | ❌ | Keine MIME-/Signatur-/Grössen-Prüfung, kein Scan/Quarantäne, kein Hash-Dedupe. |
| Betrieb (Backup/Monitoring) | ❌ | Kein Staging≠Prod, kein Error-Tracking, kein Backup-/Restore-Test, kein Incident-Runbook. |
| Datenschutz / Recht | 🟡 (kein Code) | AGB/DSE/Impressum als Muster da; AVV/DPA, Verzeichnis, Löschprozess offen. |

---

## 2. Detail-Findings

### 2.1 Mandantentrennung / RLS — 🟡 (gut gebaut, 1 kritischer Bug)

**Vorhanden & solide:**
- Jede Fachtabelle trägt `organization_id` (`0001_schema.sql`).
- RLS auf **allen** Kundentabellen aktiv (`0002_rls.sql:44-53`).
- `SECURITY DEFINER`-Helfer mit fest gesetztem `search_path` (`sx_org_id`, `sx_role`, `sx_can_write`, `sx_sees_company`) — vermeidet RLS-Rekursion, gute Praxis.
- `WITH CHECK` bindet Inserts/Updates an die eigene Org **und** Firma → `organization_id`-Spoofing beim Schreiben ist blockiert.

**❌ KRITISCH (P0, Privilege Escalation):**
`0002_rls.sql:62-63`
```sql
create policy prof_update_self on profiles for update
  using (id = auth.uid());   -- kein WITH CHECK!
```
Ohne `WITH CHECK` darf eine Person die **eigene** Profilzeile beliebig ändern — inkl. `role` und `organization_id`. Ein `mitarbeitend` kann sich damit selbst zu `gruppenadmin` hochstufen oder in eine andere Organisation umhängen. **Muss vor Verkauf gefixt werden:** `WITH CHECK`, das `role`, `organization_id`, `company_id`, `active` unveränderlich lässt (nur `name`/`email` selbst editierbar); Rollenänderung nur über `prof_admin_write`.

**Weitere Lücken:**
- ❌ Keine automatisierten **Cross-Tenant-Negativtests** (kein `tests/`). Der Leitfaden fordert 6 (Ziff. 5.2).
- 🟡 Standortberechtigung hängt an **einer** `company_id` im Profil — keine feingranulare Mehrfach-Standortzuordnung (`member_site_access`); für Enterprise (mehrere Standorte je Person) später nötig.
- 🟡 `auditor_readonly` als Rolle existiert nicht (Enum: `viewer, mitarbeitend, lagerverantwortlich, firmenadmin, gruppenadmin`).

### 2.2 Auth / Account-Schutz — 🟡
- ✅ Supabase-Auth; Einladungs-Flow (`0004_invitations.sql`, `redeem_invite`).
- ❌ **Keine MFA/2FA** (auch nicht optional für Owner/Admin/SIBE).
- 🟡 Rate-Limits: Login/Reset/Invite laufen über GoTrue (built-in Limits); App-eigene KI-/Upload-Limits noch offen.
- 🟡 E-Mail-Verifikation, Session-Dauer, Enumeration-Schutz: Supabase-Standard — zu prüfen/konfigurieren.

**Konto-Lebenszyklus (Sweep 2026-09-04)** — nach dem Fund der fehlenden Passwort-Änderung systematisch geprüft:

| Funktion | Status |
|---|---|
| Login / Logout / Signup | ✅ vorhanden |
| **Passwort ändern** (eingeloggt) | ✅ neu (`58d429a`), Konto-Menü |
| **Passwort-Reset** («vergessen» → E-Mail → neues Passwort) | ✅ neu — Login-Link + `resetPasswordForEmail` + `PASSWORD_RECOVERY`-Handling. **Config nötig:** Redirect-URL `…/live/` in Supabase-Auth-Allowlist + SMTP für Versand |
| Enumeration-Schutz beim Reset | ✅ generische Meldung, egal ob E-Mail existiert |
| Passwort-Mindestlänge | ✅ vereinheitlicht auf 8 (Signup + Änderung + Reset) |
| Session-Handling (`onAuthStateChange`) | 🟡 Recovery-Event gehandhabt; automatischer Redirect bei `SIGNED_OUT`/Token-Ablauf noch offen |
| E-Mail-Verifikation erzwingen | 🟡 Supabase-Toggle (nicht Code) — vor Fremdverkauf aktivieren |
| Re-Auth bei Passwortänderung («secure password change») | 🟡 Supabase-Toggle — empfohlen |
| Konto / Organisation löschen (revDSG-Löschrecht) | ❌ offen → **P1** |
| MFA | ❌ offen → **P1** |

### 2.3 SDB-Lifecycle & KI-Governance — 🟢 Kern erledigt (2026-09-04), Rest P1

**Umgesetzt (Migration `0013`, live + deploy-ready):**
- Stoff-**Lebenszyklus** `status` (draft/needs_review/approved/restricted/archived/superseded) + `approved_by`/`approved_at`/`source`. Bestehende Stoffe grandfathered = `approved`.
- **Freigabe-RPC** `substance_set_status` + Integritäts-Trigger: Nicht-Admins können nicht direkt freigeben (INSERT `approved`→`needs_review`, UPDATE blockiert). 4/4 SQL-Tests grün (`tests/lifecycle.sql`).
- **Hartes Gate**: Betriebsanweisung, Instruktions-QR und Umfüll-Etikett nur bei `approved`. Status-Badge + Freigabe-Karte auf der Stoffkarte, „Zur Freigabe"-Board in der Verwaltung.
- Neu erfasste Stoffe: KI → `needs_review`; sonst Admin → `approved`, Nicht-Admin → `needs_review`. Lieferschein-Import → `needs_review`.
- **`parse-sdb`-Governance** (deployt, `verify_jwt=true`, aktiv sobald `ANTHROPIC_API_KEY` gesetzt): Auth+Org, Rate-Limit pro Nutzer, **Prompt-Injection-Härtung**, **Confidence pro Feld**, **serverseitige UN-Validierung**, **Persistenz** in `sds_extractions` (Modell-/Prompt-Version), Rückgabe `needs_review:true`.
- `sds_documents`: Spalten `sha256`/`mime`/`size_bytes`/`original_name` angelegt.

**Rest → P1:** Malware-Scan/Quarantäne (externer Dienst), asynchroner Verarbeitungs-Job, Client-Datei-Härtung beim Upload (MIME/Signatur/Grösse/Hash wirklich befüllen), BA-Versionierung.

<details><summary>Ursprünglicher Befund (vor der Umsetzung)</summary>
`sds_documents` (`0001:90-101`) speichert Pfad/Link/Revision/Version/`uploaded_by` — aber:
- ❌ **Kein Status-Lifecycle** (`draft/needs_review/approved/restricted/archived/superseded`), kein `approved_by/at`.
- ❌ **Kein Datei-Hash** (SHA-256), kein Duplikat-Dedupe.
- ❌ **`parse-sdb`** (`functions/parse-sdb/index.ts`): CORS `*`; kein serverseitiger Auth-/Org-Bezug; **keine Datei-Validierung** (MIME/Signatur/Grösse); **kein Malware-Scan/Quarantäne**; **keine Confidence/Quellenseite je Feld**; **keine serverseitige Validierung** gegen Referenzdaten (CAS/UN/GHS/VeVA); **keine Persistenz** von Modell-/Prompt-Version + Audit; **kein Freigabe-Gate** (Client übernimmt KI-Ergebnis direkt); **kein Prompt-Injection-Schutz** (Dokumenttext ist untrusted, System-Prompt nicht dagegen abgesichert).
- ❌ Kein asynchroner Verarbeitungs-Job (`sds_processing_jobs`).

> Kern-Regel des Leitfadens („keine verbindliche KI-Ausgabe ohne menschliche Freigabe") ist **technisch noch nicht erzwungen**.
</details>

### 2.4 Betriebsanweisung / Instruktion — 🟡
- ✅ Instruktionsnachweise (`0007_instructions.sql`), BA-Generierung (DE/FR/IT), QR.
- ❌ **Keine eingefrorene, freigegebene BA-Version** (`operating_instruction_versions`): BA wird bei Bedarf neu aus den Stoffdaten erzeugt. Ein Instruktionsnachweis referenziert damit keine unveränderliche Dokumentversion; QR zeigt die „aktuelle" generierte Fassung, nicht eine freigabegebundene. Für Auditnachweis (welcher Stand wurde wann bestätigt) muss versioniert + eingefroren werden.

### 2.5 Audit-Log — 🟡
- ✅ `audit_logs` (`0001:157`), org-scoped; Policy nur `select` + `insert` (`0002:122-125`) → normale Nutzer können nicht per RLS updaten/löschen.
- 🟡 Keine **DB-seitige** Unveränderlichkeit (kein Trigger, der Update/Delete verbietet; Service-Role umgeht RLS ohnehin).
- ❌ **Export-/Download-Protokollierung** fehlt (`document_access_log`); Leitfaden fordert Protokoll für Exporte/Downloads.
- 🟡 Abdeckung hängt an App-Aufrufen — `login/permission_change/billing_change/export` nicht systematisch erfasst.

### 2.6 Audit-Dossier — ✅/🟡
- ✅ Prüf-Dossier als PDF (Deckblatt, Kennzahlen, Mängel, SDB-Status, Zusammenlagerung, Instruktionen).
- 🟡 Kein **XLSX/CSV-Auditexport mit Zeitraumfilter**, keine Export-Protokollierung, kein **Auditor-Read-only-Zugang** mit zeitlich begrenztem Recht.

### 2.7 Entitlements / Billing — 🟡 (Gerüst, nicht scharf)
- ✅ `create-checkout-session`: **price-ID serverseitig** aus ENV (kein Client-Spoofing), Auth via JWT, **Admin-Check**, Org aus Profil — sauber gebaut.
- ✅ `stripe-webhook`: **Signaturprüfung** vorhanden (`constructEventAsync`).
- ❌ **Keine Idempotenz** (kein `billing_events` mit `event.id`-Dedupe) → doppelte Events möglich.
- ❌ **Keine `plan_features`/`usage_counters`; Limits werden NICHT erzwungen.** `0005` legt nur Felder auf `organizations` an (`plan`, `subscription_status`, Trial, Stripe-IDs). Es gibt **keine serverseitige Prüfung** vor „weiterer Standort/Stoff/Nutzer/KI-Call". `set_org_plan` setzt den Plan sogar ohne Zahlung (für Pre-Stripe-Demo ok, aber nicht als Verkaufszustand).
- ❌ **Grace-Period/Read-only** bei `past_due`/`canceled` in der App nicht erzwungen.
- ❌ Nicht **live** (keine Stripe-Keys/Produkte gesetzt).

### 2.8 Security-Härtung (Infra) — ❌
- ❌ `netlify.toml`: nur `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy=camera`. **Kein CSP, kein HSTS, kein `X-Frame-Options`/`frame-ancestors` (Clickjacking), kein COOP/CORP.**
- ❌ **CORS `*`** auf allen Edge Functions — auch authentifizierten (`parse-sdb`, `create-checkout-session`, `validate-substance`).
- 🟡 `validate-substance` `verify_jwt=false` nur mit apikey: liefert zwar nur **öffentliche** Regulierungsdaten (UN/VeVA/PubChem), aber **ohne Rate-Limit/Origin-Check** → Missbrauch/Kosten (PubChem-Fetches, DB-Reads) möglich. Zudem nutzt sie den **Service-Role-Key** für öffentliche Reads → besser least-privilege/anon-Client oder eng gescopte Rolle.
- ❌ Keine Rate-Limits in Functions; keine **CI**, kein **Secret-Scanning**.

### 2.9 Datei-/Upload-Sicherheit — ❌
- Storage-Bucket `sds` + Policies (`0003_onboarding_storage.sql`), Öffnen via Signed-URL. Aber: keine MIME-/Dateisignatur-/Grössenprüfung, **kein Malware-Scan/Quarantäne**, kein Hash-Dedupe, Original-Unveränderlichkeit nicht erzwungen; Signed-URL-TTL zu verifizieren.

### 2.10 Betrieb — ❌
- Kein **Staging≠Production** (ein Supabase-Projekt, eine Netlify-Site). Kein Error-Tracking (Sentry), keine Health-Checks, kein Backup-/Restore-Testkonzept, kein Incident-Runbook, keine Feature-Flags.

### 2.11 Datenschutz / Recht — 🟡 (kein Code, extern)
- ✅ AGB/Datenschutz/Impressum als Seiten mit Musterangaben.
- ❌ AVV/DPA-Entwurf, Verzeichnis der Bearbeitungstätigkeiten, Unterauftragsbearbeiter-Liste, Lösch-/Aufbewahrungsprozess — für Fremdverkauf nötig, aber **juristisch/prozessual**, nicht durch Code lösbar.

---

## 3. Konkrete Sicherheits-Findings (nach Schwere)

| # | Schwere | Finding | Ort | Fix |
|---|---|---|---|---|
| S1 | ~~Kritisch~~ **✅ behoben** | Selbst-Hochstufung: `prof_update_self` ohne `WITH CHECK` | `0002_rls.sql:62` | **Gefixt in `0011` (Policy `WITH CHECK` + Guard-Trigger); 6/6 Cross-Tenant-Tests grün.** |
| S2 | Hoch | Keine serverseitige Limit-Durchsetzung (Plan-Umgehung) | `0005` + Live-Client | `usage_counters` + Checks vor limitrelevanten Aktionen |
| S3 | Hoch | KI-Ergebnis ohne Freigabe-Gate direkt übernommen | `parse-sdb` + Client | Status-Lifecycle + Review-Gate |
| S4 | Hoch | Webhook nicht idempotent | `stripe-webhook` | `billing_events`-Dedupe über `event.id` |
| S5 | ~~Hoch~~ **✅ behoben** | Keine Security-Header (CSP/HSTS/Clickjacking) | `netlify.toml` | **CSP (validiert, 0 Violations) + HSTS + X-Frame-Options/frame-ancestors + COOP + Permissions-Policy.** `'unsafe-inline'` bleibt nötig (Single-File-Inline-JS) → P1-Refactor. |
| S6 | ~~Mittel~~ **✅ behoben** | CORS `*` auf Functions | `functions/*` | **Wildcard entfernt:** `validate-substance` mit Origin-Allowlist (live verifiziert), die 3 (noch nicht deployten) Auth-Functions auf feste Prod-Origin umgestellt. |
| S7 | ~~Mittel~~ **✅ behoben** | `verify_jwt=false` ohne Rate-Limit | `validate-substance` | **Rate-Limit pro IP (`rl_hit`, 30/min) + Origin-Allowlist**, live verifiziert (5/2-Test, 200/ACAO-Test). Least-privilege statt Service-Role → P1. |
| S8 | Mittel | Upload ohne MIME/Signatur/Grösse/Scan/Hash | `parse-sdb`, Storage | Validierung + Quarantäne + Hash |
| S9 | Mittel | Keine MFA für Admin/SIBE | Auth | TOTP-Enrollment (Option) |
| S10 | ~~Niedrig~~ **✅ teilw.** | Kein Cross-Tenant-Testset | Repo | Testset da (`tests/rls_cross_tenant.sql`); CI/Secret-Scanning noch offen |
| S11 | Niedrig | `sx_*`-RLS-Helfer als `/rest/v1/rpc/` exponiert (Advisor 0028/0029) | `0002` | In privates Schema verschieben (nicht aus `public`) – **darf nicht** aus `authenticated` revoked werden (RLS braucht sie). Trigger-Fn bereits entzogen. |
| S12 | Niedrig | Leaked-Password-Protection (HaveIBeenPwned) deaktiviert | Auth-Config | Im Dashboard aktivieren |
| S13 | Info | `product_catalog(_contributors)`: RLS aktiv, keine Policy | `0006` | Beabsichtigt (Zugriff nur via RPC) – explizite Deny-Doku/Policy ergänzen |

---

## 4. Priorisierte Umsetzungsreihenfolge

### P0 – Blocker vor dem ersten zahlenden Fremdkunden
1. ✅ **ERLEDIGT (2026-09-04):** RLS-Fix S1 (Migration `0011`) + Cross-Tenant-Negativtests (`supabase/tests/rls_cross_tenant.sql`, 6/6 grün, gegen Prod verifiziert & zurückgerollt).
2. 🟢 **KERN ERLEDIGT (2026-09-04):** SDB-Lifecycle + hartes Freigabe-Gate + KI-Governance (Migration `0013`, `parse-sdb` v-gov, `tests/lifecycle.sql`). **Rest P1:** Malware-Scan/Quarantäne, async Job, Client-Upload-Härtung (Hash/MIME wirklich befüllen), BA-Versionierung.
3. ✅ **ERLEDIGT (2026-09-04):** Infra-Härtung (S5/S6/S7) – Security-Header in `netlify.toml` (CSP validiert), CORS-Allowlist, Rate-Limit für `validate-substance` (Migration `0012`, live verifiziert). Offen als P1: `'unsafe-inline'`-Refactor, least-privilege-Client für Public-Reads.
4. **Entitlements serverseitig** (S2, S4): `plan_features`/`usage_counters`, Limit-Checks, Webhook-Idempotenz, Grace/Read-only. Danach Stripe live.
5. **Betrieb-Minimum**: Staging≠Prod, automatische Backups + **1 dokumentierter Restore-Test**, Error-Tracking, Secret-Scanning/CI.

### P1 – Vertrauen & Nachweis
6. **BA-Versionierung** + eingefrorene, freigabegebundene Instruktionsnachweise.
7. **Audit**: Export-/Download-Protokollierung, XLSX-Auditexport mit Zeitraum, **Auditor-Read-only**-Rolle.
8. **MFA** (Option für Admin/SIBE), Rate-Limits Login/Reset/Invite (S9).
9. **`member_site_access`** (Mehrfach-Standortzuordnung je Person).

### P2 – Premium / später
10. API/Webhooks nach aussen, erweiterte StFV-/Substitutionsmodule, Absicherung KI-Chat.

### Nicht-Code (parallel, extern)
- AVV/DPA-Entwurf, Verzeichnis der Bearbeitungstätigkeiten, Unterauftragsbearbeiter-Liste (revDSG).
- MWST-/Rechnungslogik mit Treuhand.
- Datenschutz-/Vertragsprüfung durch Fachperson.

---

## 5. Was bereits steht (nicht neu bauen)
Mandantentrennung + RLS (gut), Rollen-Enum + Einladungen, **Checkout-Session serverseitig sauber**, Webhook-Signaturprüfung, `audit_logs` insert-only, Prüf-Dossier-PDF, Instruktionsnachweise, StFV/VeVA/UN-Referenzdaten, PWA/Offline, AGB/DSE/Impressum (Muster). Der Perplexity-Leitfaden nimmt vieles davon als „zu bauen" an — das trifft **nicht** zu.

---

## 6. Empfohlener nächster Schritt
Mit **P0-Punkt 1** starten (RLS-Fix S1 + Cross-Tenant-Tests): kleinster Aufwand, grösster Sicherheitshebel, nicht-destruktiv, sofort testbar. Danach der SDB-Lifecycle-Block (P0-2) als grösste inhaltliche Baustelle.
