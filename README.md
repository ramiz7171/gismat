# GISMAT 💙

Modern, minimalist, cyan-themed dating app for Android & iOS — built with **Flutter + Supabase + Stripe**.

**Meet people near you.** Swipe the deck, **Poke (Dürtmə)** someone you like — if they poke back, it's a match and a chat opens instantly.

## Features

- 🃏 Tinder-style swipe deck with spring physics, LIKE/NOPE/POKE overlays, premium rewind
- 👋 Poke → reciprocal poke → match → chat, with haptics + push notifications
- 📍 Nearby with adjustable radius (2 km default), PostGIS-backed, privacy-safe bucketed distances
- 💬 Realtime chat: text, emoji, voice messages, image/file attachments, typing indicators, read receipts, online/last-seen
- 🛡️ Safety: photo verification, report/block/unmatch, snooze, explicit-image blur, Safety Center
- 💳 Subscriptions via Stripe Checkout: Basic (free, 8 swipes/day, 3 photos) · Pro (3 AZN/week, 30/day, 10 photos) · Max (5 AZN/week, unlimited, 10 photos) — limits enforced server-side, no trial, no refunds
- 🌍 4 languages: Azərbaycanca (primary), English, Русский, Türkçe — runtime switch
- 🛠️ Built-in admin panel (users, reports, verifications, stats)
- ♿ WCAG-informed accessibility: 44pt targets, semantics, dynamic type, reduce-motion support

## Stack

Flutter 3.32 / Dart 3.8 · Riverpod (codegen) · go_router · supabase_flutter (Postgres + RLS + Realtime + Storage + Edge Functions) · Stripe · FCM · Inter font.

## Getting started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

See [docs/SETUP.md](docs/SETUP.md) for infrastructure/secrets and [docs/DECISIONS.md](docs/DECISIONS.md) for architecture decisions.

## Quality gates

```bash
flutter analyze   # zero warnings
flutter test      # unit + widget tests
```

Both run in CI on every push.
