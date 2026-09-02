// import-un-reference — einmaliger/aktualisierbarer Import der UN-Nummern
// aus der deutschen Wikipedia (Liste der UN-Nummern) in public.un_reference.
// Läuft serverseitig (Edge Runtime hat Internet-Egress), schreibt via Service-Role.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const UA = "StoffScan/1.0 (hazmat reference importer; contact filip.subara@gmail.com)";

function stripWiki(s: string): string {
  return (s || "")
    .replace(/<ref[^>]*\/>/g, "")
    .replace(/<ref[^>]*>[\s\S]*?<\/ref>/g, "")
    .replace(/\[\[[^\]|]*\|([^\]]*)\]\]/g, "$1")
    .replace(/\[\[([^\]]*)\]\]/g, "$1")
    .replace(/'''?/g, "")
    .replace(/<[^>]+>/g, "")
    .replace(/&nbsp;/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}
function clean(s: string): string | null {
  const t = stripWiki(s);
  return t === "–" || t === "-" || t === "" ? null : t;
}

Deno.serve(async (_req: Request) => {
  try {
    const url = "https://de.wikipedia.org/w/api.php?action=parse&page=Liste%20der%20UN-Nummern&prop=wikitext&format=json&formatversion=2";
    const res = await fetch(url, { headers: { "User-Agent": UA, "accept": "application/json" } });
    if (!res.ok) return Response.json({ ok: false, step: "fetch", status: res.status }, { status: 502 });
    const json = await res.json();
    const wt: string = json?.parse?.wikitext || "";
    if (!wt) return Response.json({ ok: false, step: "wikitext leer" }, { status: 502 });

    const re = /^\|\s*(\d{4})\s*\|\|\s*([^|\n]*)\|\|\s*([^|\n]*)\|\|\s*(.+?)\s*$/gm;
    const seen = new Set<string>();
    const rows: any[] = [];
    let m: RegExpExecArray | null;
    while ((m = re.exec(wt)) !== null) {
      const un = m[1];
      if (seen.has(un)) continue;
      seen.add(un);
      const benennung = stripWiki(m[4]);
      if (!benennung) continue;
      rows.push({
        un_number: un,
        gefahrenzahl: clean(m[2]),
        klasse: clean(m[3]),
        benennung,
        source: "wikipedia:Liste der UN-Nummern",
        updated_at: new Date().toISOString(),
      });
    }

    const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    let inserted = 0;
    const errors: string[] = [];
    for (let i = 0; i < rows.length; i += 500) {
      const batch = rows.slice(i, i + 500);
      const { error } = await sb.from("un_reference").upsert(batch, { onConflict: "un_number" });
      if (error) errors.push(error.message);
      else inserted += batch.length;
    }
    return Response.json({
      ok: errors.length === 0,
      parsed: rows.length,
      inserted,
      errors,
      sample: rows.slice(0, 4),
    });
  } catch (e) {
    return Response.json({ ok: false, error: (e as Error).message }, { status: 500 });
  }
});
