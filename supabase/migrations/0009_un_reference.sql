-- 0009_un_reference.sql
-- Referenztabelle UN-Nummern (Gefahrgut) für die Datenqualität.
-- Befüllt durch die Edge Function `import-un-reference` aus der deutschen
-- Wikipedia „Liste der UN-Nummern" (~2365 Einträge). Nur-Lesen für
-- authentifizierte Nutzer; Schreiben ausschliesslich via Service-Role.

create table if not exists public.un_reference (
  un_number    text primary key,
  gefahrenzahl text,
  klasse       text,
  benennung    text,
  source       text default 'wikipedia:Liste der UN-Nummern',
  updated_at   timestamptz default now()
);

alter table public.un_reference enable row level security;

drop policy if exists "un_reference readable by authenticated" on public.un_reference;
create policy "un_reference readable by authenticated"
  on public.un_reference for select to authenticated using (true);

comment on table public.un_reference is
  'Referenz UN-Nummern (Gefahrgut). Nur-Lesen fuer authentifizierte Nutzer; Schreiben nur via Service-Role (Edge Function import-un-reference).';
