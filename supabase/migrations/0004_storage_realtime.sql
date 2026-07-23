-- GISMAT storage buckets, storage RLS, realtime publication

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('profile-photos', 'profile-photos', true, 10485760,
   array['image/jpeg','image/png','image/webp','image/heic','image/heif']),
  ('chat-attachments', 'chat-attachments', false, 10485760,
   array['image/jpeg','image/png','image/webp','image/gif','application/pdf']),
  ('voice-messages', 'voice-messages', false, 10485760,
   array['audio/mp4','audio/m4a','audio/aac','audio/mpeg','audio/x-m4a'])
on conflict (id) do nothing;

-- profile-photos: public read, owner-folder write  (path: {user_id}/{uuid}.jpg)
create policy "profile photos public read" on storage.objects for select
  using (bucket_id = 'profile-photos');
create policy "profile photos owner insert" on storage.objects for insert to authenticated
  with check (bucket_id = 'profile-photos'
              and (storage.foldername(name))[1] = auth.uid()::text);
create policy "profile photos owner update" on storage.objects for update to authenticated
  using (bucket_id = 'profile-photos'
         and (storage.foldername(name))[1] = auth.uid()::text);
create policy "profile photos owner delete" on storage.objects for delete to authenticated
  using (bucket_id = 'profile-photos'
         and (storage.foldername(name))[1] = auth.uid()::text);

-- chat media: participant-scoped  (path: {conversation_id}/{uuid}.{ext})
create policy "chat media participant read" on storage.objects for select to authenticated
  using (bucket_id in ('chat-attachments','voice-messages')
         and public.is_conversation_participant(((storage.foldername(name))[1])::uuid));
create policy "chat media participant insert" on storage.objects for insert to authenticated
  with check (bucket_id in ('chat-attachments','voice-messages')
              and public.is_conversation_participant(((storage.foldername(name))[1])::uuid));

-- Realtime
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.notifications;
alter publication supabase_realtime add table public.conversation_participants;
alter publication supabase_realtime add table public.matches;
