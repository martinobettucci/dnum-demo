# developpeur — 2026-11-17T12:07:15+00:00

## Brief
Itération 002, tour 1. Réalise toute l'application selon specs/ (lis specs/README.md, SPEC-001 à SPEC-006, ADR-002, ADR-006, ADR-007, ADR-008, les journaux iterations/002/journal/*, iterations/002/mise-en-service.md et iterations/002/tests/rapport.md). Livrables : services Supabase dans stack/compose.yml (db, auth, rest, migrate, seed, app) conforme à SPEC-004.11 à 004.16 ; stack/compose.service.yml (tag devenv/app:service, sans redéfinir ports) ; passerelle nginx ; migrations SQL, RLS et RPC dans app/db/migrations/NNN_<sujet>.sql ; front HTML/JS construit dans Docker, en deux fichiers (/app.js et /vendor/supabase.js 2.47.10) avec CSP ; auth : limites de débit conformes à SPEC-001.14 ; publication app sur 10.77.0.25 uniquement. Tu ne lances ni deploy, ni teardown, ni reset (garde-fou) ; vérifie avec ./dev build et ./dev policies, une commande par appel. Compte rendu : fichiers produits, specs couvertes, points ouverts.

## Compte rendu
## Compte rendu développeur — itération 002, tour 1

Le front, la passerelle, la pile Supabase et les migrations sont écrits. Le build de l'image passe, mais rien n'a été exécuté à l'exécution : la pile n'est pas redéployée et le garde-fou m'interdit les conteneurs jetables. Ce sont les premiers points à valider au prochain `./dev deploy`.

### Fichiers produits (rien commité)
- **Pile** : `stack/compose.yml` (db, auth, rest, migrate, seed, app, runner, client), `stack/compose.service.yml` (`devenv/app:service`, sans `ports`), `stack/db-init/zz-roles-devenv.sh` (mots de passe de `authenticator` et `supabase_auth_admin`, que l'image ne fixe pas).
- **Migrations** : `app/db/migrations/001_socle.sql`, `002_taches_temps_entraide.sql`, `003_rls_privileges.sql`, `004_vues.sql`, `005_rpc.sql`.
- **Passerelle** : `app/nginx/default.conf` (relais, blocage admin, CSP), `app/nginx/40-config-js.sh` (génère `/config.js` avec la seule clé anon).
- **Front** : `app/web/` (package.json et lock épinglés : supabase-js 2.47.10, esbuild 0.24.2 ; `build.mjs` ; `src/app.js`, `src/vendor.js` ; `index.html`, `style.css`).
- **Image** : `app/Dockerfile` (node 22.12.0 puis nginx 1.27.3), `app/.dockerignore`. Suppression du placeholder `app/public/index.html`. Ajout de `app/web/node_modules/` et `app/web/dist/` dans `.gitignore`.

### Vérifications faites
- `./dev build` : rc=0, images `devenv/app:dev`, `runner`, `client` construites (deux fois, après retouche).
- Front construit dans une copie `/tmp` : `2.47.10` présent dans le vendor ; aucun motif interdit dans `app.js`, `index.html` ni le vendor ; `window.location.origin` utilisé ; aucun JWT en dur.
- `docker compose config` : pile `dev` avec une seule publication `10.77.0.25:8080->80` ; surcouche `service` donne `10.77.0.25:8081->80`, tag `:service`, `restart`. `API_EXTERNAL_URL` dérivée correctement. Pas de `GOTRUE_RATE_LIMIT_HEADER` ; limites à 1000.
- Images Supabase inspectées (lecture seule) : `supabase_admin` reçoit `POSTGRES_PASSWORD` ; `auth.uid()` existe ; GoTrue embarque `wget` (healthcheck possible) ; l'image accorde `ALL` aux rôles API par défaut, d'où les `revoke` explicites.
- `./dev policies` : rc=1, 10 respectées, 9 violées, 1 non applicable. Détail en point ouvert 2.

### Specs couvertes (implémentées, non exécutées)
- **SPEC-001** : .1, .2, .3 (publication LAN seule), .6, .7, .8 (front sans URL d'hôte, partition app/vendor), .9 (CSP), .10, .11, .12, .13, .14 (débit, sans limitation nginx).
- **SPEC-002** : .1 à .22 par les migrations (tables, RLS forcée, vues `security_invoker`, RPC avec erreurs `DNUM:`, déclencheurs d'expiration, privilèges par colonnes, aucun DELETE).
- **SPEC-004** : .7 (surcouche), .11, .12, .13, .14, .15 (côté compose), .16 (tags par pile).
- **SPEC-005** : écrans et libellés exacts, saisie clavier/souris (`details`, boutons natifs), messages en français. Non recetté.

### Points ouverts
1. **Non exécuté à l'exécution** : syntaxe nginx, SQL et plpgsql, démarrage GoTrue/PostgREST, déclenchement des scripts `docker-entrypoint-initdb.d`. Le garde-fou m'interdit `docker run` ; la vérification SQL réelle se fera au premier `deploy`.
2. **Pile `devenv` non redéployée** : le conteneur `devenv-app-1` sert encore l'ancien placeholder. Les contrôles déployés (GW-*, GW-csp, FRONT, API-anon, ENV-secrets-fichier, APP-repond) sont donc en échec. Il faut `./dev reset` puis `./dev deploy` par le responsable applicatif.
3. **Policy 00 (ENV-images-epinglees)** : elle échoue sur `devenv/app:service` dans la surcouche, car elle exempte seulement les services avec `build:`. ADR-008 veut que le `build:` reste dans la pile de base. Correction à faire par `policy`, pas dans la surcouche.
4. **Policy 21 (STACK-ports)** : elle exige encore `127.0.0.1`, contraire à ADR-007. À réécrire par `policy`. Mon compose respecte ADR-007.
5. **Pile service sans `restart` sur db, auth, rest** : SPEC-004.7 ne le demande que pour `app`. Après un redémarrage de l'hôte, `app` redémarrera sans sa base. À trancher par l'architecte ou le PO.
6. **Écart à SPEC-004.11 à arbitrer** : `env_file` est en forme longue `required: false`. Sans cela, `teardown` et `reset` échouent quand le fichier de secrets n'existe pas encore (SPEC-004.2). Le chemin reste `${DEVENV_SECRETS}`. L'architecte doit aligner la spec.
7. **`./dev` (action)** : le message de `deploy` affiche encore `http://127.0.0.1:${APP_PORT}/` (ADR-007). `APP_LAN_IP` n'est pas exporté (le défaut compose s'applique).
8. **Audit npm** : 3 vulnérabilités (2 faibles, 1 modérée) dans l'arbre transitif. Les versions sont épinglées et je ne les ai pas changées. À évaluer.
9. **Dérogation CA-002-1 (127.0.0.1)** : à valider par le PO. Adresse LAN stable (risque R3) : à traiter par le responsable applicatif avant `deploy service`.

Je n'ai lancé ni deploy, ni teardown, ni reset, et je n'ai rien commité.
