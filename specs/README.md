# Spécifications (persistées par l'agent `architecte`)

## Spécifications
| Id | Titre | Itération | CA couverts | Statut |
|---|---|---|---|---|
| SPEC-000 | Socle de l'environnement | 001 | — | actif |
| SPEC-001 | Pile Supabase auto-hébergée et passerelle unique | 002 | CA-002-1, 2, 3, 6, 7, 11, 33 | actif (amendé tour 1 complément : 001.3, 001.4, 001.11 ; tour 2 : 001.15 nouvelle, puis (b) et (d) et policy n° 25, arbitrage 2026-11-17 ; décision 2026-11-17 : 001.15 (d) amendé, (e) ajouté, policy n° 28 ; tour 4 : 001.15 (b) précisé, audit hors runner, ADR-014) |
| SPEC-002 | Modèle de données, RLS, charge projetée, entraide | 002 | CA-002-4, 6, 8 à 36 | actif |
| SPEC-003 | Compte administrateur initial et secrets | 002 | CA-002-2, 4, 5, 33 | actif (amendé : 003.9 passe en `[T]` ; tour 3 : 003.5 amendé, 003.10 à 003.12 nouvelles, ADR-012 ; tour 4 : [R] de 003.10 et 003.12 (d) réécrits pour la pile service, ADR-013 D-6) |
| SPEC-004 | Piles dev / service, persistance, sauvegarde, contrat `./dev` | 002 | CA-002-1, 2, 33, 36 | actif (amendé tour 1 complément : 004.7 à 004.10, 004.16 ; tour 2 : 004.7 restart (ADR-009), 004.11 env_file longue, 004.17 nouvelle ; tour 2 complément : renommage `secrets.py` → `gen_secrets.py` ; tour 3 : 004.18 nouvelle, ADR-011 ; tour 3 : 004.8 et 004.13 amendés, ADR-012) |
| SPEC-005 | Interface web (recette clavier/souris) | 002 | CA-002-5 à 8, 10, 12 à 15, 17 à 19, 21 à 25, 27 à 30, 32, 34, 35 ; tour 3 : 27, 28, 34 précisés ; 37 à 39 proposés | actif (tour 3 : 005.6, 005.7, 005.62, 005.63 nouvelles ; 005.1, 005.33, 005.40, 005.60 amendées ; messages M-1 à M-6) |
| SPEC-006 | Plan de vérification (test / client / policy / RA) | 002 | CA-002-1 à 36 | actif (amendé : §1, §2, §3, §5 ; tour 2 : §2, §3 ; arbitrage 2026-11-17 : CA-002-1 (c) en [P], CA-002-9 avec 005.61, policies renumérotées n° 25 à 27 ; décision 2026-11-17 : §2 CA-002-2, §3 policy n° 28 ; tour 3 : §2 CA-002-27, 28, 33, 34 et CA-002-37 à 39 proposés, §3 policies n° 29 à 31 ; tour 4 : §2 CA-002-1 (écart accepté, ADR-013 D-8), §3 policies 25 et 16 (c) précisées, policy n° 35 proposée, numéros de fichiers explicités) |

## Décisions d'architecture
| Id | Titre | Statut |
|---|---|---|
| ADR-000 | Environnement de développement reproductible | accepté |
| ADR-001 | Supabase auto-hébergé minimal derrière nginx (postgres 15.8.1.060, gotrue v2.170.0, postgrest v12.2.8) | accepté (amendé par ADR-007 : réseau) |
| ADR-002 | Front HTML/JS natif, supabase-js 2.47.10, construit dans Docker (node 22.12.0) | accepté |
| ADR-003 | Secrets générés hors git (`.devenv/secrets/`) et seed admin idempotent | accepté (amendé par ADR-012 : pas d'écrasement du mot de passe admin) |
| ADR-004 | Deux piles (dev jetable, service persistante) et sauvegarde | accepté (amendé par ADR-007, ADR-008, ADR-009) |
| ADR-005 | Sécurité : RLS forcée, écritures sensibles par RPC | accepté |
| ADR-006 | Vérifiabilité de la pile dev : débit GoTrue (≥ 500 inscriptions/h), règle de même origine (code / `vendor/`), contrat `./dev` ↔ application | accepté (amende ADR-002 ; §3 amendé tour 2 : `env_file` longue) |
| ADR-007 | Publication des ports : une seule adresse LAN par pile (`${APP_LAN_IP}:${APP_PORT}`), runner hors LAN | accepté ; **dérogation CA-002-1 validée par le PO** (perimetre.md, D1) |
| ADR-008 | Tags des images construites localement, propres à chaque pile (`:dev`, `:service`) | accepté |
| ADR-009 | Redémarrage automatique de toute la pile service (db, auth, rest, app) | accepté (tour 2) ; policy n° 26 |
| ADR-010 | Vulnérabilités npm transitives de `app/web` : évaluation et décision | **accepté, tranché** (décision 2026-11-17) : esbuild GHSA-67mh-4wv8-2f99 = cas A, non bloquant ; auth-js GHSA-8r88-6cj9-9fh5 = cas A (voie 1), **blocage `deploy service` levé** sous condition de la policy n° 28 ; policies n° 25 et 28 ; tour 4 : contrôle continu par ADR-014, garde esbuild ouvert (ADR-013 D-1) |
| ADR-011 | Migrations additives et non destructives sur données réelles | accepté (tour 3, 2026-11-17) ; amende SPEC-004.12 par SPEC-004.18 ; policy n° 29 ; référence de comparaison précisée par ADR-015 |
| ADR-012 | Seed admin sans écrasement : la base fait foi après création | accepté (tour 3, 2026-11-17) ; amende ADR-003, SPEC-003.5, SPEC-004.8, SPEC-004.13 ; SPEC-003.10 à 003.12 (révisés : 003.10/003.11 vérifiés par stub GoTrue sans deploy) ; §6 complété (tour 4 : canal API, ADR-013 D-5) ; point à vérifier : champ `email_confirmed_at` de GoTrue v2.170.0 (premier contrôle réel au second `deploy service`) |
| ADR-013 | Trace des décisions du chef de projet (itération 002, 2026-11-17) | accepté (trace) ; D-1 garde esbuild **ouvert** |
| ADR-014 | Audit npm produit hors runner (`./dev audit-npm`, sans socket Docker) | accepté ; amende ADR-010 §5, SPEC-001.15 (b), SPEC-006 §3 (policy 25) |
| ADR-015 | git dans l'image du runner (apt, version exacte) pour la policy 29 | accepté ; amende ADR-011 (référence), SPEC-006 §3 (policy 29, item 16 (c)) ; version apt à relever |

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

**Points ouverts** (état du tour 2 avant la décision ci-dessous) :
1. ~~**Chef de projet** : lire GHSA-8r88-6cj9-9fh5 et indiquer le module et la fonction visés (voie 1), ou choisir la voie 2 ou 3.~~
   Traité (décision 2026-11-17, voie 1). `CA-002-36` (pile service) n'est plus bloqué par auth-js.
2. **Chef de projet** : inscrire la montée d'esbuild 0.28.2 au périmètre de l'itération 003 (recommandé).
3. **Policy** : écrire et exécuter la policy n° 25 (identifiants, metafile C2, recherche `serve`/`watch`/`context(`), dans `iterations/002/policies/`.
   Attention : `policy` doit utiliser le numéro 25 réservé, et non 13.
4. **Policies n° 26 et n° 27** : à écrire par `policy` avec les mêmes numéros.
5. **Divergence de sources** : `122914` (refus de `docker run`) et `123343` (`npm audit` réussi via le wrapper). La policy 25
   rejoue le relevé pour une preuve unique.
6. **Montée supabase-js** : si la voie 2 est choisie, amender SPEC-001.8 (b), SPEC-006 §3 item 2, ADR-002 et la policy 2 (version 2.47.10 écrite en dur).
7. **C3** (non-ouverture de WebSocket) et **C2** (metafile reproduit) : toujours non faits ; C3 n'est nécessaire que pour `realtime-js` en B conditionnel.

## Décision du chef de projet sur ADR-010 (tour 2, 2026-11-17) — voie 1 retenue

- **auth-js (GHSA-8r88-6cj9-9fh5, CVE-2025-48370, CWE-22, CVSS v4 2,7, ≤ 2.69.1, corrigé en 2.70.0)** : passe du cas C provisoire
  au **cas A** (non applicable, accepté). Fonctions visées : `auth.admin.getUserById`, `deleteUser`, `updateUserById`,
  `auth.mfa.listFactors`, `deleteFactor`. `app.js` n'appelle que `getSession`, `signInWithPassword`, `signUp`, `signOut`, et le
  front n'a pas la clé `service_role`. **Blocage de `./dev deploy service` levé**, sous condition de la **policy n° 28
  `FRONT-auth-js-non-appel`** (SPEC-001.15 (e), SPEC-006 §3) : aucune occurrence de `.admin.`, `getUserById`, `updateUserById`,
  `deleteUser`, `listFactors`, `deleteFactor` dans `app/web/src`.
- Réserve : la policy 28 ne couvre pas le bundle `vendor/supabase.js` ; la preuve C2 (metafile) reste à compléter (ADR-010).
- **SPEC-001.15** : (d) amendé (plus de cas C), (e) ajouté. **SPEC-006 §2** : CA-002-2 renvoie à la policy 28. **SPEC-006 §3** : policy 28.
- **CA-002-36** (pile service) : confirmable après exécution réussie de la policy 28 et du `deploy service` (SPEC-006 §2).
- Numéro **28** attribué à `FRONT-auth-js-non-appel` (libre au 2026-11-17).

**Itération 003** (à inscrire au périmètre) : montée de `@supabase/supabase-js` vers une version dont auth-js est **≥ 2.70.0**
(version exacte à fixer, nouvelle décision ; amendements SPEC-001.8 (b), SPEC-006 §3 item 2, ADR-002, policy 2) et montée
d'esbuild vers **0.28.x** (majeure, `build.mjs` et metafile à revalider).

Fichiers modifiés : `specs/adr/ADR-010-vulnerabilites-npm-front.md`, `specs/SPEC-001-pile-supabase.md` (SPEC-001.15),
`specs/SPEC-006-plan-verification.md` (§2 CA-002-2, §3 policy 28), `specs/README.md`.

## Tour 3 de l'itération 002 (2026-11-17) — retours de recette

Demandé par le chef de projet ; périmètre : specs uniquement. **Aucune mise en service** (pile `dev` gelée).

Décisions :
- **Retours 1 à 4 traités en front seul** (`app/web/src/app.js`, `app/web/style.css`). **Aucune migration SQL** : les RPC
  `request_help`, `offer_help`, `admin_list_accounts`, `admin_set_active` sont inchangées.
  - (1) confirmations exactes après « Demander de l'aide » et « Proposer mon aide », avec nom de tâche : SPEC-005.7, .33, .40 ;
  - (2) barre supérieure fixe (`sticky`), `scroll-padding-top` : SPEC-005.6 ;
  - (3) confirmation avant « Désactiver » (bloc inline, pas de modale native) : SPEC-005.63 ;
  - (4) recherche dans chaque liste d'administration, filtrage côté client : SPEC-005.62.
  - Textes exacts : section « Messages exacts » de SPEC-005 (M-1 à M-6).
- **Règle migrations** : SPEC-004.18 et ADR-011 (additives, non destructives, idempotentes ; `001` à `005` figés ;
  voie d'exception par ADR amendé, accord du chef de projet et sauvegarde préalable).
- **CA proposés** : CA-002-37 (barre), CA-002-38 (recherche), CA-002-39 (confirmation de désactivation et messages).
  Le product owner les inscrit au périmètre ; l'architecte ne crée pas de CA.

Nouveaux : `adr/ADR-011-migrations-additives.md`. Amendés : `SPEC-004-piles-dev-service.md` (004.18), `SPEC-005-interface.md`,
`SPEC-006-plan-verification.md` (§2, §3 policies 29 à 31), `README.md`.

Points ouverts :
1. Périmètre : inscrire CA-002-37 à 39 (product owner). Sans cela, les specs 005.6, .7, .62, .63 n'ont pas de CA de référence.
2. Policies 29, 30 et 31 à écrire par `policy` ; le `policy` vérifie que les numéros sont libres.
3. « Réaffecter » sans message de confirmation, « Loguer du temps » et « Modifier » : même défaut, non spécifiés (décision chef de projet). → **Accepté** pour 002 (ADR-013 D-7).
4. Policy 29 : référence git de comparaison des migrations `001`–`005` à consigner dans `mise-en-service.md` au prochain `deploy`. → Précisé (ADR-015 : `dae9044`).
5. Recette client de ces retours : à programmer après la levée du gel et un `./dev deploy` (pas de `reset`, SPEC-004.12 / ADR-011).

## Tour 3 de l'itération 002, suite : seed admin sans écrasement (2026-11-17, ADR-012)

Motif : relevé DevOps, le seed réécrit `ADMIN_PASSWORD` à chaque `deploy`, y compris sans `reset` avec données réelles.

Décisions :
- Le seed **crée** `ADMIN_EMAIL` s'il est absent et **ne modifie jamais** un compte existant (SPEC-003.10). Compte existant
  sans e-mail confirmé : rc≠0, rien modifié (SPEC-003.11).
- Après création, la **base fait foi** pour le mot de passe admin ; `ADMIN_PASSWORD` est un mot de passe initial ; le fichier
  et la base peuvent diverger, sans resynchronisation (SPEC-003.12, ADR-012). `reset` ramène au mot de passe du fichier ;
  `restore` restitue celui du dump (SPEC-004.8).
- Promotion `db.sh promote-admin` : idempotente, une ligne mise à jour même si déjà admin (SPEC-004.13, 003.5).
- **Aucun changement de `./dev`** (séquence SPEC-004.15 inchangée). Changement de `tools/deploy/seed.py` seul : agent `action`.

Fichiers modifiés : `SPEC-003-admin-secrets.md`, `SPEC-004-piles-dev-service.md`, `adr/ADR-003-secrets-et-seed.md` (renvoi),
`README.md`. Nouveau : `adr/ADR-012-seed-admin-sans-ecrasement.md`.

Points ouverts :
1. **Action** : modifier `tools/deploy/seed.py` (branche « compte absent » seule en écriture) ; `db.sh promote-admin` à vérifier
   idempotent (une ligne sur admin déjà promu). Déploiement sans `reset` par le responsable applicatif, à la levée du gel.
2. **Chef de projet** : le relevé ne dit pas si un administrateur a changé son mot de passe depuis le dernier `deploy` (il aurait
   été écrasé). À vérifier avant la levée du gel ; prévenir les utilisateurs concernés le cas échéant.
3. **Testeur** : `tests/test_003_admin.py` (SPEC-003.5, 003.10, 003.11, 003.12). **Policy** (`policy`) : contrôle statique de
   `seed.py` (SPEC-003.10) ; numéro à attribuer par `policy` après vérification qu'il est libre (25 à 31 déjà réservés par les tours 2 et 3).
4. **Chef de projet** : confirmer qu'aucune fonction de changement de mot de passe n'est attendue dans cette itération
   (sinon, nouvelle spec ; ADR-012, décision 6). → **Confirmé** (ADR-013 D-5) : hors périmètre 002 ; canal API existant, à trancher.
5. Non tranché : la modification de `ADMIN_EMAIL` dans le fichier de secrets après création crée un second compte admin
   (le seed ne supprime rien). Hors périmètre ; à traiter dans une itération dédiée si besoin.

## Mission du chef de projet, itération 002 (2026-11-17, suite à la réaction AOPR)

Source : `iterations/002/journal/132650-reaction.md` (lecture seule). Décisions consignées dans **ADR-013** (trace), détaillées dans
ADR-014 et ADR-015. Arbitrages confirmés : « Réaffecter », « Loguer du temps » et « Modifier » sans confirmation ; écart CA-002-1 « après reset » accepté.

Décisions :
- **D-1 (ADR-010, policy 25)** : auth-js cas A, `BLOQUE_AUTHJS="non"` (fichier conforme, ligne 17). Garde esbuild : libellé « cas C esbuild gardé » **signalé, non tranché** (contradiction avec le cas A de ADR-010) ; décision bloquant ou note à prendre.
- **D-2 (ADR-014)** : `./dev audit-npm` sur l'hôte écrit `iterations/<NNN>/policies/audit-npm.json` et `audit-npm.meta.json` ; la policy 25 vérifie le statut et le sha256 du lock. Pas de socket Docker dans le runner.
- **D-3 (ADR-015)** : git dans l'image runner, version apt exacte, `safe.directory /workspace` ; policy 29 (c) par `git show` et sha256 ; référence `dae9044`.
- **D-4 (SPEC-003.11, ADR-012)** : `email_confirmed_at`, repli `confirmed_at`, sinon rc≠0. Premier contrôle réel au second `deploy service`.
- **D-5 (ADR-012 §6 complété)** : pas de changement de mot de passe dans l'interface. Par API : canal `PUT /auth/v1/user` relayé par la passerelle, non spécifié. Hors périmètre 002.
- **D-6 (SPEC-003.10, 003.12)** : le premier `./dev deploy` après levée du gel est `./dev deploy service` ; [R] réécrits pour service.
- **D-7 (SPEC-005, défauts connus)** : « Réaffecter », « Loguer du temps », « Modifier » acceptés sans confirmation pour 002.
- **D-8 (SPEC-006 §2, CA-002-1)** : écart « après reset » accepté ; remplacé par le déploiement à blanc de service.

Fichiers modifiés : `SPEC-001-pile-supabase.md` (001.15 (b)), `SPEC-003-admin-secrets.md` (en-tête, 003.10 [R], 003.12 [R] (d)),
`SPEC-006-plan-verification.md` (en-tête, §2 CA-002-1, §3 items 8, 9, 11, 13, 16 (c), 19), `adr/ADR-010-vulnerabilites-npm-front.md`
(contrôle continu, points ouverts 2, 3, 6, historique), `adr/ADR-011-migrations-additives.md` (renvoi), `adr/ADR-012-seed-admin-sans-ecrasement.md`
(§6 complété), `README.md`. Nouveaux : `adr/ADR-013-trace-decisions-chef-de-projet.md`, `adr/ADR-014-audit-npm-hors-runner.md`,
`adr/ADR-015-git-dans-runner.md`.

**Points ouverts** :
1. **Chef de projet** : garde esbuild, bloquant ou note (ADR-013 D-1).
2. **Chef de projet** : canal API de changement de mot de passe, accepter et documenter, ou fermer (ADR-013 D-5).
3. **Chef de projet** : confirmer le numéro 35 pour la policy `SEED-sans-ecrasement` (SPEC-006 §3, item 19).
4. **Action** : vérifier que `dae9044` existe et correspond aux fichiers `001` à `005` de `dfbc020` (version déployée sur `dev`), relever la version apt de git (ADR-015).
5. **Action** : ajouter `./dev audit-npm` à `./dev help` et au contrat SPEC-004.1 (SPEC-004 non modifiée, hors périmètre de cette mission).
6. **Policy** : ADR-013 « actions consécutives » (policies 25, 29, 35).

**Actions par équipe** : voir ADR-013, section « Actions consécutives ».
