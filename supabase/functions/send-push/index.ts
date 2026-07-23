// FCM push fan-out, invoked by a Supabase Database Webhook on INSERT into
// public.notifications. Guarded by a shared secret header (no JWT).
import { createClient } from "jsr:@supabase/supabase-js@2";
import { importPKCS8, SignJWT } from "npm:jose@5";

const admin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

/** OAuth2 JWT-bearer flow → short-lived FCM access token. */
async function getFcmAccessToken(sa: ServiceAccount): Promise<string> {
  const key = await importPKCS8(sa.private_key, "RS256");
  const now = Math.floor(Date.now() / 1000);
  const assertion = await new SignJWT({
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(sa.client_email)
    .setSubject(sa.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(key);

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!res.ok) throw new Error(`OAuth token exchange failed: ${res.status}`);
  const { access_token } = await res.json();
  if (!access_token) throw new Error("No access_token in OAuth response");
  return access_token as string;
}

Deno.serve(async (req) => {
  try {
    // 1. Shared-secret guard.
    const secret = Deno.env.get("WEBHOOK_SECRET");
    if (!secret || req.headers.get("x-webhook-secret") !== secret) {
      return json({ error: "Unauthorized" }, 401);
    }

    // 2. Parse the database-webhook payload.
    const payload = await req.json();
    if (payload?.type !== "INSERT" || !payload?.record) {
      return json({ skipped: true });
    }
    const record = payload.record as {
      recipient_id: string;
      type: string;
      title: string;
      body: string;
      data?: Record<string, unknown>;
    };

    // 3. Recipient's device tokens.
    const { data: devices, error: devError } = await admin
      .from("devices")
      .select("fcm_token")
      .eq("user_id", record.recipient_id);
    if (devError) throw devError;
    if (!devices || devices.length === 0) {
      return json({ sent: 0, removed: 0, failed: 0 });
    }

    // 4. FCM v1 access token via the service-account JWT flow.
    const sa = JSON.parse(
      Deno.env.get("FCM_SERVICE_ACCOUNT")!,
    ) as ServiceAccount;
    const accessToken = await getFcmAccessToken(sa);

    // 5. Data payload — FCM requires string values.
    const data: Record<string, string> = { type: String(record.type) };
    for (const [k, v] of Object.entries(record.data ?? {})) {
      data[k] = typeof v === "string" ? v : JSON.stringify(v);
    }

    // 6. Fan out; prune dead tokens.
    let sent = 0;
    let removed = 0;
    let failed = 0;
    for (const device of devices) {
      const res = await fetch(
        `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages/send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token: device.fcm_token,
              notification: { title: record.title, body: record.body },
              data,
            },
          }),
        },
      );
      if (res.ok) {
        sent++;
        continue;
      }
      const errText = await res.text();
      if (res.status === 404 || errText.includes("UNREGISTERED")) {
        await admin.from("devices").delete().eq("fcm_token", device.fcm_token);
        removed++;
      } else {
        failed++;
      }
    }

    return json({ sent, removed, failed });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return json({ error: message }, 400);
  }
});
