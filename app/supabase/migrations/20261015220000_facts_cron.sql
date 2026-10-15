-- Daily facts refresh at 03:00 Bangkok (20:00 UTC). The call carries a
-- dedicated secret, read from Vault ('facts_cron_secret') at run time; the
-- facts-refresh function accepts only that bearer. The secret's value is
-- never in this file.
create extension if not exists pg_cron;
create extension if not exists pg_net;

select cron.unschedule('facts-refresh-daily')
where exists (select 1 from cron.job where jobname = 'facts-refresh-daily');

select cron.schedule(
  'facts-refresh-daily',
  '0 20 * * *',
  $$
  select net.http_post(
    url := 'https://ufoyezpfxwqfonfyrgcy.supabase.co/functions/v1/facts-refresh',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (
        select decrypted_secret from vault.decrypted_secrets
        where name = 'facts_cron_secret'
      )
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 120000
  );
  $$
);
