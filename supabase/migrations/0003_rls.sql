-- GISMAT row-level security

alter table public.tier_limits enable row level security;
create policy "read tier limits" on public.tier_limits for select to authenticated using (true);

alter table public.profiles enable row level security;
create policy "read profiles" on public.profiles for select to authenticated using (true);
create policy "insert own profile" on public.profiles for insert to authenticated
  with check (id = (select auth.uid()));
create policy "update own profile" on public.profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));
-- privileged columns (tier/is_admin/is_verified/is_banned) are reverted by the
-- profiles_guard trigger for non-admin, non-service_role writers.
create policy "admin update profiles" on public.profiles for update to authenticated
  using ((select public.is_admin()));

alter table public.photos enable row level security;
create policy "read photos" on public.photos for select to authenticated using (true);
create policy "manage own photos" on public.photos for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "admin delete photos" on public.photos for delete to authenticated
  using ((select public.is_admin()));

alter table public.swipes enable row level security;
create policy "read own swipes" on public.swipes for select to authenticated
  using (swiper_id = (select auth.uid()));   -- writes via record_swipe RPC only

alter table public.pokes enable row level security;
create policy "see my pokes" on public.pokes for select to authenticated
  using ((select auth.uid()) in (poker_id, pokee_id));  -- writes via send_poke RPC only

alter table public.matches enable row level security;
create policy "see my matches" on public.matches for select to authenticated
  using ((select auth.uid()) in (user_a, user_b));

alter table public.conversations enable row level security;
create policy "see my conversations" on public.conversations for select to authenticated
  using (public.is_conversation_participant(id));

alter table public.conversation_participants enable row level security;
create policy "see participants of my conversations" on public.conversation_participants
  for select to authenticated using (public.is_conversation_participant(conversation_id));
create policy "update my read state" on public.conversation_participants
  for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

alter table public.messages enable row level security;
create policy "read my messages" on public.messages for select to authenticated
  using (public.is_conversation_participant(conversation_id));
create policy "send my messages" on public.messages for insert to authenticated
  with check (sender_id = (select auth.uid())
              and public.is_conversation_participant(conversation_id));
create policy "admin read messages" on public.messages for select to authenticated
  using ((select public.is_admin()));
create policy "admin delete messages" on public.messages for delete to authenticated
  using ((select public.is_admin()));

alter table public.reports enable row level security;
create policy "file report" on public.reports for insert to authenticated
  with check (reporter_id = (select auth.uid()));
create policy "read own reports" on public.reports for select to authenticated
  using (reporter_id = (select auth.uid()));
create policy "admin manage reports" on public.reports for all to authenticated
  using ((select public.is_admin()));

alter table public.blocks enable row level security;
create policy "manage blocks" on public.blocks for all to authenticated
  using (blocker_id = (select auth.uid())) with check (blocker_id = (select auth.uid()));

alter table public.devices enable row level security;
create policy "manage own devices" on public.devices for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

alter table public.notifications enable row level security;
create policy "read own notifications" on public.notifications for select to authenticated
  using (recipient_id = (select auth.uid()));
create policy "update own notifications" on public.notifications for update to authenticated
  using (recipient_id = (select auth.uid())) with check (recipient_id = (select auth.uid()));

alter table public.subscriptions enable row level security;
create policy "read own subscription" on public.subscriptions for select to authenticated
  using (user_id = (select auth.uid()));   -- writes: service_role (webhook) only
