-- 0016_golive_perf_indexes.sql
-- Go-Live-Härtung (Performance). Rein additiv, keine Verhaltensänderung.
--   1) RLS-Initplan-Fix: auth.uid() in profiles.prof_update_self als Subselect,
--      damit es nicht pro Zeile evaluiert wird (Advisor 0003).
--   2) Deckende Indizes für alle vom Advisor (0001) gemeldeten unindexierten
--      Fremdschlüssel.

-- 1) RLS initplan fix
ALTER POLICY prof_update_self ON public.profiles
  USING (id = (select auth.uid()))
  WITH CHECK (id = (select auth.uid()));

-- 2) Deckende Indizes für Fremdschlüssel
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON public.audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_companies_parent_id ON public.companies(parent_id);
CREATE INDEX IF NOT EXISTS idx_instructions_company_id ON public.instructions(company_id);
CREATE INDEX IF NOT EXISTS idx_instructions_created_by ON public.instructions(created_by);
CREATE INDEX IF NOT EXISTS idx_instructions_profile_id ON public.instructions(profile_id);
CREATE INDEX IF NOT EXISTS idx_instructions_substance_id ON public.instructions(substance_id);
CREATE INDEX IF NOT EXISTS idx_invitations_company_id ON public.invitations(company_id);
CREATE INDEX IF NOT EXISTS idx_invitations_invited_by ON public.invitations(invited_by);
CREATE INDEX IF NOT EXISTS idx_pcc_organization_id ON public.product_catalog_contributors(organization_id);
CREATE INDEX IF NOT EXISTS idx_profiles_company_id ON public.profiles(company_id);
CREATE INDEX IF NOT EXISTS idx_sds_documents_organization_id ON public.sds_documents(organization_id);
CREATE INDEX IF NOT EXISTS idx_sds_documents_uploaded_by ON public.sds_documents(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_sds_extractions_created_by ON public.sds_extractions(created_by);
CREATE INDEX IF NOT EXISTS idx_sds_extractions_sds_document_id ON public.sds_extractions(sds_document_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_organization_id ON public.stock_movements(organization_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_user_id ON public.stock_movements(user_id);
CREATE INDEX IF NOT EXISTS idx_storage_locations_parent_location_id ON public.storage_locations(parent_location_id);
CREATE INDEX IF NOT EXISTS idx_substance_instances_responsible_user_id ON public.substance_instances(responsible_user_id);
CREATE INDEX IF NOT EXISTS idx_substances_approved_by ON public.substances(approved_by);
