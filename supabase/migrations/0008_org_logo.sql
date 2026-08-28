-- 0008_org_logo.sql
-- Firmenlogo pro Organisation. Erscheint auf generierten Dokumenten
-- (Betriebsanweisung, Instruktionsnachweis-PDF), damit diese firmenbezogen sind.
-- Gespeichert als Data-URL (kleines, herunterskaliertes PNG/SVG) in der
-- organizations-Zeile; gesetzt nur durch Admins via SECURITY-DEFINER-RPC.

alter table organizations add column if not exists logo_url text;

create or replace function set_org_logo(p_logo text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not sx_is_admin() then
    raise exception 'not authorized';
  end if;
  update organizations set logo_url = p_logo where id = sx_org_id();
end $$;

revoke all on function set_org_logo(text) from public, anon;
grant execute on function set_org_logo(text) to authenticated;
