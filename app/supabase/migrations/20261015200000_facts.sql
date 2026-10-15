-- Facts checked once a day against their official pages (5-assist, facts-refresh).
-- Read by everyone (the figures are public facts with sources); written only
-- by the facts-refresh Edge Function with the service role.
create table if not exists public.facts (
  key text primary key,
  value numeric not null check (value > 0),
  unit text not null,
  source_url text not null,
  quoted_text text,
  checked_at timestamptz not null default now(),
  fetched_at timestamptz,
  status text not null default 'new'
    check (status in ('new', 'updated', 'unchanged', 'kept')),
  note text
);

alter table public.facts enable row level security;

create policy "facts are readable by anyone"
  on public.facts for select
  to anon, authenticated
  using (true);

-- No insert/update/delete policies: only the service role (which bypasses
-- RLS) writes.
revoke insert, update, delete, truncate on public.facts from anon, authenticated;
grant select on public.facts to anon, authenticated;

-- Seed with the values the app already ships (assets/data/pay_facts.json,
-- read 2026-10-15), so a failed first run still has a sourced row.
insert into public.facts (key, value, unit, source_url, quoted_text, checked_at, status)
values
  ('th.atm_fee.kasikorn.visa', 250, 'THB',
   'https://www.kasikornbank.com/en/rate/fee/feePDF/servicingfees-en-20052026.pdf',
   null, '2026-10-15T00:00:00+07:00', 'new'),
  ('th.atm_fee.kasikorn.mastercard', 350, 'THB',
   'https://www.kasikornbank.com/en/rate/fee/feePDF/servicingfees-en-20052026.pdf',
   null, '2026-10-15T00:00:00+07:00', 'new')
on conflict (key) do nothing;
