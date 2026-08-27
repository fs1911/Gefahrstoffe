// StoffScan – Stripe Webhook (Block B: «Stripe vorbereiten»)
//
// Empfängt Stripe-Ereignisse und schreibt den Abo-Status zurück in
// organizations (plan, subscription_status, stripe_*-IDs, current_period_end).
// Schreibt mit dem Service-Role-Key (umgeht RLS) – daher NUR serverseitig.
//
// Endpoint in Stripe eintragen:
//   https://<project-ref>.supabase.co/functions/v1/stripe-webhook
// Diese Funktion OHNE JWT-Prüfung deployen:
//   supabase functions deploy stripe-webhook --no-verify-jwt
//
// Benötigte Secrets:
//   STRIPE_SECRET_KEY          sk_live_… / sk_test_…
//   STRIPE_WEBHOOK_SECRET      whsec_…  (aus dem Stripe-Webhook)
//   SUPABASE_SERVICE_ROLE_KEY  Service-Role-Key des Projekts
// (SUPABASE_URL steht automatisch bereit.)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Stripe from "https://esm.sh/stripe@16?target=deno";

// Preis-ID -> Plan (Rückabbildung für Subscription-Events).
const PLAN_BY_PRICE: Record<string, string> = {
  [Deno.env.get("STRIPE_PRICE_STARTER") ?? "__starter"]: "starter",
  [Deno.env.get("STRIPE_PRICE_BETRIEB") ?? "__betrieb"]: "betrieb",
};

Deno.serve(async (req) => {
  const stripeKey = Deno.env.get("STRIPE_SECRET_KEY");
  const whSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET");
  if (!stripeKey || !whSecret) {
    // Noch nicht konfiguriert.
    return new Response(JSON.stringify({ configured: false }), { status: 200 });
  }

  const stripe = new Stripe(stripeKey, { apiVersion: "2024-06-20" });
  const sig = req.headers.get("stripe-signature") ?? "";
  const raw = await req.text();

  let event: Stripe.Event;
  try {
    event = await stripe.webhooks.constructEventAsync(raw, sig, whSecret);
  } catch (e) {
    console.error("Signaturprüfung fehlgeschlagen", e);
    return new Response("Bad signature", { status: 400 });
  }

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const setOrg = async (orgId: string, fields: Record<string, unknown>) => {
    if (!orgId) return;
    await admin.from("organizations").update(fields).eq("id", orgId);
  };
  const statusMap = (s: string) =>
    ({ trialing: "trialing", active: "active", past_due: "past_due",
       unpaid: "past_due", canceled: "canceled" } as Record<string, string>)[s] ?? "active";

  try {
    switch (event.type) {
      case "checkout.session.completed": {
        const s = event.data.object as Stripe.Checkout.Session;
        const orgId = (s.metadata?.organization_id as string) ?? (s.client_reference_id as string) ?? "";
        await setOrg(orgId, {
          stripe_customer_id: s.customer as string,
          stripe_subscription_id: s.subscription as string,
          subscription_status: "active",
          plan: (s.metadata?.plan as string) || undefined,
        });
        break;
      }
      case "customer.subscription.updated":
      case "customer.subscription.created":
      case "customer.subscription.deleted": {
        const sub = event.data.object as Stripe.Subscription;
        const orgId = (sub.metadata?.organization_id as string) ?? "";
        const priceId = sub.items?.data?.[0]?.price?.id ?? "";
        const plan = (sub.metadata?.plan as string) || PLAN_BY_PRICE[priceId];
        await setOrg(orgId, {
          stripe_subscription_id: sub.id,
          subscription_status: event.type === "customer.subscription.deleted"
            ? "canceled" : statusMap(sub.status),
          plan: plan || undefined,
          current_period_end: sub.current_period_end
            ? new Date(sub.current_period_end * 1000).toISOString() : null,
        });
        break;
      }
      default:
        // andere Events ignorieren
        break;
    }
  } catch (e) {
    console.error("Webhook-Verarbeitung fehlgeschlagen", e);
    return new Response("error", { status: 500 });
  }

  return new Response(JSON.stringify({ received: true }), { status: 200 });
});
