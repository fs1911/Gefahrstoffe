// StoffScan – «Frag StoffScan»: KI-Chat auf den eigenen Daten (Block 7)
//
// Beantwortet Fragen zu den Gefahrstoffen des Betriebs (wo steht ein Stoff,
// Erste Hilfe, fehlende SDB, Zusammenlagerung, Mengen) – geerdet ausschliesslich
// auf den mitgeschickten Kontext (die Daten der eigenen Organisation).
//
// Ohne ANTHROPIC_API_KEY antwortet die Funktion mit { configured:false } – die
// App fällt dann auf die lokale, regelbasierte Antwort-Engine zurück (kein Fehler).
//
// Secret setzen:  supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
// Deployen:       supabase functions deploy ask-stoffscan

import Anthropic from "https://esm.sh/@anthropic-ai/sdk@0.32?target=deno";

const cors = {
  // Härtung P0-3: keine Wildcard-CORS. Origin via PRIMARY_ORIGIN (Default = Prod-Site).
  "Access-Control-Allow-Origin": Deno.env.get("PRIMARY_ORIGIN") ?? "https://gefahrstoff.netlify.app",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (b: unknown, s = 200) =>
  new Response(JSON.stringify(b), { status: s, headers: { ...cors, "Content-Type": "application/json" } });

const SYSTEM = `Du bist «StoffScan», ein sachlicher Assistent für das Gefahrstoff-Kataster
eines Schweizer Betriebs. Beantworte Fragen NUR auf Basis der mitgelieferten Betriebsdaten
(JSON-Kontext mit Stoffen, Beständen, Lagerorten). Regeln:
- Erfinde nichts. Kommt die Antwort nicht aus den Daten, sage das klar und schlage vor,
  wonach man fragen kann (wo ein Stoff steht, Erste Hilfe, fehlende SDB, Zusammenlagerung).
- Antworte in der Sprache der Frage (Standard Deutsch), kurz und konkret, für Werkhof-/
  Baustellen-Alltag. Nenne bei Standorten Lagerort und Menge, wenn vorhanden.
- Sicherheit zuerst: Bei Erste-Hilfe-/Notfall-Fragen nenne die Schweizer Notrufnummern
  144 (Sanität), 145 (Tox Info Suisse), 118 (Feuerwehr) und verweise auf das SDB.
- Ersetze keine Gefährdungsbeurteilung. Keine erfundenen H-/P-Sätze.
- Nutze einfache Sätze; kurze Aufzählungen mit «- » sind erlaubt. Kein Markdown-Titel, keine Code-Blöcke.`;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const key = Deno.env.get("ANTHROPIC_API_KEY");
  if (!key) return json({ configured: false });

  try {
    const body = await req.json().catch(() => ({}));
    const question = String((body?.question ?? "")).slice(0, 2000).trim();
    if (!question) return json({ error: "Keine Frage übergeben." }, 400);
    const context = JSON.stringify(body?.context ?? {}).slice(0, 120000);

    const anthropic = new Anthropic({ apiKey: key });
    const msg = await anthropic.messages.create({
      // Bewusst das günstigste/schnellste Modell – ein geerdeter Q&A-Chat über
      // wenig Kontext braucht kein Opus. Bei Bedarf auf "claude-sonnet-5" anheben.
      model: "claude-haiku-4-5",
      max_tokens: 700,
      system: SYSTEM,
      messages: [{
        role: "user",
        content:
          `Betriebsdaten (JSON):\n${context}\n\nFrage der Mitarbeiterin/des Mitarbeiters:\n${question}`,
      }] as never,
    });

    const answer = msg.content?.map((c: { type: string; text?: string }) => (c.type === "text" ? c.text : "")).join("").trim() ?? "";
    if (!answer) return json({ error: "Keine Antwort erhalten." }, 502);
    return json({ configured: true, answer });
  } catch (e) {
    console.error("ask-stoffscan", e);
    return json({ error: "Anfrage fehlgeschlagen." }, 500);
  }
});
