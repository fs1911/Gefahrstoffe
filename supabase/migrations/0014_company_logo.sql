-- StoffScan – Logo je Firma (Tochtergesellschaft)
-- Dokumente (Betriebsanweisung, Feuerwehr-Einsatzkarte, Dossier) sollen das Logo
-- der jeweiligen Firma tragen; fehlt es, gilt das Gruppen-/Org-Logo als Rückfall.
alter table companies add column if not exists logo_url text;

-- Setzen/Entfernen nur durch Admins, nur für Firmen der eigenen Organisation.
-- Spiegelt set_org_logo (sx_is_admin) und ergänzt eine Org-Zugehörigkeitsprüfung.
create or replace function set_company_logo(p_company_id uuid, p_logo text)
returns void language plpgsql security definer set search_path = public as $$
declare v_org uuid;
begin
  if not sx_is_admin() then
    raise exception 'not authorized' using errcode = '42501';
  end if;
  select organization_id into v_org from companies where id = p_company_id;
  if v_org is null then
    raise exception 'Firma nicht gefunden';
  end if;
  if v_org <> sx_org_id() then
    raise exception 'not authorized' using errcode = '42501';
  end if;
  update companies set logo_url = p_logo where id = p_company_id;
end $$;
revoke execute on function set_company_logo(uuid, text) from anon, public;
grant  execute on function set_company_logo(uuid, text) to authenticated;
