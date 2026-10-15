-- What the assistant may remember about a traveler: card and ATM fee facts
-- on the profile, where and how each saved result happened, and every round
-- of a haggle. All of it is private to its owner (row level security), and
-- the AI reads it only on that owner's behalf.

-- Fee facts the traveler states about their own card. Never a card number.
alter table public.profiles
  -- Foreign transaction fee the card charges, in percent (e.g. 2.5).
  add column card_fee_percent numeric(5, 2)
    check (card_fee_percent >= 0 and card_fee_percent <= 20),
  -- What the home bank does about ATM fees abroad.
  add column atm_fee_policy text
    check (atm_fee_policy in ('charges_fixed', 'charges_percent', 'refunds_fees', 'no_fee', 'unknown')),
  -- The fixed amount (home currency) or percent that goes with the policy.
  add column atm_fee_value numeric(10, 2) check (atm_fee_value >= 0);

-- Where and how a saved result happened. Asked and paid prices, the item
-- and the time (saved_at) are already columns.
alter table public.trip_records
  add column place_name text check (char_length(place_name) <= 120),
  add column place_lat double precision check (place_lat between -90 and 90),
  add column place_lng double precision check (place_lng between -180 and 180),
  -- The verdict's own word, e.g. 'high', 'fair', 'payLocal', 'declineConversion'.
  add column verdict text check (verdict ~ '^[a-zA-Z_]{1,40}$'),
  -- Which engines produced the result, e.g. 'mlkit_ocr' or
  -- 'speech_to_text+item_matcher+places'.
  add column ai_path text check (char_length(ai_path) <= 120),
  -- Seed rows are marked so they are never mistaken for real use.
  add column is_sample boolean not null default false,
  add constraint trip_records_place_pair check ((place_lat is null) = (place_lng is null));

-- One exchange in a haggle: what the seller said, what we suggested, and
-- how it ended. A haggle can be logged before (or without) a saved result.
create table public.haggle_rounds (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  -- The saved result this haggle led to, when there is one.
  record_id uuid references public.trip_records (id) on delete cascade,
  -- Groups the rounds of one haggle (the app's id for it).
  haggle_id text not null check (char_length(haggle_id) between 1 and 64),
  round_no smallint not null check (round_no between 1 and 50),
  item_key text check (char_length(item_key) <= 64),
  -- Recognised speech, text only (no audio is kept).
  seller_said text check (char_length(seller_said) <= 500),
  seller_price_thb numeric(12, 2) check (seller_price_thb >= 0),
  our_offer_thb numeric(12, 2) check (our_offer_thb >= 0),
  our_sentence text check (char_length(our_sentence) <= 500),
  outcome text check (outcome in ('countered', 'accepted', 'declined', 'walked_away')),
  is_sample boolean not null default false,
  created_at timestamptz not null default now(),
  unique (user_id, haggle_id, round_no)
);

create index haggle_rounds_user_created on public.haggle_rounds (user_id, created_at desc);
create index haggle_rounds_record on public.haggle_rounds (record_id);

alter table public.haggle_rounds enable row level security;

create policy "Own haggle rounds: read" on public.haggle_rounds
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "Own haggle rounds: add" on public.haggle_rounds
  for insert to authenticated with check (
    (select auth.uid()) = user_id
    and (record_id is null or exists (
      select 1 from public.trip_records r
      where r.id = record_id and r.user_id = (select auth.uid())
    ))
  );
create policy "Own haggle rounds: change" on public.haggle_rounds
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check (
    (select auth.uid()) = user_id
    and (record_id is null or exists (
      select 1 from public.trip_records r
      where r.id = record_id and r.user_id = (select auth.uid())
    ))
  );
create policy "Own haggle rounds: remove" on public.haggle_rounds
  for delete to authenticated using ((select auth.uid()) = user_id);

revoke all on public.haggle_rounds from anon;
