# developpeur — 2026-11-17T12:29:14+00:00

## Brief
Itération 002, tour 2, application des arbitrages de l'architecte (lis specs/SPEC-004 §004.7, §004.11, ADR-009, ADR-010, SPEC-001.15). Dans stack/ et app/ uniquement (pas ./dev : l'agent action de la Team AOPR s'en charge) : (1) pile service : restart unless-stopped sur db, auth, rest et app, via stack/compose.service.yml ; aucune politique sur migrate, seed, runner, client ; pile dev sans restart ; (2) env_file en forme longue required:false pour migrate et seed, conforme à SPEC-004.11 ; (3) ADR-010 : produis la preuve de non-présence/non-atteignabilité des paquets Node-only (whatwg-url, tr46, ws) dans le bundle navigateur, par exemple via le metafile d'esbuild dans app/web/build.mjs, hors image servie ; ne mets rien à jour (pas d'npm audit fix, pas d'overrides) ; si tu peux relever les identifiants des 3 avis npm sans réseau non autorisé, consigne-les ; sinon dis-le. Vérifie avec ./dev build puis ./dev policies, une commande par appel ; ni deploy, ni teardown, ni reset. Corrige aussi toute référence à tools/deploy/secrets.py dans stack/ et app/. Compte rendu : fichiers modifiés, résultats, points ouverts.

## Compte rendu
Compte rendu du développeur — itération 002, tour 2 (application des arbitrages de l'architecte).

## Fichiers modifiés

- `stack/compose.service.yml` : `restart: unless-stopped` sur `db`, `auth`, `rest` et `app` (ADR-009). `migrate`, `seed`, `runner` et `client` n'ont aucune politique. Le commentaire d'en-tête est mis à jour. `ports` n'est pas redéfini.
- `app/web/build.mjs` : le build vendor passe `metafile: true` et écrit `meta/vendor-metafile.json`. Ce dossier est dans l'étape de build, hors `dist/`, donc jamais copié dans l'image nginx. Le script affiche aussi les paquets Node-only trouvés dans le bundle et si esbuild y figure.
- Non modifiés, déjà conformes :
  - `stack/compose.yml` : `migrate` et `seed` ont `env_file` en forme longue avec `required: false` ; aucune politique `restart` dans la pile dev.
  - `app/` : aucune référence à `tools/deploy/secrets.py`.
  - `dev` : la référence était déjà corrigée en `gen_secrets.py` par le passage précédent.

Je n'ai pas touché à `package.json`, `package-lock.json`, aux overrides ni à `npm audit fix`.

## Résultats

- **`./dev build`** : rc=0. Les trois images sont construites. Le build affiche : `paquets Node-only dans dist/vendor/supabase.js : node_modules/@supabase/node-fetch/browser.js, node_modules/ws/browser.js` ; esbuild absent du bundle.
- **`./dev policies`** : rc=1, 18 respectées, 2 violées, 0 non applicable. Les deux violations ne viennent pas de mes modifications, elles relèvent des policies :
  - `ENV-images-epinglees` : signale `devenv/app:service` (tag d'image construite localement, ADR-008 / SPEC-004.16). La policy ne traite pas ce cas.
  - `STACK-ports` : attend une publication sur `127.0.0.1`, alors que ADR-007 impose `${APP_LAN_IP}`. La policy est en retard sur l'ADR.
- **Vérification statique** (`docker compose config`, lecture seule) :
  - Pile service : `db`, `auth`, `rest`, `app` sont en `unless-stopped`. `app` publie `10.77.0.25:8081 → 80`.
  - `migrate` et `seed` (profil `deploy`) ne portent aucun `restart`. `env_file` longue forme est honorée : absent, pas d'erreur ; présent, les variables sont fusionnées.
  - `runner` et `client` ne sont pas présents en service.
- **ADR-010, preuve de non-présence** (metafile extrait en lecture seule vers `/tmp`, puis supprimé) :
  - `whatwg-url`, `tr46`, `webidl-conversions` : présents dans le lock, **absents du bundle**.
  - `ws` : seul `ws/browser.js` est inclus. C'est un shim qui lève une exception à l'appel. Il est importé dynamiquement par `realtime-js/RealtimeClient.js`. Le vrai `ws` 8.23.0 n'est pas dans le bundle.
  - `@supabase/node-fetch` : seul `browser.js` est inclus. C'est un shim qui renvoie `fetch` global.
  - `app/src/app.js` n'utilise ni `channel`, ni `subscribe`, ni `realtime`, ni `WebSocket`. Le chemin WebSocket n'est donc pas emprunté.
  - Ces faits sont fournis à l'architecte pour le classement A/B/C. Je ne classe rien moi-même.

## Points ouverts

1. **Identifiants des 3 avis npm : non relevés.** Ma tentative `npm audit --package-lock-only` dans l'image `node:22.12.0-alpine` a été bloquée par le garde-fou (`docker run` refusé pour mon rôle). Je ne l'ai pas contourné. Cette vérification doit passer par `policy`/`action` (policy 13 `FRONT-audit-npm`) ou être autorisée par le chef de projet.
2. **Policy 12 `STACK-restart-service`** : absente de `policies/checks/`. J'ai vérifié la règle statiquement, mais la preuve exécutable reste à écrire par `policy`.
3. **Policies à corriger par `policy`** : `ENV-images-epinglees` (tags des images construites) et `STACK-ports` (LAN IP, ADR-007). Je n'ai pas modifié `policies/`.
4. **`specs/SPEC-004-piles-dev-service.md`** lignes 34 et 44 citent encore `tools/deploy/secrets.py`. Hors de mon périmètre (spec, à l'architecte). `policies/lib/secrets.py` (résidu) relève de `policy`.
5. **Non fait, hors périmètre** : `./dev deploy`, `teardown`, `reset`, et les vérifications `docker inspect` / `ss` de SPEC-004.7 (exigent une pile démarrée, réservée au responsable applicatif).
6. Rien n'est commité.
