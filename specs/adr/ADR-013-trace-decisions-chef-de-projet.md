# ADR-013 — Trace des décisions du chef de projet (itération 002, 2026-11-17)

Statut : accepté (trace). Itération 002.
Source : réaction AOPR consignée (`iterations/002/journal/132650-reaction.md`, lecture seule) et arbitrages du chef de
projet du 2026-11-17.
Specs et ADR touchés : ADR-010 (contrôle continu, historique), ADR-011 (renvoi), ADR-012 (§6 complété), ADR-014 et
ADR-015 (nouveaux), SPEC-001.15 (b), SPEC-003 (003.10, 003.12 (d), en-tête), SPEC-006 (§2 CA-002-1, §3), `README.md`.

## Contexte

La réaction AOPR a relevé deux policies violées (25 et 29), une contradiction entre la policy 25 et ADR-010, et plusieurs
décisions à prendre. Le chef de projet a tranché. Cet ADR persiste ces décisions pour que les specs, les policies et
`./dev` les suivent. Il ne crée aucune exigence hors des fichiers listés.

Constat de l'architecte, à l'écriture de cet ADR : le relevé de réaction (E3) annonçait `BLOQUE_AUTHJS="oui"` dans la
policy 25. Le fichier `policies/checks/25-front-audit-npm.sh` porte déjà `BLOQUE_AUTHJS="non"` (ligne 17). Ce point
n'est donc plus un écart de fichier, seulement une observation obsolète.

## Décisions

| Id | Sujet | Décision | Specs / ADR | Statut |
|---|---|---|---|---|
| D-1 | ADR-010 final, policy 25 | auth-js : cas A (voie 1). `BLOQUE_AUTHJS="non"`. Garde esbuild : libellé du chef de projet « cas C esbuild gardé » **signalé, non tranché** | ADR-010, SPEC-001.15 (b)(d) | cas A et `BLOQUE_AUTHJS` tranchés ; garde esbuild **ouvert** |
| D-2 | Audit npm hors runner | `./dev audit-npm` (hôte, toolbox) écrit `iterations/<NNN>/policies/audit-npm.json` ; la policy 25 le lit. Pas de socket Docker dans le runner | ADR-014, SPEC-001.15 (b), SPEC-006 §3 (25) | tranché |
| D-3 | git dans le runner | git installé dans l'image runner par apt, version exacte, `safe.directory /workspace` ; référence `dae9044` pour la policy 29 (c) | ADR-015, ADR-011, SPEC-006 §3 (16) | tranché ; version apt à relever |
| D-4 | Confirmation de l'admin (GoTrue) | `email_confirmed_at`, repli `confirmed_at`, sinon rc≠0 | SPEC-003.11, ADR-012 | tranché ; premier contrôle réel repoussé (voir D-4) |
| D-5 | Changement du mot de passe admin | Pas dans l'interface. Hors périmètre 002 (confirmé). Canal API existant, non spécifié | ADR-012 §6 (complété) | tranché ; canal API **ouvert** |
| D-6 | SPEC-003.10 face au gel | Le premier `./dev deploy` après levée du gel est `./dev deploy service`. Les [R] de 003.10 et 003.12 (d) sont réécrits pour service | SPEC-003 | tranché |
| D-7 | Arbitrages d'interface | « Réaffecter », « Loguer du temps » et « Modifier » sans message de confirmation : accepté pour 002 | SPEC-005 (défauts connus) | tranché |
| D-8 | Écart CA-002-1 « après reset » | Accepté. Remplacé par le déploiement à blanc de service | SPEC-001.4, SPEC-006 §2 | tranché |

## D-1 — ADR-010 final, policy 25, garde esbuild

- **auth-js (GHSA-8r88-6cj9-9fh5)** : cas A, voie 1, comme décidé dans ADR-010. Non modifié.
- **`BLOQUE_AUTHJS="non"`** : la policy 25 est conforme (fichier ligne 17). Un passage à `"oui"` rétablirait le blocage de
  `./dev deploy service` et imposerait la réévaluation de ADR-010 (SPEC-001.15 (d)).
- **Garde esbuild, formulation à reprendre telle quelle** : « cas C esbuild gardé ».
  **Contradiction signalée, non tranchée par l'architecte.** ADR-010 classe esbuild (GHSA-67mh-4wv8-2f99) en **cas A**
  (`build()` seul, aucun `serve`/`watch`/`context(`, image servie ne contenant que `dist/`). Deux lectures possibles :
  - **(i) « le garde reste »** : la recherche de `serve`, `watch` ou `context(` dans `app/web/build.mjs` reste en place.
    Si elle trouve une occurrence, ADR-010 impose une réévaluation de l'avis, qui passerait en cas C. Cette lecture est
    compatible avec le cas A retenu.
  - **(ii) « esbuild est en cas C »** : contredit ADR-010 (cas A). Non retenue par l'architecte.
- **Constat de code** : le garde est aujourd'hui une **note non bloquante** (policy 25, bloc `notes`), alors que la réaction
  supposait un blocage et qu'ADR-010 demande une réévaluation obligatoire.
- **Décision à prendre par le chef de projet** : garde bloquant, ou note non bloquante (état du code). Tant que ce point
  n'est pas tranché, ADR-010 reste en cas A et la policy 25 garde la note.

## D-2 — Audit npm hors runner

Décision détaillée dans ADR-014. Résumé : `./dev audit-npm` (hôte, image `node:22.12.0-alpine`) écrit
`audit-npm.json` et `audit-npm.meta.json` (statut, sha256 de `package-lock.json`) dans `iterations/<NNN>/policies/`.
La policy 25 vérifie le statut et le sha256. Pas de socket Docker dans le runner.

## D-3 — git dans le runner

Décision détaillée dans ADR-015. Résumé : git est installé dans `tools/runner/Dockerfile` avec une version apt exacte.
`safe.directory /workspace` est configuré au niveau système de l'image. La policy 29 (c) compare `001` à `005` à la
référence `dae9044` par `git show` et sha256, sans écrire l'index.

## D-4 — Confirmation de l'administrateur

- **Décision (tranchée)** : le seed lit `email_confirmed_at`, avec repli sur `confirmed_at`. Un compte existant dont
  aucun des deux champs n'est présent fait échouer le seed (rc≠0). Le code (`tools/deploy/seed.py`, lignes 74 à 77) suit
  déjà cette règle. Aucune spec à changer ; SPEC-003.11 et ADR-012 restent valables.
- **Point de vérification déplacé** : `seed.py` ne lit le champ que si le compte existe déjà (ligne 64 à 75). Au premier
  `./dev deploy service` sur pile vierge (S3), le compte est créé et le champ n'est pas lu. **Le premier contrôle réel de
  `email_confirmed_at` a donc lieu au second `deploy service`** (S12 de `mise-en-service.md`, ou SPEC-003.10 étape 3).
  Si le champ réel diffère, `seed.py` et le stub de test se corrigent ensemble (ADR-012).

## D-5 — Changement du mot de passe administrateur

- **Dans l'interface : non.** `app/web/src/app.js` ne consomme un mot de passe qu'à la connexion
  (`signInWithPassword`) et à l'inscription (`signUp`). Aucun formulaire ni appel de changement de mot de passe.
- **Par API : oui, techniquement.** La passerelle relaie `/auth/v1/*` vers GoTrue, sauf `/auth/v1/admin/*` (SPEC-001.6,
  SPEC-001.7, `app/nginx/default.conf` lignes 22 à 28). Un `PUT /auth/v1/user` avec le jeton d'un utilisateur atteint
  donc GoTrue. Ce canal n'est ni spécifié, ni testé, ni présenté dans l'interface.
- **Correction** : ADR-012 §6 disait que ce changement était « sans objet ». L'affirmation est incomplète : le canal
  API existe. La note de correction est ajoutée à ADR-012.
- **Décision** : hors périmètre 002, confirmé. Point ouvert : accepter ce canal (le documenter) ou le fermer (règle
  nginx, à traiter dans une itération dédiée, hors 002).

## D-6 — SPEC-003.10 face au gel

- Le gel de `dev` (pas de `reset`, `teardown`, `deploy`, `test`) reste en vigueur jusqu'à sa levée.
- **Le premier `./dev deploy` après la levée est `./dev deploy service`.** Le [R] de SPEC-003.10, qui demandait un
  `./dev deploy` sans `reset` sur `dev`, ne peut donc pas se jouer à la levée sur `dev`.
- Le scénario est réécrit sur `service` en trois étapes : premier `deploy service` sur pile vierge (création), changement
  du mot de passe admin, second `deploy service` sans `reset` (vérification). Il se consigne dans `mise-en-service.md`.
- SPEC-003.12 (d) : `reset` + `deploy` ne se joue que sur `dev`, après D4 et décision du chef de projet
  (`mise-en-service.md` S16). Jamais sur `service` (CA-002-36 (c)).

## D-7 — Arbitrages d'interface

Pour l'itération 002, « Réaffecter », « Loguer du temps » et « Modifier » n'affichent pas de message de confirmation
de succès. Le défaut est connu et documenté dans SPEC-005 (section des défauts connus). Le chef de projet accepte ce
défaut pour cette itération. Il ne crée pas d'exigence. À reprendre dans une itération suivante si le besoin est exprimé.

## D-8 — Écart CA-002-1 « après reset »

SPEC-001.4 demande, après `./dev reset` puis `./dev deploy`, un `GET /` à 200 sur l'adresse LAN. Ce contrôle n'est pas
joué : `dev` est gelée et `reset` est interdit. Le chef de projet accepte l'écart. Il est remplacé par le déploiement à
blanc de service (S3 et S4 de `mise-en-service.md`). L'écart est enregistré dans SPEC-006 §2 (CA-002-1).

## Actions consécutives (par équipe)

| Équipe / agent | Action | Référence |
|---|---|---|
| Team AOPR / `policy` | Policy 25 : lire `audit-npm.meta.json`, comparer le sha256 (retirer la comparaison de dates), lire le répertoire de l'itération courante (le chemin `002` est figé) ; mettre à jour le commentaire de la ligne 14 ; garde esbuild : bloquant ou note, après décision de D-1 | ADR-014, D-1 |
| Team AOPR / `policy` | Policy 29 (c) : `git show dae9044:<chemin>` et sha256, pas de `git status` ni `git diff` | ADR-015 |
| Team AOPR / `policy` | Policy 35 (seed, numéro proposé) : écrire le contrôle statique de `seed.py` | SPEC-003.10, 003.12 ; SPEC-006 §3 (19) |
| Team AOPR / `action` | `./dev audit-npm` : commande, `./dev help`, écriture de `iterations/<NNN>/policies/` | ADR-014 |
| Team AOPR / `action` | `tools/runner/Dockerfile` : `git=<version exacte>`, `git config --system --add safe.directory /workspace` ; relever la version apt | ADR-015 |
| Team AOPR / `action` | Vérifier que `/workspace` contient `.git`, que `dae9044` existe et que ses fichiers `001` à `005` sont identiques à ceux de `dfbc020` (version déployée sur `dev`) | ADR-015 |
| Team DevOps / `testeur` | `tests/test_003_admin.py` : stub GoTrue (SPEC-003.10, 003.11), sans `deploy` ni `reset` | SPEC-003 |
| Responsable applicatif | Séquence SPEC-003.10 sur `service` ; consignation dans `mise-en-service.md` | D-6, D-4 |

## Points ouverts

1. **Garde esbuild (D-1)** : bloquant ou note. Le libellé « cas C esbuild gardé » n'est pas repris comme classement.
2. **Canal API de changement de mot de passe (D-5)** : accepter et documenter, ou fermer (itération dédiée).
3. **Numéro de la policy seed** : 35 proposé (libre au 2026-11-17). À confirmer par le chef de projet.
4. **Référence `dae9044`** : l'architecte n'a pas pu la vérifier dans l'historique git (aucun accès git). L'action doit la
   vérifier et s'assurer qu'elle correspond à la version déployée sur `dev` (`dfbc020`).
5. **Contrat `./dev`** : `./dev audit-npm` doit être ajouté à SPEC-004.1 (liste des commandes). SPEC-004 n'était pas dans
   le périmètre de cette mission et n'est pas modifiée.
6. **Version apt de git** : à relever par l'action à la première construction de l'image (ADR-015).

## Conséquences

- Les specs et policies citent ce document pour chaque arbitrage. Une décision future qui modifie l'une de ces
  positions amende ce fichier, sans créer de doublon.
- Aucune migration SQL, aucun changement de `app/web/src`, aucun appel à la pile. Cette mission n'écrit que dans `specs/`.
