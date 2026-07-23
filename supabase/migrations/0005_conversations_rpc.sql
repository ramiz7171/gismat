-- Conversation summaries for the Matches/Chats list in a single call.
create or replace function public.my_conversations()
returns table (
  conversation_id uuid, match_id uuid, other_user_id uuid,
  other_first_name text, other_last_name text, other_verified boolean,
  other_last_seen timestamptz, other_photo_path text,
  last_message_kind text, last_message_content text, last_message_sender uuid,
  last_message_at timestamptz, my_last_read_at timestamptz, unread_count int
) language sql security definer stable set search_path = public as $$
  select c.id, c.match_id,
         case when m.user_a = auth.uid() then m.user_b else m.user_a end,
         p.first_name, p.last_name, p.is_verified, p.last_seen,
         (select ph.storage_path from public.photos ph
          where ph.user_id = p.id order by ph.position limit 1),
         lm.kind, lm.content, lm.sender_id,
         coalesce(lm.created_at, c.created_at),
         cp.last_read_at,
         (select count(*)::int from public.messages msg
          where msg.conversation_id = c.id
            and msg.sender_id <> auth.uid()
            and (cp.last_read_at is null or msg.created_at > cp.last_read_at))
  from public.conversations c
  join public.matches m on m.id = c.match_id
  join public.conversation_participants cp
    on cp.conversation_id = c.id and cp.user_id = auth.uid()
  join public.profiles p
    on p.id = case when m.user_a = auth.uid() then m.user_b else m.user_a end
  left join lateral (
    select * from public.messages
    where conversation_id = c.id
    order by created_at desc limit 1
  ) lm on true
  order by coalesce(lm.created_at, c.created_at) desc;
$$;
revoke all on function public.my_conversations() from public, anon;
grant execute on function public.my_conversations() to authenticated;

-- Mark a conversation read (also stamps last_seen for presence).
create or replace function public.mark_conversation_read(conv_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.conversation_participants
  set last_read_at = now()
  where conversation_id = conv_id and user_id = auth.uid();
  update public.profiles set last_seen = now() where id = auth.uid();
end; $$;
revoke all on function public.mark_conversation_read(uuid) from public, anon;
grant execute on function public.mark_conversation_read(uuid) to authenticated;
