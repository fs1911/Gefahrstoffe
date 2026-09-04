-- StoffScan – Rate-Limiting-Infrastruktur (Audit P0-3)
-- Fixed-Window-Zähler pro Schlüssel (z. B. IP) für öffentliche/kostenintensive
-- Endpunkte (v. a. validate-substance, verify_jwt=false). Aufruf serverseitig
-- über den Service-Role-Key aus Edge Functions.

create table if not exists rate_limits (
  bucket        text        not null,
  window_start  timestamptz not null,
  count         integer     not null default 0,
  primary key (bucket, window_start)
);
create index if not exists idx_rate_limits_window on rate_limits(window_start);

alter table rate_limits enable row level security;  -- kein direkter Client-Zugriff

-- rl_hit: zählt einen Treffer im aktuellen Zeitfenster und liefert true, solange
-- das Limit nicht überschritten ist. p_window_seconds bestimmt die Fenstergröße.
create or replace function rl_hit(p_key text, p_limit int, p_window_seconds int)
  returns boolean
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  v_ws    timestamptz := to_timestamp(
             floor(extract(epoch from now()) / p_window_seconds) * p_window_seconds);
  v_count int;
begin
  insert into rate_limits(bucket, window_start, count)
    values (p_key, v_ws, 1)
    on conflict (bucket, window_start)
      do update set count = rate_limits.count + 1
    returning count into v_count;

  -- Gelegentliches Aufräumen alter Fenster (billig, ~1 % der Aufrufe).
  if random() < 0.01 then
    delete from rate_limits where window_start < now() - interval '1 day';
  end if;

  return v_count <= p_limit;
end;
$$;

-- Nur der Service-Role (Edge Functions) darf zählen; Clients nicht.
revoke execute on function rl_hit(text, int, int) from anon, authenticated, public;
grant  execute on function rl_hit(text, int, int) to service_role;
