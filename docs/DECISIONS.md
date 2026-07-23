# GISMAT — Architecture & Product Decisions

## Backend

- **Supabase project**: `gismat` (`mkfvjvclsmgowalfscsc`) in the `ramexar` org, region `eu-central-1` (closest to the Azerbaijani market). PostGIS + pgcrypto enabled.
- **`tier_limits` created before `profiles`** — the spec's order breaks the FK; migrations fix ordering.
- **Recursion-safe `is_admin()`**: the spec's admin RLS policy selected from `profiles` inside a `profiles` policy, which recurses. A `SECURITY DEFINER public.is_admin()` helper breaks the cycle (same pattern as `is_conversation_participant`).
- **Privileged columns guarded by trigger, not policy**: Postgres RLS has no column-level policies, so a `BEFORE UPDATE` trigger reverts client changes to `tier`, `is_admin`, `is_verified`, `is_banned` unless the writer is service_role or an admin. A `BEFORE INSERT` trigger force-resets privileges on new rows and auto-grants admin + max tier to `ramizzmammadov@gmail.com` (self-seeding — no manual step after registration).
- **`matches` normalized as `user_a < user_b`** instead of a `least/greatest` expression index — makes `ON CONFLICT` trivial and the pair-uniqueness obvious.
- **`photos` position uniqueness is `DEFERRABLE INITIALLY DEFERRED`** so drag-reorder can renumber rows without transient conflicts (client still uses a two-phase renumber as belt-and-braces).
- **All swipe/poke writes via SECURITY DEFINER RPCs** (`record_swipe`, `send_poke`, `rewind_last_swipe`); tables have **no client INSERT policies**. Daily quota therefore cannot be bypassed. Error codes: `P0001` swipe limit, `P0002` photo limit, `P0003` premium required — mapped to typed `AppException`s client-side.
- **Distance privacy**: `nearby_profiles` rounds distance to 100 m server-side; the client buckets further for display (≥0.1 km). Exact coordinates and timestamps are never exposed (Happn's privacy rule).
- **18+ enforced three times**: DB check constraint on `date_of_birth`, `Validators.isAdult` client-side, and the date picker's initial range.
- **`my_conversations` RPC** returns the whole chat list (other profile, last message, unread count) in one round-trip instead of N+1 client joins.
- **Storage**: `profile-photos` public (profile photos are public product surface), `chat-attachments` + `voice-messages` private with participant-scoped RLS and 1-hour signed URLs. 10 MB caps + MIME allowlists.

## Flutter

- **Swipe deck: `swipable_stack` 2.0** (controller + rewind + overlay builder + `SwipeAnchor.bottom` for the natural bottom-pivot rotation the Tinder deck uses). Thresholds: 38% horizontal, 32% vertical; API verified against package source. A custom deck was not needed — the package exposes exactly the spring/overlay/rewind hooks the spec requires.
- **Poke accent = coral `#FF6F61`** — a complementary hue that pops against the cyan family; cyan variants would have drowned the Poke CTA.
- **Motion: `flutter_animate` + custom painters only** (staggered entrances, pulse heroes, hand-rolled confetti painter for "It's a Match"). No Lottie/Rive runtime or downloaded assets: zero licensing risk, zero asset-loading failure modes, smaller binary — while still meeting the "animated Sign-In / celebration" bar. All motion respects `MediaQuery.disableAnimations`.
- **Riverpod codegen** (`@riverpod`) throughout; `Ref` imported explicitly from `flutter_riverpod` (the resolved `riverpod_annotation` 2.6.x doesn't export it).
- **Auth gate**: single `AuthGate` provider (`unauthenticated | needsOnboarding | ready`) drives all go_router redirects; `needsOnboarding` = no profile row OR fewer than 3 photos, so users can't skip photo minimums even by killing the app mid-onboarding.
- **Offline resilience**: last discovery batch cached in `shared_preferences` and served when the RPC fails; realtime streams are Supabase-managed with automatic reconnect.
- **Optimistic chat sends** with pending/failed states and tap-to-retry; ordering comes from the server stream (newest-first, reversed ListView — keyboard-safe by construction with `resizeToAvoidBottomInset` + pinned input bar).
- **Presence/typing**: per-conversation realtime channel (`room:{id}`) with presence tracking + typing broadcasts; "online" additionally falls back to `last_seen < 2 min`.
- **Voice messages**: `record` (AAC/m4a) + `just_audio` playback with progress bar. `audio_waveforms` was skipped — a progress bar meets the UX bar without an extra platform plugin; clean seam to add waveforms later.
- **Explicit-image blur**: client-side blur-until-tap driven by `messages.flagged` + a user setting (Bumble Private-Detector seam; flagging is manual/admin in v1, automated detection can set `flagged` later without schema changes).
- **Photo verification**: selfie upload → `verification_status='pending'` → admin approves in the Admin panel. Architected so an automated face-match service can replace the manual step (same status field).
- **Push**: FCM v1 via `send-push` edge function called by a Database Webhook on `notifications` INSERT (shared-secret header). The Flutter side is fully guarded — without Firebase config files the app runs normally (web/CI/dev). Push-tap deep-linking is handled via the in-app Notifications center (which deep-links to chat/pokes); tray taps open the app.
- **Stripe**: Checkout via edge function (spec's recommended option) — no native SDK, reuses the existing Stripe account, works with the Gurbat-style webhook pattern. Webhook is the *only* writer of `subscriptions`/`profiles.tier`. Prices: Pro 3 AZN/week, Max 5 AZN/week, no trial, no refunds (stated on paywall + Terms).
- **i18n**: 4 ARB files (AZ primary market, EN fallback, RU, TR), ~150 keys each, runtime switch persisted; legal pages are canonical English (single authoritative legal text) — noted in Terms.
- **Fonts**: Inter static TTFs (400/500/600/700) bundled from the official rsms/inter 4.1 release (OFL license included); `google_fonts` remains a dependency for parity/fallback.

## Known follow-ups (documented, not blockers)

- Firebase config files (`google-services.json`, `GoogleService-Info.plist`) must be added per docs/SETUP.md before push works on devices.
- Stripe secrets + price IDs must be set as Supabase secrets (SETUP.md) — the functions are deployed and fail closed until then.
- Bumble's "Deception Detector™"-style automated fraud blocking (95% auto-block, −45% reported spam per Bumble Inc., Feb 2024) is future work; v1 ships manual report + admin moderation with a clean seam (`reports` queue, `is_banned`).
