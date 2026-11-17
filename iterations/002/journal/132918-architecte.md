# architecte — 2026-11-17T13:29:18+00:00

## Brief
Itération 002, mission du chef de projet. Écris uniquement dans specs/. Crée specs/adr/ADR-013 (trace des décisions du chef de projet) et mets à jour README, SPEC-001.15, SPEC-006 §3 et ADR-010 si nécessaire pour la cohérence. Décisions à tracer : (1) ADR-010 est final : auth-js en cas A, BLOQUE_AUTHJS="non" dans la policy 25, cas C esbuild gardé (reprends cette formulation telle quelle ; relis ADR-010 : si « cas C esbuild gardé » contredit ton classement de esbuild en cas A, signale-le explicitement et ne tranche pas à sa place). (2) L'audit npm s'exécute hors runner : ./dev audit-npm via la toolbox écrit iterations/<NNN>/policies/audit-npm.json, que lit la policy 25 ; pas de socket Docker dans le runner. (3) git est installé dans le runner (apt, version figée par l'image de base python:3.13.1-slim) avec safe.directory /workspace, pour la policy 29 (001 à 005 comparées au commit dae9044, ADR-011). Puis, du plan de réaction AOPR §2 étape 8 (iterations/002/journal/132650-reaction.md, lecture seule) : (4) tranche email_confirmed_at avec repli confirmed_at ; (5) dis si un changement de mot de passe admin est possible depuis l'interface (recommandation du chef de projet : hors périmètre 002) ; (6) précise SPEC-003.10 face au gel : le premier ./dev deploy après la levée du gel est le deploy service. Arbitrages confirmés par le chef de projet : « Réaffecter », « Loguer du temps » et « Modifier » sans confirmation ; écart CA-002-1 « après reset » accepté. Compte rendu court : décisions, fichiers, points ouverts, et ce que la Team AOPR doit changer (policies, ./dev).

## Compte rendu
## Compte rendu architecte — mission itération 002 (écrit dans `specs/` uniquement)

Je n'ai pas pu exécuter de commande git : `dae9044` et `dfbc020` restent à vérifier par l'action.

### Décisions tracées

1. **ADR-010 final.** auth-js reste en cas A (voie 1). `BLOQUE_AUTHJS="non"` est déjà en place dans la policy 25 (ligne 17), donc l'E3 de la réaction est obsolète.
   **Contradiction signalée, non tranchée :** « cas C esbuild gardé » contredit ADR-010, qui classe esbuild en cas A. Lecture compatible : le garde `serve`/`watch`/`context(` reste et déclenche une réévaluation. Le code en fait aujourd'hui une note non bloquante, alors que la réaction supposait un blocage. Votre décision : bloquant ou note.
2. **Audit npm hors runner** (ADR-014). `./dev audit-npm` sur l'hôte écrit `audit-npm.json` et `audit-npm.meta.json` (statut, sha256 du lock) dans `iterations/<NNN>/policies/`. La policy 25 vérifie le statut et le sha256, à la place de la date. Pas de socket Docker.
3. **git dans le runner** (ADR-015). Installation par apt avec version exacte, `safe.directory /workspace` au niveau système. Policy 29 (c) : `git show dae9044:<chemin>` et sha256, sans écrire l'index.
4. **email_confirmed_at** : tranché, avec repli `confirmed_at`, sinon rc≠0. Le champ n'est lu que si le compte existe déjà (`seed.py` l. 74-75) : le premier contrôle réel a lieu au second `deploy service`, pas au premier.
5. **Mot de passe admin.** Impossible depuis l'interface (`app.js` ne consomme un mot de passe qu'à la connexion et à l'inscription). Par API, la passerelle relaie `/auth/v1/*` sauf `/admin` : un `PUT /auth/v1/user` atteint GoTrue. ADR-012 §6 est complété en conséquence. Hors périmètre 002, confirmé.
6. **SPEC-003.10 face au gel.** Le premier `deploy` après levée est `deploy service`. Le [R] est réécrit en trois étapes sur service (création, changement de mot de passe, second deploy). SPEC-003.12 (d) : `reset` seulement sur `dev`, après D4.

Arbitrages : « Réaffecter », « Loguer du temps » et « Modifier » acceptés sans confirmation (ADR-013 D-7). Écart CA-002-1 « après reset » accepté (ADR-013 D-8, SPEC-006 §2).

### Fichiers

- Créés : `adr/ADR-013-trace-decisions-chef-de-projet.md`, `adr/ADR-014-audit-npm-hors-runner.md`, `adr/ADR-015-git-dans-runner.md`
- Mis à jour : `SPEC-001` (001.15 b), `SPEC-003` (en-tête, 003.10 et 003.12 [R]), `SPEC-006` (§2 CA-002-1, §3 items 8, 9, 11, 13, 16 (c), 19), `ADR-010`, `ADR-011` (renvoi), `ADR-012` (§6), `README.md`

### Points ouverts (chef de projet)

1. Garde esbuild : bloquant ou note (ADR-013 D-1).
2. Canal `PUT /auth/v1/user` : accepter et documenter, ou fermer (itération dédiée).
3. Numéro 35 proposé pour la policy seed : à confirmer.
4. `dae9044` : non vérifiable depuis mes outils, absent du reflet HEAD. La version déployée sur `dev` est `dfbc020` (+ arbre non commité). Il faut confirmer que `001` à `005` sont identiques dans les deux commits.
5. `./dev audit-npm` doit être ajouté à SPEC-004.1 (hors périmètre de cette mission, non modifié).

### Ce que la Team AOPR doit changer

**Policies**
- **25** : lire `audit-npm.meta.json`, comparer le sha256 (retirer la comparaison de mtime). Remplacer le chemin figé `iterations/002/` par l'itération courante. Corriger le commentaire ligne 14 (« ligne 13 »). Décider bloquant ou note pour le garde esbuild.
- **29 (c)** : `git show` et sha256 uniquement, pas de `git status` ni `git diff`.
- **35** (nouvelle, `SEED-sans-ecrasement`) : contrôle statique de `seed.py` (SPEC-003.10, 003.12).

**`./dev` et outillage (action)**
- Nouvelle commande `./dev audit-npm` (hôte, image `node:22.12.0-alpine`), à ajouter à `./dev help`.
- `tools/runner/Dockerfile` : `git=<version exacte>`, relevée au build et consignée dans ADR-015. Épingler aussi `curl` et `bash`, installés sans version aujourd'hui (écart existant aux règles d'épinglage).
- Vérifier que `/workspace` contient `.git`.
