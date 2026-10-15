-- Accounts: a profile, the saved trip records and the app settings for each
-- signed-in traveler. Every table is private to its owner through row level
-- security; nothing here is readable by the anon role.

-- Who the traveler is. One row per auth user, created by a trigger so a
-- profile always exists once someone signs up (any provider).
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text check (char_length(display_name) <= 80),
  -- 'visitor_in_thailand' (Part A) or 'thai_abroad' (Part B).
  traveler_type text check (traveler_type in ('visitor_in_thailand', 'thai_abroad')),
  -- ISO 4217 codes: the currency the traveler thinks in, and the one their
  -- card is billed in.
  home_currency text check (home_currency ~ '^[A-Z]{3}$'),
  card_currency text check (card_currency ~ '^[A-Z]{3}$'),
  language text check (language in ('en', 'th')),
  -- Set when the first-run questions were answered.
  onboarded_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_complete_when_onboarded check (
    onboarded_at is null or (
      traveler_type is not null and home_currency is not null
      and card_currency is not null and language is not null
    )
  )
);

-- Results the traveler saved, one row per TripSave (lib/rules/trip_ledger.dart).
-- client_id is the id the app gave the save, so a retry never duplicates it.
create table public.trip_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  client_id text not null check (char_length(client_id) between 1 and 64),
  -- SaveKind name, e.g. 'atmConversion', 'haggle'. Kept open for new kinds.
  kind text not null check (kind ~ '^[a-zA-Z]{1,40}$'),
  kept_thb numeric(12, 2) not null check (kept_thb >= 0),
  saved_at timestamptz not null,
  item_key text check (char_length(item_key) <= 64),
  asked_thb numeric(12, 2) check (asked_thb >= 0),
  paid_thb numeric(12, 2) check (paid_thb >= 0),
  -- The verdict the save came from, in the app's own JSON shape, so a record
  -- can be shown again with its numbers and sources.
  detail jsonb not null default '{}'::jsonb check (jsonb_typeof(detail) = 'object'),
  created_at timestamptz not null default now(),
  unique (user_id, client_id)
);

create index trip_records_user_saved_at on public.trip_records (user_id, saved_at desc);

-- App preferences that are not part of the profile.
create table public.settings (
  user_id uuid primary key default auth.uid() references auth.users (id) on delete cascade,
  -- How a spoken Thai request ends (PoliteEnding in settings_store.dart).
  polite_ending text not null default 'male' check (polite_ending in ('male', 'female', 'none')),
  updated_at timestamptz not null default now()
);

-- Keep updated_at honest without trusting the client.
create function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger profiles_touch before update on public.profiles
  for each row execute function public.touch_updated_at();
create trigger settings_touch before update on public.settings
  for each row execute function public.touch_updated_at();

-- A new auth user gets an empty profile and default settings. The display
-- name comes from the provider when it gives one (Google 'full_name' or
-- 'name'; Apple only on the first sign-in, sent by the app as 'full_name').
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    left(nullif(trim(coalesce(
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'name',
      ''
    )), ''), 80)
  )
  on conflict (id) do nothing;
  insert into public.settings (user_id) values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- Row level security: each traveler sees and changes only their own rows.
alter table public.profiles enable row level security;
alter table public.trip_records enable row level security;
alter table public.settings enable row level security;

create policy "Own profile: read" on public.profiles
  for select to authenticated using ((select auth.uid()) = id);
create policy "Own profile: create" on public.profiles
  for insert to authenticated with check ((select auth.uid()) = id);
create policy "Own profile: change" on public.profiles
  for update to authenticated
  using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

create policy "Own records: read" on public.trip_records
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "Own records: add" on public.trip_records
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "Own records: change" on public.trip_records
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "Own records: remove" on public.trip_records
  for delete to authenticated using ((select auth.uid()) = user_id);

create policy "Own settings: read" on public.settings
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "Own settings: create" on public.settings
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "Own settings: change" on public.settings
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

-- The anon role never touches account data, even if a policy is added later
-- by mistake. Trigger functions are not callable through the API.
revoke all on public.profiles, public.trip_records, public.settings from anon;
revoke execute on function public.handle_new_user() from anon, authenticated, public;
revoke execute on function public.touch_updated_at() from anon, authenticated, public;

-- App Store guideline 5.1.1(v): an app that lets people create an account
-- must let them delete it. Deleting the auth user cascades to every row above.
create function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  me uuid := auth.uid();
begin
  if me is null then
    raise exception 'not signed in' using errcode = '42501';
  end if;
  delete from auth.users where id = me;
end;
$$;

revoke execute on function public.delete_my_account() from anon, public;
grant execute on function public.delete_my_account() to authenticated;
