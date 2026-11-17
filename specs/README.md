# Spécifications (persistées par l'agent `architecte`)

## Spécifications
| Id | Titre | Itération | CA couverts | Statut |
|---|---|---|---|---|
| SPEC-000 | Socle de l'environnement | 001 | — | actif |
| SPEC-001 | Pile Supabase auto-hébergée et passerelle unique | 002 | CA-002-1, 2, 3, 6, 7, 11, 33 | actif (amendé tour 1 complément : 001.3, 001.4, 001.11 ; tour 2 : 001.15 nouvelle) |
| SPEC-002 | Modèle de données, RLS, charge projetée, entraide | 002 | CA-002-4, 6, 8 à 36 | actif |
| SPEC-003 | Compte administrateur initial et secrets | 002 | CA-002-2, 4, 5, 33 | actif (amendé : 003.9 passe en `[T]`) |
| SPEC-004 | Piles dev / service, persistance, sauvegarde, contrat `./dev` | 002 | CA-002-1, 2, 33, 36 | actif (amendé tour 1 complément : 004.7 à 004.10, 004.16 ; tour 2 : 004.7 restart (ADR-009), 004.11 env_file longue, 004.17 nouvelle ; tour 2 complément : renommage `secrets.py` → `gen_secrets.py`) |
| SPEC-005 | Interface web (recette clavier/souris) | 002 | CA-002 [C] | actif |
| SPEC-006 | Plan de vérification (test / client / policy / RA) | 002 | CA-002-1 à 36 | actif (amendé : §1, §2, §3, §5 ; tour 2 : §2, §3 policies 9 et 12 à 14) |

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
| ADR-009 | Redémarrage automatique de toute la pile service (db, auth, rest, app) | accepté (tour 2) |
| ADR-010 | Vulnérabilités npm transitives de `app/web` : évaluation et décision | **accepté sous conditions, provisoire** (tour 2) ; preuve de bundle obtenue (tour 2, complément) ; identifiants des 3 avis à relever ; numéro de policy `FRONT-audit-npm` en collision avec la policy 13 existante |

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
  Amende ADR-004. Policy 12 (`STACK-restart-service`).
- **Contrat `./dev`** : nouvelle SPEC-004.17. `./dev` exporte `APP_LAN_IP` (défaut `10.77.0.25`) avant tout appel docker, la
  valeur est validée (IPv4 pointée) ; la ligne finale de `deploy` affiche `http://<APP_LAN_IP>:<APP_PORT>/` ; aucune
  chaîne `127.0.0.1`, `localhost` ni `0.0.0.0` dans `dev` ni dans ses sorties (ADR-007). Policy 14 (`DEV-sortie-url`).
- **Vulnérabilités npm** (`app/web`, 3 avis transitifs, 2 faibles et 1 modérée) : ADR-010, décision **provisoire** :
  aucune mise à jour (versions épinglées conservées) ; avis acceptés sous condition de classement A (non livré) ou B
  (livré, non atteignable), avec un contrôle continu. Nouvelle SPEC-001.15, policy 13 (`FRONT-audit-npm`).

Fichiers modifiés (specs uniquement) : `SPEC-001-pile-supabase.md`, `SPEC-004-piles-dev-service.md`,
`SPEC-006-plan-verification.md`, `adr/ADR-004-piles-dev-service.md`, `adr/ADR-006-verifiabilite-pile-dev.md`,
`README.md`. Nouveaux : `adr/ADR-009-redemarrage-pile-service.md`, `adr/ADR-010-vulnerabilites-npm-front.md`.

**Points ouverts** (tour 2) :
1. ADR-010 : les identifiants des 3 avis npm ne sont pas dans le dépôt ; l'architecte ne peut pas exécuter `npm audit`.
   Action : relever les identifiants (dans `node:22.12.0-alpine`), classer chaque avis A ou B. Vérifier si `esbuild`
   (dépendance directe, non transitive) fait partie des trois.
2. Le `metafile` d'esbuild (`app/web/build.mjs`) est nécessaire pour prouver le classement B (développeur, hors image).
3. `./dev` (agent `action`) : mettre en œuvre SPEC-004.17 (export de `APP_LAN_IP`, validation, ligne d'URL, suppression de `127.0.0.1`).
4. Policies à écrire par `policy` avant l'action : `STACK-restart-service` (12), `FRONT-audit-npm` (13), `DEV-sortie-url` (14),
   et la révision de `ENV-images-epinglees` (policy 00) : la surcouche `service` n'a pas de `build:` et doit être
   admise pour la clé `image:` (ADR-008), comme la pile de base.
5. `env_file` longue exige un plugin `docker compose` qui accepte `required` sur l'hôte : à vérifier par `action` (`./dev doctor`).
6. Test de redémarrage de l'hôte non exigé cette itération (disruptif) ; vérification par `docker inspect`. À confirmer par le chef de projet.
7. Adresse LAN `10.77.0.25` stable (risque R3) : action du responsable applicatif avant le premier `deploy service` (inchangé).

**Complément tour 2 (2026-11-17)** :
- SPEC-004 : `tools/deploy/secrets.py` renommé `gen_secrets.py` (§ contrat, SPEC-004.11, SPEC-004.15).
- ADR-010 : preuve de bundle reçue du développeur (metafile). Pré-classement A/B/C établi par paquet ; décision toujours
  provisoire. Restent ouverts : identifiants des 3 avis (C1), reproduction du metafile (C2), non-ouverture de WebSocket (C3).
- Collision de numérotation : `FRONT-audit-npm` (SPEC-006 §3, SPEC-001.15, ADR-010) désignée « policy 13 », déjà occupée par
  `policies/checks/13-gw-admin-bloque.sh`. Le numéro est à trancher par `policy`, puis SPEC-006 §3 est corrigé.
