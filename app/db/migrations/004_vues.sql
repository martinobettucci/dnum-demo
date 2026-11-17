-- 004 — Vues de restitution (SPEC-002 §4), security_invoker : elles héritent de la RLS de l'appelant (ADR-005 §5).

-- Tâches avec temps passé (toutes saisies, quel qu'en soit l'auteur) et reste à faire.
create view public.task_summary with (security_invoker = true) as
select
  t.id,
  t.title,
  t.description,
  t.status,
  t.estimate_hours,
  t.assignee_id,
  t.created_by,
  t.due_date,
  t.created_at,
  t.updated_at,
  p.display_name as assignee_name,
  coalesce(l.minutes, 0) / 60.0 as logged_hours,
  greatest(t.estimate_hours - coalesce(l.minutes, 0) / 60.0, 0) as remaining_hours
from public.tasks t
left join public.profiles p on p.id = t.assignee_id
left join (
  select task_id, sum(minutes) as minutes
  from public.time_entries
  group by task_id
) l on l.task_id = t.id;

-- Charge par membre actif. projected_hours = Σ restant des tâches non terminées, arrondi au 0,25 h le plus proche.
-- overloaded = projected_hours > 7 (seuil strict, SPEC-002 §4).
create view public.team_load with (security_invoker = true) as
select
  p.id as user_id,
  p.display_name,
  coalesce(c.open_tasks, 0) as open_tasks,
  (round(coalesce(c.remaining, 0) * 4) / 4)::numeric(8,2) as projected_hours,
  (round(coalesce(c.remaining, 0) * 4) / 4) > 7 as overloaded
from public.profiles p
left join lateral (
  select
    count(*) as open_tasks,
    sum(greatest(t.estimate_hours - coalesce(l.minutes, 0) / 60.0, 0)) as remaining
  from public.tasks t
  left join (
    select task_id, sum(minutes) as minutes
    from public.time_entries
    group by task_id
  ) l on l.task_id = t.id
  where t.assignee_id = p.id and t.status <> 'done'
) c on true
where p.is_active;

revoke all on public.task_summary, public.team_load from anon;
grant select on public.task_summary, public.team_load to authenticated;
