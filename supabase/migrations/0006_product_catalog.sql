-- 0006_product_catalog.sql
-- Mandantenübergreifender, crowdsourced Schweizer Produkt-Katalog.
-- Ein Produkt, das ein Betrieb einmal sauber erfasst, wird für alle Betriebe
-- wiedererkannt: Barcode scannen -> Stoffkarte kommt fertig zurück.
--
-- Datenschutz: Kein Betrieb sieht, WER beigetragen hat. Lesbar sind nur die
-- reinen Produktangaben und die Anzahl der bestätigenden Betriebe. Erreicht
-- wird das über gesperrte Tabellen + SECURITY-DEFINER-Funktionen; die Spalte
-- mit den Beitragenden liegt in einer separaten Tabelle, die nie exponiert wird.

create table if not exists product_catalog (
  id uuid primary key default gen_random_uuid(),
  barcode text not null unique,            -- EAN/GTIN, nur Ziffern
  produktname text not null,
  hersteller text,
  signalwort text,                         -- 'Gefahr' | 'Achtung'
  ghs_piktogramme text[] not null default '{}',
  h_saetze text,
  p_saetze text,
  un_nummer text,
  lagerklasse text,
  quelle text,                             -- 'kuratiert' | 'neu' | 'bestaetigt'
  bestaetigungen int not null default 1,   -- Zahl distinct Betriebe (Crowd-Vertrauen)
  status text not null default 'aktiv',    -- 'aktiv' | 'gesperrt' (Moderation)
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Welche Organisationen ein Produkt bestätigt haben (nie an Clients exponiert).
create table if not exists product_catalog_contributors (
  catalog_id uuid not null references product_catalog(id) on delete cascade,
  organization_id uuid not null references organizations(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (catalog_id, organization_id)
);

-- RLS an, aber ohne Policies -> keine direkten Selects/Inserts durch Clients.
-- Aller Zugriff läuft ausschliesslich über die RPCs unten.
alter table product_catalog enable row level security;
alter table product_catalog_contributors enable row level security;

-- Barcode normalisieren (nur Ziffern behalten; leere -> NULL).
create or replace function catalog_norm(p text)
returns text language sql immutable set search_path = public as $$
  select nullif(regexp_replace(coalesce(p,''), '\D', '', 'g'), '')
$$;

-- Nachschlagen: liefert genau die öffentlichen Felder (ohne Beitragende).
create or replace function catalog_find(p_barcode text)
returns table(produktname text, hersteller text, signalwort text,
              ghs_piktogramme text[], h_saetze text, p_saetze text,
              un_nummer text, lagerklasse text, bestaetigungen int)
language sql security definer set search_path = public as $$
  select c.produktname, c.hersteller, c.signalwort, c.ghs_piktogramme,
         c.h_saetze, c.p_saetze, c.un_nummer, c.lagerklasse, c.bestaetigungen
  from product_catalog c
  where c.status = 'aktiv' and c.barcode = catalog_norm(p_barcode)
  limit 1
$$;

-- Beitrag: legt Produkt an oder füllt fehlende Felder auf und erhöht die
-- Bestätigungszahl (maximal 1 pro Betrieb). Überschreibt vorhandene Werte nicht.
create or replace function catalog_contribute(
  p_barcode text, p_produktname text, p_hersteller text default null,
  p_signalwort text default null, p_ghs text[] default '{}',
  p_h text default null, p_p text default null,
  p_un text default null, p_lk text default null, p_quelle text default null)
returns void language plpgsql security definer set search_path = public as $$
declare v_bc text; v_org uuid; v_id uuid;
begin
  v_bc := catalog_norm(p_barcode);
  v_org := sx_org_id();
  if v_bc is null or length(v_bc) < 8 or v_org is null or coalesce(p_produktname,'') = '' then
    return;
  end if;

  insert into product_catalog(barcode, produktname, hersteller, signalwort,
      ghs_piktogramme, h_saetze, p_saetze, un_nummer, lagerklasse, quelle)
    values(v_bc, p_produktname, p_hersteller, p_signalwort,
      coalesce(p_ghs,'{}'), p_h, p_p, p_un, p_lk, coalesce(p_quelle,'neu'))
  on conflict (barcode) do update set
      hersteller      = coalesce(product_catalog.hersteller, excluded.hersteller),
      signalwort      = coalesce(product_catalog.signalwort, excluded.signalwort),
      ghs_piktogramme = case when array_length(product_catalog.ghs_piktogramme,1) is null
                             then excluded.ghs_piktogramme else product_catalog.ghs_piktogramme end,
      h_saetze        = coalesce(product_catalog.h_saetze, excluded.h_saetze),
      p_saetze        = coalesce(product_catalog.p_saetze, excluded.p_saetze),
      un_nummer       = coalesce(product_catalog.un_nummer, excluded.un_nummer),
      lagerklasse     = coalesce(product_catalog.lagerklasse, excluded.lagerklasse),
      updated_at      = now()
  returning id into v_id;

  insert into product_catalog_contributors(catalog_id, organization_id)
    values(v_id, v_org) on conflict do nothing;

  update product_catalog set bestaetigungen =
    (select count(*) from product_catalog_contributors where catalog_id = v_id)
    where id = v_id;
end $$;

revoke all on function catalog_find(text) from public, anon;
revoke all on function catalog_contribute(text,text,text,text,text[],text,text,text,text,text) from public, anon;
grant execute on function catalog_find(text) to authenticated;
grant execute on function catalog_contribute(text,text,text,text,text[],text,text,text,text,text) to authenticated;

-- Kuratierte Grunddaten (bekannte CH-Handelsprodukte), damit der Katalog vom
-- ersten Tag an Treffer liefert. bestaetigungen = kuratierte Startzahl.
insert into product_catalog(barcode, produktname, hersteller, signalwort, ghs_piktogramme, h_saetze, p_saetze, un_nummer, lagerklasse, quelle, bestaetigungen) values
 ('7640140630012','Isopropanol 99,9 %','Kisling AG','Gefahr','{flamm,reiz}','H225, H319, H336','P210, P233, P280, P305+P351+P338','UN 1219','3','kuratiert',14),
 ('5032227400221','WD-40 Multifunktionsspray','WD-40 Company','Gefahr','{flamm}','H222, H229','P210, P211, P251, P410+P412','UN 1950','2B','kuratiert',63),
 ('7610827411006','Natriumhypochlorit 12 %','Sigma AG','Gefahr','{aetz,umwelt}','H314, H400','P280, P305+P351+P338, P310, P273','UN 1791','8B','kuratiert',9),
 ('7612345000019','Nitroverdünner','Colorex AG','Gefahr','{flamm,reiz}','H225, H319, H336','P210, P240, P280, P303+P361+P353','UN 1993','3','kuratiert',21),
 ('4011750017707','Silikonentferner Spray','Presto','Gefahr','{flamm}','H222, H229, H336','P210, P251, P260, P271','UN 1950','2B','kuratiert',7),
 ('7610000999015','Rostlöser MoS2','Motorex','Achtung','{flamm}','H222, H229','P210, P211, P251','UN 1950','2B','kuratiert',32)
on conflict (barcode) do nothing;
