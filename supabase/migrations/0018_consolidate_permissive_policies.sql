-- 0018_consolidate_permissive_policies.sql
-- Performance-Haertung (Advisor 0006 multiple_permissive_policies).
--
-- Ausgangslage: jede Mandanten-Tabelle hatte eine breite *_select-Policy
-- (FOR SELECT) UND eine strengere *_write-Policy (FOR ALL). FOR ALL deckt
-- auch SELECT ab -> zwei permissive Policies pro SELECT, die je Zeile
-- ausgewertet werden.
--
-- Fix: jede FOR-ALL-Write-Policy wird in getrennte INSERT/UPDATE/DELETE-
-- Policies zerlegt. SELECT liegt danach nur noch bei der *_select-Policy.
-- Semantik-erhaltend: die Write-Bedingung ist strenger als die Select-
-- Bedingung (Write-Menge ist Teilmenge der Select-Menge), der Lesezugriff
-- bleibt identisch; die Schreibrechte (INSERT/UPDATE/DELETE) bleiben exakt
-- gleich. Bei profiles werden zusaetzlich die beiden UPDATE-Policies
-- (Admin bzw. eigenes Profil) zu einer Policy mit OR zusammengefuehrt.

-- alerts
drop policy alert_write on public.alerts;
create policy alert_ins on public.alerts for insert with check ((organization_id = sx_org_id()) and sx_can_write());
create policy alert_upd on public.alerts for update using ((organization_id = sx_org_id()) and sx_can_write()) with check ((organization_id = sx_org_id()) and sx_can_write());
create policy alert_del on public.alerts for delete using ((organization_id = sx_org_id()) and sx_can_write());

-- companies
drop policy comp_admin_write on public.companies;
create policy comp_admin_ins on public.companies for insert with check (sx_is_admin() and (organization_id = sx_org_id()));
create policy comp_admin_upd on public.companies for update using (sx_is_admin() and (organization_id = sx_org_id())) with check (sx_is_admin() and (organization_id = sx_org_id()));
create policy comp_admin_del on public.companies for delete using (sx_is_admin() and (organization_id = sx_org_id()));

-- sds_documents
drop policy sds_write on public.sds_documents;
create policy sds_ins on public.sds_documents for insert with check ((organization_id = sx_org_id()) and sx_can_write());
create policy sds_upd on public.sds_documents for update using ((organization_id = sx_org_id()) and sx_can_write()) with check ((organization_id = sx_org_id()) and sx_can_write());
create policy sds_del on public.sds_documents for delete using ((organization_id = sx_org_id()) and sx_can_write());

-- sds_extractions
drop policy sdsx_write on public.sds_extractions;
create policy sdsx_ins on public.sds_extractions for insert with check ((organization_id = sx_org_id()) and sx_can_write());
create policy sdsx_upd on public.sds_extractions for update using ((organization_id = sx_org_id()) and sx_can_write()) with check ((organization_id = sx_org_id()) and sx_can_write());
create policy sdsx_del on public.sds_extractions for delete using ((organization_id = sx_org_id()) and sx_can_write());

-- stock_movements
drop policy mov_write on public.stock_movements;
create policy mov_ins on public.stock_movements for insert with check ((organization_id = sx_org_id()) and sx_can_write());
create policy mov_upd on public.stock_movements for update using ((organization_id = sx_org_id()) and sx_can_write()) with check ((organization_id = sx_org_id()) and sx_can_write());
create policy mov_del on public.stock_movements for delete using ((organization_id = sx_org_id()) and sx_can_write());

-- storage_locations
drop policy loc_write on public.storage_locations;
create policy loc_ins on public.storage_locations for insert with check ((organization_id = sx_org_id()) and (sx_role() = any (array['lagerverantwortlich'::user_role, 'firmenadmin'::user_role, 'gruppenadmin'::user_role])) and sx_sees_company(company_id));
create policy loc_upd on public.storage_locations for update using ((organization_id = sx_org_id()) and (sx_role() = any (array['lagerverantwortlich'::user_role, 'firmenadmin'::user_role, 'gruppenadmin'::user_role])) and sx_sees_company(company_id)) with check ((organization_id = sx_org_id()) and (sx_role() = any (array['lagerverantwortlich'::user_role, 'firmenadmin'::user_role, 'gruppenadmin'::user_role])) and sx_sees_company(company_id));
create policy loc_del on public.storage_locations for delete using ((organization_id = sx_org_id()) and (sx_role() = any (array['lagerverantwortlich'::user_role, 'firmenadmin'::user_role, 'gruppenadmin'::user_role])) and sx_sees_company(company_id));

-- substance_instances
drop policy inst_write on public.substance_instances;
create policy inst_ins on public.substance_instances for insert with check ((organization_id = sx_org_id()) and sx_can_write() and sx_sees_company(company_id));
create policy inst_upd on public.substance_instances for update using ((organization_id = sx_org_id()) and sx_can_write() and sx_sees_company(company_id)) with check ((organization_id = sx_org_id()) and sx_can_write() and sx_sees_company(company_id));
create policy inst_del on public.substance_instances for delete using ((organization_id = sx_org_id()) and sx_can_write() and sx_sees_company(company_id));

-- substances
drop policy sub_write on public.substances;
create policy sub_ins on public.substances for insert with check ((organization_id = sx_org_id()) and sx_can_write());
create policy sub_upd on public.substances for update using ((organization_id = sx_org_id()) and sx_can_write()) with check ((organization_id = sx_org_id()) and sx_can_write());
create policy sub_del on public.substances for delete using ((organization_id = sx_org_id()) and sx_can_write());

-- profiles: FOR ALL zerlegen; die beiden UPDATE-Policies zu einer mit OR zusammenfuehren
drop policy prof_admin_write on public.profiles;
drop policy prof_update_self on public.profiles;
create policy prof_admin_ins on public.profiles for insert with check (sx_is_admin() and (organization_id = sx_org_id()));
create policy prof_admin_del on public.profiles for delete using (sx_is_admin() and (organization_id = sx_org_id()));
create policy prof_update on public.profiles for update using ((sx_is_admin() and (organization_id = sx_org_id())) or (id = (select auth.uid()))) with check ((sx_is_admin() and (organization_id = sx_org_id())) or (id = (select auth.uid())));
