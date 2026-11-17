# Spécifications (persistées par l'agent `architecte`)

## Spécifications
| Id | Titre | Itération | CA couverts | Statut |
|---|---|---|---|---|
| SPEC-000 | Socle de l'environnement | 001 | — | actif |
| SPEC-001 | Pile Supabase auto-hébergée et passerelle unique | 002 | CA-002-1, 2, 3, 6, 7, 11, 33 | actif (amendé tour 1 complément : 001.3, 001.4, 001.11 ; tour 2 : 001.15 nouvelle, puis (b) et (d) et policy n° 25, arbitrage 2026-11-17) |
| SPEC-002 | Modèle de données, RLS, charge projetée, entraide | 002 | CA-002-4, 6, 8 à 36 | actif |
| SPEC-003 | Compte administrateur initial et secrets | 002 | CA-002-2, 4, 5, 33 | actif (amendé : 003.9 passe en `[T]`) |
| SPEC-004 | Piles dev / service, persistance, sauvegarde, contrat `./dev` | 002 | CA-002-1, 2, 33, 36 | actif (amendé tour 1 complément : 004.7 à 004.10, 004.16 ; tour 2 : 004.7 restart (ADR-009), 004.11 env_file longue, 004.17 nouvelle ; tour 2 complément : renommage `secrets.py` → `gen_secrets.py`) |
| SPEC-005 | Interface web (recette clavier/souris) | 002 | CA-002 [C] | actif |
| SPEC-006 | Plan de vérification (test / client / policy / RA) | 002 | CA-002-1 à 36 | actif (amendé : §1, §2, §3, §5 ; tour 2 : §2, §3 ; arbitrage 2026-11-17 : CA-002-1 (c) en [P], CA-002-9 avec 005.61, policies renumérotées n° 25 à 27) |

## Décisions d'architecture
| Id | Titre | Statut |
|---|---|---|
| ADR-000 | Environnement de développement reproductible | accepté |
| ADR-001 | Supabase auto-hébergé minimal derrière nginx (postgres 15.8.1.060, gotrue v2.170.0, postgrest v12.2.8) | accepté (amendé par ADR-007 : réseau) |
| ADR-002 | Front HTML/JS natif, supabase-js 2.47.10, construit dans Docker (node 22.12.0) | accepté |
| ADR-003 | Secrets générés hors git (`.devenv/secrets/`) et seed admin idempotent | accepté |
| ADR-004 | Deux piles (dev jetable, service persistante) et sauvegarde | accepté (amendé par ADR-007, ADR-008, ADR-009) |
| ADR-005 | Sécurité : RLS forcée, écritures sensibles par RPC | accepté |
| ADR-006 | Vérifiabilité de la pile dev : débit GoTrue (≥ 500 inscriptions/h), règle de même origine (code / `vendor/`), contrat `./dev` ↔ application | accepté (amende ADR-002 ; §3 amendé tour 2 : `env_file` longue) |
| ADR-007 | Publication des ports : une seule adresse LAN par pile (`${APP_LAN_IP}:${APP_PORT}`), runner hors LAN | accepté ; **dérogation CA-002-1 validée par le PO** (perimetre.md, D1) |
| ADR-008 | Tags des images construites localement, propres à chaque pile (`:dev`, `:service`) | accepté |
| ADR-009 | Redémarrage automatique de toute la pile service (db, auth, rest, app) | accepté (tour 2) ; policy n° 26 |
| ADR-010 | Vulnérabilités npm transitives de `app/web` : évaluation et décision | **accepté, partiellement tranché** (arbitrage 2026-11-17) : esbuild GHSA-67mh-4wv8-2f99 = cas A, non bloquant ; auth-js GHSA-8r88-6cj9-9fh5 = cas C provisoire, **bloquant pour `deploy service` uniquement** ; policy n° 25 |

Notes :
- SPEC-000.1 reste valable (`/` répond 200) ; la publication du port est désormais précisée par ADR-007
  (une adresse LAN par pile, `10.77.0.25`, plus de `127.0.0.1`). SPEC-001.3 et SPEC-001.4 suivent ADR-007.
- L'ADR-000 (« pile jetable ») est complété par l'ADR-004 : la pile `dev` reste jetable, seule la pile `service` est persistante.

## Tour 1 de l'itération 002 (ADR-006)
- nouvelles exigences : SPEC-001.14 (débit d'authentification) et SPEC-004.11 à SPEC-004.15 (contrat entre `./dev` et l'application) ;
- exigences précisées : SPEC-001.1, 001.8, 001.11, 001.13, SPEC-003.6, SPEC-004.7, 004.8, SPEC-006 §1 et §3.

## Tour 1, complément (arbitrage du chef de projet, 2026-11-17)
- publication des ports : option (b), une seule publication LAN par pile (ADR-007) ; SPEC-001.3, 001.4, 001.11, 004.10 amendées ;
- runner : ne joint pas `10.77.0.25` ; test LAN retiré du runner, vérification `[R]` (ADR-007 §4, SPEC-006 §5) ;
- tags d'images par pile (ADR-008) : nouvelle SPEC-004.16 ; `stack/compose.service.yml` porte `devenv/app:service` ;
- pile service retenue pour l'itération 002 : SPEC-004.7 à 004.9 ne sont plus « Could » ;
- SPEC-003.9 : vérification passée de `[R]` à `[T]` (marqueur à ajouter par le testeur), énoncé précisé ;
- **Points ouverts** (tour 1) : `perimetre.md` à mettre à jour (statut de la pile service) ; `policies/checks/21-stack-ports.sh`
  et la nouvelle policy `STACK-tags-par-pile` à écrire par l'agent `policy` ; adresse LAN de l'hôte à rendre stable
  (risque R3, responsable applicatif). La dérogation CA-002-1 est validée (D1 du PO) ; ce point est clos.

## Tour 2 de l'itération 002 (2026-11-17)
Demandé par le chef de projet ; périmètre : specs uniquement (l'architecte n'écrit que dans `specs/`).

Décisions :
- **SPEC-004.11** aligné sur la forme `env_file` longue `- path: ${DEVENV_SECRETS}` avec `required: false` (retenue par le
  développeur ; sans elle, `teardown` et `reset` échouent sans fichier de secrets, SPEC-004.2). Amende aussi SPEC-006 §3 (policy 9), ADR-006 §3.
- **Restart de la pile service** : `restart: unless-stopped` sur **db, auth, rest et app** (SPEC-004.7, ADR-009). Sans cela,
  après redémarrage de l'hôte, `app` repart seul et la pile n'est pas fonctionnelle. Pile `dev` : aucune politique.
  Amende ADR-004. Policy n° 26 (`STACK-restart-service`).
- **Contrat `./dev`** : nouvelle SPEC-004.17. `./dev` exporte `APP_LAN_IP` (défaut `10.77.0.25`) avant tout appel docker, la
  valeur est validée (IPv4 pointée) ; la ligne finale de `deploy` affiche `http://<APP_LAN_IP>:<APP_PORT>/` ; aucune
  chaîne `127.0.0.1`, `localhost` ni `0.0.0.0` dans `dev` ni dans ses sorties (ADR-007). Policy n° 27 (`DEV-sortie-url`).
- **Vulnérabilités npm** (`app/web`, 3 avis transitifs, 2 faibles et 1 modérée) : ADR-010, décision **provisoire** :
  aucune mise à jour (versions épinglées conservées). Nouvelle SPEC-001.15, policy n° 25 (`FRONT-audit-npm`).

Fichiers modifiés (specs uniquement) : `SPEC-001-pile-supabase.md`, `SPEC-004-piles-dev-service.md`,
`SPEC-006-plan-verification.md`, `adr/ADR-004-piles-dev-service.md`, `adr/ADR-006-verifiabilite-pile-dev.md`,
`README.md`. Nouveaux : `adr/ADR-009-redemarrage-pile-service.md`, `adr/ADR-010-vulnerabilites-npm-front.md`.

**Points ouverts** (tour 2, état initial) :
1. ADR-010 : identifiants des avis npm relevés (arbitrage 2026-11-17, ci-dessous).
2. Le `metafile` d'esbuild (`app/web/build.mjs`) est nécessaire pour la condition C2 (développeur, hors image).
3. `./dev` (agent `action`) : mettre en œuvre SPEC-004.17 (export de `APP_LAN_IP`, validation, ligne d'URL, suppression de `127.0.0.1`).
4. Policies à écrire par `policy` avant l'action : `STACK-restart-service` (n° 26), `FRONT-audit-npm` (n° 25), `DEV-sortie-url` (n° 27),
   et la révision de `ENV-images-epinglees` (policy 00) : la surcouche `service` n'a pas de `build:` et doit être
   admise pour la clé `image:` (ADR-008), comme la pile de base.
5. `env_file` longue exige un plugin `docker compose` qui accepte `required` sur l'hôte : à vérifier par `action` (`./dev doctor`).
6. Test de redémarrage de l'hôte non exigé cette itération (disruptif) ; vérification par `docker inspect`. À confirmer par le chef de projet.
7. Adresse LAN `10.77.0.25` stable (risque R3) : action du responsable applicatif avant le premier `deploy service` (inchangé).

**Complément tour 2 (2026-11-17)** :
- SPEC-004 : `tools/deploy/secrets.py` renommé `gen_secrets.py` (§ contrat, SPEC-004.11, SPEC-004.15).
- ADR-010 : preuve de bundle reçue du développeur (metafile). Pré-classement A/B/C établi par paquet.

## Arbitrages du chef de projet, tour 2 (2026-11-17, second arbitrage)

Décisions :
- **ADR-010, esbuild (GHSA-67mh-4wv8-2f99)** : cas **A**, accepté, non bloquant. Preuve : `build()` seul dans `build.mjs`,
  aucun `serve`/`watch`/`context(` dans `app/`, image servie ne contenant que `dist/`. Montée 0.28.2 (majeure) à demander
  au chef de projet pour l'**itération 003**.
- **ADR-010, auth-js (GHSA-8r88-6cj9-9fh5, et entrée dérivée supabase-js 2.47.10)** : cas **C provisoire** (pas de preuve de
  non-appel : le texte de l'avis n'est pas dans le dépôt). **Bloquant pour `./dev deploy service`**, non bloquant pour la
  pile `dev` ni pour la recette `dev`. Levée par la voie 1 (preuve de non-appel, recommandée), la voie 2 (montée
  supabase-js 2.119.0, nouvelle décision) ou la voie 3 (acceptation écrite du chef de projet). Pas de montée d'office.
- **SPEC-006 §2, CA-002-9** : reste [C] + [T] ; SPEC-005.61 ajouté à sa ligne.
- **SPEC-006 §2, CA-002-1 (c)** : passe en [P] (policy n° 27 `DEV-sortie-url`) ; le [R] se limite à (a) `curl` et (b) `ss -ltn`.
- **Collision de numéros** : la policy `FRONT-audit-npm` n'existe pas encore (aucun numéro attribué). Le « 13 » des specs
  est corrigé en **n° 25** (`policies/checks/13-gw-admin-bloque.sh` occupe 13). Par la même logique, `STACK-restart-service`
  passe de 12 à **n° 26** (`12-gw-relais-rest.sh`) et `DEV-sortie-url` de 14 à **n° 27** (`14-gw-csp.sh`). Numéros libres au
  2026-11-17 : 07, 08, 09, 18, 19, 25, 26, 27 et au-delà de 24, réservés ici à ces trois policies.

Fichiers modifiés : `specs/adr/ADR-010-vulnerabilites-npm-front.md`, `specs/SPEC-001-pile-supabase.md` (SPEC-001.15),
`specs/SPEC-006-plan-verification.md` (§2, §3), `specs/adr/ADR-009-redemarrage-pile-service.md` (référence de policy), `specs/README.md`.

**Points ouverts** :
1. **Chef de projet** : lire GHSA-8r88-6cj9-9fh5 et indiquer le module et la fonction visés (voie 1), ou choisir la voie 2 ou 3.
   Tant que ce point n'est pas levé, `CA-002-36` (pile service) reste **non confirmé**.
2. **Chef de projet** : inscrire la montée d'esbuild 0.28.2 au périmètre de l'itération 003 (recommandé).
3. **Policy** : écrire et exécuter la policy n° 25 (identifiants, metafile C2, recherche `serve`/`watch`/`context(`), dans `iterations/002/policies/`.
   Attention : `policy` doit utiliser le numéro 25 réservé, et non 13.
4. **Policies n° 26 et n° 27** : à écrire par `policy` avec les mêmes numéros.
5. **Divergence de sources** : `122914` (refus de `docker run`) et `123343` (`npm audit` réussi via le wrapper). La policy 25
   rejoue le relevé pour une preuve unique.
6. **Montée supabase-js** : si la voie 2 est choisie, amender SPEC-001.8 (b), SPEC-006 §3 item 2, ADR-002 et la policy 2 (version 2.47.10 écrite en dur).
7. **C3** (non-ouverture de WebSocket) et **C2** (metafile reproduit) : toujours non faits ; C3 n'est nécessaire que pour `realtime-js` en B conditionnel.
