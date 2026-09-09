-- StoffScan – Baustellenmodus (Phase 1)
-- Eine Baustelle ist ein storage_location mit typ='Baustelle'. Damit erben
-- Baustellen automatisch QR-Code, Feuerwehr-Einsatzplan, Bestände (substance_
-- instances via location_id), Zusammenlagerungsprüfung und Prüf-Dossier.
--
-- Diese Migration ergänzt nur baustellenspezifische Felder. Rein additiv:
-- bestehende Lagerorte bleiben active=true, alle übrigen Felder null.
-- RLS bleibt unverändert (zeilenbasiert über organization_id/company_id;
-- neue Spalten erben die bestehenden Policies aus 0002_rls.sql).

alter table storage_locations
  add column if not exists active     boolean not null default true, -- offen (true) / abgeschlossen (false)
  add column if not exists start_date date,                          -- Bauzeit von
  add column if not exists end_date   date,                          -- Bauzeit bis
  add column if not exists bauleiter  text,                          -- verantwortliche Person vor Ort
  add column if not exists adresse    text;                          -- Baustellenadresse

comment on column storage_locations.active     is 'Baustelle offen (true) oder abgeschlossen (false). Lager sind immer true.';
comment on column storage_locations.start_date is 'Baustelle: geplanter Baubeginn.';
comment on column storage_locations.end_date   is 'Baustelle: geplantes Bauende.';
comment on column storage_locations.bauleiter  is 'Baustelle: verantwortliche Person vor Ort (Freitext).';
comment on column storage_locations.adresse    is 'Baustelle: Adresse / Ortsangabe (Freitext).';

-- Schneller Zugriff auf offene Baustellen einer Organisation.
create index if not exists idx_loc_typ_active
  on storage_locations(organization_id, typ, active);
