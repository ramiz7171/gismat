// Stripe webhook — the ONLY writer of subscription tiers.
// No JWT (Stripe calls it); authenticity is proven by signature verification.
import { createClient } from "jsr:@supabase/supabase-js@2";
import Stripe from "npm:stripe@17";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!);
const admin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

const PRICE_PRO = Deno.env.get("STRIPE_PRICE_PRO");
const PRICE_MAX = Deno.env.get("STRIPE_PRICE_MAX");

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

function tierFromPrice(priceId: string | undefined): "pro" | "max" | "basic" {
  if (priceId && priceId === PRICE_PRO) return "pro";
  if (priceId && priceId === PRICE_MAX) return "max";
  return "basic";
}

function periodEndIso(sub: Stripe.Subscription): string | null {
  // current_period_end lives on the subscription in classic API versions and
  // on the items in 2025+ versions — handle both.
  // deno-lint-ignore no-explicit-any
  const raw: number | undefined = (sub as any).current_period_end ??
    // deno-lint-ignore no-explicit-any
    (sub.items?.data?.[0] as any)?.current_period_end;
  return raw ? new Date(raw * 1000).toISOString() : null;
}

async function applyState(
  userId: string,
  patch: Record<string, unknown>,
  tier: string,
) {
  const { error: subError } = await admin
    .from("subscriptions")
    .upsert({ user_id: userId, ...patch, updated_at: new Date().toISOString() });
  if (subError) throw subError;
  const { error: profError } = await admin
    .from("profiles")
    .update({ tier })
    .eq("id", userId);
  if (profError) throw profError;
}

async function userIdForSubscription(
  sub: Stripe.Subscription,
): Promise<string | null> {
  if (sub.metadata?.user_id) return sub.metadata.user_id;
  const customerId =
    typeof sub.customer === "string" ? sub.customer : sub.customer?.id;
  if (!customerId) return null;
  const { data } = await admin
    .from("subscriptions")
    .select("user_id")
    .eq("stripe_customer_id", customerId)
    .maybeSingle();
  return data?.user_id ?? null;
}

Deno.serve(async (req) => {
  // 1. Verify the Stripe signature against the raw body.
  const signature = req.headers.get("stripe-signature");
  const body = await req.text();
  let event: Stripe.Event;
  try {
    event = await stripe.webhooks.constructEventAsync(
      body,
      signature ?? "",
      Deno.env.get("STRIPE_WEBHOOK_SECRET")!,
    );
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return json({ error: `Invalid signature: ${message}` }, 400);
  }

  // 2. Handle the event; always answer 200 quickly so Stripe stops retrying.
  try {
    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object as Stripe.Checkout.Session;
        const userId = session.metadata?.user_id;
        const tier = session.metadata?.tier;
        if (!userId || (tier !== "pro" && tier !== "max")) break;

        const subscriptionId =
          typeof session.subscription === "string"
            ? session.subscription
            : session.subscription?.id ?? null;
        const customerId =
          typeof session.customer === "string"
            ? session.customer
            : session.customer?.id ?? null;

        let currentPeriodEnd: string | null = null;
        if (subscriptionId) {
          try {
            const sub = await stripe.subscriptions.retrieve(subscriptionId);
            currentPeriodEnd = periodEndIso(sub);
          } catch (_) {
            // best-effort; a later subscription.updated event will fill it in
          }
        }

        await applyState(
          userId,
          {
            stripe_customer_id: customerId,
            stripe_subscription_id: subscriptionId,
            tier,
            status: "active",
            current_period_end: currentPeriodEnd,
          },
          tier,
        );
        break;
      }

      case "customer.subscription.updated": {
        const sub = event.data.object as Stripe.Subscription;
        const userId = await userIdForSubscription(sub);
        if (!userId) break;

        const priceTier = tierFromPrice(sub.items?.data?.[0]?.price?.id);
        const status = sub.status;
        const isDead = ["canceled", "unpaid", "incomplete_expired"].includes(
          status,
        );
        const tier =
          status === "active" || status === "trialing"
            ? priceTier
            : isDead
              ? "basic"
              : priceTier;

        await applyState(
          userId,
          {
            stripe_subscription_id: sub.id,
            tier,
            status,
            current_period_end: periodEndIso(sub),
          },
          tier,
        );
        break;
      }

      case "customer.subscription.deleted": {
        const sub = event.data.object as Stripe.Subscription;
        const userId = await userIdForSubscription(sub);
        if (!userId) break;

        await applyState(
          userId,
          {
            tier: "basic",
            status: "canceled",
            current_period_end: periodEndIso(sub),
          },
          "basic",
        );
        break;
      }

      default:
        break; // unhandled event types are acknowledged
    }
  } catch (e) {
    // Log but still 200 — signature was valid; retries won't fix data errors.
    console.error("stripe-webhook handler error:", e);
  }

  return json({ received: true });
});
