-- GISMAT schema: extensions, tables, indexes
create extension if not exists postgis;
create extension if not exists pgcrypto;

-- TIER LIMITS (data-driven; never hardcode limits in app)
create table public.tier_limits (
  tier text primary key,            -- 'basic','pro','max'
  daily_swipe_limit int,            -- NULL = unlimited
  max_photos int not null
);
insert into public.tier_limits (tier, daily_swipe_limit, max_photos) values
  ('basic', 8, 3),
  ('pro',   30, 10),
  ('max',   null, 10);

-- PROFILES (1:1 with auth.users)
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  first_name text not null,
  last_name  text not null,
  date_of_birth date not null check (date_of_birth <= (now() - interval '18 years')::date),
  gender text check (gender in ('male','female','other')),
  interested_in text[] default '{}',
  bio text,
  tier text not null default 'basic' references public.tier_limits(tier),
  is_admin boolean not null default false,
  is_verified boolean not null default false,
  is_snoozed boolean not null default false,
  is_banned boolean not null default false,
  verification_status text not null default 'none'
    check (verification_status in ('none','pending','approved','rejected')),
  verification_photo_path text,
  last_seen timestamptz,
  location geography(Point,4326),        -- PostGIS point (lng,lat)
  location_updated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index profiles_location_gix on public.profiles using gist (location);

-- Derived age (never store age)
create or replace function public.age_years(dob date) returns int
language sql immutable as $$ select extract(year from age(dob))::int $$;

-- PHOTOS (min 3 enforced in app flow, max per tier enforced by trigger)
create table public.photos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null,       -- profile-photos/{user_id}/{uuid}.jpg
  position int not null default 0,  -- ordering; 0 = primary
  created_at timestamptz not null default now(),
  constraint photos_user_position_uniq unique (user_id, position)
    deferrable initially deferred
);
create index photos_user_idx on public.photos (user_id, position);

-- SWIPES (log; powers daily quota + prevents re-showing)
create table public.swipes (
  id bigint generated always as identity primary key,
  swiper_id uuid not null references auth.users(id) on delete cascade,
  swipee_id uuid not null references auth.users(id) on delete cascade,
  direction text not null check (direction in ('like','pass')),
  created_at timestamptz not null default now(),
  swipe_date date not null default (now() at time zone 'utc')::date,
  check (swiper_id <> swipee_id)
);
create unique index swipes_unique_pair on public.swipes (swiper_id, swipee_id);
create index swipes_daily_idx on public.swipes (swiper_id, swipe_date);

-- POKES (directional; mutual-consent match mechanic)
create table public.pokes (
  id bigint generated always as identity primary key,
  poker_id uuid not null references auth.users(id) on delete cascade,
  pokee_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (poker_id, pokee_id),
  check (poker_id <> pokee_id)
);

-- MATCHES (one row per pair; order-independent uniqueness)
create table public.matches (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references auth.users(id) on delete cascade,
  user_b uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  check (user_a <> user_b),
  check (user_a < user_b)  -- normalized ordering makes uniqueness trivial
);
create unique index matches_unique_pair on public.matches (user_a, user_b);

-- CONVERSATIONS (1 per match)
create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null unique references public.matches(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table public.conversation_participants (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  last_read_at timestamptz,
  primary key (conversation_id, user_id)
);

-- MESSAGES (text/emoji/voice/attachment)
create table public.messages (
  id bigint generated always as identity primary key,
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  kind text not null default 'text' check (kind in ('text','voice','image','file')),
  content text,                      -- text body OR storage path for media
  duration_ms int,                   -- for voice
  flagged boolean not null default false,  -- explicit-content blur seam
  created_at timestamptz not null default now(),
  read_at timestamptz,
  check (content is not null and length(content) > 0)
);
create index messages_conv_idx on public.messages (conversation_id, created_at);

-- REPORTS & BLOCKS
create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  reported_id uuid not null references auth.users(id) on delete cascade,
  reason text not null,
  details text,
  status text not null default 'open' check (status in ('open','reviewed','actioned','dismissed')),
  created_at timestamptz not null default now()
);
create table public.blocks (
  blocker_id uuid not null references auth.users(id) on delete cascade,
  blocked_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id)
);

-- DEVICES (FCM tokens) & NOTIFICATIONS (push fan-out via edge function webhook)
create table public.devices (
  user_id uuid not null references auth.users(id) on delete cascade,
  fcm_token text not null,
  platform text,
  updated_at timestamptz not null default now(),
  primary key (user_id, fcm_token)
);
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references auth.users(id) on delete cascade,
  type text not null check (type in ('poke','match','message','system')),
  title text not null,
  body text not null,
  data jsonb default '{}',
  read boolean not null default false,
  created_at timestamptz not null default now()
);
create index notifications_recipient_idx on public.notifications (recipient_id, created_at desc);

-- SUBSCRIPTIONS (synced from Stripe webhook; service_role only writes)
create table public.subscriptions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  stripe_customer_id text,
  stripe_subscription_id text,
  tier text not null default 'basic' references public.tier_limits(tier),
  status text not null default 'inactive',
  current_period_end timestamptz,
  updated_at timestamptz not null default now()
);
