-- StoffScan – Cross-Tenant- & Privilege-Escalation-Tests (RLS)
--
-- Prüft die Mandantentrennung und den P0-Fix aus 0011 mit simulierten Nutzern.
-- Läuft komplett in EINER Transaktion und wird am Ende zurückgerollt – es
-- bleiben keine Testdaten zurück. Jede fehlgeschlagene Prüfung wirft eine
-- Exception (bricht die Transaktion ab); bei Erfolg erscheinen PASS-Notices.
--
-- Ausführen:  supabase db execute --file supabase/tests/rls_cross_tenant.sql
--        oder per SQL-Runner / MCP execute_sql (als Service-Role).
--
-- Technik: RLS wird als Rolle `authenticated` mit gesetztem
-- `request.jwt.claims` (sub = Nutzer-UUID) erzwungen; auth.uid() liest daraus.

begin;

-- ---------------------------------------------------------------------------
-- Seed (als Service-Role/postgres – RLS ausgesetzt). Feste Test-UUIDs.
-- ---------------------------------------------------------------------------
\set ON_ERROR_STOP on

-- Orgs
insert into organizations (id, name) values
  ('11111111-1111-1111-1111-111111111111','TEST Org A'),
  ('22222222-2222-2222-2222-222222222222','TEST Org B')
on conflict (id) do nothing;

-- Firmen
insert into companies (id, organization_id, name, is_group) values
  ('1a111111-1111-1111-1111-111111111111','11111111-1111-1111-1111-111111111111','A-Firma1', true),
  ('1b111111-1111-1111-1111-111111111111','11111111-1111-1111-1111-111111111111','A-Firma2', false),
  ('2a222222-2222-2222-2222-222222222222','22222222-2222-2222-2222-222222222222','B-Firma1', true)
on conflict (id) do nothing;

-- Auth-Users (minimal)
insert into auth.users (instance_id, id, aud, role, email, encrypted_password,
                        email_confirmed_at, created_at, updated_at)
values
  ('00000000-0000-0000-0000-000000000000','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
   'authenticated','authenticated','test_a@example.test','', now(), now(), now()),
  ('00000000-0000-0000-0000-000000000000','dddddddd-dddd-dddd-dddd-dddddddddddd',
   'authenticated','authenticated','test_admin_a@example.test','', now(), now(), now()),
  ('00000000-0000-0000-0000-000000000000','bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
   'authenticated','authenticated','test_b@example.test','', now(), now(), now())
on conflict (id) do nothing;

-- Profile: A = mitarbeitend (Org A / A-Firma1), AdminA = gruppenadmin (Org A),
--          B = mitarbeitend (Org B). ON CONFLICT, falls ein auth-Trigger schon
--          ein Profil angelegt hat.
insert into profiles (id, organization_id, company_id, name, email, role) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','11111111-1111-1111-1111-111111111111','1a111111-1111-1111-1111-111111111111','User A','test_a@example.test','mitarbeitend'),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd','11111111-1111-1111-1111-111111111111','1a111111-1111-1111-1111-111111111111','Admin A','test_admin_a@example.test','gruppenadmin'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb','22222222-2222-2222-2222-222222222222','2a222222-2222-2222-2222-222222222222','User B','test_b@example.test','mitarbeitend')
on conflict (id) do update set organization_id = excluded.organization_id,
  company_id = excluded.company_id, role = excluded.role;

-- Stoff + Bestand je Org
insert into substances (id, organization_id, produktname) values
  ('5a5a5a5a-5a5a-5a5a-5a5a-5a5a5a5a5a5a','11111111-1111-1111-1111-111111111111','A-Stoff'),
  ('5b5b5b5b-5b5b-5b5b-5b5b-5b5b5b5b5b5b','22222222-2222-2222-2222-222222222222','B-Stoff')
on conflict (id) do nothing;

insert into substance_instances (id, organization_id, substance_id, company_id, status) values
  ('6b6b6b6b-6b6b-6b6b-6b6b-6b6b6b6b6b6b','22222222-2222-2222-2222-222222222222','5b5b5b5b-5b5b-5b5b-5b5b-5b5b5b5b5b5b','2a222222-2222-2222-2222-222222222222','Lager')
on conflict (id) do nothing;

-- Helper zum Setzen des simulierten Nutzers.
create or replace function pg_temp.act_as(p_uid uuid) returns void
  language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', p_uid, 'role','authenticated')::text, true);
end $$;

-- ===========================================================================
-- TESTS  (als Rolle authenticated → RLS aktiv)
-- ===========================================================================
set local role authenticated;

-- T1: User A darf B-Stoffe NICHT lesen.
select pg_temp.act_as('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
do $$ begin
  if (select count(*) from substances where organization_id='22222222-2222-2222-2222-222222222222') <> 0
    then raise exception 'FAIL T1: User A sieht fremde Stoffe (Org B)'; end if;
  raise notice 'PASS T1: Cross-Tenant SELECT substances blockiert';
end $$;

-- T2: User A darf B-Bestand NICHT lesen.
do $$ begin
  if (select count(*) from substance_instances where organization_id='22222222-2222-2222-2222-222222222222') <> 0
    then raise exception 'FAIL T2: User A sieht fremden Bestand (Org B)'; end if;
  raise notice 'PASS T2: Cross-Tenant SELECT substance_instances blockiert';
end $$;

-- T3: User A darf keinen Stoff mit fremder organization_id einfügen (WITH CHECK).
do $$ begin
  begin
    insert into substances (organization_id, produktname)
      values ('22222222-2222-2222-2222-222222222222','Schmuggel');
    raise exception 'FAIL T3: Insert mit fremder organization_id wurde zugelassen';
  exception when insufficient_privilege or check_violation then
    raise notice 'PASS T3: Insert mit fremder organization_id blockiert';
  end;
end $$;

-- T4: User A (mitarbeitend) darf eigene Rolle NICHT hochstufen (0011-Guard).
do $$ begin
  begin
    update profiles set role='gruppenadmin' where id='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    raise exception 'FAIL T4: Selbst-Hochstufung der Rolle war moeglich';
  exception when insufficient_privilege then
    raise notice 'PASS T4: Selbst-Hochstufung der Rolle blockiert';
  end;
end $$;

-- T5: User A darf eigene organization_id NICHT wechseln (0011-Guard).
do $$ begin
  begin
    update profiles set organization_id='22222222-2222-2222-2222-222222222222'
      where id='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    raise exception 'FAIL T5: Org-Wechsel des eigenen Profils war moeglich';
  exception when insufficient_privilege then
    raise notice 'PASS T5: Org-Wechsel des eigenen Profils blockiert';
  end;
end $$;

-- T6a: Legitim – User A darf eigenen Namen ändern.
do $$ begin
  update profiles set name='User A neu' where id='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  if (select name from profiles where id='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa') <> 'User A neu'
    then raise exception 'FAIL T6a: Namensaenderung nicht wirksam'; end if;
  raise notice 'PASS T6a: Selbst-Namensaenderung erlaubt';
end $$;

-- T6b: Legitim – Admin A darf die Rolle von User A ändern.
select pg_temp.act_as('dddddddd-dddd-dddd-dddd-dddddddddddd');
do $$ begin
  update profiles set role='lagerverantwortlich' where id='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  if (select role from profiles where id='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')::text <> 'lagerverantwortlich'
    then raise exception 'FAIL T6b: Admin konnte Rolle nicht setzen'; end if;
  raise notice 'PASS T6b: Admin-Rollenvergabe erlaubt';
end $$;

reset role;
rollback;
