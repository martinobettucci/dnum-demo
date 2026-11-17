Mise en service assurée exclusivement par le responsable applicatif. Aucun autre agent ne démarre, n'arrête ni ne détruit la pile : adressez vos demandes au chef de projet.

# Itération 002 — tour 2 : mise en service DEV (SUCCÈS)

- Statut : **succès**. `./dev deploy` (pile `dev` uniquement, sans `reset`) rend la main avec le code 0.
- Date : 2026-11-17, déploiement vers 12:29 — 12:30 UTC.
- Pile : `dev` uniquement. Pile `service` **non déployée** (conformément à la consigne).
- Version déployée : commit `dfbc020` (itération 002 tour 1) + arbre de travail non commité. Correctif appliqué : `tools/deploy/secrets.py` renommé en `tools/deploy/gen_secrets.py` (non commité, `D` + `??` dans git) ; `dev` ligne 98 appelle `gen_secrets.py`.
- Durée : **21 s** (build en cache, démarrage, migrations, seed, santé).
- URL : **http://10.77.0.25:8080/** — répond (HTTP 200).

## 1. Services (`./dev status`)

| Service | Image | État |
|---|---|---|
| app (nginx) | devenv/app:dev | Up, **healthy**, publié sur 10.77.0.25:8080 |
| db | supabase/postgres:15.8.1.060 | Up, **healthy** |
| auth (GoTrue) | supabase/gotrue:v2.170.0 | Up, **healthy** |
| rest (PostgREST) | postgrest/postgrest:v12.2.8 | Up (pas de healthcheck déclaré ; joignable via nginx) |
| client | devenv/client:dev | Up (driver de recette) |
| migrate, seed | — | exécutés (conteneurs ponctuels) |

## 2. Validation exécutée

| Point | Résultat |
|---|---|
| Migrations SQL | **OK** : 5 fichiers appliqués (`001_socle` à `005_rpc`), niveau 005. Ordre : migrations, puis seed, puis re-passage de migration (idempotent). |
| GoTrue | **OK** : `/health` répond v2.170.0 ; `/auth/v1/health` via nginx = 200. |
| PostgREST | **OK** : `/rest/v1/` via nginx = 200. |
| nginx | **OK** : 10.77.0.25:8080 = 200. |
| Seed admin | **OK** : compte admin créé dans `auth.users` ; profil `role=admin` actif. (1 compte, rôle admin confirmé.) |
| Secrets `.devenv/secrets/dev.env` | **OK** : fichier `600` (spark-docker), répertoire `.devenv/secrets` `700`. Clés présentes : POSTGRES_PASSWORD, JWT_SECRET, ANON_KEY, SERVICE_ROLE_KEY, ADMIN_EMAIL, ADMIN_PASSWORD. Ignoré par git (`.gitignore` : `.devenv/`). |
| RLS (psql dans `db`) | **OK** : RLS activée et forcée sur `tasks`, `profiles`, `time_entries`, `help_proposals`. 7 politiques (SELECT/INSERT/UPDATE pour `authenticated` uniquement). Rôle `anon` : `permission denied` sur les 4 tables. Rôle `authenticated` sans JWT : 0 ligne visible sur les 4 tables. |

Localhost : `http://127.0.0.1:8080/` ne répond pas (code 000) car la publication est liée à **10.77.0.25 uniquement**. C'est le comportement voulu pour la pile DEV sur le LAN, mais le message final de `./dev deploy` indique `http://127.0.0.1:8080/` : il faut le corriger (voir section 4).

## 3. Incidents et observations

Aucun échec bloquant pendant ce tour. Journal complet du déploiement : `/tmp/deploy-dev-002-t2.log` (secrets masqués).

Rappel de l'échec du tour 1 : `secrets.py` masquait le module standard `secrets` (AttributeError `choice`). Corrigé par le renommage en `gen_secrets.py`.

Observations non bloquantes, extraites de `./dev logs` :

1. **Message de sortie trompeur** : `Mise en service (dev) OK ... — http://127.0.0.1:8080/` alors que la pile écoute sur 10.77.0.25:8080. À corriger par l'`action` ou le `developpeur` (fichier `dev`).
2. **FATAL TimescaleDB** (`db-1`, 12:29:27) : `terminating background worker "TimescaleDB Background Worker Launcher" due to administrator command`. Arrêt normal de worker lors du redémarrage de la base, sans conséquence observée.
3. **Avertissements GoTrue** (`auth-1`) : `GOTRUE_JWT_ADMIN_GROUP_NAME` et `GOTRUE_JWT_DEFAULT_GROUP_NAME` non supportés, dépréciés. Non bloquant ; à retirer de la configuration de la pile.
4. **Lignes `ERROR permission denied` dans `db-1`** (12:30:00 — 12:30:05) : produites par mon propre test RLS en rôle `anon` et `authenticated`. Comportement attendu, pas une panne.
5. **Ordre des conteneurs** : `seed-run` s'exécute entre deux passages de `migrate-run`. Les migrations ont été appliquées avant le seed, donc l'ordre est correct ; le second passage de migration est idempotent. À documenter si ce n'est pas voulu.

## 4. Points ouverts

- Décision ADR sur la publication 10.77.0.25 (tour 1, section 1) : toujours à trancher par le chef de projet.
- Corriger le message `127.0.0.1` dans `./dev deploy` (observation 1).
- Retirer les variables GoTrue dépréciées (observation 3).

## 5. Accès administrateur

Le mot de passe admin n'est pas reproduit ici. Il se trouve **uniquement** dans `.devenv/secrets/dev.env` (variable `ADMIN_PASSWORD`, fichier `600`, hors git). L'identifiant `ADMIN_EMAIL` figure dans le même fichier.
