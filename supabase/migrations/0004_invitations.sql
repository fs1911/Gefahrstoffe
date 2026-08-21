-- StoffScan – Personen per Einladung (Phase 1 / Block B)
-- Ein Admin lädt eine E-Mail-Adresse mit Rolle + Firma ein. Die Person registriert
-- sich selbst; beim ersten Login wird sie über redeem_invite() automatisch dieser
-- Organisation zugeordnet. Kein Service-Role-Key, kein SMTP nötig.

create table if not exists invitations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  email text not null,
  role user_role not null default 'mitarbeitend',
  company_id uuid references companies(id) on delete set null,
  invited_by uuid references profiles(id) on delete set null,
  accepted_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists idx_inv_org on invitations(organization_id);
create index if not exists idx_inv_email on invitations(lower(email));

alter table invitations enable row level security;

-- Nur Admins der eigenen Organisation verwalten deren Einladungen.
drop policy if exists inv_select on invitations;
drop policy if exists inv_insert on invitations;
drop policy if exists inv_delete on invitations;

create policy inv_select on invitations for select to authenticated
  using (organization_id = sx_org_id() and sx_is_admin());
create policy inv_insert on invitations for insert to authenticated
  with check (organization_id = sx_org_id() and sx_is_admin());
create policy inv_delete on invitations for delete to authenticated
  using (organization_id = sx_org_id() and sx_is_admin());

-- Einladung einlösen: neu registrierte Person ohne Profil sucht eine offene
-- Einladung zu ihrer E-Mail und erhält daraus Profil + Rolle + Firma.
create or replace function redeem_invite()
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email text;
  v_inv   invitations;
begin
  if exists (select 1 from profiles where id = auth.uid()) then
    raise exception 'Profil existiert bereits';
  end if;

  select email into v_email from auth.users where id = auth.uid();
  if v_email is null then return null; end if;

  select * into v_inv
    from invitations
    where lower(email) = lower(v_email) and accepted_at is null
    order by created_at desc
    limit 1;

  if v_inv.id is null then return null; end if;

  insert into profiles (id, organization_id, company_id, name, email, role)
    values (auth.uid(), v_inv.organization_id, v_inv.company_id, v_email, v_email, v_inv.role);

  update invitations set accepted_at = now() where id = v_inv.id;
  return v_inv.organization_id;
end;
$$;

grant execute on function redeem_invite() to authenticated;
revoke execute on function redeem_invite() from public;
revoke execute on function redeem_invite() from anon;
