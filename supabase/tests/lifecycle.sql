-- StoffScan – Stoff-Freigabe-Lifecycle-Tests (Migration 0013)
-- Läuft in einer zurückgerollten Transaktion; simulierte Nutzer via jwt.claims.
-- Prüft: Grandfathering, Guard-Downgrade, Blockade der Selbst-Freigabe, RPC.
begin;
insert into organizations (id,name) values ('11111111-1111-1111-1111-111111111111','T Org A') on conflict do nothing;
insert into companies (id,organization_id,name,is_group) values ('1a111111-1111-1111-1111-111111111111','11111111-1111-1111-1111-111111111111','A1',true) on conflict do nothing;
insert into auth.users (instance_id,id,aud,role,email,encrypted_password,email_confirmed_at,created_at,updated_at) values
 ('00000000-0000-0000-0000-000000000000','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','authenticated','authenticated','t_a@ex.test','',now(),now(),now()),
 ('00000000-0000-0000-0000-000000000000','dddddddd-dddd-dddd-dddd-dddddddddddd','authenticated','authenticated','t_d@ex.test','',now(),now(),now())
 on conflict do nothing;
insert into profiles (id,organization_id,company_id,name,email,role) values
 ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','11111111-1111-1111-1111-111111111111','1a111111-1111-1111-1111-111111111111','UA','t_a@ex.test','mitarbeitend'),
 ('dddddddd-dddd-dddd-dddd-dddddddddddd','11111111-1111-1111-1111-111111111111','1a111111-1111-1111-1111-111111111111','AD','t_d@ex.test','gruppenadmin')
 on conflict (id) do update set organization_id=excluded.organization_id,company_id=excluded.company_id,role=excluded.role;
create or replace function pg_temp.act(u uuid) returns void language plpgsql as $f$ begin perform set_config('request.jwt.claims',json_build_object('sub',u,'role','authenticated')::text,true); end $f$;
set local role authenticated;

-- T1: Nicht-Admin INSERT status='approved' -> auf needs_review heruntergestuft
select pg_temp.act('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
insert into substances (id,organization_id,produktname,status,source)
  values ('50000000-0000-0000-0000-000000000001','11111111-1111-1111-1111-111111111111','NonAdmin','approved','manual');
do $$ begin
  if (select status from substances where id='50000000-0000-0000-0000-000000000001')<>'needs_review' then raise exception 'FAIL T1'; end if;
  raise notice 'PASS T1: Nicht-Admin-Insert heruntergestuft';
end $$;

-- T2: Nicht-Admin UPDATE auf approved -> blockiert
do $$ begin
  begin update substances set status='approved' where id='50000000-0000-0000-0000-000000000001';
    raise exception 'FAIL T2';
  exception when insufficient_privilege then raise notice 'PASS T2: Selbst-Freigabe blockiert'; end;
end $$;

-- T3: Nicht-Admin RPC approve -> Fehler; needs_review/draft -> ok
do $$ begin
  begin perform substance_set_status('50000000-0000-0000-0000-000000000001','approved');
    raise exception 'FAIL T3a';
  exception when insufficient_privilege then raise notice 'PASS T3a: RPC approve fuer Nicht-Admin blockiert'; end;
  perform substance_set_status('50000000-0000-0000-0000-000000000001','draft');
  raise notice 'PASS T3b: RPC draft ok';
end $$;

-- T4: Admin RPC approve -> approved + approved_by + Audit
select pg_temp.act('dddddddd-dddd-dddd-dddd-dddddddddddd');
do $$ declare v text; v_by uuid; v_a int; begin
  perform substance_set_status('50000000-0000-0000-0000-000000000001','approved');
  select status,approved_by into v,v_by from substances where id='50000000-0000-0000-0000-000000000001';
  select count(*) into v_a from audit_logs where entity_id='50000000-0000-0000-0000-000000000001' and aktion='approve';
  if v<>'approved' or v_by<>'dddddddd-dddd-dddd-dddd-dddddddddddd' or v_a<1 then raise exception 'FAIL T4 %/%/%',v,v_by,v_a; end if;
  raise notice 'PASS T4: Admin-Freigabe + approved_by + Audit';
end $$;
reset role;
rollback;
