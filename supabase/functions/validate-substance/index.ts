// validate-substance — StoffScan Datenqualität
// UN-Nummer wird gegen public.un_reference geprüft (vollständige Liste,
// importiert aus Wikipedia "Liste der UN-Nummern"). VeVA-Code gegen einen
// eingebetteten Auszug (amtliche LVA-Liste folgt). CAS-Anreicherung live
// aus PubChem PUG-REST (GHS / H-Sätze).
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// ---- VeVA/LVA-Referenz (Auszug) : Code -> [Beschreibung, Sonderabfall] ----
const VEVA_REF: Record<string, [string, boolean]> = {
  "06 01 06*": ["Andere Säuren", true],
  "06 02 05*": ["Andere Basen", true],
  "08 01 11*": ["Farb- und Lackabfälle mit organischen Lösemitteln/gefährlichen Stoffen", true],
  "08 01 12": ["Farb- und Lackabfälle mit Ausnahme derjenigen, die unter 08 01 11 fallen", false],
  "13 02 08*": ["Andere Maschinen-, Getriebe- und Schmieröle", true],
  "13 07 01*": ["Heizöl und Diesel", true],
  "13 07 02*": ["Benzin", true],
  "14 06 03*": ["Andere Lösemittel und Lösemittelgemische", true],
  "15 01 10*": ["Verpackungen, die Rückstände gefährlicher Stoffe enthalten oder verunreinigt sind", true],
  "16 05 04*": ["Gase in Druckbehältern, die gefährliche Stoffe enthalten", true],
  "16 05 05": ["Gase in Druckbehältern mit Ausnahme derjenigen, die unter 16 05 04 fallen", false],
  "16 05 06*": ["Laborchemikalien, die aus gefährlichen Stoffen bestehen", true],
  "16 09 04*": ["Oxidierende Stoffe a.n.g.", true],
  "20 01 13*": ["Lösemittel", true],
  "20 01 27*": ["Farben, Druckfarben, Klebstoffe mit gefährlichen Stoffen", true],
  "20 01 29*": ["Reinigungsmittel, die gefährliche Stoffe enthalten", true],
  "20 01 30": ["Reinigungsmittel mit Ausnahme derjenigen, die unter 20 01 29 fallen", false],
};

const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

function normUn(x: string) { return String(x || "").replace(/[^0-9]/g, "").padStart(4, "0"); }
function normCode(x: string) { return String(x || "").replace(/\s+/g, " ").trim().toUpperCase(); }

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
function lookupVeva(code?: string) {
  if (!code) return null;
  const key = normCode(code);
  const hit = VEVA_REF[key] || VEVA_REF[key.replace(/\s*\*$/, "") + "*"] || VEVA_REF[key.replace(/\*$/, "")];
  return hit
    ? { input: code, valid: true, description: hit[0], special: hit[1], source: "LVA/VeVA-Auszug" }
    : { input: code, valid: false, source: "LVA/VeVA-Auszug", note: "Nicht im Referenz-Auszug – amtliches Abfallverzeichnis prüfen." };
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
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return new Response(JSON.stringify({ error: "POST erwartet" }), { status: 405, headers: { ...cors, "Content-Type": "application/json" } });
  let body: any = {};
  try { body = await req.json(); } catch (_) { /* leerer Body ok */ }
  const { cas, name, un, veva } = body || {};

  const [casRes, unRes] = await Promise.all([pubchem(cas, name), lookupUn(un)]);
  const vevaRes = lookupVeva(veva);

  const notes: string[] = [];
  if (casRes?.found && casRes.hCodes?.length) notes.push("H-Sätze aus PubChem geladen – mit der Einstufung im SDB abgleichen.");
  if (unRes && !unRes.valid) notes.push("UN-Nummer nicht in der Referenzliste. Massgeblich ist SDB Abschnitt 14.");
  if (vevaRes && !vevaRes.valid) notes.push("VeVA-Code nicht im Referenz-Auszug. Massgeblich ist das amtliche Abfallverzeichnis.");

  const out = {
    ok: true,
    query: { cas: cas || null, name: name || null, un: un || null, veva: veva || null },
    cas: casRes,
    un: unRes,
    veva: vevaRes,
    notes,
    disclaimer: "UN-Referenz aus Wikipedia (Liste der UN-Nummern); VeVA-Auszug, amtliche LVA-Liste folgt. UN-Nummern sind produktspezifisch – SDB Abschnitt 14 bleibt massgeblich.",
    generatedAt: new Date().toISOString(),
  };
  return new Response(JSON.stringify(out), { headers: { ...cors, "Content-Type": "application/json" } });
});
