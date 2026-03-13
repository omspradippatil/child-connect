-- Child Connect backend schema for Supabase Free Tier
-- Safe defaults: RLS enabled, public users can only INSERT form submissions.

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

-- RLS: protect data by default.
alter table public.contact_messages enable row level security;
alter table public.adoption_applications enable row level security;
alter table public.mentor_applications enable row level security;

-- Allow app users (anon + authenticated) to submit forms.
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

-- Admin/service role can read and manage all rows.
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
