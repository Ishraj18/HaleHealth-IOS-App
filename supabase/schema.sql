-- ───────────────────────────────────────────────────────────────────────────
-- Hale Health — Supabase schema (Phase 1)
--
-- Run this in the Supabase SQL editor. It is forward-compatible with Phase 2/3
-- (orders, subscriptions, insights are created now even though their UI ships
-- later). RLS is enabled on every user-owned table.
--
-- Differences from the original Phase-1 draft (deliberate, see README):
--   • profiles.email column added (the app's UserProfile carries email).
--   • profiles INSERT policy added — the draft only had SELECT/UPDATE, which
--     would have blocked new-user profile creation via upsert.
--   • handle_new_user() trigger auto-creates a profiles row on signup, so a row
--     always exists even before the app writes goals.
--   • insights uses RLS + a public read policy (secure-by-default) rather than
--     leaving RLS off.
-- ───────────────────────────────────────────────────────────────────────────

-- ── Profiles (extends auth.users) ──────────────────────────────────────────
create table if not exists public.profiles (
  id           uuid references auth.users(id) on delete cascade primary key,
  display_name text,
  email        text,
  phone        text,
  body_goals   text[]      default '{}',
  streak_count integer     default 0,
  last_log_date date,
  created_at   timestamptz default now(),
  updated_at   timestamptz default now()
);

alter table public.profiles enable row level security;

create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- ── Drink logs ──────────────────────────────────────────────────────────────
create table if not exists public.drink_logs (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid references public.profiles(id) on delete cascade,
  product_id      text not null,
  logged_at       timestamptz default now(),
  aqi_at_log_time integer,
  mood_emoji      text,
  notes           text
);

alter table public.drink_logs enable row level security;

create policy "Users can manage own logs"
  on public.drink_logs for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index if not exists drink_logs_user_logged_idx
  on public.drink_logs (user_id, logged_at desc);

-- ── Orders (stub for Phase 2) ────────────────────────────────────────────────
create table if not exists public.orders (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid references public.profiles(id) on delete cascade,
  items               jsonb not null,
  total_paise         integer not null,
  razorpay_order_id   text,
  razorpay_payment_id text,
  status              text default 'pending',
  delivery_date       date,
  created_at          timestamptz default now()
);

alter table public.orders enable row level security;

create policy "Users can view own orders"
  on public.orders for select
  using (auth.uid() = user_id);

create policy "Users can insert own orders"
  on public.orders for insert
  with check (auth.uid() = user_id);

-- ── Subscriptions (stub for Phase 2) ─────────────────────────────────────────
create table if not exists public.subscriptions (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid references public.profiles(id) on delete cascade,
  weekly_plan  jsonb,
  is_active    boolean default true,
  paused_until date,
  created_at   timestamptz default now()
);

alter table public.subscriptions enable row level security;

create policy "Users can manage own subscriptions"
  on public.subscriptions for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ── Insights (pre-populated content, publicly readable) ──────────────────────
create table if not exists public.insights (
  id      serial primary key,
  content text not null,
  tags    text[] default '{}',
  season  text   default 'all'
);

alter table public.insights enable row level security;

create policy "Insights are publicly readable"
  on public.insights for select
  using (true);

-- ── Triggers ─────────────────────────────────────────────────────────────────

-- Keep profiles.updated_at fresh.
create or replace function public.update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at
  before update on public.profiles
  for each row execute function public.update_updated_at();

-- Auto-create a profiles row when a new auth user signs up. SECURITY DEFINER so
-- it runs with the privileges needed to write the row.
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
