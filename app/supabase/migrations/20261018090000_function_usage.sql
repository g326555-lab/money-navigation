-- Per-user daily call counts for public Edge Functions.
-- Only the service role (inside Edge Functions) reads or writes it.

create table if not exists public.function_usage (
  user_id uuid not null references auth.users(id) on delete cascade,
  day date not null default (now() at time zone 'utc')::date,
  function text not null,
  count integer not null default 0,
  primary key (user_id, day, function)
);

alter table public.function_usage enable row level security;
-- No policies: anon and authenticated roles get nothing.

create or replace function public.bump_function_usage(p_user uuid, p_function text, p_limit integer)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer;
begin
  insert into public.function_usage as u (user_id, day, function, count)
  values (p_user, (now() at time zone 'utc')::date, p_function, 1)
  on conflict (user_id, day, function)
  do update set count = u.count + 1
  returning u.count into v_count;
  return v_count <= p_limit;
end;
$$;

revoke all on function public.bump_function_usage(uuid, text, integer) from public, anon, authenticated;
grant execute on function public.bump_function_usage(uuid, text, integer) to service_role;
