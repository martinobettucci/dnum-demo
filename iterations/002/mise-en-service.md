Mise en service assurée exclusivement par le responsable applicatif. Aucun autre agent ne démarre, n'arrête ni ne détruit la pile : adressez vos demandes au chef de projet.

# Itération 002 — tour 1 : préparation de la mise en service (AUCUN déploiement)

- Statut : **non déployé**. Ce document est un plan de préparation et un relevé d'état, pas un compte rendu de mise en service.
- Date : 2026-11-17.
- Version du dépôt : commit `8a451c2`, arbre de travail propre pour `stack/`, `dev`, `app/`, `policies/` (non commité : uniquement les journaux d'agents de l'itération 002).
- Pile dev existante : projet `devenv`, issue de l'itération 001, toujours en marche (`devenv-app-1` healthy, port 127.0.0.1:8080 ; `devenv-client-1` up). Non touchée ce tour.
- Pile service : non déployée ; `stack/compose.service.yml` absent.
- Secrets : `.devenv/secrets/` absent (aucun fichier de secrets créé ce tour).
- Sauvegardes : `.devenv/backups/` absent.

## 1. Test de publication de port (SPEC-001.3, SPEC-001.4, ADR-004)

Conteneur jetable (`python:3.13.1-slim`, `http.server`), supprimé après chaque essai. Hôte : `10.77.0.25` (bail DHCP, `dynamic`), Docker 29.10.0 en mode rootless, driver de port `builtin`.

| Essai | Résultat |
|---|---|
| Publication `127.0.0.1:18099` seule | OK (200 sur 127.0.0.1) |
| Publication `10.77.0.25:18199` seule | OK (200 sur 10.77.0.25) |
| Publication `127.0.0.1:P` **et** `10.77.0.25:P` (même port P) | **ÉCHEC** : `address already in use`, dans les deux ordres d'écriture |
| `127.0.0.1:18500` et `10.77.0.25:18501` (ports différents) | OK (200 sur les deux) |

Conclusion : SPEC-001.3 et SPEC-001.4 (même `APP_PORT` sur les deux adresses) **ne peuvent pas être satisfaits** avec le driver actuel. Ce n'est pas un défaut de la pile applicative. Aucune configuration du daemon n'a été modifiée. Les options sont à trancher par l'architecte (ADR) : (a) ports distincts pour 127.0.0.1 et 10.77.0.25 (amendement de SPEC-001.3/.4) ; (b) publication sur 10.77.0.25 seul (la contrainte 127.0.0.1 tombe) ; (c) changement du driver de port du daemon rootless (`slirp4netns` ou `pasta`), qui touche l'hôte et demande une validation et un test dédié.

## 2. Relecture de `./dev deploy`, `backup`, `restore`

Constats bloquants, vérifiés dans le dépôt :

1. **`stack/compose.yml` ne définit ni `db`, ni `auth`, ni `rest`, ni `migrate`, ni `seed`.** SPEC-001.1 n'est pas satisfait. `./dev deploy` prend donc la branche « pas de service db » : il démarre `app` seul, affiche « migrations et seed ignorés » et **rend la main avec code 0**. C'est un faux succès, contraire à SPEC-001.5.
2. **`app/db/migrations/` absent** : aucune migration à appliquer (SPEC-001.13).
3. **`stack/compose.service.yml` absent** : `./dev deploy service` n'avertit que sur stderr et déploie une pile `app` seule sur 127.0.0.1:8081, sans `restart: unless-stopped` (ADR-004).
4. **`./dev backup` et `./dev restore` sont inopérants** : ils passent par `dbop` (service `migrate`) et `en_marche db` (service `db`), tous deux absents. Ils échoueront avant toute écriture. `restore` appelle aussi `dc stop auth rest`, qui n'existe pas.
5. **`app` publie uniquement `127.0.0.1:${APP_PORT}:80`** : la publication sur 10.77.0.25 manque (cf. section 1).
6. Image `app` = `nginx:1.27.3-alpine` (`wget` présent via busybox : healthcheck OK).
7. Les garde-fous `policies/checks/20-stack-services.sh`, `21-stack-ports.sh`, `22-db-migrations-versionnees.sh` doivent échouer tant que 1 à 5 ne sont pas corrigés. Non exécutés ce tour pour ne pas écrire dans `iterations/002/policies/`.

## 3. Plan de mise en service (à exécuter après correction des points bloquants)

Préalables (action/developpeur/architecte, pas moi) : services `db`, `auth`, `rest`, `migrate`, `seed` dans `stack/compose.yml` ; `app/db/migrations/001_*.sql` ; décision sur la publication 10.77.0.25 ; `stack/compose.service.yml` si la pile service est retenue.

**Pile dev** (jetable)
1. `./dev doctor` puis `./dev policies` (contrôle, observation).
2. `./dev teardown` (la pile actuelle est issue de l'itération 001 ; à faire seulement si le plan le demande).
3. `./dev reset` puis `./dev deploy` : SPEC-001.4 (deux URL) et SPEC-001.5 (code ≠ 0 si un service échoue).
4. Relevés : `./dev status`, `curl -sI http://127.0.0.1:8080/`, `curl -sI http://10.77.0.25:8080/` (si publication retenue), `ss -ltn`.
5. `./dev backup` puis `./dev reset` puis `./dev deploy` puis `./dev restore dev <fichier.dump>` (scénario SPEC-004.8).

**Pile service** (persistante)
1. Avant tout : `docker compose ls`, `docker volume ls` (référence pour SPEC-004.7).
2. `./dev deploy service` (port 8081, secrets `.devenv/secrets/service.env`).
3. Vérifier après : la pile `devenv` et ses volumes sont inchangés (comparaison avec l'étape 1).
4. `./dev backup service` régulièrement. `./dev reset service` **exige** `--confirmer-destruction` et une sauvegarde préalable.

## 4. Risques

| # | Risque | Gravité | Action proposée |
|---|---|---|---|
| R1 | Faux succès de `deploy` (code 0 sans base ni migrations) | Élevée | Faire échouer `deploy` si `db` absent ; bloquant avant toute mise en service |
| R2 | SPEC-001.3/.4 impossibles avec le driver rootless `builtin` (même port sur deux IP) | Élevée | Décision ADR (amendement, ou driver `slirp4netns`/`pasta` après test) |
| R3 | IP 10.77.0.25 en bail DHCP (`dynamic`) : un changement d'adresse casse la publication LAN | Moyenne | Adresse fixe ou `APP_LAN_IP` vérifié avant `deploy` |
| R4 | `backup`/`restore` inopérants : aucune sauvegarde possible à ce jour | Élevée pour la pile service | Ne pas `reset service` tant que backup/restore ne fonctionnent pas |
| R5 | Images `devenv/app:dev` partagées entre `devenv` et `dnum-service` (même tag) : un rebuild de l'une réécrit le tag de l'autre | Faible | Tag distinct par pile (ex. `devenv/app:service`) |
| R6 | Pile `devenv` de l'itération 001 encore en marche, hors commit documenté (`deploy.log` : « non-commite ») | Faible | Un `reset` + `deploy` la remettra à l'état du dépôt |
| R7 | Pas de secrets ni de sauvegardes existants : un `reset` de la pile service effacerait toute donnée non sauvegardée | Élevée | Sauvegarde obligatoire avant tout `reset service` |

## 5. État de la pile au moment du relevé

- `devenv-app-1` : Up 36 min, healthy, `127.0.0.1:8080->80`.
- `devenv-client-1` : Up 36 min.
- `dnum-service` : absente.
- Aucune publication sur 10.77.0.25.
- Aucun conteneur de test restant (vérifié après chaque essai).
