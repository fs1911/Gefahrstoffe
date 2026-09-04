// StoffScan – SDB → Stoffkarte per KI (Differenzierung, Block 1)
//
// Nimmt ein Sicherheitsdatenblatt (PDF/Bild als base64 ODER bereits
// extrahierten Text) entgegen und lässt Claude die relevanten Felder
// strukturiert herauslesen: Produktname, Hersteller, Signalwort, GHS-
// Piktogramme, H-/P-Sätze, UN-Nummer, Lagerklasse.
//
// Ohne ANTHROPIC_API_KEY antwortet die Funktion mit { configured:false } –
// die App füllt die Stoffkarte dann wie bisher manuell aus (kein Fehler).
//
// Secret setzen:  supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
// Deployen:       supabase functions deploy parse-sdb

import Anthropic from "https://esm.sh/@anthropic-ai/sdk@0.32?target=deno";

const cors = {
  // Härtung P0-3: keine Wildcard-CORS. Origin via PRIMARY_ORIGIN (Default = Prod-Site).
  "Access-Control-Allow-Origin": Deno.env.get("PRIMARY_ORIGIN") ?? "https://gefahrstoff.netlify.app",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (b: unknown, s = 200) =>
  new Response(JSON.stringify(b), { status: s, headers: { ...cors, "Content-Type": "application/json" } });

// GHS-Schlüssel wie in der App (Chips).
const GHS_KEYS = ["explosiv", "flamm", "oxid", "druckgas", "aetz", "giftig", "reiz", "gesundheit", "umwelt"];

const SYSTEM = `Du bist Fachassistent für Gefahrstoffe (Schweiz, CLP/GHS). Lies das
Sicherheitsdatenblatt und gib die Angaben NUR als JSON zurück, exakt in diesem Schema:
{
 "produktname": string,
 "hersteller": string,
 "signalwort": "Gefahr" | "Achtung" | "",
 "ghs": string[],           // Teilmenge von: ${GHS_KEYS.join(", ")}
 "h_saetze": string,        // z. B. "H225, H319, H336"
 "p_saetze": string,        // z. B. "P210, P280"
 "un_nummer": string,       // z. B. "UN 1090" oder ""
 "lagerklasse": string      // z. B. "3" oder "" wenn nicht ableitbar
}
Keine Erklärungen, kein Markdown, nur das JSON-Objekt. Wenn ein Feld fehlt, leerer String bzw. leeres Array.`;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const key = Deno.env.get("ANTHROPIC_API_KEY");
  if (!key) return json({ configured: false });

  try {
    const body = await req.json().catch(() => ({}));
    const { pdf_base64, image_base64, media_type, text } = body ?? {};

    const content: unknown[] = [];
    if (pdf_base64) {
      content.push({ type: "document", source: { type: "base64", media_type: "application/pdf", data: pdf_base64 } });
    } else if (image_base64) {
      content.push({ type: "image", source: { type: "base64", media_type: media_type || "image/jpeg", data: image_base64 } });
    } else if (text) {
      content.push({ type: "text", text: `Sicherheitsdatenblatt (Text):\n\n${String(text).slice(0, 60000)}` });
    } else {
      return json({ error: "Kein SDB übergeben (pdf_base64 | image_base64 | text)." }, 400);
    }
    content.push({ type: "text", text: "Extrahiere die Felder gemäss Schema als JSON." });

    const anthropic = new Anthropic({ apiKey: key });
    const msg = await anthropic.messages.create({
      model: "claude-sonnet-5",
      max_tokens: 1024,
      system: SYSTEM,
      messages: [{ role: "user", content: content as never }],
    });

    const raw = msg.content?.map((c: { type: string; text?: string }) => (c.type === "text" ? c.text : "")).join("") ?? "";
    const jsonStr = raw.slice(raw.indexOf("{"), raw.lastIndexOf("}") + 1);
    let data: Record<string, unknown>;
    try {
      data = JSON.parse(jsonStr);
    } catch {
      return json({ error: "KI-Antwort nicht lesbar.", raw }, 502);
    }

    // GHS auf erlaubte Schlüssel begrenzen.
    const ghs = Array.isArray(data.ghs) ? (data.ghs as string[]).filter((g) => GHS_KEYS.includes(g)) : [];
    return json({
      configured: true,
      produktname: String(data.produktname ?? ""),
      hersteller: String(data.hersteller ?? ""),
      signalwort: ["Gefahr", "Achtung"].includes(String(data.signalwort)) ? String(data.signalwort) : "",
      ghs,
      h_saetze: String(data.h_saetze ?? ""),
      p_saetze: String(data.p_saetze ?? ""),
      un_nummer: String(data.un_nummer ?? ""),
      lagerklasse: String(data.lagerklasse ?? ""),
    });
  } catch (e) {
    console.error("parse-sdb", e);
    return json({ error: "Analyse fehlgeschlagen." }, 500);
  }
});
