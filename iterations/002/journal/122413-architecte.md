# architecte — 2026-11-17T12:24:13+00:00

## Brief
Itération 002, tour 2. Écris uniquement dans specs/. (1) Aligne SPEC-004.11 sur la forme env_file longue required:false retenue par le développeur (nécessaire pour que teardown/reset marchent sans fichier de secrets, SPEC-004.2). (2) Tranche le restart de db, auth et rest dans la pile service (recommandation du chef de projet : restart unless-stopped pour toute la pile service, exposée en continu) ; ADR si utile. (3) Fixe le comportement attendu de ./dev : affichage de l'URL (plus de 127.0.0.1, ADR-007) et export de APP_LAN_IP ; écris-le comme spec précise, car l'agent action de la Team AOPR modifiera ./dev. (4) Les 3 vulnérabilités npm transitives (2 faibles, 1 modérée, app/web, versions épinglées) : évalue leur exploitabilité dans un front statique construit en Docker et documente la décision dans un ADR ; pas de mise à jour non épinglée. Compte rendu : décisions, fichiers modifiés, points ouverts, et la spec ./dev à transmettre.

## Compte rendu
Warning: no stdin data received in 3s, proceeding without it. If piping from a slow command, redirect stdin explicitly: < /dev/null to skip, or wait longer.
## Compte rendu architecte, itération 002, tour 2

Écriture limitée à `specs/`. Je n'ai exécuté aucun outil : je n'ai pas de shell, donc pas d'`npm audit` ni de `docker compose config`. Les vérifications sont décrites dans les specs, pas faites.

### Décisions

1. **SPEC-004.11 aligné** sur `env_file` en forme longue `- path: ${DEVENV_SECRETS}` avec `required: false`, pour `migrate` et `seed`. Justification : `teardown` et `reset` doivent rester possibles sans fichier de secrets (SPEC-004.2). Vérification ajoutée : fichier déplacé, puis `teardown` et `reset` rc=0.

2. **Restart de la pile service : `unless-stopped` sur db, auth, rest et app** (SPEC-004.7, ADR-009). Sans cela, après redémarrage de l'hôte, `app` repart seul et la pile répond sans fonctionner. `migrate`, `seed`, `runner` et `client` n'ont aucune politique. La pile `dev` n'en a aucune. `restore` reste correct : `stop` manuel n'est pas relancé par le démon. Choix écarté : `restart: always`.

3. **Contrat `./dev` : SPEC-004.17 (nouvelle)**, qui précise SPEC-004.15 :
   - `APP_LAN_IP` est exporté avant tout appel compose, sur la même ligne que `APP_PORT`, défaut `10.77.0.25`, lu dans l'environnement de l'appelant (jamais dans le fichier de secrets).
   - Une valeur non IPv4 en notation pointée arrête `./dev` avec rc≠0, avant tout appel docker.
   - La seule URL imprimée par `deploy` est `Mise en service (<pile>) OK en <N> s — http://<APP_LAN_IP>:<APP_PORT>/`.
   - Ni `dev` ni ses sorties ne contiennent `127.0.0.1`, `localhost` ni `0.0.0.0`.

4. **Vulnérabilités npm (ADR-010), décision provisoire** :
   - Aucune mise à jour. Pas de `npm audit fix`, pas d'`overrides`, versions épinglées conservées.
   - Constat : le front servi est `dist/` seul, dans une image nginx. Les dépendances de build (esbuild) ne sont pas livrées. Les paquets Node-only (`whatwg-url`, `tr46`, `ws`) ne doivent pas figurer dans le bundle navigateur ; c'est à prouver.
   - Classement par avis : cas A (absent du bundle) ou cas B (présent mais non atteignable) = accepté ; cas C ou sévérité haute/critique = bloquant.
   - **Je ne peux pas classer les 3 avis** : leurs identifiants ne figurent nulle part dans le dépôt, et je ne peux pas relancer l'audit. La décision reste donc conditionnelle.

### Fichiers modifiés (specs uniquement)

- `specs/SPEC-004-piles-dev-service.md` : amendements 004.7, 004.11, 004.15 ; nouvelle 004.17.
- `specs/SPEC-001-pile-supabase.md` : nouvelle 001.15 (chaîne d'approvisionnement du front).
- `specs/SPEC-006-plan-verification.md` : §2 (CA-002-1, CA-002-2, CA-002-36), §3 policy 9 amendée, policies 12, 13, 14 ajoutées.
- `specs/adr/ADR-004-piles-dev-service.md` et `specs/adr/ADR-006-verifiabilite-pile-dev.md` : notes d'amendement.
- `specs/README.md` : index mis à jour, bloc tour 2, points ouverts.
- Nouveaux : `specs/adr/ADR-009-redemarrage-pile-service.md`, `specs/adr/ADR-010-vulnerabilites-npm-front.md`.

### Spec `./dev` à transmettre à `action`

- Ligne 25 : ajouter `APP_LAN_IP="${APP_LAN_IP:-10.77.0.25}"` à l'export (avec `APP_PORT`), puis valider `^[0-9]{1,3}(\.[0-9]{1,3}){3}$` avant tout appel docker.
- Ligne 115 : remplacer `http://127.0.0.1:${APP_PORT}/` par `http://${APP_LAN_IP}:${APP_PORT}/`.
- Ne rien changer d'autre, `set -euo pipefail` compris. `grep -nE '127\.0\.0\.1\|localhost\|0\.0\.0\.0' dev` doit être vide.
- Le texte complet est dans SPEC-004.17.

### Points ouverts

1. **ADR-010** : relever les 3 identifiants (`npm audit --json` dans `node:22.12.0-alpine`, sur `app/web/package-lock.json`), puis classer chaque avis A ou B. Vérifier si `esbuild` (dépendance directe, pas transitive) en fait partie.
2. **Preuve du cas B** : le `metafile` d'esbuild dans `app/web/build.mjs`, hors image (développeur).
3. **Policies à écrire par `policy`** avant l'action : 12 `STACK-restart-service`, 13 `FRONT-audit-npm`, 14 `DEV-sortie-url`. Revoir aussi `ENV-images-epinglees` (policy 00) : la surcouche `service` a une clé `image:` sans `build:` et doit être admise, comme ADR-008 le prévoit.
4. **Plugin compose de l'hôte** : `env_file.required` doit être accepté ; à vérifier par `action` (`./dev doctor` ne le teste pas aujourd'hui).
5. **Test de redémarrage de l'hôte** : non exigé cette itération (disruptif). Vérification par `docker inspect`. À trancher par le chef de projet.
6. **Adresse LAN `10.77.0.25`** : toujours à stabiliser par le responsable applicatif avant `deploy service` (risque R3, inchangé).
