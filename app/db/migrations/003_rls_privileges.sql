-- 003 — RLS forcée et privilèges (SPEC-002 §5, ADR-005 §1-3).
-- anon : aucun privilège. authenticated : lecture sous RLS ; écriture par colonnes autorisées ;
-- aucune écriture directe sur profiles ni help_proposals (RPC uniquement) ; aucun DELETE.

-- ------------------------------------------------------------------ privilèges de base
revoke all on all tables in schema public from anon, authenticated;
grant usage on schema public to anon, authenticated;

grant select on public.profiles, public.tasks, public.time_entries, public.help_proposals to authenticated;
grant insert (title, description, estimate_hours, assignee_id, created_by, due_date) on public.tasks to authenticated;
grant update (title, description, estimate_hours, status, due_date) on public.tasks to authenticated;
grant insert (task_id, user_id, minutes, work_date) on public.time_entries to authenticated;

-- ------------------------------------------------------------------ RLS activée et forcée
alter table public.profiles enable row level security;
alter table public.profiles force row level security;
alter table public.tasks enable row level security;
alter table public.tasks force row level security;
alter table public.time_entries enable row level security;
alter table public.time_entries force row level security;
alter table public.help_proposals enable row level security;
alter table public.help_proposals force row level security;

-- ------------------------------------------------------------------ politiques
create policy profiles_lecture on public.profiles
  for select to authenticated
  using ((private.is_active_member() and is_active) or private.is_admin());

create policy tasks_lecture on public.tasks
  for select to authenticated
  using (private.is_active_member());

create policy tasks_creation on public.tasks
  for insert to authenticated
  with check (private.is_active_member() and assignee_id = auth.uid() and created_by = auth.uid());

create policy tasks_modification on public.tasks
  for update to authenticated
  using (private.is_active_member() and (assignee_id = auth.uid() or created_by = auth.uid()))
  with check (private.is_active_member() and (assignee_id = auth.uid() or created_by = auth.uid()));

create policy temps_lecture on public.time_entries
  for select to authenticated
  using (private.is_active_member());

create policy temps_creation on public.time_entries
  for insert to authenticated
  with check (
    private.is_active_member()
    and user_id = auth.uid()
    and exists (select 1 from public.tasks t where t.id = task_id and t.assignee_id = auth.uid())
  );

create policy propositions_lecture on public.help_proposals
  for select to authenticated
  using (private.is_active_member() and (from_user = auth.uid() or to_user = auth.uid()));
