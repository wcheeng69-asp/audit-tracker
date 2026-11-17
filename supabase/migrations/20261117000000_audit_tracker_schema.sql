-- Audit Tracker schema (applied to project qjlzyqadysgcslfjgrff on 2026-11-17)

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique check (username ~ '^[a-z0-9._-]{2,40}$'),
  full_name text,
  role text not null default 'auditor' check (role in ('admin','auditor')),
  must_change_password boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.settings (
  user_id uuid primary key references auth.users(id) on delete cascade default auth.uid(),
  entity text default '',
  fye date default '2025-12-31',
  currency text default 'S$',
  materiality numeric default 500000,
  pm_pct numeric default 75,
  trivial_pct numeric default 5,
  round_threshold numeric default 10000,
  cutoff_days integer default 14,
  updated_at timestamptz not null default now()
);

create table public.workbooks (
  user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  id text not null,
  name text not null,
  size bigint default 0,
  is_sample boolean default false,
  sheets jsonb not null default '[]'::jsonb,
  uploaded_at timestamptz default now(),
  tested_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (user_id, id)
);

create table public.issues (
  user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  id text not null,
  workbook_id text,
  auto boolean not null default false,
  test text,
  title text not null,
  detail text,
  amount numeric default 0,
  category text,
  level text check (level in ('High','Medium','Low')),
  priority text check (priority in ('P1','P2','P3')),
  pri_manual boolean default false,
  level_manual boolean default false,
  pri_floor text,
  status text not null default 'Open' check (status in ('Open','In review','Resolved')),
  refs text[] not null default '{}',
  loc jsonb,
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, id)
);
create index issues_user_workbook_idx on public.issues (user_id, workbook_id);

alter table public.profiles enable row level security;
alter table public.settings enable row level security;
alter table public.workbooks enable row level security;
alter table public.issues enable row level security;

create policy "profiles readable by signed-in users" on public.profiles
  for select to authenticated using (true);
create policy "own settings" on public.settings for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "own workbooks" on public.workbooks for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "own issues" on public.issues for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, username, full_name)
  values (
    new.id,
    lower(coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1))),
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1))
  );
  insert into public.settings (user_id) values (new.id);
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.mark_password_changed()
returns void language sql security definer set search_path = '' as $$
  update public.profiles set must_change_password = false where id = (select auth.uid());
$$;
revoke execute on function public.mark_password_changed() from public, anon;
grant execute on function public.mark_password_changed() to authenticated;
revoke execute on function public.handle_new_user() from public, anon, authenticated;
