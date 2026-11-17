-- 001 — Socle : schéma privé, profils, fonctions d'aide, création du profil à l'inscription.
-- SPEC-002 §1-2-3, ADR-005. Exécuté par supabase_admin après le démarrage sain de auth (SPEC-004.12).
-- Aucune instruction de transaction ici : psql --single-transaction par fichier (db.sh).

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;

-- L'image Supabase accorde ALL sur les objets de public à anon/authenticated par défaut : on retire.
alter default privileges for role supabase_admin in schema public revoke all on tables from anon, authenticated;
alter default privileges for role supabase_admin in schema public revoke execute on functions from public, anon;

-- ------------------------------------------------------------------ profils (SPEC-002 §2)
create table public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(btrim(display_name)) between 1 and 80),
  role         text not null default 'member' check (role in ('admin', 'member')),
  is_active    boolean not null default false,
  created_at   timestamptz not null default now(),
  activated_at timestamptz
);

-- ------------------------------------------------------------------ fonctions d'aide (SPEC-002 §3)
create or replace function private.is_active_member()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_active);
$$;

create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_active and p.role = 'admin');
$$;

revoke all on function private.is_active_member() from public;
revoke all on function private.is_admin() from public;
grant execute on function private.is_active_member(), private.is_admin() to authenticated;

-- ------------------------------------------------------------------ inscription -> profil inactif
create or replace function private.creer_profil_inscription()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name, role, is_active)
  values (
    new.id,
    left(coalesce(
      nullif(btrim(new.raw_user_meta_data ->> 'display_name'), ''),
      nullif(split_part(new.email, '@', 1), ''),
      'Membre'), 80),
    'member',
    false
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.creer_profil_inscription();
