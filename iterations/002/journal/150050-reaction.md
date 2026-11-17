# reaction — 2026-11-17T15:00:50+00:00

## Brief
Mission structure (incident de recette), lecture seule. À partir de iterations/002/journal/150001-observation.md (lis-la en entier, vérifie results.json), propose le plan de réaction : ce qui bloque la policy 36 (production de dist/build-sha256.txt par build.mjs et copie dans l'image, à faire par Agile), la vérification de la recréation client au prochain deploy dev (responsable-applicatif), et ce qui doit être vérifié avant de considérer l'incident clos. Ne modifie aucun fichier.

## Compte rendu
# Plan de réaction — incident de recette itération 002 (structure)

Lecture seule : aucun fichier modifié, rien exécuté. J'ai lu l'observation en entier, `results.json`, et vérifié le code cité (`app/web/build.mjs`, `app/Dockerfile`, `app/.dockerignore`, `app/nginx/default.conf`, `dev`). Je n'ai pas pu inspecter la pile en cours d'exécution (pas de docker ni de curl dans mon périmètre).

## 0. Corrections à l'observation

L'observation contient deux affirmations que le code ne confirme pas. Le chef de projet doit les corriger avant de consigner l'incident.

1. **« build.mjs ne produit pas build-sha256.txt » (journal 145827 l.29-31, reprise par l'observation) : faux dans les sources actuelles.**
   - `app/web/build.mjs` l.52-57 calcule les sha256 de `dist/app.js` et `dist/vendor/supabase.js` et écrit `dist/build-sha256.txt` en dernier. Le format (« `<sha256>  <chemin>` », LF) correspond à ce que vérifie la policy 36.
   - Chaîne complète présente dans les sources : `app/Dockerfile` l.10 (`RUN npm run build`), l.19 (`COPY --from=build /build/dist/`) ; `app/.dockerignore` n'exclut que `web/dist` ; `app/nginx/default.conf` l.68-74 sert `/build-sha256.txt` en `text/plain`.
   - Le grep de l'observation (« ne renvoie que la policy 36 ») est donc périmé, ou les sources ont changé après la policy.
2. **Le constat « 200 text/html » est incompatible avec la configuration actuelle.** Avec `location = /build-sha256.txt { try_files $uri =404; }`, un fichier absent donne **404**, pas un 200 HTML. Un 200 `text/html` suggère que la pile en marche tourne avec une configuration nginx plus ancienne, sans ce bloc, et que c'est un repli générique qui répond.
3. **Date de `results.json`** : le fichier indique `2026-11-17T15:00:08`, et l'observation cite `14:59:42`. À corriger.

## 1. Diagnostic des écarts

| # | Écart | Cause probable | Preuve |
|---|---|---|---|
| E1 | Policy 36 violée (rc 1) | Image `devenv/app:dev` en marche construite avant l'ajout de la production de `build-sha256.txt` (ou avant le bloc nginx). Le code source est correct. | `results.json` l.290-292 ; `build.mjs` l.52-57 ; `Dockerfile` l.10, l.19 ; réponse 200 text/html incompatible avec `default.conf` l.68-74 |
| E2 | Recréation client ajoutée sans effet vérifié | Ligne ajoutée à `deploy`, sans `--build`, donc recréation de l'image existante (`devenv/client:dev`). L'effet réel n'a jamais été observé (aucun deploy postérieur). | `dev` l.143-144 ; `stack/compose.yml` l.122-125 ; observation §3 |
| E3 | Duplication dans `dev` | Deux appels successifs (`up -d client` puis `up -d --force-recreate client`) : redondant, sans danger. | `dev` l.143-144 |
| E4 | Incohérence de traçabilité | Journal 145827 faux sur build.mjs (cf. §0) ; `results.json` daté différemment de l'observation. | cf. §0 |

## 2. Plan ordonné

**Étape 1 — Developpeur (Agile) : établir l'état réel du dépôt.**
- Action : confirmer par `git log` / `git status` que `app/web/build.mjs`, `app/nginx/default.conf` et `app/Dockerfile` sont commités et antérieurs au dernier build de `devenv/app:dev`. Si le code est déjà correct, ne rien changer dans le code.
- Changement attendu : aucun, sauf si un fichier est absent du commit.
- Preuve : le constat est consigné (corrige le journal 145827).

**Étape 2 — Testeur : prouver la production du fichier, hors pile.**
- Action : ajouter dans `tests/` un test qui lance `npm run build` dans `app/web`, puis vérifie que `dist/build-sha256.txt` contient deux lignes `sha256  app.js` et `sha256  vendor/supabase.js` correspondant aux octets de `dist/` (contrôle type `sha256sum -c`).
- Preuve : `./dev test` vert sur ce test.

**Étape 3 — Responsable-applicatif : mise en service dev et vérification de la recréation.**
- Avant `./dev deploy` : noter l'ID d'image de `devenv/app:dev` et `devenv/client:dev`, et la date de création du conteneur `client`.
- Action : `./dev deploy` (seul le responsable-applicatif peut le lancer).
- Après : vérifier que la date de création du conteneur `client` a changé (la recréation a bien eu lieu) ; vérifier la ligne ajoutée dans `.devenv/deploy.log`.
- Preuve : dates et ligne de log consignées dans `mise-en-service.md`.

**Étape 4 — Policy / observation : contrôle de la policy 36.**
- Action : après le deploy, `./dev policies`.
- Attendu : policy 36 `respectee` (rc 0), policy 37 toujours `respectee`, synthèse 33 respectées / 0 violée.
- Si la policy 36 reste en échec : le contenu servi doit être inspecté (configuration nginx effectivement en marche, image réellement reconstruite). Cela revient à l'action, pas à une modification de la policy.

**Étape 5 — Client (recette clavier/souris) : effet réel de la recréation.**
- Action : recette du navigateur de dev après deploy, en rechargement normal (sans rechargement forcé).
- Preuve : captures montrant le nouveau front chargé, et cohérence avec le sha256 servi.

**Étape 6 — Developpeur : consolidation de `dev`, seulement après validation.**
- Action : fusionner l.143-144 en une seule ligne, sans changer la logique. Sans effet sur le comportement.
- Preuve : `./dev test` et policies de l'étape 4 toujours vertes.

## 3. Décisions à remonter (utilisateur / product owner, via le chef de projet)

- **D1** : la recréation du client à chaque deploy dev est-elle voulue ? Elle interrompt une session de recette en cours. Faut-il une option explicite (`--recreate-client`) ?
- **D2** : `./dev deploy` doit-il reconstruire l'image `client` (`--build`) quand `tools/client` a changé ? Sans cela, la recréation ne met pas à jour le navigateur.
- **D3** : la policy 36 est-elle bloquante pour la clôture d'itération ? Le PO doit trancher ; je recommande oui, car elle est la preuve du critère ADR-006 §2.
- **D4** : la correction du journal 145827 (cf. §0) doit être validée par le chef de projet avant consignation.

## 4. Critères de clôture de l'incident

L'incident n'est clos que si **tous** les points suivants sont vérifiés :

1. Policy 36 `respectee` sur un deploy dev **postérieur** à la dernière modification de `build.mjs` / `default.conf` / `Dockerfile`, avec sha256 servis identiques au build (sortie de la policy).
2. Policy 37 toujours `respectee` ; `./dev policies` : 33 respectées, 0 violée.
3. Le test de l'étape 2 est dans `tests/` et vert dans `./dev test`.
4. Recréation du conteneur `client` prouvée (date de création changée, ligne dans `deploy.log`).
5. Recette client confirmant le chargement du nouveau front sans rechargement forcé.
6. Journal 145827 corrigé, date de `results.json` réconciliée, observation restituée à nouveau si besoin.
7. Décisions D1 à D3 tranchées par l'utilisateur ou le product owner.

Tant que le point 1 n'est pas vérifié sur une pile réellement redéployée, l'incident reste **ouvert**. Je ne propose pas de clôture de l'itération.
