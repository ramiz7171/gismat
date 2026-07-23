// Creates a Stripe subscription-mode Checkout Session for the signed-in user.
// Body: { tier: 'pro' | 'max' } → { url: string }
import { createClient } from "jsr:@supabase/supabase-js@2";
import Stripe from "npm:stripe@17";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  try {
    // 1. Verify the caller's JWT.
    const authHeader = req.headers.get("Authorization") ?? "";
    const anon = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const {
      data: { user },
      error: userError,
    } = await anon.auth.getUser();
    if (userError || !user) throw new Error("Unauthorized");

    // 2. Validate requested tier.
    const { tier } = await req.json();
    if (tier !== "pro" && tier !== "max") throw new Error("Invalid tier");

    const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!);
    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // 3. Reuse or create the Stripe customer.
    const { data: subRow } = await admin
      .from("subscriptions")
      .select("stripe_customer_id")
      .eq("user_id", user.id)
      .maybeSingle();

    let customerId: string | null = subRow?.stripe_customer_id ?? null;
    if (!customerId) {
      const customer = await stripe.customers.create({
        email: user.email ?? undefined,
        metadata: { user_id: user.id },
      });
      customerId = customer.id;
      const { error: upsertError } = await admin
        .from("subscriptions")
        .upsert({ user_id: user.id, stripe_customer_id: customerId });
      if (upsertError) throw upsertError;
    }

    // 4. Create the Checkout Session.
    const priceId =
      tier === "pro"
        ? Deno.env.get("STRIPE_PRICE_PRO")
        : Deno.env.get("STRIPE_PRICE_MAX");
    if (!priceId) throw new Error("Price not configured");

    const session = await stripe.checkout.sessions.create({
      mode: "subscription",
      customer: customerId,
      line_items: [{ price: priceId, quantity: 1 }],
      success_url:
        Deno.env.get("CHECKOUT_SUCCESS_URL") ?? "https://gismat.app/success",
      cancel_url:
        Deno.env.get("CHECKOUT_CANCEL_URL") ?? "https://gismat.app/cancel",
      metadata: { user_id: user.id, tier },
      subscription_data: { metadata: { user_id: user.id, tier } },
    });

    return json({ url: session.url });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return json({ error: message }, 400);
  }
});
