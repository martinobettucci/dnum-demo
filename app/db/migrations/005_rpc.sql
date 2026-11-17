-- 005 — Fonctions RPC métier (SPEC-002 §6, ADR-005 §3 et §6).
-- Toutes SECURITY DEFINER, search_path vide, noms qualifiés. EXECUTE retiré de public et anon, accordé à authenticated.
-- Erreurs métier : RAISE EXCEPTION 'DNUM:<code>' (P0001), affichées en français par l'interface.
-- Sauf my_status(), chaque RPC vérifie d'abord que l'appelant est un membre actif.

-- ------------------------------------------------------------------ état du compte appelant
create or replace function public.my_status()
returns json
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (select json_build_object('is_active', p.is_active, 'role', p.role, 'display_name', p.display_name)
       from public.profiles p where p.id = auth.uid()),
    json_build_object('is_active', false, 'role', 'member', 'display_name', null)
  );
$$;

revoke execute on function public.my_status() from public, anon;
grant execute on function public.my_status() to authenticated;

-- ------------------------------------------------------------------ administration des comptes
create or replace function public.admin_list_accounts()
returns table (
  id uuid,
  display_name text,
  email text,
  role text,
  is_active boolean,
  created_at timestamptz,
  activated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
begin
  if not private.is_admin() then
    raise exception 'DNUM:non_autorise' using errcode = 'P0001';
  end if;
  return query
    select p.id, p.display_name, u.email::text, p.role, p.is_active, p.created_at, p.activated_at
      from public.profiles p
      join auth.users u on u.id = p.id
     order by p.created_at;
end;
$$;

revoke execute on function public.admin_list_accounts() from public, anon;
grant execute on function public.admin_list_accounts() to authenticated;

create or replace function public.admin_set_active(p_user uuid, p_active boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not private.is_admin() then
    raise exception 'DNUM:non_autorise' using errcode = 'P0001';
  end if;
  if not exists (select 1 from public.profiles p where p.id = p_user) then
    raise exception 'DNUM:cible_introuvable' using errcode = 'P0001';
  end if;
  if not p_active and (
       p_user = auth.uid()
    or exists (select 1 from public.profiles p where p.id = p_user and p.role = 'admin')
  ) then
    raise exception 'DNUM:admin_protege' using errcode = 'P0001';
  end if;
  update public.profiles p
     set is_active = p_active,
         activated_at = case when p_active then now() else p.activated_at end
   where p.id = p_user;
end;
$$;

revoke execute on function public.admin_set_active(uuid, boolean) from public, anon;
grant execute on function public.admin_set_active(uuid, boolean) to authenticated;

-- ------------------------------------------------------------------ tâches : réaffectation
create or replace function public.reassign_task(p_task uuid, p_to uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.tasks;
begin
  if not private.is_active_member() then
    raise exception 'DNUM:compte_inactif' using errcode = 'P0001';
  end if;
  select * into t from public.tasks where id = p_task for update;
  if not found then
    raise exception 'DNUM:tache_introuvable' using errcode = 'P0001';
  end if;
  if t.assignee_id <> auth.uid() then
    raise exception 'DNUM:non_autorise' using errcode = 'P0001';
  end if;
  if t.status = 'done' then
    raise exception 'DNUM:tache_terminee' using errcode = 'P0001';
  end if;
  if p_to = t.assignee_id then
    raise exception 'DNUM:cible_invalide' using errcode = 'P0001';
  end if;
  if not exists (select 1 from public.profiles p where p.id = p_to and p.is_active) then
    raise exception 'DNUM:cible_invalide' using errcode = 'P0001';
  end if;
  update public.tasks set assignee_id = p_to where id = p_task;
end;
$$;

revoke execute on function public.reassign_task(uuid, uuid) from public, anon;
grant execute on function public.reassign_task(uuid, uuid) to authenticated;

-- ------------------------------------------------------------------ entraide : propositions
create or replace function public.offer_help(p_task uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.tasks;
  pid uuid;
begin
  if not private.is_active_member() then
    raise exception 'DNUM:compte_inactif' using errcode = 'P0001';
  end if;
  select * into t from public.tasks where id = p_task for update;
  if not found then
    raise exception 'DNUM:tache_introuvable' using errcode = 'P0001';
  end if;
  if t.status = 'done' then
    raise exception 'DNUM:tache_terminee' using errcode = 'P0001';
  end if;
  if t.assignee_id = auth.uid() then
    raise exception 'DNUM:non_autorise' using errcode = 'P0001';
  end if;
  if exists (
    select 1 from public.help_proposals h
     where h.task_id = p_task and h.kind = 'offer' and h.from_user = auth.uid()
       and h.to_user = t.assignee_id and h.status = 'pending'
  ) then
    raise exception 'DNUM:doublon' using errcode = 'P0001';
  end if;
  insert into public.help_proposals (task_id, kind, from_user, to_user)
  values (p_task, 'offer', auth.uid(), t.assignee_id)
  returning id into pid;
  return pid;
end;
$$;

revoke execute on function public.offer_help(uuid) from public, anon;
grant execute on function public.offer_help(uuid) to authenticated;

create or replace function public.request_help(p_task uuid, p_to uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  t public.tasks;
  pid uuid;
begin
  if not private.is_active_member() then
    raise exception 'DNUM:compte_inactif' using errcode = 'P0001';
  end if;
  select * into t from public.tasks where id = p_task for update;
  if not found then
    raise exception 'DNUM:tache_introuvable' using errcode = 'P0001';
  end if;
  if t.status = 'done' then
    raise exception 'DNUM:tache_terminee' using errcode = 'P0001';
  end if;
  if t.assignee_id <> auth.uid() then
    raise exception 'DNUM:non_autorise' using errcode = 'P0001';
  end if;
  if p_to = auth.uid() or not exists (select 1 from public.profiles p where p.id = p_to and p.is_active) then
    raise exception 'DNUM:cible_invalide' using errcode = 'P0001';
  end if;
  if exists (
    select 1 from public.help_proposals h
     where h.task_id = p_task and h.kind = 'request' and h.from_user = auth.uid()
       and h.to_user = p_to and h.status = 'pending'
  ) then
    raise exception 'DNUM:doublon' using errcode = 'P0001';
  end if;
  insert into public.help_proposals (task_id, kind, from_user, to_user)
  values (p_task, 'request', auth.uid(), p_to)
  returning id into pid;
  return pid;
end;
$$;

revoke execute on function public.request_help(uuid, uuid) from public, anon;
grant execute on function public.request_help(uuid, uuid) to authenticated;

create or replace function public.respond_proposal(p_id uuid, p_accept boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  h public.help_proposals;
  t public.tasks;
  attendu uuid;
  preneur uuid;
begin
  if not private.is_active_member() then
    raise exception 'DNUM:compte_inactif' using errcode = 'P0001';
  end if;
  select * into h from public.help_proposals where id = p_id for update;
  if not found then
    raise exception 'DNUM:proposition_introuvable' using errcode = 'P0001';
  end if;
  if h.to_user <> auth.uid() then
    raise exception 'DNUM:non_autorise' using errcode = 'P0001';
  end if;
  if h.status = 'expired' then
    raise exception 'DNUM:proposition_non_valable' using errcode = 'P0001';
  end if;
  if h.status <> 'pending' then
    raise exception 'DNUM:proposition_traitee' using errcode = 'P0001';
  end if;
  select * into t from public.tasks where id = h.task_id for update;
  -- Aucune écriture avant un RAISE : une exception annulerait la transaction entière.
  attendu := case when h.kind = 'offer' then h.to_user else h.from_user end;
  if t.status = 'done' or t.assignee_id is distinct from attendu then
    raise exception 'DNUM:proposition_non_valable' using errcode = 'P0001';
  end if;
  if p_accept then
    preneur := case when h.kind = 'offer' then h.from_user else h.to_user end;
    if not exists (select 1 from public.profiles p where p.id = preneur and p.is_active) then
      raise exception 'DNUM:cible_invalide' using errcode = 'P0001';
    end if;
    -- Accepté AVANT la réaffectation : le déclencheur n'expire que les propositions encore « pending ».
    update public.help_proposals set status = 'accepted', decided_at = now() where id = p_id;
    update public.tasks set assignee_id = preneur where id = h.task_id;
  else
    update public.help_proposals set status = 'refused', decided_at = now() where id = p_id;
  end if;
end;
$$;

revoke execute on function public.respond_proposal(uuid, boolean) from public, anon;
grant execute on function public.respond_proposal(uuid, boolean) to authenticated;
