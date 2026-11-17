# SPEC-002 — Modèle de données, RLS, charge projetée et entraide

Itération 002. Décision : ADR-005. Couvre CA-002-4, 8, 9, 11, 13 à 36 (côté base).
Toutes les vérifications [T] passent **par l'API** (`$APP_URL/auth/v1`, `$APP_URL/rest/v1`)
depuis le runner, avec de vrais comptes créés par `/auth/v1/signup` et activés par l'admin
(identifiants lus dans `/workspace/.devenv/secrets/dev.env`).
Les noms ci-dessous (tables, colonnes, fonctions) sont **contractuels** : le testeur les utilise.

## 1. Schémas et rôles
- `public` : tables, vues et RPC exposées par PostgREST. `private` : fonctions d'aide et journal
  de migrations, non exposé. `auth` : géré par GoTrue, jamais modifié par les migrations
  applicatives (sauf trigger `on_auth_user_created`).
- `anon` : **aucun** privilège sur les objets de `public` (hors ce que PostgREST exige pour
  l'OpenAPI). `authenticated` : privilèges listés ci-dessous, toujours bornés par la RLS.

## 2. Tables

### `profiles`
| Colonne | Type | Contraintes |
|---|---|---|
| `id` | `uuid` | PK, FK `auth.users(id)` `ON DELETE CASCADE` |
| `display_name` | `text` | `NOT NULL`, `char_length(btrim(display_name)) BETWEEN 1 AND 80` |
| `role` | `text` | `NOT NULL DEFAULT 'member'`, `CHECK (role IN ('admin','member'))` |
| `is_active` | `boolean` | `NOT NULL DEFAULT false` |
| `created_at` | `timestamptz` | `NOT NULL DEFAULT now()` |
| `activated_at` | `timestamptz` | NULL tant que jamais activé |

Créée par trigger `AFTER INSERT ON auth.users` (`SECURITY DEFINER`) : `display_name` =
`raw_user_meta_data->>'display_name'` (à défaut, partie locale de l'e-mail), `role='member'`,
`is_active=false`. L'e-mail n'est pas dupliqué : il reste dans `auth.users`.

### `tasks`
| Colonne | Type | Contraintes |
|---|---|---|
| `id` | `uuid` | PK `DEFAULT gen_random_uuid()` |
| `title` | `text` | `NOT NULL`, `char_length(btrim(title)) BETWEEN 1 AND 200` |
| `description` | `text` | NULL, ≤ 4000 caractères |
| `estimate_hours` | `numeric(6,2)` | `NOT NULL`, `CHECK (estimate_hours > 0 AND estimate_hours <= 1000)` |
| `status` | `text` | `NOT NULL DEFAULT 'todo'`, `CHECK (status IN ('todo','in_progress','done'))` |
| `assignee_id` | `uuid` | `NOT NULL`, FK `profiles(id)` |
| `created_by` | `uuid` | `NOT NULL DEFAULT auth.uid()`, FK `profiles(id)` |
| `due_date` | `date` | NULL (Could, US-16) |
| `created_at`, `updated_at` | `timestamptz` | `NOT NULL DEFAULT now()` ; `updated_at` mis à jour par trigger |

### `time_entries`
| Colonne | Type | Contraintes |
|---|---|---|
| `id` | `uuid` | PK |
| `task_id` | `uuid` | `NOT NULL`, FK `tasks(id)` |
| `user_id` | `uuid` | `NOT NULL DEFAULT auth.uid()`, FK `profiles(id)` |
| `minutes` | `integer` | `NOT NULL`, `CHECK (minutes BETWEEN 1 AND 1440)` |
| `work_date` | `date` | `NOT NULL DEFAULT current_date` |
| `created_at` | `timestamptz` | `NOT NULL DEFAULT now()` |

### `help_proposals`
| Colonne | Type | Contraintes |
|---|---|---|
| `id` | `uuid` | PK |
| `task_id` | `uuid` | `NOT NULL`, FK `tasks(id)` |
| `kind` | `text` | `CHECK (kind IN ('offer','request'))` — `offer` = « Proposer mon aide », `request` = « Demander de l'aide » |
| `from_user` | `uuid` | `NOT NULL`, FK `profiles(id)` (émetteur) |
| `to_user` | `uuid` | `NOT NULL`, FK `profiles(id)` (destinataire), `CHECK (to_user <> from_user)` |
| `status` | `text` | `NOT NULL DEFAULT 'pending'`, `CHECK (status IN ('pending','accepted','refused','expired'))` |
| `created_at` | `timestamptz` | `NOT NULL DEFAULT now()` |
| `decided_at` | `timestamptz` | NULL tant que `pending` |

Index unique partiel : une seule proposition `pending` par `(task_id, kind, from_user, to_user)`.
Trigger sur `tasks` : tout changement d'`assignee_id` ou passage à `status='done'` fait passer à
`expired` les propositions `pending` de la tâche (sauf celle en cours d'acceptation).

## 3. Fonctions d'aide (`private`, `SECURITY DEFINER`, `STABLE`)
- `private.is_active_member()` → `boolean` : profil de `auth.uid()` existe et `is_active`.
- `private.is_admin()` → `boolean` : actif et `role='admin'`.

## 4. Vues (`security_invoker = true`, lecture `authenticated` uniquement)
- `task_summary` : colonnes de `tasks` + `logged_hours` (= `coalesce(sum(minutes),0)/60.0` sur
  **toutes** les saisies de la tâche, quel qu'en soit l'auteur) + `remaining_hours`
  (= `greatest(estimate_hours − logged_hours, 0)`) + `assignee_name`.
- `team_load` : une ligne par profil **actif** : `user_id`, `display_name`, `open_tasks`
  (nombre de tâches non terminées), `projected_hours`, `overloaded`.
  - **`projected_hours` = `round(Σ remaining_hours des tâches non terminées affectées × 4) / 4`**
    (arrondi au 0,25 h le plus proche, 0 si aucune tâche).
  - **`overloaded` = `projected_hours > 7`** (seuil fixe, strict).

## 5. RLS et privilèges (`authenticated`)
| Objet | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| `profiles` | si `is_active_member()` : profils actifs ; si `is_admin()` : tous | — | — (RPC) | — |
| `tasks` | si `is_active_member()` : toutes | si actif, `assignee_id = auth.uid()` et `created_by = auth.uid()` | colonnes `title, description, estimate_hours, status, due_date` si actif et (`assignee_id = auth.uid()` ou `created_by = auth.uid()`) | — |
| `time_entries` | si actif : toutes | si actif, `user_id = auth.uid()` et tâche affectée à `auth.uid()` | — | — |
| `help_proposals` | si actif et (`from_user` ou `to_user` = `auth.uid()`) | — (RPC) | — (RPC) | — |
| vues `task_summary`, `team_load` | héritent de la RLS | — | — | — |

## 6. RPC (`public`, `SECURITY DEFINER`, `EXECUTE` à `authenticated` seulement)
Chaque RPC, **sauf `my_status()`**, vérifie d'abord `is_active_member()` (sinon erreur `DNUM:compte_inactif`).

| RPC | Effet | Refus (erreur) |
|---|---|---|
| `my_status()` → `{is_active, role, display_name}` | état du compte appelant (seule information accessible à un compte non activé) | — |
| `admin_list_accounts()` → `(id, display_name, email, role, is_active, created_at, activated_at)` | liste tous les comptes | non admin |
| `admin_set_active(p_user uuid, p_active boolean)` | active (`activated_at=now()`) / désactive | non admin ; cible = soi-même ou un admin en désactivation |
| `reassign_task(p_task uuid, p_to uuid)` | `assignee_id := p_to` | appelant ≠ affecté actuel ; cible non active ou inexistante ; tâche terminée ; cible = affecté |
| `offer_help(p_task uuid)` → id | crée `kind='offer'`, `from=auth.uid()`, `to=affecté` | tâche terminée ; appelant = affecté ; doublon `pending` |
| `request_help(p_task uuid, p_to uuid)` → id | crée `kind='request'`, `from=auth.uid()`, `to=p_to` | appelant ≠ affecté ; `p_to` non actif ou = soi ; tâche terminée ; doublon |
| `respond_proposal(p_id uuid, p_accept boolean)` | si accepte : verrouille la tâche, vérifie qu'elle n'est pas terminée et que l'affecté est toujours celui attendu (`offer` : `to_user` ; `request` : `from_user`), affecte à `from_user` (`offer`) ou `to_user` (`request`), passe à `accepted` ; sinon `refused`. `decided_at=now()` | appelant ≠ `to_user` ; statut ≠ `pending` ; tâche terminée / réaffectée |

## 7. Exigences vérifiables

| Id | Exigence | CA | Vérification |
|---|---|---|---|
| SPEC-002.1 | Toutes les tables de `public` ont la RLS activée **et forcée** ; `anon` n'a aucun privilège `SELECT/INSERT/UPDATE/DELETE` sur elles ni `EXECUTE` sur les RPC métier. | CA-002-11 | [T] via l'API (SPEC-002.2/3) ; [R] requête `pg_class.relforcerowsecurity` / `information_schema.role_table_grants` par `psql` dans `db` (le runner n'accède pas à `db`) |
| SPEC-002.2 | Sans jeton (clé `anon` seule) : `GET/POST` sur `profiles`, `tasks`, `time_entries`, `help_proposals`, `task_summary`, `team_load` et appels RPC métier ⇒ 401/403 ou `[]`, jamais une ligne ; aucune écriture effective. | CA-002-11 | [T] |
| SPEC-002.3 | Avec le jeton d'un compte inscrit **non activé** : mêmes lectures ⇒ `[]` ou refus ; `POST tasks`, `POST time_entries`, RPC ⇒ refus ; `my_status()` ⇒ `is_active=false`. | CA-002-10, CA-002-11 | [T] |
| SPEC-002.4 | Après inscription, un profil existe avec `role='member'`, `is_active=false`, `display_name` saisi ; il apparaît dans `admin_list_accounts()` (admin) et pas dans `team_load`. | CA-002-6, CA-002-8, CA-002-24 | [T] |
| SPEC-002.5 | `admin_set_active(u, true)` par l'admin active `u` ; par un membre non admin ⇒ refus et `u` reste inactif. Un membre ne peut pas modifier `profiles` directement (`PATCH /profiles` ⇒ refus / 0 ligne, `role`/`is_active` inchangés). | CA-002-8, CA-002-9 | [T] |
| SPEC-002.6 | Après activation, le jeton **nouvellement obtenu** du compte voit `team_load` et `tasks`. | CA-002-12 | [T] |
| SPEC-002.7 | `POST tasks` par un membre actif avec `title`, `estimate_hours>0` et `assignee_id=moi` ⇒ 201, `status='todo'`, `created_by=moi`. Titre vide/espaces, estimation absente, 0 ou négative ⇒ 400 sans création. `assignee_id ≠ moi` ⇒ refus. | CA-002-13, CA-002-14 | [T] |
| SPEC-002.8 | `PATCH tasks` (titre, description, estimation, statut) par l'affecté ou le créateur ⇒ appliqué ; par un tiers ⇒ 0 ligne modifiée / refus ; `PATCH assignee_id` ou `created_by` directement ⇒ refus pour tous. | CA-002-15, CA-002-16 | [T] |
| SPEC-002.9 | Un membre actif lit les tâches d'un autre via `task_summary?assignee_id=eq.<id>` (titre, statut, estimation, `logged_hours`). | CA-002-17 | [T] |
| SPEC-002.10 | `POST time_entries` par l'affecté, `minutes` ∈ [1,1440] ⇒ 201 et `logged_hours` augmente de `minutes/60` ; `minutes` ≤ 0 ou > 1440 ⇒ 400 ; par un non-affecté ⇒ refus. `work_date` par défaut = date du jour. | CA-002-18, CA-002-19, CA-002-20 | [T] |
| SPEC-002.11 | **Jeu de référence** : pour un membre ayant A (4 h, 60 min loguées, `todo`), B (2 h, 180 min, `in_progress`), C (5 h, `done`) ⇒ `team_load.projected_hours = 3.00`, `overloaded = false`. | CA-002-22 | [T] |
| SPEC-002.12 | Seuil : tâches restantes totalisant 7,00 h ⇒ `overloaded=false` ; 7,25 h ⇒ `true` ; passage d'une tâche à `done` ramenant ≤ 7 h ⇒ `false`. Arrondi : reste 1 h 10 ⇒ 1,25 ; 1 h 05 ⇒ 1,00. | CA-002-22, CA-002-23 | [T] |
| SPEC-002.13 | `team_load` ne contient que les profils actifs ; un compte non activé ou désactivé n'y figure pas. | CA-002-21, CA-002-24 | [T] |
| SPEC-002.14 | `reassign_task` par l'affecté vers un membre actif ⇒ `assignee_id` changé, `team_load` des deux recalculé ; vers un compte non actif, ou appelée par un non-affecté (y compris le créateur non affecté) ⇒ refus, affectation inchangée. | CA-002-25, CA-002-26 | [T] |
| SPEC-002.15 | `offer_help` crée une proposition `pending` visible par l'émetteur et le destinataire (affecté), invisible des tiers ; sur une tâche `done` ou par l'affecté lui-même ⇒ refus. | CA-002-27 | [T] |
| SPEC-002.16 | `request_help` par l'affecté vers un membre actif crée une proposition `pending` reçue par celui-ci ; vers un non actif ⇒ refus. | CA-002-28 | [T] |
| SPEC-002.17 | `respond_proposal(id, true)` par le destinataire ⇒ `accepted` et tâche affectée au preneur (`offer` → `from_user`, `request` → `to_user`) ; `respond_proposal(id, false)` ⇒ `refused`, affectation inchangée. | CA-002-29, CA-002-30 | [T] |
| SPEC-002.18 | `respond_proposal` par un autre que `to_user` ⇒ refus ; sur une proposition non `pending` ⇒ refus ; après réaffectation ou passage à `done` de la tâche, la proposition est `expired` et ne peut plus être acceptée. | CA-002-31 | [T] |
| SPEC-002.19 | Nombre de propositions reçues en attente = `GET help_proposals?to_user=eq.<moi>&status=eq.pending` (en-tête `Prefer: count=exact`). | CA-002-32 | [T] |
| SPEC-002.20 | `admin_set_active(u, false)` (Could) : `u` disparaît de `team_load`, son jeton suivant ne voit plus aucune donnée ; l'admin ne peut se désactiver lui-même ni désactiver un admin (refus). | CA-002-34 | [T] |
| SPEC-002.21 | `due_date` (Could) facultative ; filtre « aujourd'hui » = tâches non `done` avec `due_date <= date du jour` (`task_summary?due_date=lte.<J>&status=neq.done`). | CA-002-35 | [T] |
| SPEC-002.22 | Aucun `DELETE` accordé à `authenticated` sur les tables ; `DELETE` ⇒ refus. Aucune modification de `time_entries` (`PATCH` ⇒ refus). | hors périmètre §4 | [T] |
