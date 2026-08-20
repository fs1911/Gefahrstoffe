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
