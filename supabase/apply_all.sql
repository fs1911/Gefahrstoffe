-- StoffScan – komplettes Setup (Schema + RLS) in einem Rutsch
-- Im Supabase SQL-Editor des Projekts StoffScan einfügen und ausführen.

-- StoffScan – Datenmodell (Phase 1)
-- Trennung Stoffstamm (substances) ↔ Bestand (substance_instances) ist zwingend.
-- Mandant = organizations. Jede Zeile trägt organization_id (Basis für RLS).

create extension if not exists pgcrypto;

-- Rollen
do $$ begin
  create type user_role as enum
    ('viewer','mitarbeitend','lagerverantwortlich','firmenadmin','gruppenadmin');
exception when duplicate_object then null; end $$;

-- Organisationen (Mandant / Kunde)
create table if not exists organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

-- Firmen innerhalb einer Organisation (Gruppe via parent_id)
create table if not exists companies (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  parent_id uuid references companies(id) on delete set null,
  name text not null,
  short text,
  kanton text,
  typ text,
  is_group boolean not null default false,
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create index if not exists idx_companies_org on companies(organization_id);

-- Profile (1:1 zu auth.users), tragen Rolle + Firmenzuordnung
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  organization_id uuid references organizations(id) on delete set null,
  company_id uuid references companies(id) on delete set null,
  name text,
  email text,
  role user_role not null default 'mitarbeitend',
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create index if not exists idx_profiles_org on profiles(organization_id);

-- Lagerorte (hierarchisch)
create table if not exists storage_locations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  company_id uuid not null references companies(id) on delete cascade,
  parent_location_id uuid references storage_locations(id) on delete set null,
  name text not null,
  bereich text,
  typ text,
  pfad text,
  gps_lat double precision,
  gps_lng double precision,
  qr_code text unique,               -- Deep-Link-Ziel, z. B. LOC-xxxx
  created_at timestamptz not null default now()
);
create index if not exists idx_loc_org on storage_locations(organization_id);
create index if not exists idx_loc_company on storage_locations(company_id);

-- Stoffstamm (produktbezogen, je Organisation einmalig)
create table if not exists substances (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  produktname text not null,
  hersteller text,
  lieferant text,
  signalwort text,                   -- 'Gefahr' | 'Achtung'
  ghs_piktogramme text[] not null default '{}',
  h_saetze text,
  p_saetze text,
  un_nummer text,
  externer_barcode text,
  info_link text,
  wassergefaehrdend boolean,
  brennbar boolean,
  lagerklasse text,
  zusammenlagerung_hinweis text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_sub_org on substances(organization_id);

-- Sicherheitsdatenblätter (Datei im Storage-Bucket 'sds' oder externer Link)
create table if not exists sds_documents (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  substance_id uuid not null references substances(id) on delete cascade,
  storage_path text,
  external_link text,
  revisionsdatum date,
  sprache text default 'de',
  version text,
  uploaded_by uuid references profiles(id) on delete set null,
  uploaded_at timestamptz not null default now()
);
create index if not exists idx_sds_substance on sds_documents(substance_id);

-- Vorkommen / Bestand (Firma + Lagerort + Menge + Status + interner QR)
create table if not exists substance_instances (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  substance_id uuid not null references substances(id) on delete restrict,
  company_id uuid not null references companies(id) on delete cascade,
  storage_location_id uuid references storage_locations(id) on delete set null,
  gebindeart text,
  gebindegroesse text,
  anzahl_gebinde numeric,
  menge_aktuell numeric,
  mengeneinheit text,
  status text,                       -- 'Lager','im Einsatz','zur Entsorgung','unklar'
  responsible_user_id uuid references profiles(id) on delete set null,
  foto_url text,
  internal_qr text unique,           -- Deep-Link-Ziel, z. B. INST-xxxx
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_inst_org on substance_instances(organization_id);
create index if not exists idx_inst_company on substance_instances(company_id);
create index if not exists idx_inst_substance on substance_instances(substance_id);
create index if not exists idx_inst_location on substance_instances(storage_location_id);

-- Mengenbewegungen
create table if not exists stock_movements (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  substance_instance_id uuid not null references substance_instances(id) on delete cascade,
  typ text not null,                 -- 'Zugang','Abgang','Korrektur','Umlagerung'
  menge_delta numeric,
  einheit text,
  user_id uuid references profiles(id) on delete set null,
  notiz text,
  created_at timestamptz not null default now()
);
create index if not exists idx_mov_instance on stock_movements(substance_instance_id);

-- Hinweise / Warnungen
create table if not exists alerts (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  bezug_typ text not null,           -- 'substance_instance' | 'substance'
  bezug_id uuid not null,
  typ text not null,                 -- 'SDB_fehlt','SDB_veraltet','Menge_fehlt',...
  schwere text default 'info',
  status text not null default 'offen',  -- 'offen' | 'erledigt'
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);
create index if not exists idx_alerts_org on alerts(organization_id);

-- Audit-Log (wer/wann/was)
create table if not exists audit_logs (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  entity_typ text not null,
  entity_id uuid,
  aktion text not null,
  user_id uuid references profiles(id) on delete set null,
  alt_wert jsonb,
  neu_wert jsonb,
  created_at timestamptz not null default now()
);
create index if not exists idx_audit_org on audit_logs(organization_id);


-- StoffScan – Row-Level-Security (Mandantentrennung)
-- Prinzip: Nutzer sehen nur ihre Organisation. Firmen-Rollen nur ihre Firma;
-- Rolle 'gruppenadmin' (IMS) sieht die ganze Organisation.
-- Helfer sind SECURITY DEFINER -> lesen profiles ohne RLS-Rekursion.

create or replace function sx_org_id() returns uuid
  language sql stable security definer set search_path = public as $$
  select organization_id from profiles where id = auth.uid()
$$;

create or replace function sx_role() returns user_role
  language sql stable security definer set search_path = public as $$
  select role from profiles where id = auth.uid()
$$;

create or replace function sx_company_id() returns uuid
  language sql stable security definer set search_path = public as $$
  select company_id from profiles where id = auth.uid()
$$;

create or replace function sx_is_admin() returns boolean
  language sql stable security definer set search_path = public as $$
  select coalesce((select role in ('firmenadmin','gruppenadmin')
                   from profiles where id = auth.uid()), false)
$$;

create or replace function sx_can_write() returns boolean
  language sql stable security definer set search_path = public as $$
  select coalesce((select role in ('mitarbeitend','lagerverantwortlich','firmenadmin','gruppenadmin')
                   from profiles where id = auth.uid()), false)
$$;

-- true, wenn die aktuelle Person die Firma sehen darf (Gruppenadmin: ganze Org)
create or replace function sx_sees_company(cid uuid) returns boolean
  language sql stable security definer set search_path = public as $$
  select coalesce((
    select p.organization_id = (select c.organization_id from companies c where c.id = cid)
           and (p.role = 'gruppenadmin' or p.company_id = cid)
    from profiles p where p.id = auth.uid()
  ), false)
$$;

-- RLS aktivieren
alter table organizations       enable row level security;
alter table companies           enable row level security;
alter table profiles            enable row level security;
alter table storage_locations   enable row level security;
alter table substances          enable row level security;
alter table sds_documents       enable row level security;
alter table substance_instances enable row level security;
alter table stock_movements     enable row level security;
alter table alerts              enable row level security;
alter table audit_logs          enable row level security;

-- ORGANIZATIONS
create policy org_select on organizations for select
  using (id = sx_org_id());

-- PROFILES (Kolleg:innen der eigenen Org sichtbar; Selbst-Update; Admin verwaltet)
create policy prof_select on profiles for select
  using (organization_id = sx_org_id());
create policy prof_update_self on profiles for update
  using (id = auth.uid());
create policy prof_admin_write on profiles for all
  using (sx_is_admin() and organization_id = sx_org_id())
  with check (sx_is_admin() and organization_id = sx_org_id());

-- COMPANIES (Liste org-weit lesbar; nur Admin schreibt)
create policy comp_select on companies for select
  using (organization_id = sx_org_id());
create policy comp_admin_write on companies for all
  using (sx_is_admin() and organization_id = sx_org_id())
  with check (sx_is_admin() and organization_id = sx_org_id());

-- STORAGE_LOCATIONS (firmenbezogen; Gruppenadmin org-weit)
create policy loc_select on storage_locations for select
  using (organization_id = sx_org_id() and sx_sees_company(company_id));
create policy loc_write on storage_locations for all
  using (organization_id = sx_org_id()
         and sx_role() in ('lagerverantwortlich','firmenadmin','gruppenadmin')
         and sx_sees_company(company_id))
  with check (organization_id = sx_org_id()
         and sx_role() in ('lagerverantwortlich','firmenadmin','gruppenadmin')
         and sx_sees_company(company_id));

-- SUBSTANCES (Stoffstamm org-weit geteilt)
create policy sub_select on substances for select
  using (organization_id = sx_org_id());
create policy sub_write on substances for all
  using (organization_id = sx_org_id() and sx_can_write())
  with check (organization_id = sx_org_id() and sx_can_write());

-- SDS_DOCUMENTS (org-weit; Schreiben ab Rolle mitarbeitend)
create policy sds_select on sds_documents for select
  using (organization_id = sx_org_id());
create policy sds_write on sds_documents for all
  using (organization_id = sx_org_id() and sx_can_write())
  with check (organization_id = sx_org_id() and sx_can_write());

-- SUBSTANCE_INSTANCES (Bestand: firmenbezogen isoliert)
create policy inst_select on substance_instances for select
  using (organization_id = sx_org_id() and sx_sees_company(company_id));
create policy inst_write on substance_instances for all
  using (organization_id = sx_org_id() and sx_can_write() and sx_sees_company(company_id))
  with check (organization_id = sx_org_id() and sx_can_write() and sx_sees_company(company_id));

-- STOCK_MOVEMENTS (org-scope; Bezug ist bereits firmen-isoliert)
create policy mov_select on stock_movements for select
  using (organization_id = sx_org_id());
create policy mov_write on stock_movements for all
  using (organization_id = sx_org_id() and sx_can_write())
  with check (organization_id = sx_org_id() and sx_can_write());

-- ALERTS
create policy alert_select on alerts for select
  using (organization_id = sx_org_id());
create policy alert_write on alerts for all
  using (organization_id = sx_org_id() and sx_can_write())
  with check (organization_id = sx_org_id() and sx_can_write());

-- AUDIT_LOGS (org-weit lesbar; Einträge nur einfügen)
create policy audit_select on audit_logs for select
  using (organization_id = sx_org_id());
create policy audit_insert on audit_logs for insert
  with check (organization_id = sx_org_id());
