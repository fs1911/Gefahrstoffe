-- 0019_restrict_sx_helpers_from_anon.sql
-- Attack-Surface-Reduktion (Advisor 0028).
-- Die internen RLS-Helfer sx_* sollen NICHT anonym per REST aufrufbar sein.
-- EXECUTE liegt per Default bei PUBLIC (anon erbt davon). Wir entziehen es
-- PUBLIC/anon und gewaehren es explizit authenticated (die RLS-Policies
-- rufen die Funktionen als authenticated auf) und service_role.
-- SECURITY-DEFINER-Funktionen laufen intern als Owner, daher bleiben
-- app-interne Aufrufe (aus anderen Definer-Funktionen) unberuehrt.
-- Ergebnis: der anon-Executable-WARN sinkt von 7 auf 1 (nur noch das
-- bewusst oeffentliche public_scan).

revoke execute on function public.sx_can_write() from public, anon;
grant execute on function public.sx_can_write() to authenticated, service_role;

revoke execute on function public.sx_company_id() from public, anon;
grant execute on function public.sx_company_id() to authenticated, service_role;

revoke execute on function public.sx_is_admin() from public, anon;
grant execute on function public.sx_is_admin() to authenticated, service_role;

revoke execute on function public.sx_org_id() from public, anon;
grant execute on function public.sx_org_id() to authenticated, service_role;

revoke execute on function public.sx_role() from public, anon;
grant execute on function public.sx_role() to authenticated, service_role;

revoke execute on function public.sx_sees_company(uuid) from public, anon;
grant execute on function public.sx_sees_company(uuid) to authenticated, service_role;
