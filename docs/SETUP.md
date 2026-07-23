# GISMAT — Setup & Operations

## Live infrastructure

| Piece | Value |
|---|---|
| Supabase project | `gismat` — ref `mkfvjvclsmgowalfscsc`, org `ramexar`, region `eu-central-1` |
| API URL | `https://mkfvjvclsmgowalfscsc.supabase.co` |
| Publishable key | `sb_publishable_wMRvGFlReNXKm8YHW7kxbw_0cqQwHa-` (safe to ship; baked as default in `lib/core/config/env.dart`) |
| Edge functions | `create-checkout-session`, `create-portal-session`, `stripe-webhook`, `send-push`, `delete-account` (all deployed) |
| GitHub | `ramiz7171/gismat` |

## Run the app

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # riverpod codegen
flutter run   # defaults point at the live Supabase project
```

Override backend/env at build time (never commit secrets):

```bash
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

## One-time manual steps (owner)

### 1. Stripe (reuse the existing account used by Gurbat)

1. In the Stripe dashboard create product **GISMAT Pro** with a recurring weekly price of **3 AZN**, and **GISMAT Max** at **5 AZN/week**. Copy both price IDs.
2. Add a webhook endpoint `https://mkfvjvclsmgowalfscsc.supabase.co/functions/v1/stripe-webhook` for events `checkout.session.completed`, `customer.subscription.updated`, `customer.subscription.deleted`; copy the signing secret.
3. Set Supabase function secrets:

```bash
npx supabase secrets set --project-ref mkfvjvclsmgowalfscsc \
  STRIPE_SECRET_KEY=sk_live_... \
  STRIPE_WEBHOOK_SECRET=whsec_... \
  STRIPE_PRICE_PRO=price_... \
  STRIPE_PRICE_MAX=price_... \
  CHECKOUT_SUCCESS_URL=https://<your-landing>/success \
  CHECKOUT_CANCEL_URL=https://<your-landing>/cancel \
  PORTAL_RETURN_URL=https://<your-landing>
```

### 2. Firebase / FCM (push)

1. Create a Firebase project (e.g. `gismat`), add an Android app `com.ramexar.gismat` and an iOS app; download `google-services.json` → `android/app/` and `GoogleService-Info.plist` → `ios/Runner/` (both are gitignored). Upload your APNs key in Firebase iOS settings.
2. In Google Cloud console create a service account with the **Firebase Cloud Messaging API** role and download its JSON key.
3. Set secrets and wire the DB webhook:

```bash
npx supabase secrets set --project-ref mkfvjvclsmgowalfscsc \
  FCM_SERVICE_ACCOUNT='<paste the service-account JSON>' \
  WEBHOOK_SECRET=<random long string>
```

4. Supabase Dashboard → Database → Webhooks → create webhook on `public.notifications`, event INSERT, type HTTP, URL `https://mkfvjvclsmgowalfscsc.supabase.co/functions/v1/send-push`, header `x-webhook-secret: <the same random string>`.

### 3. Admin account

Register in the app with **ramizzmammadov@gmail.com** — a DB trigger automatically grants `is_admin = true` and tier `max` (unlimited swipes, full moderation). No SQL needed.

### 4. Auth settings (Supabase Dashboard → Auth)

- Email provider is enabled by default. Optionally disable "Confirm email" for faster testing.
- Set Site URL / redirect URLs when you add a hosted landing page.

## CI

`.github/workflows/ci.yml` runs `flutter analyze` (zero-warning gate), `flutter test`, and an Android debug build on every push/PR.

## Migrations

`supabase/migrations/*.sql` are the source of truth and have all been applied to the live project (schema, RPCs, RLS, storage buckets + policies, realtime publication, conversations RPC). Apply future changes with `npx supabase db push` or the MCP `apply_migration` flow.
