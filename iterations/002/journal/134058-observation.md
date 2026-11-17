# observation — 2026-11-17T13:40:58+00:00

## Brief
Itération 002, tour 3 AOPR. Lecture seule. Restitue au format de ton périmètre : results.json (31 respectées, 0 violée, 13:40), audit-npm.meta.json et audit-npm.json, policies/checks/25, 29, 35 (versions modifiées ce tour), journaux du tour depuis 133755 (policy), 133919 (action, étape 1 bloquée par le garde-fou), 134002 (action, étapes 2/4/5). Écarts à vérifier : étapes 1 (pinage apt) et 3 (build) non faites ; ./dev audit-npm passe par docker run via tools/bin/npm (validé par ADR-014 hors runner, mais à consigner) ; la référence dae9044 reste en dur dans la policy 29 (ADR-015 §6) ; garde esbuild désormais bloquante ; SPEC-003.11 sans policy ; formulaires repliés non recettés. Ne modifie aucun fichier.

## Compte rendu
## 1. Faits vérifiés

Sources : `iterations/002/policies/results.json` (date 2026-11-17T13:40:39, `pile_demarree: true`, synthèse respectee 31 / violee 0 / non_applicable 0). Tous les `rc` valent 0.

**SPEC-001 (pile, passerelle, front, API)**
- 10 `APP-repond` (ENV mise en service) → respectee : « GET / → 200 ».
- 11 `GW-relais-auth` (SPEC-001.5/.6, CA-002-3) → respectee : « /auth/v1/health → 200 JSON (GoTrue v2.170.0) ».
- 12 `GW-relais-rest` (SPEC-001.5/.6, CA-002-3) → respectee : « /rest/v1/ → 200 ».
- 13 `GW-admin-bloque` (SPEC-001.7, SPEC-003.6, ADR-001, CA-002-3) → respectee : « /auth/v1/admin/* refusé (403) ».
- 14 `GW-csp` (SPEC-001.9, ADR-002, CA-002-3) → respectee : « CSP default-src 'self', connect-src 'self' ».
- 15 `FRONT-meme-origine` (SPEC-001.8/.10, CA-002-2/3) → respectee : « 4 fichiers servis sans URL d'autre hôte ; /config.js = ANON_KEY seule ».
- 16 `API-anon-refuse` (SPEC-002.1/.2, SPEC-001.12, CA-002-11) → respectee : « 27 requêtes anon, écritures et RPC refusées ».
- 20 `STACK-services` (SPEC-001.1/.2, CA-002-1) → respectee.
- 21 `STACK-ports` (SPEC-001.3, ADR-007, CA-002-1/3) → respectee : « seul app publie un port : ${APP_LAN_IP:-10.77.0.25}:${APP_PORT}:80 ».
- 33 `STACK-auth-debit` (SPEC-001.14, ADR-006 §1, CA-002-6/7/33) → respectee.
- 34 `STACK-points-accroche` (SPEC-004.11 à .14, ADR-006 §3) → respectee.

**SPEC-001.15 / ADR-010 / ADR-014 (npm)**
- 25 `FRONT-audit-npm` (SPEC-001.15 (b)(c), ADR-010, ADR-014, CA-002-2) → respectee. Message : « npm audit (iterations/002, statut reussie, sha256 du lock concordant) : 3 paquet(s) remonté(s), avis listés : GHSA-67mh-4wv8-2f99 (esbuild, cas A (ADR-010)), GHSA-8r88-6cj9-9fh5 (auth-js, cas A voie 1 (ADR-010)) ; aucun haut ni critique ; build.mjs : aucun serve/watch/context( ».
- 28 `FRONT-auth-js-non-appel` (SPEC-001.15 (e), ADR-010 voie 1) → respectee : « aucun appel à .admin., getUserById, updateUserById, deleteUser, listFactors ni deleteFactor dans 2 fichier(s) ».

**SPEC-002 (base)**
- 22 `DB-migrations-versionnees` (SPEC-001.13, SPEC-002, CA-002-1/33) → respectee : « 5 migrations 001→005 ».
- 23 `DB-rls-privileges-statique` (SPEC-002.1, SPEC-002 §5-6, ADR-005, CA-002-11) → respectee : « 4 tables à RLS ; EXECUTE révoqué sur 7 fonctions ».

**SPEC-003 (admin, secrets)**
- 02 `ENV-pas-de-secret` (SPEC-003.3, CA-002-2) → respectee.
- 05 `ENV-secrets-valeurs-absentes` (SPEC-003.3/.6/.7, SPEC-006 §1, CA-002-2) → respectee : « 5 valeurs secrètes de 2 fichiers absentes de 223 fichiers et de deploy.log ».
- 06 `ENV-devenv-ignore` (SPEC-003.3, ADR-003, CA-002-2) → respectee.
- 17 `ENV-secrets-fichier` (SPEC-003.1/.2, ADR-003, CA-002-4) → respectee.
- 35 `ADMIN-seed-sans-ecrasement` (SPEC-003.10/.12, ADR-012, CA-002-4/33) → respectee. Message : « seed.py : aucun PUT/PATCH/DELETE, POST /admin/users seulement si compte absent, aucun accès au fichier de secrets ; migrations et db.sh n'écrivent pas dans auth.users ».

**SPEC-004 (piles, ./dev, migrations)**
- 00 `ENV-images-epinglees` (SPEC-001.2, SPEC-004.16, ADR-008, CA-002-2) → respectee : « 14 références d'image vérifiées ».
- 01 `ENV-dependances-epinglees`, 03 `ENV-toolbox-epinglee`, 04 `ENV-npm-epinglees` (ADR-002, SPEC-006 §3.2) → respectee : « supabase-js 2.47.10 ».
- 24 `GARDE-FOU-mise-en-service` (SPEC-004.6, ADR-004, CLAUDE.md §5) → respectee : « 70 cas simulés ».
- 26 `STACK-restart-service` (SPEC-004.7, ADR-009, CA-002-36) → respectee.
- 27 `DEV-sortie-url` (SPEC-004.15/.17, ADR-007) → respectee.
- 29 `DB-migrations-additives` (SPEC-004.12/.18, ADR-011, ADR-015, CA-002-33) → respectee : « aucune migration >= 006 à contrôler ; 001 à 005 identiques à la référence dae9044 ».
- 32 `STACK-tags-par-pile` (SPEC-004.16, ADR-008, CA-002-2/36) → respectee.

**SPEC-005 (front)**
- 30 `FRONT-messages-tour3` (SPEC-005.7/.33/.40/.60/.62/.63 ; CA-002-27/28/34/38/39) → respectee : « M-1 à M-6 exacts ; aucun confirm(, alert(, innerHTML ».
- 31 `FRONT-barre-fixe` (SPEC-005.6, CA-002-37 proposé tour 3) → respectee.

**Audit npm (fichiers bruts)**
- `audit-npm.meta.json` : `statut` "reussie", `package_lock_sha256` 2bbd9f50bff63cd1e3a5dfc333ae786690fccdc4753c3470c70d410ce53f9eb9, `image` "node:22.12.0-alpine", `date` 2026-11-17T13:40:30+00:00.
- `audit-npm.json` : 3 entrées. `esbuild` (moderate, direct, GHSA-67mh-4wv8-2f99, range <=0.24.2, CVSS 5.3). `@supabase/auth-js` (low, GHSA-8r88-6cj9-9fh5, range <=2.69.1). `@supabase/supabase-js` (low, direct, via auth-js). `metadata.vulnerabilities` : low 2, moderate 1, high 0, critical 0.

**Journaux du tour**
- `133755-policy.md` (brief L4-8) : modifications annoncées de 25 et 29 ; L28 : « 35 : aucune modification » ; 25 réécrite (L15-21) ; 29 réécrite (L23-26) ; policies non exécutées à ce stade (L11, L35).
- `133919-action.md` : étape 1 bloquée par le garde-fou (L17-19, commande `docker run --rm python:3.13.1-slim …` refusée, rc non obtenu) ; fichiers modifiés : aucun (L27) ; étapes 2 à 5 non exécutées (L23-32).
- `134002-action.md` : étape 2 faite (L13-17, `bash -n` rc 0) ; étape 4 : rc 1, méta reussie, sha256 identique au lock (L19-26) ; étape 5 : rc 0, `{'respectee': 31, 'violee': 0, 'non_applicable': 0}` (L30-36).

## 2. Écarts constatés

**E1. Étape 1 (pinage apt de `tools/runner/Dockerfile`) non faite.**
- Preuve : `133919-action.md` L17-21 : refus du garde-fou (`tools/guards/guard.py`, regex `STACK_RE`) sur un `docker run` pour l'agent `action`. `134002-action.md` L4 : « étape 1 … NE SONT PAS faites ».
- Le Dockerfile n'est pas modifié : `133919-action.md` L21 (ligne 3 : `apt-get … install -y --no-install-recommends curl bash git`, sans version).

**E2. Étape 3 (`./dev build`) non faite.**
- Preuve : `134002-action.md` L4 et L11. Aucun journal ne consigne un `./dev build` lancé pendant ce tour.

**E3. `./dev audit-npm` passe par `docker run` (tools/bin/npm).**
- Preuve : `dev` L103 : `(cd app/web && "$ROOT/tools/bin/npm" audit --json) > "$out"`. `tools/bin/npm` L2 : `exec "$(dirname "$0")/_dockerized" npm "$@"`. `tools/bin/_dockerized` L16 : `exec docker run --rm … "$img" "$@"`.
- ADR-014 §Décision 1 (`specs/adr/ADR-014-audit-npm-hors-runner.md` L27-28) décrit cet appel : « via `tools/bin/npm`, dans l'image `node:22.12.0-alpine` ».
- `134002-action.md` L27 : l'action note que la commande « contredit l'interdiction générale de `docker run` » et que « le garde-fou ne l'a pas bloquée ». Le brief de `134002` L8 interdit pourtant « toute commande docker run ».

**E4. Référence `dae9044` en dur dans la policy 29.**
- Preuve : `policies/checks/29-db-migrations-additives.sh` L87 : `REF = "dae9044"`.
- ADR-015 §6 (`specs/adr/ADR-015-git-dans-runner.md` L44-45) : « La policy lit ce commit [consigné dans mise-en-service.md] ; `dae9044` est la valeur de l'itération 002 uniquement. »
- `133755-policy.md` L25 et L33 : la référence n'est plus lue dans `mise-en-service.md` ; la valeur est en dur.
- `iterations/002/mise-en-service.md` L114 : « Version de référence : commit `dae9044`, plus des modifications non commitées ». ADR-015 L17 : version déployée `dfbc020` plus un arbre non commité.

**E5. Garde esbuild devenue bloquante.**
- Preuve : `25-front-audit-npm.sh` L20-22 et L104-105 : `serve`, `watch` ou `context(` dans les scripts racine de `app/web` rend la policy violée (cas C).
- `133755-policy.md` L34 : « c'est une évolution par rapport à l'état précédent, où elle n'était qu'une note ».
- ADR-013 L109 : « garde esbuild : note non bloquante, violation si serve/watch/context (D-1 tranché) ».
- Constat : aucune occurrence dans les `*.mjs/*.cjs/*.js/*.ts` de la racine de `app/web` (recherche Grep, sans occurrence hors `src/`, où la policy ne scanne pas). Le message de la policy 25 le confirme.

**E6. SPEC-003.11 sans policy.**
- Preuve : `iterations/002/journal/133231-policy.md` L22 : « SPEC-003.11 : pas de policy » (spec classée « [P] et [R] : néant », vérification [T]).
- `results.json` : aucune entrée portant SPEC-003.11 ; la REF de la policy 35 (ligne 278) ne cite que SPEC-003.10 | SPEC-003.12.
- Pas de test de 003.11 à ce jour : `iterations/002/observation.md` L107 et `journal/132025-testeur.md` L30.
- Vérification `email_confirmed_at` reportée au second `deploy service` : `specs/adr/ADR-013-trace-decisions-chef-de-projet.md` L28 (D-4).

**E7. Formulaires repliés non recettés.**
- Le correctif CSS/`app.js` est documenté dans `journal/131243-developpeur.md` L21-24.
- `iterations/002/observation.md` L113 et `journal/133418-observation.md` L81 : non recetté dans un navigateur.
- `iterations/002/rapport-client.md` L81 liste encore le défaut « Formulaires repliés » (source : `journal/123712-client.md` L339).
- Dernier journal `client` : `journal/123712-client.md` (listing `journal/*client*` : 115831, 123328, 123527, 123712). Aucun journal client après le correctif du 131243.

**E8. Divergence sur la modification de la policy 35.**
- Le brief de la session demande « 25, 29, 35 (versions modifiées ce tour) ».
- `133755-policy.md` L28 : « 35 : aucune modification. L'en-tête porte déjà SPEC-003.10 et SPEC-003.12 » (la policy 35 avait été écrite au tour précédent, `133231-policy.md`).
- Non tranché : je ne dispose pas d'un moyen de lire les dates de modification.

**E9. Empreinte de l'audit non consignée dans `mise-en-service.md`.**
- ADR-014 L66 : la vérification [R] demande `statut` et sha256 « consignés dans `iterations/<NNN>/mise-en-service.md` ».
- Recherche sur `mise-en-service.md` (`audit|sha256|2bbd9f50`) : aucune occurrence de l'empreinte ni du statut d'audit (seule L114, sur `dae9044`).

## 3. Ce qui n'a pas pu être observé et pourquoi

- **Ré-exécution** : aucune commande n'a été lancée (lecture seule). Les résultats des policies 25, 28, 29, 35 sont rapportés tels que consignés dans `results.json` ; je n'ai pas relancé leur logique.
- **Policy 29 (git)** : la comparaison sha256 avec `git show dae9044:…` n'a pas été vérifiée ; seul le message de `results.json` est disponible.
- **Policy 28** : son script n'a pas été lu ; seul le résultat est consigné.
- **Modification réelle des fichiers ce tour** (25, 29, 35) : je n'ai pas accès aux dates de modification ; voir E8.
- **`./dev build` (étape 3)** : aucun journal de build de ce tour ; non vérifiable.
- **Tests (`iterations/002/tests/`)** : non consultés dans ce périmètre.
- **Recette client** : les captures `iterations/002/client/*.png` n'ont pas été ouvertes ; `rapport-client.md` n'a été lu que sur la ligne 81.
- **Journal `134015-developpeur.md`** (13:40:15, hors périmètre listé) : brief de modification de `tools/deploy/seed.py` et des messages de logs, compte rendu vide. Je ne peux pas dire si des fichiers ont été modifiés avant ou après l'exécution de `./dev policies` (13:40:39).
- **Garde-fou** : le blocage de l'étape 1 est rapporté par le journal `133919` ; je n'ai pas lu `tools/guards/guard.py`.
