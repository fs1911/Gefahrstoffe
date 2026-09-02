// validate-substance — StoffScan Datenqualität
// Validiert UN-Nummer & VeVA-/Abfallcode gegen eine Referenzliste und
// reichert per CAS aus PubChem (PUG-REST) an (GHS / H-Sätze, live).
//
// Referenzlisten sind ein KERN-AUSZUG (source: "seed"); die vollständigen
// amtlichen Listen (ADR/SDR-Gefahrgutliste, LVA/VeVA-Abfallverzeichnis)
// werden 1:1 nachgeladen. So ist jede UN-Nr / jeder Code gegen einen echten
// Eintrag geprüft statt frei geraten.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// ---- UN-Referenz (ADR/SDR, Auszug) : UN -> [Stoffname, Klasse, VG] ----
const UN_REF: Record<string, [string, string, string]> = {
  "1090": ["Aceton", "3", "II"],
  "1133": ["Klebstoffe (entzündbar)", "3", "II/III"],
  "1170": ["Ethanol / Ethanol-Lösung", "3", "II/III"],
  "1202": ["Dieselkraftstoff / Heizöl (leicht)", "3", "III"],
  "1203": ["Benzin (Ottokraftstoff)", "3", "II"],
  "1263": ["Farbe / Farbzubehörstoffe", "3", "II/III"],
  "1268": ["Erdöldestillate a.n.g.", "3", "I/II/III"],
  "1300": ["Terpentinersatz / White Spirit", "3", "III"],
  "1760": ["Ätzender flüssiger Stoff, a.n.g.", "8", "I/II/III"],
  "1789": ["Salzsäure (Chlorwasserstoffsäure)", "8", "II/III"],
  "1805": ["Phosphorsäure, Lösung", "8", "III"],
  "1824": ["Natriumhydroxid-Lösung (Natronlauge)", "8", "II/III"],
  "1830": ["Schwefelsäure", "8", "II"],
  "1863": ["Kraftstoff für Luftfahrzeuge (Turbine)", "3", "I/II/III"],
  "1866": ["Harzlösung (entzündbar)", "3", "II/III"],
  "1950": ["Druckgaspackungen (Aerosole)", "2", "-"],
  "1965": ["Kohlenwasserstoffgas-Gemisch, verflüssigt a.n.g.", "2", "-"],
  "1978": ["Propan", "2", "-"],
  "1993": ["Entzündbarer flüssiger Stoff, a.n.g.", "3", "I/II/III"],
  "2789": ["Essigsäure, Eisessig oder Lösung > 80 %", "8", "II"],
  "3077": ["Umweltgefährdender Stoff, fest, a.n.g.", "9", "III"],
  "3082": ["Umweltgefährdender Stoff, flüssig, a.n.g.", "9", "III"],
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

function normUn(x: string) { return String(x || "").replace(/[^0-9]/g, ""); }
function normCode(x: string) { return String(x || "").replace(/\s+/g, " ").trim().toUpperCase().replace(/\*$/, "*"); }

function lookupUn(un?: string) {
  if (!un) return null;
  const key = normUn(un);
  const hit = UN_REF[key];
  return hit
    ? { input: un, normalized: "UN " + key, valid: true, name: hit[0], class: hit[1], packingGroup: hit[2], source: "ADR/SDR-Auszug" }
    : { input: un, normalized: key ? "UN " + key : "", valid: false, source: "ADR/SDR-Auszug", note: "Nicht im Referenz-Auszug – gegen SDB Abschnitt 14 / vollständige ADR-Liste prüfen." };
}
function lookupVeva(code?: string) {
  if (!code) return null;
  const key = normCode(code);
  const hit = VEVA_REF[key] || VEVA_REF[key.replace(/\s*\*$/, "") + "*"] || VEVA_REF[key.replace(/\*$/, "")];
  return hit
    ? { input: code, valid: true, description: hit[0], special: hit[1], source: "LVA/VeVA-Auszug" }
    : { input: code, valid: false, source: "LVA/VeVA-Auszug", note: "Nicht im Referenz-Auszug – gegen amtliches Abfallverzeichnis prüfen." };
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

  const [casRes] = await Promise.all([pubchem(cas, name)]);
  const unRes = lookupUn(un);
  const vevaRes = lookupVeva(veva);

  const notes: string[] = [];
  if (casRes?.found && casRes.hCodes?.length) notes.push("H-Sätze aus PubChem geladen – mit der Einstufung im SDB abgleichen.");
  if (unRes && !unRes.valid) notes.push("UN-Nummer nicht im Referenz-Auszug. Massgeblich ist SDB Abschnitt 14.");
  if (vevaRes && !vevaRes.valid) notes.push("VeVA-Code nicht im Referenz-Auszug. Massgeblich ist das amtliche Abfallverzeichnis.");

  const out = {
    ok: true,
    query: { cas: cas || null, name: name || null, un: un || null, veva: veva || null },
    cas: casRes,
    un: unRes,
    veva: vevaRes,
    notes,
    disclaimer: "Referenzlisten sind ein Auszug; vollständige amtliche Listen (ADR/SDR, LVA/VeVA) werden nachgeladen. UN-Nummern sind produktspezifisch – SDB Abschnitt 14 bleibt massgeblich.",
    generatedAt: new Date().toISOString(),
  };
  return new Response(JSON.stringify(out), { headers: { ...cors, "Content-Type": "application/json" } });
});
