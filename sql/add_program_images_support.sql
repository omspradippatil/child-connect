-- Migration: add program image support to admin/user RPCs.
-- Run this once before using program images in admin paneel.

begin;

alter table if exists public.program_catalog
add column if not exists image_url text;

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
          select id, name, age, location, story, gender, avatar_color_hex, is_active, display_order, created_at
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

drop function if exists public.app_admin_upsert_program(text, uuid, text, text, text, text, boolean, int);

create function public.app_admin_upsert_program(
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

revoke all on function public.app_admin_upsert_program(text, uuid, text, text, text, text, text, boolean, int) from public;
grant execute on function public.app_admin_upsert_program(text, uuid, text, text, text, text, text, boolean, int) to anon, authenticated, service_role;

commit;
