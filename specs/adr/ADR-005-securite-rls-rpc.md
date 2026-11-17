# ADR-005 — Modèle de sécurité : RLS partout, écritures sensibles par fonctions RPC

Statut : accepté (itération 002) — couvre CA-002-9, CA-002-11, CA-002-16, CA-002-20, CA-002-26, CA-002-31.

## Contexte
L'API REST est directement joignable par tout navigateur (même origine, clé anonyme publique).
L'interface ne protège rien : **toute règle d'accès doit être appliquée par la base**.
Un compte inscrit mais non activé possède un JWT valide (`role=authenticated`) : être
authentifié ne suffit donc pas.

## Décision
1. **RLS activée et forcée** (`ENABLE` + `FORCE ROW LEVEL SECURITY`) sur toutes les tables de
   `public`. Le rôle `anon` n'a **aucun** privilège sur ces tables, vues et fonctions métier.
2. Toute politique d'accès d'`authenticated` commence par `private.is_active_member()`
   (profil de `auth.uid()` avec `is_active = true`). Fonctions d'aide dans un schéma `private`
   **non exposé** par PostgREST, `SECURITY DEFINER`, `STABLE`, `search_path` fixé.
3. **Privilèges de colonnes** : `authenticated` ne peut modifier, sur `tasks`, que `title`,
   `description`, `estimate_hours`, `status`, `due_date`. `assignee_id`, `created_by`,
   `profiles.*`, `help_proposals.*` ne sont modifiables que via des fonctions RPC
   `SECURITY DEFINER` qui vérifient elles-mêmes les droits et les invariants dans une
   transaction (verrou `FOR UPDATE` sur la tâche).
4. Aucune suppression (`DELETE` non accordé), conformément au hors-périmètre.
5. Les vues de restitution sont `security_invoker = true` : elles héritent de la RLS de l'appelant.
6. Les erreurs métier des RPC sont levées avec un `SQLSTATE` dédié et un message français
   affichable (`RAISE EXCEPTION … USING ERRCODE = 'P0001'`, préfixe stable, ex.
   `DNUM:non_autorise`), que PostgREST renvoie en HTTP 400/403.

## Conséquences
- Les tests automatiques peuvent prouver chaque règle par l'API seule (SPEC-006).
- Toute nouvelle table doit suivre (1)-(2) ; une policy vérifie que chaque table de `public` a la
  RLS forcée et aucun privilège pour `anon`.
