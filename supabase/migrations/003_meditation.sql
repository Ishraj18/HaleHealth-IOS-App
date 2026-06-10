-- Shuddhi meditation sessions.
create table if not exists public.meditation_sessions (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid references public.profiles(id) on delete cascade,
  pattern_id       text not null,
  duration_seconds int not null,
  breath_cycles    int default 0,
  aqi_at_start     int,
  completed_at     timestamptz default now()
);
alter table public.meditation_sessions enable row level security;
create policy "Users manage own meditation sessions"
  on public.meditation_sessions for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
