# developpeur — 2026-11-17T14:56:02+00:00

## Brief
Complément à l'incident (journal 145221). Constat du chef de projet de la Team Agile en lecture seule : les bundles servis sur 10.77.0.25:8080 et :8081 (md5 4eb8c08e) CONTIENNENT bien les correctifs (« Proposition envoy\xE9e \xE0 ${c} pour la t\xE2che », « Demande d'aide envoy\xE9e », sticky dans style.css, champ de recherche type search) ; pourtant le client (tools/client/driver.py, APP_URL=http://app, Chromium dans le conteneur client, conteneur longue durée utilisé aussi à la passe N=1) a observé l'ancien comportement (« Proposition envoyée. », pas de recherche, pas de barre fixe). Hypothèse la plus plausible : cache navigateur. nginx (app/nginx/default.conf) n'envoie que ETag et Last-Modified, sans Cache-Control, et les fichiers n'ont pas de nom haché : un navigateur peut réutiliser une ancienne version par fraîcheur heuristique ; cela touche aussi de vrais utilisateurs après chaque mise en service. Corrige dans app/nginx/default.conf (et app/Dockerfile si utile) : Cache-Control: no-cache (revalidation par ETag) pour /, /index.html, /app.js, /vendor/supabase.js, /style.css et /config.js. ATTENTION au piège nginx : add_header dans un bloc location annule les add_header hérités du niveau server ; les en-têtes de sécurité (CSP, X-Content-Type-Options, Referrer-Policy) doivent rester présents sur ces réponses (répète-les dans chaque location concernée, ou utilise un include/map, et vérifie par relecture de la config effective). Ne casse ni la CSP (SPEC-001.9) ni le blocage /admin, ni les types MIME. Pas de deploy, pas de conteneur touché, pas de docker run direct. Vérifie ./dev build (le build ne teste pas la syntaxe nginx : dis ce que tu ne peux pas vérifier, ex. nginx -t, et si un moyen autorisé existe via la toolbox ou un test de build, utilise-le), puis ./dev policies. Dis aussi si tu vois une autre explication au KO du client (par exemple le service app résolu par le client n'est pas celui du port 8080). Compte rendu court.

## Compte rendu
## Compte rendu développeur : cache nginx et KO du client

**Fichiers modifiés**
- `app/nginx/default.conf` : `Cache-Control: no-cache` sur `/`, `/index.html`, `/app.js`, `/config.js` et `/style.css` (location regex). Ajout d'une location exacte `= /vendor/supabase.js` avec la même politique. Les trois en-têtes de sécurité (CSP à l'identique, `X-Content-Type-Options`, `Referrer-Policy`) sont répétés dans chacune de ces locations, car `add_header` d'une location annule ceux du niveau server. Le blocage `/auth/v1/admin` (regex placée avant `/auth/v1/`) et les relais ne sont pas touchés.
- `app/Dockerfile` : `RUN nginx -t` après la copie de la config, pour que le build échoue si la syntaxe est invalide.

**Vérifications**
- `./dev build` : succès. Les couches `RUN nginx -t` et `COPY default.conf` datent de 14:56:44, après la modification à 14:56:39 : la config validée est bien la nouvelle.
- `./dev policies` : 31 respectées, 0 violée. Ces contraintes ne testent ni `Cache-Control` ni les en-têtes des nouvelles locations, et elles frappent les conteneurs en cours, qui tournent encore sur l'ancienne image. Elles ne valident donc pas le correctif.
- Non vérifié : les en-têtes réellement servis par la nouvelle config. Je n'ai pas lancé de conteneur, et `docker run` est exclu. Relecture manuelle faite : `nginx -t` passe, mais l'en-tête effectif n'est pas testé à l'exécution.

**Constat important**
- Les conteneurs en cours ne sont pas ceux de la dernière construction : `devenv-app-1` tourne sur l'image `84b339…` alors que `devenv/app:dev` est `7df9215…`. `dnum-service-app-1` est aussi en retard (`e0f4b…` contre `devenv/app:service` = `7ded09…`). Rien de cela n'est mis en service tant que le `responsable-applicatif` ne lance pas `./dev deploy`.

**Autre explication du KO client (probable, à confirmer)**
- `tools/client/driver.py` appelle `page.goto(APP_URL)` une seule fois au démarrage, dans un Chromium longue durée (`devenv-client-1`, actif depuis 2 h). La page reste en mémoire avec l'ancien JavaScript, sans rechargement, indépendamment du cache HTTP. Une recette après mise en service doit donc recharger la page. Je ne touche pas `tools/client/` (hors de mon périmètre).
- Le client résout `http://app` dans le projet `devenv` uniquement : il ne voit jamais le 8081 (`dnum-service`).

**Specs couvertes**
- `SPEC-001.9` (CSP) : en-têtes conservés, non réévalué à l'exécution.
- `SPEC-001.7` (blocage admin) : config inchangée, policy `GW-admin-bloque` non réévaluée sur la nouvelle config.
- Aucune spec ne porte sur le cache : je n'ai pas d'identifiant `SPEC-xxx` à citer pour `Cache-Control`.

**Points ouverts**
1. Mise en service par le `responsable-applicatif` (`./dev deploy`), puis vérification des en-têtes (`curl -I` sur `/`, `/app.js`, `/vendor/supabase.js`).
2. Demander au `policy` une contrainte exécutable pour `Cache-Control: no-cache` sur ces chemins et pour la présence des en-têtes de sécurité sur chaque location.
3. Demander à l'équipe de recette de recharger la page après chaque mise en service.
4. Le md5 `4eb8c08e` annoncé par la Team Agile n'a pas été vérifié par moi.
5. Rien n'a été commité.
