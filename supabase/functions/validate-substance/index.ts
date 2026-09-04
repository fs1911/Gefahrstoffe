// validate-substance — StoffScan Datenqualität
// UN-Nummer wird gegen public.un_reference geprüft (importiert aus Wikipedia
// "Liste der UN-Nummern"). VeVA-/Abfallcode gegen public.waste_codes (amtliches
// Abfallverzeichnis SR 814.610.1, inkl. Sonderabfall-Flag & StFV-Mengenschwelle).
// CAS-Anreicherung live aus PubChem PUG-REST (GHS / H-Sätze).
// Öffentlich aufrufbar (verify_jwt=false): liefert nur öffentliche Regulierungs-
// daten, keine mandantenspezifischen Inhalte. Service-Role bleibt serverseitig.
//
// Härtung (Audit P0-3):
//  - CORS: nur erlaubte Origins (ALLOWED_ORIGINS, Default = Produktions-Site)
//    statt "*". Browser-Aufrufe fremder Seiten werden so blockiert.
//  - Rate-Limit pro IP (rl_hit): begrenzt Missbrauch/Kosten des öffentlichen
//    Endpunkts (PubChem-Fetches, DB-Reads) auch für Nicht-Browser-Clients.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const ALLOWED = (Deno.env.get("ALLOWED_ORIGINS") ?? "https://gefahrstoff.netlify.app")
  .split(",").map((s) => s.trim()).filter(Boolean);

function corsFor(req: Request) {
  const origin = req.headers.get("Origin") ?? "";
  const allow = ALLOWED.includes(origin) ? origin : ALLOWED[0];
  return {
    "Access-Control-Allow-Origin": allow,
    "Vary": "Origin",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  };
}

// Rate-Limit: max. Anfragen je IP pro Zeitfenster.
const RL_LIMIT = Number(Deno.env.get("RL_LIMIT") ?? "30");
const RL_WINDOW = Number(Deno.env.get("RL_WINDOW_SECONDS") ?? "60");

const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

function clientIp(req: Request) {
  return (req.headers.get("x-forwarded-for") ?? "").split(",")[0].trim() || "unknown";
}
async function underLimit(req: Request): Promise<boolean> {
  try {
    const { data, error } = await sb.rpc("rl_hit", {
      p_key: "vs:" + clientIp(req), p_limit: RL_LIMIT, p_window_seconds: RL_WINDOW,
    });
    if (error) return true;           // fail-open bei Infra-Fehler (Verfügbarkeit)
    return data !== false;
  } catch (_) {
    return true;
  }
}

function normUn(x: string) { return String(x || "").replace(/[^0-9]/g, "").padStart(4, "0"); }
function normCode(x: string) { return String(x || "").replace(/\*/g, "").replace(/\s+/g, " ").trim(); }

async function lookupUn(un?: string) {
  if (!un) return null;
  const key = normUn(un);
  if (!/^\d{4}$/.test(key)) return { input: un, valid: false, source: "un_reference", note: "Keine gültige 4-stellige UN-Nummer." };
  const { data, error } = await sb.from("un_reference").select("un_number, benennung, klasse, gefahrenzahl, source").eq("un_number", key).maybeSingle();
  if (error) return { input: un, valid: false, source: "un_reference", note: "Abfrage-Fehler: " + error.message };
  return data
    ? { input: un, normalized: "UN " + key, valid: true, name: data.benennung, class: data.klasse, gefahrenzahl: data.gefahrenzahl, source: data.source || "un_reference" }
    : { input: un, normalized: "UN " + key, valid: false, source: "un_reference", note: "Nicht in der UN-Referenzliste – SDB Abschnitt 14 prüfen." };
}
async function lookupVeva(code?: string) {
  if (!code) return null;
  const key = normCode(code);
  const { data, error } = await sb.from("waste_codes").select("code, beschreibung, special, schwelle_kg, klassierung").eq("code", key).maybeSingle();
  if (error) return { input: code, valid: false, source: "waste_codes", note: "Abfrage-Fehler: " + error.message };
  return data
    ? { input: code, normalized: data.code, valid: true, description: data.beschreibung, special: data.special, klassierung: data.klassierung, schwelle_kg: data.schwelle_kg, source: "VeVA/LVA SR 814.610.1" }
    : { input: code, valid: false, source: "waste_codes", note: "Nicht im amtlichen Abfallverzeichnis (VeVA/LVA)." };
}

async function pubchem(cas?: string, name?: string) {
  const q = (cas || name || "").trim();
  if (!q) return null;
  const base = "https://pubchem.ncbi.nlm.nih.gov/rest";
  try {
    const cidRes = await fetch(`${base}/pug/compound/name/${encodeURIComponent(q)}/cids/JSON`, { headers: { "accept": "application/json" } });
    if (!cidRes.ok) return { input: q, found: false, source: "PubChem", note: "Kein Treffer (Status " + cidRes.status + ")." };
    const cidJson = await cidRes.json();
    const cid = cidJson?.IdentifierList?.CID?.[0];
    if (!cid) return { input: q, found: false, source: "PubChem", note: "Kein CID gefunden." };
    let hCodes: string[] = [], signal: string | null = null;
    try {
      const ghsRes = await fetch(`${base}/pug_view/data/compound/${cid}/JSON?heading=GHS+Classification`, { headers: { "accept": "application/json" } });
      if (ghsRes.ok) {
        const txt = await ghsRes.text();
        hCodes = Array.from(new Set((txt.match(/H\d{3}[A-Za-z]?/g) || []))).sort();
        if (/"Danger"/.test(txt)) signal = "Gefahr";
        else if (/"Warning"/.test(txt)) signal = "Achtung";
      }
    } catch (_) { /* GHS optional */ }
    return { input: q, found: true, cid, pubchemUrl: `https://pubchem.ncbi.nlm.nih.gov/compound/${cid}`, hCodes, signal, source: "PubChem PUG-REST" };
  } catch (e) {
    return { input: q, found: false, source: "PubChem", note: "Abruf fehlgeschlagen: " + (e as Error).message };
  }
}

Deno.serve(async (req: Request) => {
  const cors = corsFor(req);
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return new Response(JSON.stringify({ error: "POST erwartet" }), { status: 405, headers: { ...cors, "Content-Type": "application/json" } });

  if (!(await underLimit(req))) {
    return new Response(JSON.stringify({ error: "Zu viele Anfragen. Bitte kurz warten." }),
      { status: 429, headers: { ...cors, "Content-Type": "application/json", "Retry-After": String(RL_WINDOW) } });
  }

  let body: any = {};
  try { body = await req.json(); } catch (_) { /* leerer Body ok */ }
  const { cas, name, un, veva } = body || {};

  const [casRes, unRes, vevaRes] = await Promise.all([pubchem(cas, name), lookupUn(un), lookupVeva(veva)]);

  const notes: string[] = [];
  if (casRes?.found && casRes.hCodes?.length) notes.push("H-Sätze aus PubChem geladen – mit der Einstufung im SDB abgleichen.");
  if (unRes && !unRes.valid) notes.push("UN-Nummer nicht in der Referenzliste. Massgeblich ist SDB Abschnitt 14.");
  if (vevaRes && !vevaRes.valid) notes.push("VeVA-Code nicht im amtlichen Abfallverzeichnis.");
  if (vevaRes && vevaRes.valid && vevaRes.special) notes.push("Sonderabfall – nur an bewilligte Entsorger; Begleitschein via veva-online.ch.");

  const out = {
    ok: true,
    query: { cas: cas || null, name: name || null, un: un || null, veva: veva || null },
    cas: casRes,
    un: unRes,
    veva: vevaRes,
    notes,
    disclaimer: "UN-Referenz aus Wikipedia (Liste der UN-Nummern); VeVA/Abfallcode aus dem amtlichen Abfallverzeichnis (SR 814.610.1). UN-Nummern sind produktspezifisch – SDB Abschnitt 14 bleibt massgeblich.",
    generatedAt: new Date().toISOString(),
  };
  return new Response(JSON.stringify(out), { headers: { ...cors, "Content-Type": "application/json" } });
});
