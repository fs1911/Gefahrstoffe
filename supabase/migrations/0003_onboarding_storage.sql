-- StoffScan – Onboarding-Funktion + Storage-Bucket (Phase 1)
-- Ein neu registrierter Nutzer hat noch kein Profil -> RLS würde Inserts blocken.
-- Diese SECURITY-DEFINER-Funktion legt Organisation + erste Firma + Profil an.

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

  insert into organizations (name)
    values (coalesce(nullif(p_org_name,''), 'Meine Organisation'))
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

grant execute on function create_org_and_profile(text, text) to authenticated;
-- nur eingeloggte Nutzer dürfen onboarden (anon nicht)
revoke execute on function create_org_and_profile(text, text) from public;
revoke execute on function create_org_and_profile(text, text) from anon;

-- Storage-Bucket für Sicherheitsdatenblätter (privat).
-- Dateien werden unter <organization_id>/<dateiname> abgelegt -> erste Pfadebene = org.
insert into storage.buckets (id, name, public)
  values ('sds', 'sds', false)
  on conflict (id) do nothing;

drop policy if exists sds_read   on storage.objects;
drop policy if exists sds_write  on storage.objects;
drop policy if exists sds_update on storage.objects;
drop policy if exists sds_delete on storage.objects;

create policy sds_read on storage.objects for select to authenticated
  using (bucket_id = 'sds' and (storage.foldername(name))[1] = sx_org_id()::text);

create policy sds_write on storage.objects for insert to authenticated
  with check (bucket_id = 'sds' and (storage.foldername(name))[1] = sx_org_id()::text and sx_can_write());

create policy sds_update on storage.objects for update to authenticated
  using (bucket_id = 'sds' and (storage.foldername(name))[1] = sx_org_id()::text and sx_can_write());

create policy sds_delete on storage.objects for delete to authenticated
  using (bucket_id = 'sds' and (storage.foldername(name))[1] = sx_org_id()::text and sx_is_admin());
