-- 0007_instructions.sql
-- Instruktionsnachweis (Block 5): Mitarbeitende bestätigen «Betriebsanweisung
-- gelesen und verstanden». Jede Bestätigung ist ein Nachweis (Datum + Name),
-- der Pflicht-Instruktion nach Chemikalienrecht. Empfohlen jährlich zu erneuern.

create table if not exists instructions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  substance_id uuid not null references substances(id) on delete cascade,
  company_id uuid references companies(id) on delete set null,
  person_name text not null,
  profile_id uuid references profiles(id) on delete set null,  -- optional: falls App-Nutzer
  confirmed_at timestamptz not null default now(),
  created_by uuid references profiles(id) on delete set null,
  created_at timestamptz not null default now()
);
create index if not exists instructions_org_sub_idx on instructions(organization_id, substance_id);

alter table instructions enable row level security;

-- Lesen: alle in der eigenen Organisation.
create policy instructions_select on instructions for select
  using (organization_id = sx_org_id());

-- Bestätigen: jede angemeldete Person der eigenen Organisation.
create policy instructions_insert on instructions for insert
  with check (organization_id = sx_org_id());

-- Korrigieren/Löschen: nur Admins (versehentliche Einträge bereinigen).
create policy instructions_delete on instructions for delete
  using (organization_id = sx_org_id() and sx_is_admin());

grant select, insert, delete on instructions to authenticated;
