-- Security hardening from Supabase advisor findings.

-- Trigger functions must not be exposed as PostgREST RPC endpoints.
revoke all on function public.enforce_photo_limit() from public, anon, authenticated;
revoke all on function public.guard_profile_columns() from public, anon, authenticated;
revoke all on function public.on_message_insert() from public, anon, authenticated;
revoke all on function public.on_profile_insert() from public, anon, authenticated;
revoke all on function public.touch_updated_at() from public, anon, authenticated;

-- Pin search_path on remaining functions.
alter function public.age_years(date) set search_path = public;
alter function public.touch_updated_at() set search_path = public;

-- Public bucket objects are reachable via their public URL; a broad SELECT
-- policy additionally allows LISTING every object — remove it.
drop policy if exists "profile photos public read" on storage.objects;

-- PostGIS system artifacts: best-effort lockdown (extension-owned; may be
-- non-alterable on managed Postgres — ignore failures).
do $$
begin
  begin
    revoke select on table public.spatial_ref_sys from anon, authenticated;
  exception when others then null;
  end;
  begin
    revoke all on function public.st_estimatedextent(text, text) from public, anon, authenticated;
    revoke all on function public.st_estimatedextent(text, text, text) from public, anon, authenticated;
    revoke all on function public.st_estimatedextent(text, text, text, boolean) from public, anon, authenticated;
  exception when others then null;
  end;
end $$;
