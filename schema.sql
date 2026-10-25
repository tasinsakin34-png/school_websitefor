-- Mushuli High School website schema for Supabase
-- Run this entire file in Supabase Dashboard > SQL Editor > New query.
-- Uses publishable key in the browser; NEVER put sb_secret_ or service_role keys in app.js.

create extension if not exists pgcrypto;

create table if not exists public.notices (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 1 and 180),
  body text not null check (char_length(body) between 1 and 5000),
  published_on date not null default current_date,
  created_at timestamptz not null default now()
);

create table if not exists public.teachers (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 160),
  designation text not null check (char_length(designation) between 1 and 160),
  photo_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.gallery (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 1 and 180),
  image_url text not null,
  created_at timestamptz not null default now()
);

-- Result records are not publicly readable directly.
create table if not exists public.student_results (
  id uuid primary key default gen_random_uuid(),
  student_name text not null,
  roll text not null,
  exam text not null,
  class_name text not null,
  result_text text not null,
  access_code_hash text not null,
  created_at timestamptz not null default now()
);

create index if not exists notices_published_on_idx on public.notices (published_on desc);
create index if not exists teachers_name_idx on public.teachers (name);
create index if not exists gallery_created_at_idx on public.gallery (created_at desc);
create index if not exists student_results_lookup_idx on public.student_results (roll, exam);

alter table public.notices enable row level security;
alter table public.teachers enable row level security;
alter table public.gallery enable row level security;
alter table public.student_results enable row level security;

-- Public visitors can read only school public content.
drop policy if exists "Public can read notices" on public.notices;
create policy "Public can read notices" on public.notices
  for select to anon, authenticated using (true);

drop policy if exists "Public can read teachers" on public.teachers;
create policy "Public can read teachers" on public.teachers
  for select to anon, authenticated using (true);

drop policy if exists "Public can read gallery" on public.gallery;
create policy "Public can read gallery" on public.gallery
  for select to anon, authenticated using (true);

-- Only authenticated users listed in this private admin allowlist may manage school content.
create table if not exists public.school_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.school_admins enable row level security;
revoke all on public.school_admins from anon, authenticated;

create or replace function public.is_school_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.school_admins a
    where a.user_id = (select auth.uid())
  );
$$;
revoke all on function public.is_school_admin() from public, anon;
grant execute on function public.is_school_admin() to authenticated;

drop policy if exists "Admins manage notices" on public.notices;
create policy "Admins manage notices" on public.notices
  for all to authenticated using ((select public.is_school_admin()))
  with check ((select public.is_school_admin()));

drop policy if exists "Admins manage teachers" on public.teachers;
create policy "Admins manage teachers" on public.teachers
  for all to authenticated using ((select public.is_school_admin()))
  with check ((select public.is_school_admin()));

drop policy if exists "Admins manage gallery" on public.gallery;
create policy "Admins manage gallery" on public.gallery
  for all to authenticated using ((select public.is_school_admin()))
  with check ((select public.is_school_admin()));

-- Results cannot be selected, inserted, updated, or deleted directly through the browser API.
drop policy if exists "Admins manage results" on public.student_results;
create policy "Admins manage results" on public.student_results
  for all to authenticated using ((select public.is_school_admin()))
  with check ((select public.is_school_admin()));
revoke all on public.student_results from anon, authenticated;
grant select, insert, update, delete on public.student_results to authenticated;

-- Admin-only function adds result and hashes its access code.
create or replace function public.admin_add_result(
  p_student_name text,
  p_roll text,
  p_exam text,
  p_class_name text,
  p_result_text text,
  p_access_code text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_school_admin() then
    raise exception 'Only approved school admins may add results';
  end if;
  if length(trim(coalesce(p_access_code, ''))) < 6 then
    raise exception 'Access code must be at least 6 characters';
  end if;
  insert into public.student_results
    (student_name, roll, exam, class_name, result_text, access_code_hash)
  values
    (trim(p_student_name), trim(p_roll), trim(p_exam), trim(p_class_name),
     trim(p_result_text), extensions.crypt(p_access_code, extensions.gen_salt('bf')));
end;
$$;
revoke all on function public.admin_add_result(text,text,text,text,text,text) from public, anon;
grant execute on function public.admin_add_result(text,text,text,text,text,text) to authenticated;

-- Public RPC reveals only one matching result if the school-issued access code is correct.
-- Do not use simple roll-only lookup. Give each student a unique, hard-to-guess access code.
create or replace function public.lookup_student_result(
  p_roll text,
  p_exam text,
  p_access_code text
)
returns table(student_name text, roll text, exam text, class_name text, result_text text)
language sql
stable
security definer
set search_path = ''
as $$
  select r.student_name, r.roll, r.exam, r.class_name, r.result_text
  from public.student_results r
  where r.roll = trim(p_roll)
    and r.exam = trim(p_exam)
    and extensions.crypt(p_access_code, r.access_code_hash) = r.access_code_hash
  limit 1;
$$;
revoke all on function public.lookup_student_result(text,text,text) from public;
grant execute on function public.lookup_student_result(text,text,text) to anon, authenticated;

-- IMPORTANT: create the admin in Supabase Authentication first, then replace
-- YOUR_ADMIN_AUTH_USER_UUID below with that user's Auth UID and run this insert.
-- Do not make the first registered user an admin automatically.
-- insert into public.school_admins (user_id)
-- values ('YOUR_ADMIN_AUTH_USER_UUID');

-- SECURITY CHECKLIST:
-- 1. Supabase Authentication > Users: create the official school admin account.
-- 2. Copy its UUID and run the allowlist INSERT above after replacing the placeholder.
-- 3. Keep student access codes private and give each student/guardian their own code.
-- 4. Only publish results with school authorization; avoid exposing sensitive personal data.
-- 5. This SQL does not create public storage for images. Use public https image URLs, or configure a Storage bucket and its policies separately.
