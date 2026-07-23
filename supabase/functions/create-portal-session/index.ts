// Creates a Stripe billing-portal session for the signed-in user.
// → { url: string }
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

    // 2. Look up the Stripe customer (service-role read).
    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    const { data: subRow } = await admin
      .from("subscriptions")
      .select("stripe_customer_id")
      .eq("user_id", user.id)
      .maybeSingle();
    const customerId: string | null = subRow?.stripe_customer_id ?? null;
    if (!customerId) throw new Error("No Stripe customer for this user");

    // 3. Create the portal session.
    const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!);
    const session = await stripe.billingPortal.sessions.create({
      customer: customerId,
      return_url: Deno.env.get("PORTAL_RETURN_URL") ?? "https://gismat.app",
    });

    return json({ url: session.url });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return json({ error: message }, 400);
  }
});
