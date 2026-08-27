// StoffScan – Stripe Checkout (Block B: «Stripe vorbereiten»)
//
// Erstellt eine Stripe-Checkout-Session für den gewählten Plan und gibt die
// URL zurück. Die App ruft diese Funktion via supabase.functions.invoke(
// 'create-checkout-session', { body: { plan } }) auf.
//
// Solange die Stripe-Secrets NICHT gesetzt sind, antwortet die Funktion mit
// { configured: false } (Status 200) – die App merkt sich dann nur den
// gewählten Plan (set_org_plan) und zeigt keinen Fehler. Erst wenn die
// Secrets gesetzt sind, wird eine echte Checkout-URL zurückgegeben.
//
// Benötigte Secrets (supabase secrets set ...):
//   STRIPE_SECRET_KEY        sk_live_… / sk_test_…
//   STRIPE_PRICE_STARTER     price_… (Abo-Preis Starter)
//   STRIPE_PRICE_BETRIEB     price_… (Abo-Preis Betrieb)
//   SITE_URL                 z. B. https://stoffscan.ch  (für Success/Cancel)
// (SUPABASE_URL und SUPABASE_ANON_KEY stehen in Edge Functions automatisch bereit.)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Stripe from "https://esm.sh/stripe@16?target=deno";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

const PRICE_ENV: Record<string, string> = {
  starter: "STRIPE_PRICE_STARTER",
  betrieb: "STRIPE_PRICE_BETRIEB",
  // 'gruppe' ist nicht self-service (Kontakt aufnehmen).
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const stripeKey = Deno.env.get("STRIPE_SECRET_KEY");
  if (!stripeKey) {
    // Noch nicht konfiguriert – App fällt auf set_org_plan zurück.
    return json({ configured: false });
  }

  try {
    const { plan } = await req.json().catch(() => ({ plan: "" }));
    const priceEnv = PRICE_ENV[plan];
    if (!priceEnv) return json({ error: "Für diesen Plan ist keine Online-Buchung möglich." }, 400);
    const price = Deno.env.get(priceEnv);
    if (!price) return json({ configured: false });

    // Aufrufer identifizieren (JWT aus dem Authorization-Header).
    const authHeader = req.headers.get("Authorization") ?? "";
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return json({ error: "Nicht angemeldet." }, 401);

    // Profil/Rolle + Organisation (RLS erlaubt Lesen der eigenen Org).
    const { data: profile } = await supabase
      .from("profiles").select("organization_id, role").eq("id", user.id).maybeSingle();
    if (!profile) return json({ error: "Kein Profil gefunden." }, 403);
    if (!["firmenadmin", "gruppenadmin"].includes(profile.role))
      return json({ error: "Nur Admins dürfen ein Abo buchen." }, 403);

    const { data: org } = await supabase
      .from("organizations").select("id, name, stripe_customer_id").eq("id", profile.organization_id).maybeSingle();
    if (!org) return json({ error: "Keine Organisation gefunden." }, 403);

    const stripe = new Stripe(stripeKey, { apiVersion: "2024-06-20" });

    // Stripe-Kunde wiederverwenden oder anlegen.
    let customer = org.stripe_customer_id as string | null;
    if (!customer) {
      const c = await stripe.customers.create({
        email: user.email ?? undefined,
        name: org.name ?? undefined,
        metadata: { organization_id: org.id },
      });
      customer = c.id;
    }

    const siteUrl = Deno.env.get("SITE_URL") ?? new URL(req.url).origin;
    const session = await stripe.checkout.sessions.create({
      mode: "subscription",
      customer,
      line_items: [{ price, quantity: 1 }],
      allow_promotion_codes: true,
      client_reference_id: org.id,
      subscription_data: { metadata: { organization_id: org.id, plan } },
      metadata: { organization_id: org.id, plan },
      success_url: `${siteUrl}/live/?abo=success`,
      cancel_url: `${siteUrl}/live/?abo=cancel`,
    });

    return json({ url: session.url });
  } catch (e) {
    console.error("create-checkout-session", e);
    return json({ error: "Checkout fehlgeschlagen." }, 500);
  }
});
