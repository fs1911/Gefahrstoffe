-- StoffScan – SDB-/Stoff-Freigabe-Lifecycle & KI-Governance (Audit P0-2)
-- Ziel: Kein KI-/Entwurfsdatensatz wird verbindlich, bevor eine berechtigte
-- Person ihn freigegeben hat. Bestehende Stoffe werden als 'approved'
-- grandfathered (Default), damit der laufende Betrieb nicht bricht.

-- 1) Stoff-Lebenszyklus
alter table substances
  add column if not exists status      text not null default 'approved',
  add column if not exists source      text not null default 'manual',
  add column if not exists approved_by uuid references profiles(id) on delete set null,
  add column if not exists approved_at timestamptz;

do $$ begin
  alter table substances add constraint substances_status_chk
    check (status in ('draft','needs_review','approved','restricted','archived','superseded'));
exception when duplicate_object then null; end $$;
do $$ begin
  alter table substances add constraint substances_source_chk
    check (source in ('manual','ai','import','catalog'));
exception when duplicate_object then null; end $$;

-- 2) SDB-Datei-Härtung (Hash/Typ/Grösse/Originalname)
alter table sds_documents
  add column if not exists sha256        text,
  add column if not exists mime          text,
  add column if not exists size_bytes    bigint,
  add column if not exists original_name text;

-- 3) KI-Extraktion: Provenienz getrennt vom Originaldokument
create table if not exists sds_extractions (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  substance_id    uuid references substances(id) on delete cascade,
  sds_document_id uuid references sds_documents(id) on delete set null,
  model           text,
  prompt_version  text,
  extracted       jsonb,
  confidence      jsonb,
  validation      jsonb,
  created_by      uuid references profiles(id) on delete set null,
  created_at      timestamptz not null default now()
);
create index if not exists idx_sdsx_org on sds_extractions(organization_id);
create index if not exists idx_sdsx_sub on sds_extractions(substance_id);
alter table sds_extractions enable row level security;
create policy sdsx_select on sds_extractions for select
  using (organization_id = sx_org_id());
create policy sdsx_write on sds_extractions for all
  using (organization_id = sx_org_id() and sx_can_write())
  with check (organization_id = sx_org_id() and sx_can_write());

-- 4) Freigabe-RPC: Statuswechsel; 'approved'/'restricted' nur durch Admins.
--    Jede Änderung wird ins Audit-Log geschrieben.
create or replace function substance_set_status(p_id uuid, p_status text)
returns void language plpgsql security definer set search_path = public as $$
declare v_org uuid; v_old text;
begin
  if p_status not in ('draft','needs_review','approved','restricted','archived','superseded') then
    raise exception 'Ungültiger Status';
  end if;
  select organization_id, status into v_org, v_old from substances where id = p_id;
  if v_org is null then raise exception 'Stoff nicht gefunden'; end if;
  if v_org <> sx_org_id() then raise exception 'Kein Zugriff' using errcode = '42501'; end if;
  if not sx_can_write() then raise exception 'Keine Schreibrechte' using errcode = '42501'; end if;
  if p_status in ('approved','restricted') and not sx_is_admin() then
    raise exception 'Nur Admins dürfen freigeben oder einschränken' using errcode = '42501';
  end if;
  update substances set
    status      = p_status,
    approved_by = case when p_status = 'approved' then auth.uid() else approved_by end,
    approved_at = case when p_status = 'approved' then now() else approved_at end,
    updated_at  = now()
  where id = p_id;
  insert into audit_logs(organization_id, entity_typ, entity_id, aktion, user_id, alt_wert, neu_wert)
    values (v_org, 'substance', p_id,
            case when p_status = 'approved'     then 'approve'
                 when p_status = 'needs_review' then 'submit'
                 when p_status = 'restricted'   then 'restrict'
                 when p_status = 'archived'     then 'archive'
                 else 'status' end,
            auth.uid(), jsonb_build_object('status', v_old), jsonb_build_object('status', p_status));
end $$;
revoke execute on function substance_set_status(uuid, text) from anon, public;
grant  execute on function substance_set_status(uuid, text) to authenticated;

-- 5) Integritäts-Trigger: Nicht-Admins können Stoffe nicht direkt freigeben.
--    INSERT mit 'approved'/'restricted' durch Nicht-Admin -> auf 'needs_review'
--    heruntergestuft; UPDATE auf 'approved'/'restricted' durch Nicht-Admin -> Fehler.
create or replace function sx_guard_substance_status()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is not null and not sx_is_admin() and new.status in ('approved','restricted') then
    if tg_op = 'INSERT' then
      new.status := 'needs_review';
    elsif new.status is distinct from old.status then
      raise exception 'Freigabe/Einschränkung nur durch Admins' using errcode = '42501';
    end if;
  end if;
  return new;
end $$;
drop trigger if exists trg_guard_substance_status on substances;
create trigger trg_guard_substance_status
  before insert or update on substances
  for each row execute function sx_guard_substance_status();
revoke execute on function sx_guard_substance_status() from anon, authenticated, public;
