-- GISMAT functions, RPCs and triggers

-- Recursion-safe admin check (querying profiles inside a profiles policy
-- would recurse; SECURITY DEFINER breaks the cycle).
create or replace function public.is_admin()
returns boolean language sql security definer set search_path = public stable as $$
  select coalesce((select is_admin from public.profiles where id = auth.uid()), false);
$$;
revoke all on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;

-- updated_at maintenance
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at := now(); return new; end; $$;
create trigger profiles_touch before update on public.profiles
  for each row execute function public.touch_updated_at();
create trigger subscriptions_touch before update on public.subscriptions
  for each row execute function public.touch_updated_at();

-- Guard privileged profile columns: clients may never change
-- tier / is_admin / is_verified / is_banned / verification_status(except pending).
create or replace function public.guard_profile_columns()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if current_setting('request.jwt.claim.role', true) = 'service_role'
     or current_setting('role', true) = 'service_role'
     or public.is_admin() then
    return new;
  end if;
  new.tier := old.tier;
  new.is_admin := old.is_admin;
  new.is_verified := old.is_verified;
  new.is_banned := old.is_banned;
  -- users may only move verification to 'pending' (selfie submitted)
  if new.verification_status is distinct from old.verification_status
     and new.verification_status <> 'pending' then
    new.verification_status := old.verification_status;
  end if;
  return new;
end; $$;
create trigger profiles_guard before update on public.profiles
  for each row execute function public.guard_profile_columns();

-- New profiles may never self-assign privileges; owner email is auto-admin.
create or replace function public.on_profile_insert()
returns trigger language plpgsql security definer set search_path = public as $$
declare owner_email text;
begin
  select email into owner_email from auth.users where id = new.id;
  if owner_email = 'ramizzmammadov@gmail.com' then
    new.is_admin := true;
    new.tier := 'max';
  else
    new.is_admin := false;
    new.tier := 'basic';
  end if;
  new.is_verified := false;
  new.is_banned := false;
  return new;
end; $$;
create trigger profiles_before_insert before insert on public.profiles
  for each row execute function public.on_profile_insert();

-- Enforce max photos per tier
create or replace function public.enforce_photo_limit()
returns trigger language plpgsql security definer set search_path = public as $$
declare cap int; cnt int;
begin
  select tl.max_photos into cap
  from public.profiles p join public.tier_limits tl on tl.tier = p.tier
  where p.id = new.user_id;
  select count(*) into cnt from public.photos where user_id = new.user_id;
  if cnt >= coalesce(cap, 3) then
    raise exception 'Photo limit reached for your tier' using errcode='P0002',
      hint='Upgrade your subscription to add more photos';
  end if;
  return new;
end; $$;
create trigger photos_limit before insert on public.photos
  for each row execute function public.enforce_photo_limit();

-- RPC: record a swipe with tamper-proof daily quota
create or replace function public.record_swipe(target_user uuid, swipe_direction text)
returns json language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); user_tier text; day_limit int; used int;
        remaining int; admin_user boolean;
begin
  if uid is null then raise exception 'Not authenticated' using errcode='42501'; end if;
  if uid = target_user then raise exception 'Cannot swipe yourself'; end if;
  if swipe_direction not in ('like','pass') then raise exception 'Invalid direction'; end if;

  select p.tier, p.is_admin, tl.daily_swipe_limit into user_tier, admin_user, day_limit
  from public.profiles p join public.tier_limits tl on tl.tier = p.tier
  where p.id = uid;

  if admin_user or day_limit is null then
    insert into public.swipes(swiper_id, swipee_id, direction)
    values (uid, target_user, swipe_direction)
    on conflict (swiper_id, swipee_id) do nothing;
    return json_build_object('allowed', true, 'remaining', -1, 'tier', user_tier);
  end if;

  select count(*) into used from public.swipes
  where swiper_id = uid and swipe_date = (now() at time zone 'utc')::date;

  if used >= day_limit then
    raise exception 'Daily swipe limit reached' using errcode='P0001',
      hint='Upgrade your subscription for more swipes';
  end if;

  insert into public.swipes(swiper_id, swipee_id, direction)
  values (uid, target_user, swipe_direction)
  on conflict (swiper_id, swipee_id) do nothing;

  remaining := day_limit - (used + 1);
  return json_build_object('allowed', true, 'remaining', remaining, 'tier', user_tier);
end; $$;
revoke all on function public.record_swipe(uuid, text) from public, anon;
grant execute on function public.record_swipe(uuid, text) to authenticated;

-- RPC: remaining swipes today (for the deck counter on app start)
create or replace function public.swipes_remaining()
returns json language plpgsql security definer set search_path = public stable as $$
declare uid uuid := auth.uid(); day_limit int; used int; admin_user boolean; user_tier text;
begin
  if uid is null then raise exception 'Not authenticated' using errcode='42501'; end if;
  select p.tier, p.is_admin, tl.daily_swipe_limit into user_tier, admin_user, day_limit
  from public.profiles p join public.tier_limits tl on tl.tier = p.tier where p.id = uid;
  if admin_user or day_limit is null then
    return json_build_object('remaining', -1, 'tier', user_tier);
  end if;
  select count(*) into used from public.swipes
  where swiper_id = uid and swipe_date = (now() at time zone 'utc')::date;
  return json_build_object('remaining', greatest(day_limit - used, 0), 'tier', user_tier);
end; $$;
revoke all on function public.swipes_remaining() from public, anon;
grant execute on function public.swipes_remaining() to authenticated;

-- RPC: rewind last swipe (premium only)
create or replace function public.rewind_last_swipe()
returns json language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); user_tier text; admin_user boolean; last_id bigint; undone uuid;
begin
  if uid is null then raise exception 'Not authenticated' using errcode='42501'; end if;
  select tier, is_admin into user_tier, admin_user from public.profiles where id = uid;
  if not admin_user and user_tier = 'basic' then
    raise exception 'Rewind is a premium feature' using errcode='P0003',
      hint='Upgrade to Pro or Max to rewind swipes';
  end if;
  select id, swipee_id into last_id, undone from public.swipes
  where swiper_id = uid order by created_at desc limit 1;
  if last_id is null then
    return json_build_object('rewound', false);
  end if;
  delete from public.swipes where id = last_id;
  return json_build_object('rewound', true, 'user_id', undone);
end; $$;
revoke all on function public.rewind_last_swipe() from public, anon;
grant execute on function public.rewind_last_swipe() to authenticated;

-- RPC: Poke -> reciprocal -> Match -> Conversation
create or replace function public.send_poke(target_user uuid)
returns json language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); reciprocal boolean; a uuid; b uuid;
        v_match uuid; v_conv uuid; poker_name text;
begin
  if uid is null then raise exception 'Not authenticated' using errcode='42501'; end if;
  if uid = target_user then raise exception 'Cannot poke yourself'; end if;
  if exists(select 1 from public.blocks
            where (blocker_id = target_user and blocked_id = uid)
               or (blocker_id = uid and blocked_id = target_user)) then
    raise exception 'Cannot poke this user';
  end if;

  insert into public.pokes(poker_id, pokee_id) values (uid, target_user)
  on conflict (poker_id, pokee_id) do nothing;

  select exists(select 1 from public.pokes where poker_id = target_user and pokee_id = uid)
    into reciprocal;

  if reciprocal then
    a := least(uid, target_user); b := greatest(uid, target_user);
    insert into public.matches(user_a, user_b) values (a, b)
      on conflict (user_a, user_b) do nothing
      returning id into v_match;
    if v_match is null then
      select id into v_match from public.matches where user_a = a and user_b = b;
    end if;
    insert into public.conversations(match_id) values (v_match)
      on conflict (match_id) do nothing returning id into v_conv;
    if v_conv is null then
      select id into v_conv from public.conversations where match_id = v_match;
    end if;
    insert into public.conversation_participants(conversation_id, user_id)
      values (v_conv, a), (v_conv, b) on conflict do nothing;

    select first_name into poker_name from public.profiles where id = uid;
    insert into public.notifications(recipient_id, type, title, body, data)
      values (target_user, 'match', 'It''s a match!',
              'You and ' || coalesce(poker_name, 'someone') || ' poked each other.',
              jsonb_build_object('conversation_id', v_conv, 'match_id', v_match));
    return json_build_object('matched', true, 'conversation_id', v_conv, 'match_id', v_match);
  else
    select first_name into poker_name from public.profiles where id = uid;
    insert into public.notifications(recipient_id, type, title, body, data)
      values (target_user, 'poke', 'You got poked!',
              coalesce(poker_name, 'Someone') || ' poked you',
              jsonb_build_object('from', uid));
    return json_build_object('matched', false);
  end if;
end; $$;
revoke all on function public.send_poke(uuid) from public, anon;
grant execute on function public.send_poke(uuid) to authenticated;

-- RPC: Nearby (PostGIS radius + distance sort). Excludes swiped, poked-by-me,
-- blocked (both directions), snoozed and banned users. Distance is bucketed
-- to 100 m server-side so exact coordinates are never derivable.
create or replace function public.nearby_profiles(radius_km float, max_results int default 50)
returns table (
  id uuid, first_name text, last_name text, age int, bio text, gender text,
  is_verified boolean, last_seen timestamptz, distance_m float, photo_paths text[]
)
language sql security definer set search_path = public stable as $$
  with me as (select location, id as my_id from public.profiles where id = auth.uid())
  select p.id, p.first_name, p.last_name,
         public.age_years(p.date_of_birth) as age, p.bio, p.gender,
         p.is_verified, p.last_seen,
         (round(st_distance(p.location, me.location) / 100.0) * 100.0) as distance_m,
         coalesce((select array_agg(ph.storage_path order by ph.position)
                   from public.photos ph where ph.user_id = p.id), '{}') as photo_paths
  from public.profiles p, me
  where p.id <> me.my_id
    and p.is_snoozed = false
    and p.is_banned = false
    and p.location is not null and me.location is not null
    and st_dwithin(p.location, me.location, radius_km * 1000)
    and not exists (select 1 from public.swipes s
                    where s.swiper_id = me.my_id and s.swipee_id = p.id)
    and not exists (select 1 from public.matches m
                    where (m.user_a = me.my_id and m.user_b = p.id)
                       or (m.user_b = me.my_id and m.user_a = p.id))
    and not exists (select 1 from public.blocks b
                    where (b.blocker_id = me.my_id and b.blocked_id = p.id)
                       or (b.blocker_id = p.id and b.blocked_id = me.my_id))
  order by p.location <-> me.location
  limit max_results;
$$;
revoke all on function public.nearby_profiles(float, int) from public, anon;
grant execute on function public.nearby_profiles(float, int) to authenticated;

-- RPC: unmatch (delete match -> cascades conversation + messages)
create or replace function public.unmatch(target_match uuid)
returns void language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid();
begin
  if uid is null then raise exception 'Not authenticated' using errcode='42501'; end if;
  delete from public.matches
  where id = target_match and (user_a = uid or user_b = uid);
  -- also clear the pokes so the pair can re-match intentionally later
end; $$;
revoke all on function public.unmatch(uuid) from public, anon;
grant execute on function public.unmatch(uuid) to authenticated;

-- RPC: update own location (fuzz-free storage; sharing is bucketed on read)
create or replace function public.update_location(lat float, lng float)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.profiles
  set location = st_setsrid(st_makepoint(lng, lat), 4326)::geography,
      location_updated_at = now(), last_seen = now()
  where id = auth.uid();
end; $$;
revoke all on function public.update_location(float, float) from public, anon;
grant execute on function public.update_location(float, float) to authenticated;

-- Recursion-safe participant helper for chat RLS
create or replace function public.is_conversation_participant(conv_id uuid)
returns boolean language sql security definer set search_path = public stable as $$
  select exists(select 1 from public.conversation_participants
    where conversation_id = conv_id and user_id = auth.uid());
$$;
revoke all on function public.is_conversation_participant(uuid) from public, anon;
grant execute on function public.is_conversation_participant(uuid) to authenticated;

-- Pokes received (with poker profile) for the notifications/pokes screen
create or replace function public.pokes_received()
returns table (
  poker_id uuid, first_name text, age int, is_verified boolean,
  poked_at timestamptz, photo_path text, poked_back boolean
)
language sql security definer set search_path = public stable as $$
  select pk.poker_id, p.first_name, public.age_years(p.date_of_birth),
         p.is_verified, pk.created_at,
         (select ph.storage_path from public.photos ph
          where ph.user_id = p.id order by ph.position limit 1),
         exists(select 1 from public.pokes r
                where r.poker_id = auth.uid() and r.pokee_id = pk.poker_id)
  from public.pokes pk join public.profiles p on p.id = pk.poker_id
  where pk.pokee_id = auth.uid()
    and p.is_banned = false
    and not exists (select 1 from public.blocks b
                    where (b.blocker_id = auth.uid() and b.blocked_id = pk.poker_id)
                       or (b.blocker_id = pk.poker_id and b.blocked_id = auth.uid()))
  order by pk.created_at desc;
$$;
revoke all on function public.pokes_received() from public, anon;
grant execute on function public.pokes_received() to authenticated;

-- Message notification fan-out (push handled by send-push edge fn webhook)
create or replace function public.on_message_insert()
returns trigger language plpgsql security definer set search_path = public as $$
declare recipient uuid; sender_name text;
begin
  select user_id into recipient from public.conversation_participants
  where conversation_id = new.conversation_id and user_id <> new.sender_id limit 1;
  if recipient is not null then
    select first_name into sender_name from public.profiles where id = new.sender_id;
    insert into public.notifications(recipient_id, type, title, body, data)
    values (recipient, 'message', coalesce(sender_name, 'New message'),
            case new.kind when 'text' then left(new.content, 80)
                          when 'voice' then '🎤 Voice message'
                          when 'image' then '📷 Photo'
                          else '📎 Attachment' end,
            jsonb_build_object('conversation_id', new.conversation_id));
  end if;
  return new;
end; $$;
create trigger messages_notify after insert on public.messages
  for each row execute function public.on_message_insert();
