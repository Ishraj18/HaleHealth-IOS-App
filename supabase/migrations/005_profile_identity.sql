-- Identity-provider profile data. Run after 004_history.sql.
--
-- Google/Apple sign-in carries the user's real name and photo in auth
-- metadata; the app now mirrors them onto the profile row so every surface
-- (and future AI context) can address the user properly.

alter table public.profiles
  add column if not exists avatar_url text;
