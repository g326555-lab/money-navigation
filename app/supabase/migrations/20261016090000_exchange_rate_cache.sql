-- Cache the attributed public Thai cash-exchange feed once per refresh cycle.
-- The source dataset is retained verbatim so its provenance travels with it.
create table if not exists public.exchange_rate_cache (
  cache_key text primary key check (cache_key = 'latest'),
  payload jsonb not null,
  source_generated_at timestamptz not null,
  refreshed_at timestamptz not null default now()
);

alter table public.exchange_rate_cache enable row level security;

drop policy if exists "exchange rate cache is readable by anyone"
  on public.exchange_rate_cache;
create policy "exchange rate cache is readable by anyone"
  on public.exchange_rate_cache for select
  to anon, authenticated
  using (true);

revoke insert, update, delete, truncate on public.exchange_rate_cache
  from anon, authenticated;
grant select on public.exchange_rate_cache to anon, authenticated;

-- ThaiRate asks clients to cache for at least 60 seconds and says its
-- underlying board data updates about every 15 minutes. Refresh once per cycle.
create extension if not exists pg_cron;
create extension if not exists pg_net;

select cron.unschedule('exchange-rates-refresh-15m')
where exists (
  select 1 from cron.job where jobname = 'exchange-rates-refresh-15m'
);

select cron.schedule(
  'exchange-rates-refresh-15m',
  '*/15 * * * *',
  $$
  select net.http_post(
    url := 'https://ufoyezpfxwqfonfyrgcy.supabase.co/functions/v1/exchange-rates-refresh',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (
        select decrypted_secret from vault.decrypted_secrets
        where name = 'facts_cron_secret'
      )
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 30000
  );
  $$
);
