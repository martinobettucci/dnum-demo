# responsable-applicatif — 2026-11-17T12:29:13+00:00

## Brief
Itération 002, tour 2, relance, pile DEV uniquement. Le correctif gen_secrets.py est en place. 1) Lance ./dev deploy (pas de reset : la pile est déjà détruite). 2) Valide à l'exécution : migrations SQL, GoTrue, PostgREST, nginx, seed admin, secrets dans .devenv/secrets/dev.env (droits 0600/0700). 3) Vérifie la RLS par psql dans db. 4) Vérifie que 10.77.0.25:8080 répond. 5) Mets à jour iterations/002/mise-en-service.md (services, santé, URL, incidents avec logs). 6) NE déploie PAS la pile service. 7) N'affiche JAMAIS le mot de passe admin (ni compte rendu, ni fichier suivi par git, ni commande affichant sa valeur) ; indique seulement où il se trouve. 8) En cas d'échec, donne l'incident avec les logs dans ton compte rendu.

## Compte rendu
Mise en service de la pile `dev` réussie : tous les points de validation sont verts. Je n'ai pas déployé la pile `service`.

Mise en service assurée exclusivement par le responsable applicatif. Aucun autre agent ne démarre, n'arrête ni ne détruit la pile : adressez vos demandes au chef de projet.

**Résultat**
- `./dev deploy` (sans reset) : code 0, durée 21 s.
- Version : commit `dfbc020` + arbre non commité. Correctif appliqué : `tools/deploy/secrets.py` renommé en `gen_secrets.py`, et `dev` ligne 98 l'appelle désormais.
- URL : http://10.77.0.25:8080/ répond en HTTP 200.

**Services** (`./dev status`)
- app (nginx), db, auth (GoTrue) : Up, healthy.
- rest (PostgREST) : Up, sans healthcheck déclaré ; joignable via nginx (200).
- client : Up.

**Validations**
- Migrations : 5 fichiers appliqués (001 à 005), niveau 005.
- GoTrue : `/health` en v2.170.0, `/auth/v1/health` en 200.
- PostgREST : `/rest/v1/` en 200.
- Seed admin : compte créé, profil `role=admin` actif.
- Secrets : `.devenv/secrets/dev.env` en 0600, dossier en 0700, ignoré par git.
- RLS (psql dans `db`) : activée et forcée sur tasks, profiles, time_entries, help_proposals, avec 7 politiques. `anon` reçoit `permission denied` ; `authenticated` sans JWT ne voit aucune ligne.

**Mot de passe admin** : il n'apparaît dans aucun compte rendu ni fichier suivi. Il se trouve uniquement dans `.devenv/secrets/dev.env` (variable `ADMIN_PASSWORD`, fichier 0600, hors git).

**Observations non bloquantes** (détail dans `iterations/002/mise-en-service.md`)
1. Le message final de `./dev deploy` affiche `http://127.0.0.1:8080/`, alors que la pile n'écoute que sur 10.77.0.25:8080 (127.0.0.1 ne répond pas). À corriger dans `dev`.
2. GoTrue signale `GOTRUE_JWT_ADMIN_GROUP_NAME` et `GOTRUE_JWT_DEFAULT_GROUP_NAME` comme dépréciés. À retirer de la configuration.
3. Le `FATAL` TimescaleDB au démarrage est un arrêt normal de worker, sans conséquence.
4. Les `ERROR permission denied` dans les logs `db` viennent de mon test RLS et sont attendus.
5. Le seed s'exécute entre deux passages de migration. L'ordre est correct, le second passage est idempotent.

**Points ouverts pour le chef de projet** : trancher la décision ADR sur la publication 10.77.0.25 ; faire corriger les points 1 et 2 par `action` ou `developpeur`.

Aucun échec à remonter. Journal complet du déploiement, secrets masqués : `/tmp/deploy-dev-002-t2.log`.
