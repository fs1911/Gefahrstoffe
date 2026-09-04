-- StoffScan – P0-Sicherheitsfix: Privilege Escalation über prof_update_self
--
-- Befund (SAAS_READINESS_AUDIT S1): Die Policy `prof_update_self` erlaubte
-- UPDATE der eigenen Profilzeile OHNE `with check`. Eine angemeldete Person
-- konnte damit die eigene `role` (z. B. auf 'gruppenadmin') sowie
-- `organization_id` / `company_id` / `active` ändern – also sich selbst zum
-- Admin machen oder in eine fremde Organisation wechseln.
--
-- Fix (zwei Schichten, defense in depth):
--   1) Policy `prof_update_self` erhält `with check (id = auth.uid())`, damit
--      eine Selbstbearbeitung die Zeilenidentität nicht auf eine fremde id
--      umbiegen kann.
--   2) BEFORE-UPDATE-Trigger blockiert jede Änderung der privilegierten
--      Spalten role / organization_id / company_id / active durch NICHT-Admins.
--      Admins (sx_is_admin) verwalten Rollen weiterhin über prof_admin_write;
--      Service-Role (auth.uid() IS NULL, serverseitig, RLS-frei) bleibt
--      ausgenommen, damit Onboarding-/Support-Serverflüsse funktionieren.
--
-- Rollenvergabe bleibt unberührt: create_org_and_profile und redeem_invite
-- setzen die Rolle per INSERT (nicht UPDATE) und werden vom Trigger nicht
-- getroffen.

-- 1) Policy härten: Selbst-Update nur der eigenen Zeile, ohne id-Umbiegen.
drop policy if exists prof_update_self on profiles;
create policy prof_update_self on profiles for update
  using (id = auth.uid())
  with check (id = auth.uid());

-- 2) Guard-Trigger gegen Selbst-Hochstufung / Org-Wechsel.
create or replace function sx_guard_profile_privileged()
  returns trigger
  language plpgsql
  security definer
  set search_path = public
as $$
begin
  -- Nur angemeldete Nicht-Admins einschränken. Service-Role (uid IS NULL)
  -- und Admins dürfen privilegierte Felder ändern (Letztere zusätzlich durch
  -- prof_admin_write auf die eigene Organisation begrenzt).
  if auth.uid() is not null
     and not sx_is_admin()
     and ( new.role            is distinct from old.role
        or new.organization_id is distinct from old.organization_id
        or new.company_id      is distinct from old.company_id
        or new.active          is distinct from old.active ) then
    raise exception
      'Rolle, Organisation, Firma oder Aktiv-Status dürfen nur durch Admins geändert werden'
      using errcode = '42501';  -- insufficient_privilege
  end if;
  return new;
end;
$$;

drop trigger if exists trg_profiles_guard_privileged on profiles;
create trigger trg_profiles_guard_privileged
  before update on profiles
  for each row execute function sx_guard_profile_privileged();

-- Trigger-Funktion nicht als RPC exponieren (Supabase-Advisor 0028/0029).
-- Trigger feuern unabhängig von EXECUTE-Grants – der Guard bleibt wirksam.
revoke execute on function public.sx_guard_profile_privileged() from anon, authenticated, public;
