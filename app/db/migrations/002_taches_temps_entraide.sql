-- 002 — Tâches, temps passé, propositions d'entraide (SPEC-002 §2).
-- Déclencheurs : horodatage, et expiration des propositions ouvertes à la réaffectation ou au passage à « done »
-- (SPEC-002 §2 et 002.18). Les déclencheurs sont SECURITY DEFINER : ils n'exigent aucun droit de l'appelant.

create table public.tasks (
  id             uuid primary key default gen_random_uuid(),
  title          text not null check (char_length(btrim(title)) between 1 and 200),
  description    text check (char_length(description) <= 4000),
  estimate_hours numeric(6,2) not null check (estimate_hours > 0 and estimate_hours <= 1000),
  status         text not null default 'todo' check (status in ('todo', 'in_progress', 'done')),
  assignee_id    uuid not null references public.profiles(id),
  created_by     uuid not null default auth.uid() references public.profiles(id),
  due_date       date,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create index tasks_assignee_id_idx on public.tasks (assignee_id);

create table public.time_entries (
  id         uuid primary key default gen_random_uuid(),
  task_id    uuid not null references public.tasks(id),
  user_id    uuid not null default auth.uid() references public.profiles(id),
  minutes    integer not null check (minutes between 1 and 1440),
  work_date  date not null default current_date,
  created_at timestamptz not null default now()
);

create index time_entries_task_id_idx on public.time_entries (task_id);

create table public.help_proposals (
  id         uuid primary key default gen_random_uuid(),
  task_id    uuid not null references public.tasks(id),
  kind       text not null check (kind in ('offer', 'request')),
  from_user  uuid not null references public.profiles(id),
  to_user    uuid not null references public.profiles(id),
  status     text not null default 'pending' check (status in ('pending', 'accepted', 'refused', 'expired')),
  created_at timestamptz not null default now(),
  decided_at timestamptz,
  constraint help_proposals_destinataire_distinct check (to_user <> from_user)
);

create unique index help_proposals_pending_unique
  on public.help_proposals (task_id, kind, from_user, to_user)
  where status = 'pending';

-- ------------------------------------------------------------------ déclencheurs
create or replace function private.toucher_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger tasks_touch_updated_at
  before update on public.tasks
  for each row execute function private.toucher_updated_at();

-- Réaffectation ou passage à « done » : les propositions encore en attente deviennent « expired ».
-- La proposition acceptée a déjà le statut « accepted » au moment de la réaffectation : elle n'est pas touchée.
create or replace function private.expirer_propositions_ouvertes()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.assignee_id is distinct from old.assignee_id
     or (new.status = 'done' and old.status is distinct from 'done') then
    update public.help_proposals
       set status = 'expired', decided_at = now()
     where task_id = new.id and status = 'pending';
  end if;
  return new;
end;
$$;

create trigger tasks_expire_propositions
  after update of assignee_id, status on public.tasks
  for each row execute function private.expirer_propositions_ouvertes();
