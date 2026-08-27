-- StoffScan – Abo / Subscription (Phase 3, Block B: «Stripe vorbereiten»)
-- Additive Felder auf organizations + Admin-RPC für die Planwahl.
-- Bezahlung läuft später über Stripe (siehe supabase/functions/). Der Status
-- bleibt 'trialing', bis der Stripe-Webhook ihn auf 'active' setzt. Ohne
-- konfigurierte Stripe-Keys ändert die App nur den gewählten Plan (Absicht),
-- nicht den Bezahlstatus.

alter table organizations
  add column if not exists plan                  text not null default 'starter',
  add column if not exists subscription_status   text not null default 'trialing',
  add column if not exists trial_ends_at         timestamptz,
  add column if not exists stripe_customer_id     text,
  add column if not exists stripe_subscription_id text,
  add column if not exists current_period_end     timestamptz;

-- Erlaubte Werte absichern
do $$ begin
  alter table organizations
    add constraint organizations_plan_chk check (plan in ('starter','betrieb','gruppe'));
exception when duplicate_object then null; end $$;

do $$ begin
  alter table organizations
    add constraint organizations_substatus_chk
    check (subscription_status in ('trialing','active','past_due','canceled'));
exception when duplicate_object then null; end $$;

-- Bestehende Organisationen ohne Trial-Datum: 14 Tage ab jetzt.
update organizations set trial_ends_at = now() + interval '14 days'
  where trial_ends_at is null;

-- Onboarding: neue Organisation startet mit 14-Tage-Testphase.
create or replace function create_org_and_profile(p_org_name text, p_user_name text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_org uuid;
  v_company uuid;
  v_email text;
begin
  if exists (select 1 from profiles where id = auth.uid()) then
    raise exception 'Profil existiert bereits';
  end if;

  select email into v_email from auth.users where id = auth.uid();

  insert into organizations (name, trial_ends_at)
    values (coalesce(nullif(p_org_name,''), 'Meine Organisation'),
            now() + interval '14 days')
    returning id into v_org;

  insert into companies (organization_id, name, short, is_group)
    values (v_org, coalesce(nullif(p_org_name,''), 'Meine Firma'), 'Gruppe', true)
    returning id into v_company;

  insert into profiles (id, organization_id, company_id, name, email, role)
    values (auth.uid(), v_org, v_company,
            coalesce(nullif(p_user_name,''), v_email),
            v_email, 'gruppenadmin');

  return v_org;
end;
$$;
revoke execute on function create_org_and_profile(text, text) from public, anon;
grant  execute on function create_org_and_profile(text, text) to authenticated;

-- Planwahl / Upgrade durch Admins (nur die eigene Organisation).
-- Setzt nur den gewünschten Plan; der Bezahlstatus bleibt Stripe vorbehalten.
create or replace function set_org_plan(p_plan text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_plan not in ('starter','betrieb','gruppe') then
    raise exception 'Ungültiger Plan';
  end if;
  if not sx_is_admin() then
    raise exception 'Nur Admins dürfen den Plan ändern';
  end if;
  update organizations set plan = p_plan where id = sx_org_id();
end;
$$;
revoke execute on function set_org_plan(text) from public, anon;
grant  execute on function set_org_plan(text) to authenticated;
