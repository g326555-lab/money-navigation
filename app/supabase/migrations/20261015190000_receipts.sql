-- Receipts the traveler checked and kept (lib/rules/receipt_record.dart).
-- Only the result is stored: no photo and no item names. Private to the
-- owner through row level security, like trip_records.
create table public.receipts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  -- ReceiptRecord.id, so a retry never duplicates a receipt.
  client_id text not null check (char_length(client_id) between 1 and 64),
  saved_at timestamptz not null,
  total_thb numeric(12, 2) not null check (total_thb > 0),
  -- True only when the arithmetic proved the figures.
  verified boolean not null default false,
  merchant_name text check (char_length(merchant_name) <= 120),
  place_name text check (char_length(place_name) <= 120),
  place_lat double precision check (place_lat between -90 and 90),
  place_lng double precision check (place_lng between -180 and 180),
  kind text check (kind in ('serviceCharge', 'vatOnTop', 'vatIncluded', 'itemsOnly')),
  subtotal_thb numeric(12, 2) check (subtotal_thb >= 0),
  discount_thb numeric(12, 2) check (discount_thb >= 0),
  service_thb numeric(12, 2) check (service_thb >= 0),
  service_percent numeric(5, 2) check (service_percent >= 0 and service_percent <= 100),
  service_included boolean not null default false,
  vat_thb numeric(12, 2) check (vat_thb >= 0),
  vat_on_top boolean not null default false,
  item_count int check (item_count >= 0),
  category text not null default 'other'
    check (category in ('food', 'transport', 'shopping', 'lodging', 'other')),
  user_corrected boolean not null default false,
  is_sample boolean not null default false,
  created_at timestamptz not null default now(),
  unique (user_id, client_id),
  constraint receipts_place_pair check ((place_lat is null) = (place_lng is null))
);

create index receipts_user_saved_at on public.receipts (user_id, saved_at desc);
create index receipts_user_merchant on public.receipts (user_id, merchant_name);

alter table public.receipts enable row level security;

create policy "Own receipts: read" on public.receipts
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "Own receipts: add" on public.receipts
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "Own receipts: change" on public.receipts
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "Own receipts: remove" on public.receipts
  for delete to authenticated using ((select auth.uid()) = user_id);

revoke all on public.receipts from anon;
