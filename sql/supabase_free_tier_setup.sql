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
  role text not null default 'user' check (role in ('user', 'admin', 'mentor')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists ux_app_users_email_lower
on public.app_users (lower(email));

-- Session table for token-based login state.
create table if not exists public.app_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.app_users(id) on delete cascade,
  token_hash text not null unique,
  expires_at timestamptz not null,
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_app_sessions_user_id on public.app_sessions(user_id);
create index if not exists idx_app_sessions_expires_at on public.app_sessions(expires_at);

-- Internal helper: creates and stores a session token.
create or replace function public.app_create_session(
  p_user_id uuid
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_token text;
  v_token_hash text;
begin
  v_token := encode(extensions.gen_random_bytes(32), 'hex');
  v_token_hash := encode(extensions.digest(v_token, 'sha256'), 'hex');

  insert into public.app_sessions (user_id, token_hash, expires_at)
  values (p_user_id, v_token_hash, now() + interval '30 days');

  return v_token;
end;
$$;

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
  v_session_token text;
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
    extensions.crypt(p_password, extensions.gen_salt('bf'))
  )
  returning * into v_user;

  v_session_token := public.app_create_session(v_user.id);

  return jsonb_build_object(
    'session_token', v_session_token,
    'user', jsonb_build_object(
      'id', v_user.id,
      'full_name', v_user.full_name,
      'email', v_user.email,
      'role', v_user.role
    )
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
  v_session_token text;
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

  if v_user.password_hash <> extensions.crypt(coalesce(p_password, ''), v_user.password_hash) then
    raise exception 'Invalid email or password';
  end if;

  delete from public.app_sessions s
  where s.user_id = v_user.id and (s.expires_at < now() or s.revoked_at is not null);

  v_session_token := public.app_create_session(v_user.id);

  return jsonb_build_object(
    'session_token', v_session_token,
    'user', jsonb_build_object(
      'id', v_user.id,
      'full_name', v_user.full_name,
      'email', v_user.email,
      'role', v_user.role
    )
  );
end;
$$;

-- Validate session token and return user profile.
create or replace function public.app_get_session_user(
  p_session_token text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_token_hash text;
  v_user public.app_users;
begin
  if coalesce(p_session_token, '') = '' then
    raise exception 'Missing session token';
  end if;

  v_token_hash := encode(extensions.digest(p_session_token, 'sha256'), 'hex');

  select u.*
  into v_user
  from public.app_sessions s
  join public.app_users u on u.id = s.user_id
  where s.token_hash = v_token_hash
    and s.revoked_at is null
    and s.expires_at > now()
    and u.is_active = true
  limit 1;

  if not found then
    raise exception 'Session invalid or expired';
  end if;

  return jsonb_build_object(
    'id', v_user.id,
    'full_name', v_user.full_name,
    'email', v_user.email,
    'role', v_user.role
  );
end;
$$;

-- Revoke session token.
create or replace function public.app_sign_out(
  p_session_token text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_token_hash text;
begin
  if coalesce(p_session_token, '') = '' then
    return;
  end if;

  v_token_hash := encode(extensions.digest(p_session_token, 'sha256'), 'hex');

  update public.app_sessions
  set revoked_at = now()
  where token_hash = v_token_hash and revoked_at is null;
end;
$$;

-- Admin dashboard snapshot function.
create or replace function public.app_admin_dashboard_snapshot(
  p_session_token text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_token_hash text;
  v_user_id uuid;
  v_result jsonb;
begin
  if coalesce(p_session_token, '') = '' then
    raise exception 'Not authorized';
  end if;

  v_token_hash := encode(extensions.digest(p_session_token, 'sha256'), 'hex');

  select u.id
  into v_user_id
  from public.app_sessions s
  join public.app_users u on u.id = s.user_id
  where s.token_hash = v_token_hash
    and s.revoked_at is null
    and s.expires_at > now()
    and u.role = 'admin'
    and u.is_active = true
  limit 1;

  if v_user_id is null then
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

-- Resolve admin user id from a valid session token.
create or replace function public.app_admin_user_id_from_token(
  p_session_token text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_token_hash text;
  v_user_id uuid;
begin
  if coalesce(p_session_token, '') = '' then
    raise exception 'Not authorized';
  end if;

  v_token_hash := encode(extensions.digest(p_session_token, 'sha256'), 'hex');

  select u.id
  into v_user_id
  from public.app_sessions s
  join public.app_users u on u.id = s.user_id
  where s.token_hash = v_token_hash
    and s.revoked_at is null
    and s.expires_at > now()
    and u.role = 'admin'
    and u.is_active = true
  limit 1;

  if v_user_id is null then
    raise exception 'Not authorized';
  end if;

  return v_user_id;
end;
$$;

-- Child profiles managed from admin panel.
create table if not exists public.child_profiles (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(trim(name)) >= 2),
  age int not null check (age between 1 and 18),
  location text not null,
  story text not null check (char_length(trim(story)) >= 10),
  interests text,
  image_url text,
  gender text not null default 'other' check (gender in ('boy', 'girl', 'other')),
  avatar_color_hex text not null default '#FFD8B4',
  is_active boolean not null default true,
  display_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.child_profiles
add column if not exists interests text;

alter table public.child_profiles
add column if not exists image_url text;

create index if not exists idx_child_profiles_active_order
on public.child_profiles (is_active, display_order, created_at desc);

-- Programs managed from admin panel.
create table if not exists public.program_catalog (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(trim(title)) >= 2),
  description text not null check (char_length(trim(description)) >= 10),
  icon_key text not null default 'school',
  image_url text,
  color_hex text not null default '#4FA8D5',
  is_active boolean not null default true,
  display_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.program_catalog
add column if not exists image_url text;

create index if not exists idx_program_catalog_active_order
on public.program_catalog (is_active, display_order, created_at desc);

-- Public APIs consumed by user app.
create or replace function public.app_get_public_children()
returns jsonb
language sql
security definer
set search_path = public
as $$
  select coalesce(
    jsonb_agg(to_jsonb(c)),
    '[]'::jsonb
  )
  from (
    select id, name, age, location, story, interests, image_url, gender, avatar_color_hex, display_order
    from public.child_profiles
    where is_active = true
    order by display_order asc, created_at desc
  ) c;
$$;

create or replace function public.app_get_public_programs()
returns jsonb
language sql
security definer
set search_path = public
as $$
  select coalesce(
    jsonb_agg(to_jsonb(p)),
    '[]'::jsonb
  )
  from (
    select id, title, description, icon_key, image_url, color_hex, display_order
    from public.program_catalog
    where is_active = true
    order by display_order asc, created_at desc
  ) p;
$$;

-- Admin APIs for content management.
create or replace function public.app_admin_list_content(
  p_session_token text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.app_admin_user_id_from_token(p_session_token);

  return jsonb_build_object(
    'children', coalesce(
      (
        select jsonb_agg(to_jsonb(c))
        from (
          select id, name, age, location, story, interests, image_url, gender, avatar_color_hex, is_active, display_order, created_at
          from public.child_profiles
          order by display_order asc, created_at desc
        ) c
      ),
      '[]'::jsonb
    ),
    'programs', coalesce(
      (
        select jsonb_agg(to_jsonb(p))
        from (
          select id, title, description, icon_key, image_url, color_hex, is_active, display_order, created_at
          from public.program_catalog
          order by display_order asc, created_at desc
        ) p
      ),
      '[]'::jsonb
    )
  );
end;
$$;

create or replace function public.app_admin_upsert_child(
  p_session_token text,
  p_id uuid,
  p_name text,
  p_age int,
  p_location text,
  p_story text,
  p_interests text,
  p_image_url text,
  p_gender text,
  p_avatar_color_hex text,
  p_is_active boolean,
  p_display_order int
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.child_profiles;
begin
  perform public.app_admin_user_id_from_token(p_session_token);

  if p_id is null then
    insert into public.child_profiles (
      name,
      age,
      location,
      story,
      interests,
      image_url,
      gender,
      avatar_color_hex,
      is_active,
      display_order
    )
    values (
      trim(p_name),
      p_age,
      trim(p_location),
      trim(p_story),
      nullif(trim(coalesce(p_interests, '')), ''),
      nullif(trim(coalesce(p_image_url, '')), ''),
      lower(trim(coalesce(p_gender, 'other'))),
      coalesce(nullif(trim(p_avatar_color_hex), ''), '#FFD8B4'),
      coalesce(p_is_active, true),
      coalesce(p_display_order, 0)
    )
    returning * into v_row;
  else
    update public.child_profiles
    set
      name = trim(p_name),
      age = p_age,
      location = trim(p_location),
      story = trim(p_story),
      interests = nullif(trim(coalesce(p_interests, '')), ''),
      image_url = nullif(trim(coalesce(p_image_url, '')), ''),
      gender = lower(trim(coalesce(p_gender, 'other'))),
      avatar_color_hex = coalesce(nullif(trim(p_avatar_color_hex), ''), '#FFD8B4'),
      is_active = coalesce(p_is_active, true),
      display_order = coalesce(p_display_order, display_order),
      updated_at = now()
    where id = p_id
    returning * into v_row;
  end if;

  return to_jsonb(v_row);
end;
$$;

create or replace function public.app_admin_upsert_program(
  p_session_token text,
  p_id uuid,
  p_title text,
  p_description text,
  p_icon_key text,
  p_image_url text,
  p_color_hex text,
  p_is_active boolean,
  p_display_order int
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.program_catalog;
begin
  perform public.app_admin_user_id_from_token(p_session_token);

  if p_id is null then
    insert into public.program_catalog (
      title,
      description,
      icon_key,
      image_url,
      color_hex,
      is_active,
      display_order
    )
    values (
      trim(p_title),
      trim(p_description),
      lower(trim(coalesce(p_icon_key, 'school'))),
      nullif(trim(coalesce(p_image_url, '')), ''),
      coalesce(nullif(trim(p_color_hex), ''), '#4FA8D5'),
      coalesce(p_is_active, true),
      coalesce(p_display_order, 0)
    )
    returning * into v_row;
  else
    update public.program_catalog
    set
      title = trim(p_title),
      description = trim(p_description),
      icon_key = lower(trim(coalesce(p_icon_key, 'school'))),
      image_url = nullif(trim(coalesce(p_image_url, '')), ''),
      color_hex = coalesce(nullif(trim(p_color_hex), ''), '#4FA8D5'),
      is_active = coalesce(p_is_active, true),
      display_order = coalesce(p_display_order, display_order),
      updated_at = now()
    where id = p_id
    returning * into v_row;
  end if;

  return to_jsonb(v_row);
end;
$$;

create or replace function public.app_admin_list_requests(
  p_session_token text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.app_admin_user_id_from_token(p_session_token);

  return jsonb_build_object(
    'contacts', coalesce(
      (
        select jsonb_agg(to_jsonb(c))
        from (
          select id, full_name, email, message, status, created_at
          from public.contact_messages
          order by created_at desc
          limit 100
        ) c
      ),
      '[]'::jsonb
    ),
    'adoptions', coalesce(
      (
        select jsonb_agg(to_jsonb(a))
        from (
          select id, full_name, email, city, reason, status, created_at
          from public.adoption_applications
          order by created_at desc
          limit 100
        ) a
      ),
      '[]'::jsonb
    ),
    'mentors', coalesce(
      (
        select jsonb_agg(to_jsonb(m))
        from (
          select id, full_name, email, skills, availability, motivation, status, created_at
          from public.mentor_applications
          order by created_at desc
          limit 100
        ) m
      ),
      '[]'::jsonb
    )
  );
end;
$$;

create or replace function public.app_admin_update_request_status(
  p_session_token text,
  p_request_type text,
  p_id uuid,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.app_admin_user_id_from_token(p_session_token);

  if lower(p_request_type) = 'contact' then
    update public.contact_messages
    set status = p_status, updated_at = now()
    where id = p_id;
  elsif lower(p_request_type) = 'adoption' then
    update public.adoption_applications
    set status = p_status, updated_at = now()
    where id = p_id;
  elsif lower(p_request_type) = 'mentor' then
    update public.mentor_applications
    set status = p_status, updated_at = now()
    where id = p_id;
  else
    raise exception 'Invalid request type';
  end if;
end;
$$;

create or replace function public.app_admin_delete_request(
  p_session_token text,
  p_request_type text,
  p_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.app_admin_user_id_from_token(p_session_token);

  if lower(p_request_type) = 'contact' then
    delete from public.contact_messages
    where id = p_id;
  elsif lower(p_request_type) = 'adoption' then
    delete from public.adoption_applications
    where id = p_id;
  elsif lower(p_request_type) = 'mentor' then
    delete from public.mentor_applications
    where id = p_id;
  else
    raise exception 'Invalid request type';
  end if;
end;
$$;

create or replace function public.app_admin_delete_child(
  p_session_token text,
  p_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.app_admin_user_id_from_token(p_session_token);
  delete from public.child_profiles where id = p_id;
end;
$$;

create or replace function public.app_admin_delete_program(
  p_session_token text,
  p_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.app_admin_user_id_from_token(p_session_token);
  delete from public.program_catalog where id = p_id;
end;
$$;

revoke all on function public.app_sign_up(text, text, text) from public;
revoke all on function public.app_sign_in(text, text) from public;
revoke all on function public.app_get_session_user(text) from public;
revoke all on function public.app_sign_out(text) from public;
revoke all on function public.app_admin_dashboard_snapshot(text) from public;
revoke all on function public.app_admin_user_id_from_token(text) from public;
revoke all on function public.app_get_public_children() from public;
revoke all on function public.app_get_public_programs() from public;
revoke all on function public.app_admin_list_content(text) from public;
revoke all on function public.app_admin_upsert_child(text, uuid, text, int, text, text, text, text, text, text, boolean, int) from public;
revoke all on function public.app_admin_upsert_program(text, uuid, text, text, text, text, text, boolean, int) from public;
revoke all on function public.app_admin_list_requests(text) from public;
revoke all on function public.app_admin_update_request_status(text, text, uuid, text) from public;
revoke all on function public.app_admin_delete_request(text, text, uuid) from public;
revoke all on function public.app_admin_delete_child(text, uuid) from public;
revoke all on function public.app_admin_delete_program(text, uuid) from public;

grant execute on function public.app_sign_up(text, text, text) to anon, authenticated, service_role;
grant execute on function public.app_sign_in(text, text) to anon, authenticated, service_role;
grant execute on function public.app_get_session_user(text) to anon, authenticated, service_role;
grant execute on function public.app_sign_out(text) to anon, authenticated, service_role;
grant execute on function public.app_admin_dashboard_snapshot(text) to anon, authenticated, service_role;
grant execute on function public.app_get_public_children() to anon, authenticated, service_role;
grant execute on function public.app_get_public_programs() to anon, authenticated, service_role;
grant execute on function public.app_admin_list_content(text) to anon, authenticated, service_role;
grant execute on function public.app_admin_upsert_child(text, uuid, text, int, text, text, text, text, text, text, boolean, int) to anon, authenticated, service_role;
grant execute on function public.app_admin_upsert_program(text, uuid, text, text, text, text, text, boolean, int) to anon, authenticated, service_role;
grant execute on function public.app_admin_list_requests(text) to anon, authenticated, service_role;
grant execute on function public.app_admin_update_request_status(text, text, uuid, text) to anon, authenticated, service_role;
grant execute on function public.app_admin_delete_request(text, text, uuid) to anon, authenticated, service_role;
grant execute on function public.app_admin_delete_child(text, uuid) to anon, authenticated, service_role;
grant execute on function public.app_admin_delete_program(text, uuid) to anon, authenticated, service_role;

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
  first_name text,
  last_name text,
  date_of_birth date,
  marital_status text,
  address_street text,
  state text,
  zip_code text,
  email text not null check (position('@' in email) > 1),
  phone text,
  city text,
  employer text,
  occupation text,
  annual_income text,
  preferred_age_range text,
  preferred_gender text,
  number_of_family_members int,
  number_of_children int,
  family_background text,
  residence_type text,
  ownership_status text,
  health_insurance_provider text,
  overall_health_status text,
  reference1_name text,
  reference1_phone text,
  reference1_email text,
  consent_background_check boolean not null default false,
  agree_home_visits boolean not null default false,
  previous_adoption_experience text,
  motivation_for_adoption text,
  reason text not null check (char_length(trim(reason)) >= 20),
  has_children boolean,
  status text not null default 'submitted' check (status in ('submitted', 'shortlisted', 'approved', 'rejected')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.adoption_applications add column if not exists first_name text;
alter table public.adoption_applications add column if not exists last_name text;
alter table public.adoption_applications add column if not exists date_of_birth date;
alter table public.adoption_applications add column if not exists marital_status text;
alter table public.adoption_applications add column if not exists address_street text;
alter table public.adoption_applications add column if not exists state text;
alter table public.adoption_applications add column if not exists zip_code text;
alter table public.adoption_applications add column if not exists employer text;
alter table public.adoption_applications add column if not exists annual_income text;
alter table public.adoption_applications add column if not exists preferred_age_range text;
alter table public.adoption_applications add column if not exists preferred_gender text;
alter table public.adoption_applications add column if not exists number_of_family_members int;
alter table public.adoption_applications add column if not exists number_of_children int;
alter table public.adoption_applications add column if not exists family_background text;
alter table public.adoption_applications add column if not exists residence_type text;
alter table public.adoption_applications add column if not exists ownership_status text;
alter table public.adoption_applications add column if not exists health_insurance_provider text;
alter table public.adoption_applications add column if not exists overall_health_status text;
alter table public.adoption_applications add column if not exists reference1_name text;
alter table public.adoption_applications add column if not exists reference1_phone text;
alter table public.adoption_applications add column if not exists reference1_email text;
alter table public.adoption_applications add column if not exists consent_background_check boolean not null default false;
alter table public.adoption_applications add column if not exists agree_home_visits boolean not null default false;
alter table public.adoption_applications add column if not exists previous_adoption_experience text;
alter table public.adoption_applications add column if not exists motivation_for_adoption text;

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

-- Parent feedback stories from families with completed adoptions.
create table if not exists public.parent_feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.app_users(id) on delete cascade,
  parent_names text not null check (char_length(trim(parent_names)) >= 3),
  story_title text not null check (char_length(trim(story_title)) >= 5),
  story_body text not null check (char_length(trim(story_body)) >= 50),
  child_name text,
  confirm_adopted boolean not null default false,
  accept_terms boolean not null default false,
  like_count int not null default 0 check (like_count >= 0),
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.parent_feedback_likes (
  feedback_id uuid not null references public.parent_feedback(id) on delete cascade,
  user_id uuid not null references public.app_users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (feedback_id, user_id)
);

-- Lightweight indexes for common admin sorting/filtering.
create index if not exists idx_contact_messages_created_at on public.contact_messages (created_at desc);
create index if not exists idx_contact_messages_status on public.contact_messages (status);

create index if not exists idx_adoption_applications_created_at on public.adoption_applications (created_at desc);
create index if not exists idx_adoption_applications_status on public.adoption_applications (status);

create index if not exists idx_mentor_applications_created_at on public.mentor_applications (created_at desc);
create index if not exists idx_mentor_applications_status on public.mentor_applications (status);
create index if not exists idx_parent_feedback_ordering on public.parent_feedback (like_count desc, created_at desc);
create index if not exists idx_parent_feedback_likes_user_id on public.parent_feedback_likes (user_id);

-- Triggers to keep updated_at fresh.
drop trigger if exists set_app_users_updated_at on public.app_users;
create trigger set_app_users_updated_at
before update on public.app_users
for each row execute function public.set_updated_at();

drop trigger if exists set_child_profiles_updated_at on public.child_profiles;
create trigger set_child_profiles_updated_at
before update on public.child_profiles
for each row execute function public.set_updated_at();

drop trigger if exists set_program_catalog_updated_at on public.program_catalog;
create trigger set_program_catalog_updated_at
before update on public.program_catalog
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

drop trigger if exists set_parent_feedback_updated_at on public.parent_feedback;
create trigger set_parent_feedback_updated_at
before update on public.parent_feedback
for each row execute function public.set_updated_at();

-- RLS.
alter table public.app_users enable row level security;
alter table public.app_sessions enable row level security;
alter table public.child_profiles enable row level security;
alter table public.program_catalog enable row level security;
alter table public.contact_messages enable row level security;
alter table public.adoption_applications enable row level security;
alter table public.mentor_applications enable row level security;
alter table public.parent_feedback enable row level security;
alter table public.parent_feedback_likes enable row level security;

alter table public.app_users
drop constraint if exists app_users_role_check;

alter table public.app_users
add constraint app_users_role_check check (role in ('user', 'admin', 'mentor'));

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

drop policy if exists app_sessions_service_all on public.app_sessions;
create policy app_sessions_service_all
on public.app_sessions
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

drop policy if exists child_profiles_service_all on public.child_profiles;
create policy child_profiles_service_all
on public.child_profiles
for all
to service_role
using (true)
with check (true);

drop policy if exists program_catalog_service_all on public.program_catalog;
create policy program_catalog_service_all
on public.program_catalog
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

drop policy if exists parent_feedback_service_all on public.parent_feedback;
create policy parent_feedback_service_all
on public.parent_feedback
for all
to service_role
using (true)
with check (true);

drop policy if exists parent_feedback_likes_service_all on public.parent_feedback_likes;
create policy parent_feedback_likes_service_all
on public.parent_feedback_likes
for all
to service_role
using (true)
with check (true);

-- Mentor chat tables.
create table if not exists public.mentor_chat_threads (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.app_users(id) on delete cascade,
  assigned_mentor_id uuid references public.app_users(id) on delete set null,
  status text not null default 'open' check (status in ('open', 'closed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists ux_mentor_chat_threads_user_id
on public.mentor_chat_threads (user_id);

create table if not exists public.mentor_chat_messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.mentor_chat_threads(id) on delete cascade,
  sender_user_id uuid not null references public.app_users(id) on delete cascade,
  sender_role text not null check (sender_role in ('user', 'mentor', 'admin')),
  message_text text not null check (char_length(trim(message_text)) >= 1),
  created_at timestamptz not null default now()
);

create index if not exists idx_mentor_chat_messages_thread_created
on public.mentor_chat_messages (thread_id, created_at asc);

drop trigger if exists set_mentor_chat_threads_updated_at on public.mentor_chat_threads;
create trigger set_mentor_chat_threads_updated_at
before update on public.mentor_chat_threads
for each row execute function public.set_updated_at();

alter table public.mentor_chat_threads enable row level security;
alter table public.mentor_chat_messages enable row level security;

drop policy if exists mentor_chat_threads_service_all on public.mentor_chat_threads;
create policy mentor_chat_threads_service_all
on public.mentor_chat_threads
for all
to service_role
using (true)
with check (true);

drop policy if exists mentor_chat_messages_service_all on public.mentor_chat_messages;
create policy mentor_chat_messages_service_all
on public.mentor_chat_messages
for all
to service_role
using (true)
with check (true);

-- Resolve an active session into an app user.
create or replace function public.app_session_user_from_token(
  p_session_token text
)
returns public.app_users
language plpgsql
security definer
set search_path = public
as $$
declare
  v_token_hash text;
  v_user public.app_users;
begin
  if coalesce(p_session_token, '') = '' then
    raise exception 'Missing session token';
  end if;

  v_token_hash := encode(extensions.digest(p_session_token, 'sha256'), 'hex');

  select u.*
  into v_user
  from public.app_sessions s
  join public.app_users u on u.id = s.user_id
  where s.token_hash = v_token_hash
    and s.revoked_at is null
    and s.expires_at > now()
    and u.is_active = true
  limit 1;

  if not found then
    raise exception 'Session invalid or expired';
  end if;

  return v_user;
end;
$$;

-- Admin and mentor both can access mentor chat surfaces.
create or replace function public.app_admin_or_mentor_user_id_from_token(
  p_session_token text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user public.app_users;
begin
  v_user := public.app_session_user_from_token(p_session_token);

  if v_user.role not in ('admin', 'mentor') then
    raise exception 'Not authorized';
  end if;

  return v_user.id;
end;
$$;

create or replace function public.app_admin_create_user(
  p_session_token text,
  p_full_name text,
  p_email text,
  p_password text,
  p_role text,
  p_is_active boolean default true
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_admin_id uuid;
  v_email text;
  v_role text;
  v_user public.app_users;
begin
  v_admin_id := public.app_admin_user_id_from_token(p_session_token);
  if v_admin_id is null then
    raise exception 'Not authorized';
  end if;

  v_email := lower(trim(coalesce(p_email, '')));
  v_role := lower(trim(coalesce(p_role, '')));

  if char_length(trim(coalesce(p_full_name, ''))) < 2 then
    raise exception 'Full name must be at least 2 characters';
  end if;

  if position('@' in v_email) <= 1 then
    raise exception 'Invalid email address';
  end if;

  if char_length(coalesce(p_password, '')) < 6 then
    raise exception 'Password must be at least 6 characters';
  end if;

  if v_role not in ('admin', 'mentor') then
    raise exception 'Role must be admin or mentor';
  end if;

  if exists (select 1 from public.app_users u where lower(u.email) = v_email) then
    raise exception 'Email already registered';
  end if;

  insert into public.app_users (
    full_name,
    email,
    password_hash,
    role,
    is_active
  ) values (
    trim(p_full_name),
    v_email,
    extensions.crypt(p_password, extensions.gen_salt('bf')),
    v_role,
    coalesce(p_is_active, true)
  )
  returning * into v_user;

  return jsonb_build_object(
    'id', v_user.id,
    'full_name', v_user.full_name,
    'email', v_user.email,
    'role', v_user.role,
    'is_active', v_user.is_active,
    'created_at', v_user.created_at
  );
end;
$$;

create or replace function public.app_admin_list_team_users(
  p_session_token text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.app_admin_user_id_from_token(p_session_token);

  return coalesce(
    (
      select jsonb_agg(to_jsonb(u))
      from (
        select id, full_name, email, role, is_active, created_at
        from public.app_users
        where role in ('admin', 'mentor')
        order by role asc, created_at desc
      ) u
    ),
    '[]'::jsonb
  );
end;
$$;

create or replace function public.app_user_get_or_create_chat_thread(
  p_session_token text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user public.app_users;
  v_thread public.mentor_chat_threads;
begin
  v_user := public.app_session_user_from_token(p_session_token);

  if v_user.role <> 'user' then
    raise exception 'Only user accounts can open this chat';
  end if;

  select *
  into v_thread
  from public.mentor_chat_threads t
  where t.user_id = v_user.id
  limit 1;

  if not found then
    insert into public.mentor_chat_threads (user_id)
    values (v_user.id)
    returning * into v_thread;
  end if;

  return jsonb_build_object(
    'id', v_thread.id,
    'user_id', v_thread.user_id,
    'assigned_mentor_id', v_thread.assigned_mentor_id,
    'status', v_thread.status,
    'created_at', v_thread.created_at,
    'updated_at', v_thread.updated_at
  );
end;
$$;

create or replace function public.app_user_list_chat_messages(
  p_session_token text,
  p_thread_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user public.app_users;
begin
  v_user := public.app_session_user_from_token(p_session_token);

  if not exists (
    select 1
    from public.mentor_chat_threads t
    where t.id = p_thread_id
      and t.user_id = v_user.id
  ) then
    raise exception 'Thread not found';
  end if;

  return coalesce(
    (
      select jsonb_agg(to_jsonb(m))
      from (
        select id, thread_id, sender_user_id, sender_role, message_text, created_at
        from public.mentor_chat_messages
        where thread_id = p_thread_id
        order by created_at asc
      ) m
    ),
    '[]'::jsonb
  );
end;
$$;

create or replace function public.app_user_send_chat_message(
  p_session_token text,
  p_thread_id uuid,
  p_message_text text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user public.app_users;
  v_msg public.mentor_chat_messages;
begin
  v_user := public.app_session_user_from_token(p_session_token);

  if v_user.role <> 'user' then
    raise exception 'Only user accounts can send from this endpoint';
  end if;

  if not exists (
    select 1
    from public.mentor_chat_threads t
    where t.id = p_thread_id
      and t.user_id = v_user.id
  ) then
    raise exception 'Thread not found';
  end if;

  insert into public.mentor_chat_messages (
    thread_id,
    sender_user_id,
    sender_role,
    message_text
  ) values (
    p_thread_id,
    v_user.id,
    'user',
    trim(coalesce(p_message_text, ''))
  )
  returning * into v_msg;

  update public.mentor_chat_threads
  set updated_at = now()
  where id = p_thread_id;

  return to_jsonb(v_msg);
end;
$$;

create or replace function public.app_admin_list_chat_threads(
  p_session_token text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_id uuid;
begin
  v_actor_id := public.app_admin_or_mentor_user_id_from_token(p_session_token);

  return coalesce(
    (
      select jsonb_agg(to_jsonb(x))
      from (
        select
          t.id,
          t.user_id,
          u.full_name as user_name,
          u.email as user_email,
          t.status,
          t.updated_at,
          (
            select m.message_text
            from public.mentor_chat_messages m
            where m.thread_id = t.id
            order by m.created_at desc
            limit 1
          ) as last_message,
          (
            select m.created_at
            from public.mentor_chat_messages m
            where m.thread_id = t.id
            order by m.created_at desc
            limit 1
          ) as last_message_at
        from public.mentor_chat_threads t
        join public.app_users u on u.id = t.user_id
        order by coalesce(
          (
            select m.created_at
            from public.mentor_chat_messages m
            where m.thread_id = t.id
            order by m.created_at desc
            limit 1
          ),
          t.updated_at
        ) desc
      ) x
    ),
    '[]'::jsonb
  );
end;
$$;

create or replace function public.app_admin_list_chat_messages(
  p_session_token text,
  p_thread_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.app_admin_or_mentor_user_id_from_token(p_session_token);

  if not exists (select 1 from public.mentor_chat_threads where id = p_thread_id) then
    raise exception 'Thread not found';
  end if;

  return coalesce(
    (
      select jsonb_agg(to_jsonb(m))
      from (
        select id, thread_id, sender_user_id, sender_role, message_text, created_at
        from public.mentor_chat_messages
        where thread_id = p_thread_id
        order by created_at asc
      ) m
    ),
    '[]'::jsonb
  );
end;
$$;

create or replace function public.app_admin_send_chat_message(
  p_session_token text,
  p_thread_id uuid,
  p_message_text text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor public.app_users;
  v_msg public.mentor_chat_messages;
begin
  v_actor := public.app_session_user_from_token(p_session_token);

  if v_actor.role not in ('admin', 'mentor') then
    raise exception 'Not authorized';
  end if;

  if not exists (select 1 from public.mentor_chat_threads where id = p_thread_id) then
    raise exception 'Thread not found';
  end if;

  insert into public.mentor_chat_messages (
    thread_id,
    sender_user_id,
    sender_role,
    message_text
  ) values (
    p_thread_id,
    v_actor.id,
    v_actor.role,
    trim(coalesce(p_message_text, ''))
  )
  returning * into v_msg;

  update public.mentor_chat_threads
  set
    assigned_mentor_id = case
      when v_actor.role = 'mentor' then v_actor.id
      else assigned_mentor_id
    end,
    updated_at = now()
  where id = p_thread_id;

  return to_jsonb(v_msg);
end;
$$;

create or replace function public.app_get_parent_feedback(
  p_session_token text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_user public.app_users;
begin
  v_user_id := null;

  if coalesce(p_session_token, '') <> '' then
    begin
      v_user := public.app_session_user_from_token(p_session_token);
      v_user_id := v_user.id;
    exception
      when others then
        v_user_id := null;
    end;
  end if;

  return coalesce(
    (
      select jsonb_agg(to_jsonb(x))
      from (
        select
          f.id,
          f.parent_names,
          f.story_title,
          f.story_body,
          coalesce(f.child_name, '') as child_name,
          f.like_count,
          f.created_at,
          case
            when v_user_id is null then false
            else exists (
              select 1
              from public.parent_feedback_likes l
              where l.feedback_id = f.id
                and l.user_id = v_user_id
            )
          end as liked_by_me
        from public.parent_feedback f
        where f.is_published = true
        order by f.like_count desc, f.created_at desc
      ) x
    ),
    '[]'::jsonb
  );
end;
$$;

create or replace function public.app_submit_parent_feedback(
  p_session_token text,
  p_parent_names text,
  p_story_title text,
  p_story_body text,
  p_child_name text default null,
  p_confirm_adopted boolean default false,
  p_accept_terms boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user public.app_users;
  v_row public.parent_feedback;
begin
  v_user := public.app_session_user_from_token(p_session_token);

  if v_user.role <> 'user' then
    raise exception 'Only user accounts can submit parent feedback';
  end if;

  if coalesce(p_confirm_adopted, false) is false then
    raise exception 'Please confirm this is from a completed adoption journey';
  end if;

  if coalesce(p_accept_terms, false) is false then
    raise exception 'You must accept terms and conditions before submitting';
  end if;

  insert into public.parent_feedback (
    user_id,
    parent_names,
    story_title,
    story_body,
    child_name,
    confirm_adopted,
    accept_terms
  ) values (
    v_user.id,
    trim(coalesce(p_parent_names, '')),
    trim(coalesce(p_story_title, '')),
    trim(coalesce(p_story_body, '')),
    nullif(trim(coalesce(p_child_name, '')), ''),
    true,
    true
  )
  returning * into v_row;

  return jsonb_build_object(
    'id', v_row.id,
    'parent_names', v_row.parent_names,
    'story_title', v_row.story_title,
    'story_body', v_row.story_body,
    'child_name', coalesce(v_row.child_name, ''),
    'like_count', v_row.like_count,
    'liked_by_me', false,
    'created_at', v_row.created_at
  );
end;
$$;

create or replace function public.app_toggle_parent_feedback_like(
  p_session_token text,
  p_feedback_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user public.app_users;
  v_liked boolean;
  v_like_count int;
begin
  v_user := public.app_session_user_from_token(p_session_token);

  if not exists (
    select 1
    from public.parent_feedback f
    where f.id = p_feedback_id
      and f.is_published = true
  ) then
    raise exception 'Story not found';
  end if;

  if exists (
    select 1
    from public.parent_feedback_likes l
    where l.feedback_id = p_feedback_id
      and l.user_id = v_user.id
  ) then
    delete from public.parent_feedback_likes
    where feedback_id = p_feedback_id
      and user_id = v_user.id;
    v_liked := false;
  else
    insert into public.parent_feedback_likes (feedback_id, user_id)
    values (p_feedback_id, v_user.id);
    v_liked := true;
  end if;

  select count(*)::int
  into v_like_count
  from public.parent_feedback_likes
  where feedback_id = p_feedback_id;

  update public.parent_feedback
  set
    like_count = v_like_count,
    updated_at = now()
  where id = p_feedback_id;

  return jsonb_build_object('liked', v_liked, 'like_count', v_like_count);
end;
$$;

revoke all on function public.app_session_user_from_token(text) from public;
revoke all on function public.app_admin_or_mentor_user_id_from_token(text) from public;
revoke all on function public.app_admin_create_user(text, text, text, text, text, boolean) from public;
revoke all on function public.app_admin_list_team_users(text) from public;
revoke all on function public.app_user_get_or_create_chat_thread(text) from public;
revoke all on function public.app_user_list_chat_messages(text, uuid) from public;
revoke all on function public.app_user_send_chat_message(text, uuid, text) from public;
revoke all on function public.app_admin_list_chat_threads(text) from public;
revoke all on function public.app_admin_list_chat_messages(text, uuid) from public;
revoke all on function public.app_admin_send_chat_message(text, uuid, text) from public;
revoke all on function public.app_get_parent_feedback(text) from public;
revoke all on function public.app_submit_parent_feedback(text, text, text, text, text, boolean, boolean) from public;
revoke all on function public.app_toggle_parent_feedback_like(text, uuid) from public;

grant execute on function public.app_session_user_from_token(text) to anon, authenticated, service_role;
grant execute on function public.app_admin_or_mentor_user_id_from_token(text) to anon, authenticated, service_role;
grant execute on function public.app_admin_create_user(text, text, text, text, text, boolean) to anon, authenticated, service_role;
grant execute on function public.app_admin_list_team_users(text) to anon, authenticated, service_role;
grant execute on function public.app_user_get_or_create_chat_thread(text) to anon, authenticated, service_role;
grant execute on function public.app_user_list_chat_messages(text, uuid) to anon, authenticated, service_role;
grant execute on function public.app_user_send_chat_message(text, uuid, text) to anon, authenticated, service_role;
grant execute on function public.app_admin_list_chat_threads(text) to anon, authenticated, service_role;
grant execute on function public.app_admin_list_chat_messages(text, uuid) to anon, authenticated, service_role;
grant execute on function public.app_admin_send_chat_message(text, uuid, text) to anon, authenticated, service_role;
grant execute on function public.app_get_parent_feedback(text) to anon, authenticated, service_role;
grant execute on function public.app_submit_parent_feedback(text, text, text, text, text, boolean, boolean) to anon, authenticated, service_role;
grant execute on function public.app_toggle_parent_feedback_like(text, uuid) to anon, authenticated, service_role;

-- Default Child Development Programs.
delete from public.program_catalog
where title in (
  'Art & Creativity',
  'Sensory & Motor Skills',
  'Social & Emotional Learning',
  'Physical Wellness & Play',
  'Literacy & Storytelling',
  'Life Skills & Independence'
);

insert into public.program_catalog (
  title,
  description,
  icon_key,
  image_url,
  color_hex,
  is_active,
  display_order
)
values
  (
    'Art & Creativity',
    'Encouraging self-expression through drawing, painting, and crafts, helping children develop confidence and imagination.',
    'palette',
    'https://images.pexels.com/photos/8613089/pexels-photo-8613089.jpeg?auto=compress&cs=tinysrgb&w=800',
    '#FF8C42',
    true,
    1
  ),
  (
    'Sensory & Motor Skills',
    'Hands-on activities like building blocks and puzzles to enhance cognitive development and fine motor skills.',
    'sports',
    'https://images.pexels.com/photos/3662667/pexels-photo-3662667.jpeg?auto=compress&cs=tinysrgb&w=800',
    '#4FA8D5',
    true,
    2
  ),
  (
    'Social & Emotional Learning',
    'Group activities and role-playing games to help children express emotions, build friendships, and develop empathy.',
    'people',
    'https://images.pexels.com/photos/8613318/pexels-photo-8613318.jpeg?auto=compress&cs=tinysrgb&w=800',
    '#6D83F2',
    true,
    3
  ),
  (
    'Physical Wellness & Play',
    'Engaging in fun sports, dance, and movement-based activities to improve fitness and teamwork.',
    'run',
    'https://images.pexels.com/photos/296301/pexels-photo-296301.jpeg?auto=compress&cs=tinysrgb&w=800',
    '#4CAF50',
    true,
    4
  ),
  (
    'Literacy & Storytelling',
    'Interactive reading sessions, storytelling, and basic literacy skills to boost communication and comprehension.',
    'book',
    'https://images.pexels.com/photos/8613183/pexels-photo-8613183.jpeg?auto=compress&cs=tinysrgb&w=800',
    '#A55EEA',
    true,
    5
  ),
  (
    'Life Skills & Independence',
    'Teaching daily life skills like hygiene, organization, and responsibility to help children adapt to new environments.',
    'school',
    'https://images.pexels.com/photos/7713321/pexels-photo-7713321.jpeg?auto=compress&cs=tinysrgb&w=800',
    '#F4A261',
    true,
    6
  );

commit;
