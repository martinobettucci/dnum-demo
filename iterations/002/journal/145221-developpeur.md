# developpeur — 2026-11-17T14:52:21+00:00

## Brief
INCIDENT priorité haute, itération 002. La recette client (journal 140419-client) met CA-002-27, 28, 37, 38, 39 en KO. Diagnostic du chef de projet : app/web/src/app.js contient bien « pour la tâche » et champRecherche, style.css contient sticky ; MAIS le app.js servi sur :8080 ET :8081 est identique (md5 4eb8c08e) et ne contient pas « pour la tâche ». Les images devenv/app:dev et devenv/app:service ont toutes deux été créées à 2026-11-17T13:14:28, avant la fin des correctifs ; ./dev deploy dev à 13:57 (commit 899ee3e) n'a pas reconstruit l'image avec le source courant. À faire SANS deploy, reset, teardown ni conteneur touché (la pile service est en production avec des comptes réels) : (1) trouve pourquoi le build ne prend pas le source : cache Docker (couche COPY), .dockerignore, contexte de build, ./dev deploy sans build, tag :service non reconstruit (stack/compose.yml, stack/compose.service.yml, app/Dockerfile, ./dev, tools/deploy/) ; lis aussi la date de création des images avec les commandes autorisées et compare les empreintes (md5) de app/web/src/app.js et de ce qui est dans l'image ; (2) corrige ./dev ou le Dockerfile ou le compose pour que tout deploy reconstruise depuis le source courant (l'édition de ./dev t'est autorisée ici par le chef de projet ; garde la sémantique de SPEC-004 et ne change rien d'autre) ; (3) lance ./dev build puis vérifie dans l'image que les correctifs y sont (grep -c « pour la tâche » dans /usr/share/nginx/html/app.js ou le chemin réel du bundle), pour les tags :dev ET :service, via la toolbox ou compose : pas de docker run direct ; si le garde-fou t'en empêche, n'insiste pas et dis précisément ce que tu n'as pas pu vérifier ; (4) ./dev policies ; propose une policy « bundle servi = source construit » (méthode : empreinte du bundle construit comparée à celle servie par app, ou à celle de l'image) à transmettre à AOPR. Compte rendu court et factuel : cause racine, fichiers modifiés, vérifications faites et non faites.

## Compte rendu
## Compte rendu — incident itération 002 (build ne prend pas le source)

**Cause racine : pas de défaut de build sur le contenu.** Le diagnostic « bundle sans correctifs » vient d'une fausse lecture :

- Le bundle est minifié par esbuild, qui écrit les caractères non ASCII en échappements. « pour la tâche » est donc dans l'image sous la forme `pour la t\xE2che` (1 occurrence). `grep` sur le texte brut échoue à tort. `champRecherche` est un identifiant minifié, il n'apparaît pas non plus.
- Empreintes : `src/app.js` md5 `d32c5f2c`. Le bundle servi sur :8080 et :8081, et le bundle de l'image, sont `4eb8c08e`. Le `vendor/supabase.js` est `bf039aec`.
- `app.js` a été modifié pour la dernière fois à 13:14:15 ; les images datent de 13:14:28. Le `./dev deploy` de 13:57 a donc correctement réutilisé le cache : le source n'avait pas changé.
- Preuve décisive : un build **sans cache** de l'étape `build` depuis le source courant (`docker build --no-cache --target build`) redonne exactement `4eb8c08e` et `bf039aec`.

**Défaut réel trouvé et corrigé :** `./dev build` ne construisait que la pile dev. Le tag `devenv/app:service` n'était donc jamais reconstruit par cette commande. Le `deploy service` reconstruit déjà via `up --build`, il n'a pas été modifié.

**Fichier modifié :** `dev`, cas `build` uniquement. Si la pile est dev et que `stack/compose.service.yml` existe, la commande se rappelle avec `DEVENV_PILE=service`. Rien d'autre n'a changé (ni Dockerfile, ni compose, ni `deploy`). Non commité.

**Vérifications faites**
- `./dev build` : OK (rc 0). Les tags `devenv/app:dev` et `devenv/app:service` ont été reconstruits. Leurs couches sont identiques, créées à 13:14:28. Les nouveaux IDs d'image sont `97d4c53` (dev) et `3514ac` (service).
- Dans les deux tags, `app.js` = `4eb8c08e`, `vendor/supabase.js` = `bf039aec`, `style.css` contient `sticky`. Ces empreintes sont identiques à celles servies sur :8080 et :8081.
- `./dev policies` : 31 respectées, 0 violée (`iterations/002/policies/results.json`).
- Aucun deploy, reset, teardown, ni `docker run`/`exec`. Les conteneurs `devenv-app-1` et `dnum-service-app-1` tournent depuis leur démarrage initial, non redémarrés. Ils utilisent encore l'ancienne image jusqu'au prochain deploy.

**Non vérifié**
- Le contenu à l'intérieur des conteneurs en marche (pas de `docker exec`) : seul le contenu servi via HTTP a été comparé.
- Le rendu réel dans un navigateur (pas de recette relancée).

**Point ouvert, à investiguer côté recette :** la recette du 14:19 lit « Proposition envoyée. », ancien texte, alors que le bundle servi depuis 13:14 contient le correctif. Le build n'explique donc pas ce KO. Piste : cache ou état côté navigateur client (`tools/client/driver.py` lance Chromium sans gestion de cache, cause non confirmée). Il faut vérifier avant de conclure que CA-002-27/28/37/38/39 sont corrigés.

**Proposition de policy pour AOPR** (non écrite, `policies/` n'est pas mon périmètre) : `FRONT-bundle-servi-egal-source`
- **A (source construit)** : `docker build --no-cache --target build -f app/Dockerfile app` hors runner, puis sha256 de `/build/dist/app.js` et `vendor/supabase.js`.
- **B (servi)** : sha256 de `GET /app.js` et `GET /vendor/supabase.js` sur la pile déployée (dev : `APP_URL` depuis le runner ; service : `10.77.0.25:8081` depuis l'hôte).
- **C (image)** : sha256 des mêmes fichiers dans `/usr/share/nginx/html` de `devenv/app:<pile>`, extraits hors runner.
- Verdict : A = B = C pour les deux fichiers, sinon violée. Non applicable si la pile n'est pas déployée.
- Règle : ne pas vérifier par `grep` de texte ou d'identifiant sur le bundle minifié (échappements esbuild) ; comparer des empreintes.
- Option à arbitrer : écrire les sha256 de build dans l'image (une ligne dans le Dockerfile) pour que le runner les compare sans socket Docker.
