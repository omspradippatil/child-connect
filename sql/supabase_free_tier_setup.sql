-- Child Connect backend schema for Supabase Free Tier
-- Uses custom app_users table authentication (no Supabase Auth required).

begin;

create extension if not exists pgcrypto;

-- Shared trigger for updated_at maintenance.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- App users table for custom authentication.
create table if not exists public.app_users (
  id uuid primary key default gen_random_uuid(),
  full_name text not null check (char_length(trim(full_name)) >= 2),
  email text not null,
  password_hash text not null,
  role text not null default 'user' check (role in ('user', 'admin')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists ux_app_users_email_lower
on public.app_users (lower(email));

-- Sign-up function.
create or replace function public.app_sign_up(
  p_full_name text,
  p_email text,
  p_password text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user public.app_users;
  v_email text;
begin
  v_email := lower(trim(coalesce(p_email, '')));

  if char_length(trim(coalesce(p_full_name, ''))) < 2 then
    raise exception 'Full name must be at least 2 characters';
  end if;

  if position('@' in v_email) <= 1 then
    raise exception 'Invalid email address';
  end if;

  if char_length(coalesce(p_password, '')) < 6 then
    raise exception 'Password must be at least 6 characters';
  end if;

  if exists (select 1 from public.app_users u where lower(u.email) = v_email) then
    raise exception 'Email already registered';
  end if;

  insert into public.app_users (full_name, email, password_hash)
  values (
    trim(p_full_name),
    v_email,
    crypt(p_password, gen_salt('bf'))
  )
  returning * into v_user;

  return jsonb_build_object(
    'id', v_user.id,
    'full_name', v_user.full_name,
    'email', v_user.email,
    'role', v_user.role
  );
end;
$$;

-- Sign-in function.
create or replace function public.app_sign_in(
  p_email text,
  p_password text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user public.app_users;
  v_email text;
begin
  v_email := lower(trim(coalesce(p_email, '')));

  select *
  into v_user
  from public.app_users u
  where lower(u.email) = v_email and u.is_active = true
  limit 1;

  if not found then
    raise exception 'Invalid email or password';
  end if;

  if v_user.password_hash <> crypt(coalesce(p_password, ''), v_user.password_hash) then
    raise exception 'Invalid email or password';
  end if;

  return jsonb_build_object(
    'id', v_user.id,
    'full_name', v_user.full_name,
    'email', v_user.email,
    'role', v_user.role
  );
end;
$$;

-- Admin dashboard snapshot function.
create or replace function public.app_admin_dashboard_snapshot(
  p_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_is_admin boolean;
  v_result jsonb;
begin
  select exists(
    select 1
    from public.app_users u
    where u.id = p_user_id and u.role = 'admin' and u.is_active = true
  ) into v_is_admin;

  if not v_is_admin then
    raise exception 'Not authorized';
  end if;

  select jsonb_build_object(
    'contact_count', (select count(*)::int from public.contact_messages),
    'adoption_count', (select count(*)::int from public.adoption_applications),
    'mentor_count', (select count(*)::int from public.mentor_applications),
    'latest_contacts', coalesce(
      (
        select jsonb_agg(to_jsonb(c))
        from (
          select full_name, status, created_at
          from public.contact_messages
          order by created_at desc
          limit 6
        ) c
      ),
      '[]'::jsonb
    ),
    'latest_adoptions', coalesce(
      (
        select jsonb_agg(to_jsonb(a))
        from (
          select full_name, status, created_at
          from public.adoption_applications
          order by created_at desc
          limit 6
        ) a
      ),
      '[]'::jsonb
    )
  ) into v_result;

  return v_result;
end;
$$;

revoke all on function public.app_sign_up(text, text, text) from public;
revoke all on function public.app_sign_in(text, text) from public;
revoke all on function public.app_admin_dashboard_snapshot(uuid) from public;

grant execute on function public.app_sign_up(text, text, text) to anon, authenticated, service_role;
grant execute on function public.app_sign_in(text, text) to anon, authenticated, service_role;
grant execute on function public.app_admin_dashboard_snapshot(uuid) to anon, authenticated, service_role;

-- Contact form submissions.
create table if not exists public.contact_messages (
  id uuid primary key default gen_random_uuid(),
  full_name text not null check (char_length(trim(full_name)) >= 2),
  email text not null check (position('@' in email) > 1),
  phone text,
  message text not null check (char_length(trim(message)) >= 10),
  status text not null default 'new' check (status in ('new', 'in_review', 'resolved')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Adoption form submissions.
create table if not exists public.adoption_applications (
  id uuid primary key default gen_random_uuid(),
  full_name text not null check (char_length(trim(full_name)) >= 2),
  email text not null check (position('@' in email) > 1),
  phone text,
  city text,
  occupation text,
  reason text not null check (char_length(trim(reason)) >= 20),
  has_children boolean,
  status text not null default 'submitted' check (status in ('submitted', 'shortlisted', 'approved', 'rejected')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Mentor enrollment submissions.
create table if not exists public.mentor_applications (
  id uuid primary key default gen_random_uuid(),
  full_name text not null check (char_length(trim(full_name)) >= 2),
  email text not null check (position('@' in email) > 1),
  phone text,
  skills text,
  availability text,
  motivation text not null check (char_length(trim(motivation)) >= 20),
  status text not null default 'submitted' check (status in ('submitted', 'screening', 'approved', 'rejected')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Lightweight indexes for common admin sorting/filtering.
create index if not exists idx_contact_messages_created_at on public.contact_messages (created_at desc);
create index if not exists idx_contact_messages_status on public.contact_messages (status);

create index if not exists idx_adoption_applications_created_at on public.adoption_applications (created_at desc);
create index if not exists idx_adoption_applications_status on public.adoption_applications (status);

create index if not exists idx_mentor_applications_created_at on public.mentor_applications (created_at desc);
create index if not exists idx_mentor_applications_status on public.mentor_applications (status);

-- Triggers to keep updated_at fresh.
drop trigger if exists set_app_users_updated_at on public.app_users;
create trigger set_app_users_updated_at
before update on public.app_users
for each row execute function public.set_updated_at();

drop trigger if exists set_contact_messages_updated_at on public.contact_messages;
create trigger set_contact_messages_updated_at
before update on public.contact_messages
for each row execute function public.set_updated_at();

drop trigger if exists set_adoption_applications_updated_at on public.adoption_applications;
create trigger set_adoption_applications_updated_at
before update on public.adoption_applications
for each row execute function public.set_updated_at();

drop trigger if exists set_mentor_applications_updated_at on public.mentor_applications;
create trigger set_mentor_applications_updated_at
before update on public.mentor_applications
for each row execute function public.set_updated_at();

-- RLS.
alter table public.app_users enable row level security;
alter table public.contact_messages enable row level security;
alter table public.adoption_applications enable row level security;
alter table public.mentor_applications enable row level security;

-- Public form submissions.
drop policy if exists contact_messages_insert_public on public.contact_messages;
create policy contact_messages_insert_public
on public.contact_messages
for insert
to anon, authenticated
with check (true);

drop policy if exists adoption_applications_insert_public on public.adoption_applications;
create policy adoption_applications_insert_public
on public.adoption_applications
for insert
to anon, authenticated
with check (true);

drop policy if exists mentor_applications_insert_public on public.mentor_applications;
create policy mentor_applications_insert_public
on public.mentor_applications
for insert
to anon, authenticated
with check (true);

-- Service role full access.
drop policy if exists app_users_service_all on public.app_users;
create policy app_users_service_all
on public.app_users
for all
to service_role
using (true)
with check (true);

drop policy if exists contact_messages_service_all on public.contact_messages;
create policy contact_messages_service_all
on public.contact_messages
for all
to service_role
using (true)
with check (true);

drop policy if exists adoption_applications_service_all on public.adoption_applications;
create policy adoption_applications_service_all
on public.adoption_applications
for all
to service_role
using (true)
with check (true);

drop policy if exists mentor_applications_service_all on public.mentor_applications;
create policy mentor_applications_service_all
on public.mentor_applications
for all
to service_role
using (true)
with check (true);

commit;
