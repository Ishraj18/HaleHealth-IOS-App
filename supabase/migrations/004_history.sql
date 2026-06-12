-- History layer: per-day plan snapshots + daily life-record snapshots.
-- Run after 003_meditation.sql (Supabase SQL editor → paste → Run).
--
-- routine_days answers "what was recommended that day" (the generated plan,
-- block by block). daily_snapshots answers "what actually happened that day"
-- (completion, meditation, drinks, Health signals, AQI). Together they make
-- follow-through computable — the ground truth future personalization/AI
-- learns from.

-- ── Plan snapshots ──────────────────────────────────────────────────────────
create table if not exists public.routine_days (
  user_id      uuid references public.profiles(id) on delete cascade,
  day          date not null,
  plan         jsonb not null,
  generated_at timestamptz default now(),
  primary key (user_id, day)
);
alter table public.routine_days enable row level security;
create policy "Users manage own routine days"
  on public.routine_days for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ── Daily snapshots ─────────────────────────────────────────────────────────
create table if not exists public.daily_snapshots (
  user_id             uuid references public.profiles(id) on delete cascade,
  day                 date not null,
  blocks_total        int default 0,
  blocks_completed    int default 0,
  meditation_sessions int default 0,
  meditation_minutes  int default 0,
  drinks_logged       int default 0,
  steps               int,
  workouts            int,
  aqi                 int,
  mood                text,
  streak_count        int default 0,
  updated_at          timestamptz default now(),
  primary key (user_id, day)
);
alter table public.daily_snapshots enable row level security;
create policy "Users manage own snapshots"
  on public.daily_snapshots for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Keep updated_at fresh on every upsert.
drop trigger if exists daily_snapshots_updated_at on public.daily_snapshots;
create trigger daily_snapshots_updated_at
  before update on public.daily_snapshots
  for each row execute function public.update_updated_at();
