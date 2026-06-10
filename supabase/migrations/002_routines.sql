-- Routine engine: profile answers, per-day completions, server-side streak.
-- Run after schema.sql.

create table if not exists public.routine_profiles (
  user_id      uuid primary key references public.profiles(id) on delete cascade,
  answers      jsonb not null,
  quiz_version int default 1,
  updated_at   timestamptz default now()
);
alter table public.routine_profiles enable row level security;
create policy "Users manage own routine profile"
  on public.routine_profiles for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create table if not exists public.routine_completions (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid references public.profiles(id) on delete cascade,
  day              date not null,
  completed_blocks text[] default '{}',
  updated_at       timestamptz default now(),
  unique (user_id, day)
);
alter table public.routine_completions enable row level security;
create policy "Users manage own completions"
  on public.routine_completions for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Server-authoritative streak: counts a day once, breaks on gaps.
create or replace function public.keep_streak(p_day date)
returns int as $$
declare new_count int;
begin
  update public.profiles
  set streak_count = case
        when last_log_date = p_day then streak_count                 -- already counted
        when last_log_date = p_day - 1 then streak_count + 1         -- consecutive
        else 1                                                        -- broken/new
      end,
      last_log_date = greatest(coalesce(last_log_date, p_day), p_day)
  where id = auth.uid()
  returning streak_count into new_count;
  return new_count;
end;
$$ language plpgsql security definer set search_path = public;
