-- 0017_public_scan.sql
-- Anonyme QR-Scan-Ansicht (Option A: nur Sicherheitsinfos).
-- Ein Scan des Gebinde-QR OHNE Login zeigt die SDB-Sicherheitsinfos des
-- zugehoerigen, FREIGEGEBENEN Stoffs. Die Funktion gibt fuer genau den
-- gescannten internen QR nur die Sicherheitsfelder zurueck – KEINE Firma,
-- KEIN Lagerort, KEINE Menge, KEINE Mandanten-IDs. RLS bleibt fuer anon
-- auf allen Tabellen dicht; nur diese eng begrenzte Funktion ist offen.

create or replace function public.public_scan(p_qr text)
returns table(
  produktname text,
  hersteller text,
  signalwort text,
  ghs_piktogramme text[],
  h_saetze text,
  p_saetze text,
  un_nummer text,
  lagerklasse text,
  wassergefaehrdend boolean,
  brennbar boolean
)
language sql
security definer
set search_path = public
stable
as $$
  select s.produktname, s.hersteller, s.signalwort, s.ghs_piktogramme,
         s.h_saetze, s.p_saetze, s.un_nummer, s.lagerklasse,
         s.wassergefaehrdend, s.brennbar
  from substance_instances i
  join substances s on s.id = i.substance_id
  where i.internal_qr = p_qr
    and s.status = 'approved'
  limit 1;
$$;

revoke all on function public.public_scan(text) from public;
grant execute on function public.public_scan(text) to anon, authenticated;

comment on function public.public_scan(text) is
  'Oeffentliche Sicherheitsansicht fuer einen gescannten Gebinde-QR. Nur SDB-Sicherheitsfelder eines freigegebenen Stoffs, keine Mandanten-/Bestandsdaten.';
