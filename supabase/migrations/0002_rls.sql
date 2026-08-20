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
