-- 0010_waste_codes.sql
-- Amtliches Abfallverzeichnis VeVA/LVA (SR 814.610.1, Verordnung des UVEK über
-- Listen zum Verkehr mit Abfällen). 860 Codes aus Anhang 1, angereichert mit den
-- StFV-Mengenschwellen aus Anhang 3.
--   special      = Sonderabfall (Klassierung «S» im Verzeichnis)
--   klassierung  = 'S' (Sonderabfall) | 'ak' (anderer kontrollierter Abfall) | ''
--   schwelle_kg  = Mengenschwelle für Sonderabfälle (StFV Anhang 1.1 / VeVA Anhang 3), sonst NULL
-- Befüllung: aus dem amtlichen PDF (Fedlex eli/cc/2005/714) geparst und per
-- Service-Role eingespielt. Nur-Lesen für authentifizierte Nutzer.

create table if not exists public.waste_codes (
  code         text primary key,   -- z. B. '14 06 03'
  klassierung  text,
  special      boolean default false,
  beschreibung text,
  schwelle_kg  integer,
  source       text default 'VeVA/LVA SR 814.610.1 Anhang 1',
  updated_at   timestamptz default now()
);

alter table public.waste_codes enable row level security;

drop policy if exists "waste_codes readable by authenticated" on public.waste_codes;
create policy "waste_codes readable by authenticated"
  on public.waste_codes for select to authenticated using (true);

comment on table public.waste_codes is
  'Amtliches Abfallverzeichnis VeVA/LVA (SR 814.610.1). special=Sonderabfall (S); schwelle_kg=StFV-Mengenschwelle. Nur-Lesen fuer authenticated; Schreiben nur via Service-Role.';
