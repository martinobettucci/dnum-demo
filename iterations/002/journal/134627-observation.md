# observation — 2026-11-17T13:46:27+00:00

## Brief
Itération 002, observation FINALE AOPR. Lecture seule. Restitue au format de ton périmètre : results.json (31 respectées, 0 violée), audit-npm.meta.json, tools/runner/Dockerfile (versions épinglées git 1:2.39.5-0+deb12u3, curl 7.88.1-10+deb12u15, bash 5.2.15-2+b13), journaux du tour depuis 134058 (observation précédente), 134230 (réaction), 134407 (responsable-applicatif, versions apt), 134451 (action). Écarts restants : aucune policy ne contrôle le pinage apt du runner ; bash installé était b7, candidat b13 ; garde esbuild bloquante ; formulaires repliés non recettés (E7, report client sur dev après bascule proxy) ; E9 ajout méta dans mise-en-service.md par DevOps. Ne modifie aucun fichier.

## Compte rendu
## 1. Faits vérifiés

**Source principale : `iterations/002/policies/results.json`** (date `2026-11-17T13:46:04`, `pile_demarree: true`, synthèse `respectee: 31`, `violee: 0`, `non_applicable: 0`). Les 31 entrées ont `rc: 0` et `status: respectee`.

**SPEC-001 (pile, passerelle, front, API)**
- `APP-repond` (ENV mise en service), policy 10 : respectée, « GET / → 200 ».
- `GW-relais-auth` (SPEC-001.5/.6, CA-002-3), policy 11 : respectée, « /auth/v1/health → 200 JSON (GoTrue v2.170.0) ».
- `GW-relais-rest` (SPEC-001.5/.6, CA-002-3), policy 12 : respectée, « /rest/v1/ → 200 ».
- `GW-admin-bloque` (SPEC-001.7, SPEC-003.6, ADR-001, CA-002-3), policy 13 : respectée, « /auth/v1/admin/* refusé par la passerelle (403) ».
- `GW-csp` (SPEC-001.9, ADR-002, CA-002-3), policy 14 : respectée, « default-src 'self', connect-src 'self' ».
- `FRONT-meme-origine` (SPEC-001.8/.10, CA-002-2/3), policy 15 : respectée, « /config.js = ANON_KEY seule ».
- `API-anon-refuse` (SPEC-002.1/.2, SPEC-001.12, CA-002-11), policy 16 : respectée, « 27 requêtes anon refusées ou vides ».
- `STACK-services` (SPEC-001.1/.2, CA-002-1), policy 20 : respectée.
- `STACK-ports` (SPEC-001.3, ADR-007, CA-002-1/3), policy 21 : respectée, seul `app` publie un port.
- `STACK-auth-debit` (SPEC-001.14, ADR-006 §1, CA-002-6/7/33), policy 33 : respectée.
- `STACK-points-accroche` (SPEC-004.11 à .14, ADR-006 §3), policy 34 : respectée.

**SPEC-001.15 / ADR-010 / ADR-014 (npm)**
- `FRONT-audit-npm` (SPEC-001.15 (b)(c), ADR-010, ADR-014, CA-002-2), policy 25 : respectée. Message : « statut reussie, sha256 du lock concordant : 3 paquets, GHSA-67mh-4wv8-2f99 (esbuild), GHSA-8r88-6cj9-9fh5 (auth-js) ; aucun haut ni critique ».
- `FRONT-auth-js-non-appel` (SPEC-001.15 (e), ADR-010 voie 1, CA-002-2), policy 28 : respectée.

**SPEC-002 (base)**
- `DB-migrations-versionnees` (SPEC-001.13, SPEC-002, CA-002-1/33), policy 22 : respectée, « 5 migrations 001→005 ».
- `DB-rls-privileges-statique` (SPEC-002.1, SPEC-002 §5-6, ADR-005, CA-002-11), policy 23 : respectée, « 4 tables RLS, EXECUTE révoqué sur 7 fonctions ».
- `DB-migrations-additives` (SPEC-004.12/.18, ADR-011, ADR-015, CA-002-33), policy 29 : respectée, « 001 à 005 identiques à la référence dae9044 ».

**SPEC-003 (admin, secrets)**
- `ENV-pas-de-secret` (SPEC-003.3, CA-002-2), policy 02 : respectée.
- `ENV-secrets-valeurs-absentes` (SPEC-003.3/.6/.7, SPEC-006 §1, CA-002-2), policy 05 : respectée.
- `ENV-devenv-ignore` (SPEC-003.3, ADR-003, CA-002-2), policy 06 : respectée.
- `ENV-secrets-fichier` (SPEC-003.1/.2, ADR-003, CA-002-4), policy 17 : respectée.
- `ADMIN-seed-sans-ecrasement` (SPEC-003.10/.12, ADR-012, CA-002-4/33), policy 35 : respectée.
- Aucune entrée de `results.json` ne porte sur SPEC-003.11.

**SPEC-004 (piles, ./dev, migrations) et SPEC-006**
- `ENV-images-epinglees` (SPEC-001.2, SPEC-004.16, ADR-008, CA-002-2), policy 00 : respectée, « 14 références d'image vérifiées ».
- `ENV-dependances-epinglees`, policy 01 : respectée.
- `ENV-toolbox-epinglee`, policy 03 : respectée.
- `ENV-npm-epinglees` (ADR-002, SPEC-006 §3.2, CA-002-2), policy 04 : respectée, « supabase-js 2.47.10 ».
- `GARDE-FOU-mise-en-service` (SPEC-004.6, ADR-004, CLAUDE.md §5), policy 24 : respectée, « 70 cas simulés ».
- `STACK-restart-service` (SPEC-004.7, ADR-009, CA-002-36), policy 26 : respectée.
- `DEV-sortie-url` (SPEC-004.15/.17, ADR-007, CA-002-1), policy 27 : respectée.
- `STACK-tags-par-pile` (SPEC-004.16, ADR-008, CA-002-2/36), policy 32 : respectée.

**SPEC-005 (front)**
- `FRONT-messages-tour3` (SPEC-005.7/.33/.40/.60/.62/.63 ; CA-002-27/28/34/38/39), policy 30 : respectée, « M-1 à M-6 exacts ; aucun confirm(, alert(, innerHTML ».
- `FRONT-barre-fixe` (SPEC-005.6, CA-002-37 proposé), policy 31 : respectée.

**Fichiers bruts de l'audit npm**
- `policies/audit-npm.meta.json` : `statut` "reussie", `package_lock_sha256` `2bbd9f50bff63cd1e3a5dfc333ae786690fccdc4753c3470c70d410ce53f9eb9`, `image` "node:22.12.0-alpine", `date` `2026-11-17T13:45:51+00:00`.
- `policies/audit-npm.json` : 3 entrées. `esbuild` (moderate, direct, GHSA-67mh-4wv8-2f99, CVSS 5.3). `@supabase/auth-js` (low, indirect, GHSA-8r88-6cj9-9fh5). `@supabase/supabase-js` (low, direct, via auth-js). `metadata.vulnerabilities` : low 2, moderate 1, high 0, critical 0, total 3.

**Tour (journaux)**
- `134451-action.md` L17-18 : `tools/runner/Dockerfile` ligne 3 contient `install -y --no-install-recommends git=1:2.39.5-0+deb12u3 curl=7.88.1-10+deb12u15 bash=5.2.15-2+b13`. Le fichier lu confirme ces trois versions (ligne 3).
- `134407-responsable-applicatif.md` L11-17 : candidats apt relevés dans `python:3.13.1-slim` : git `1:2.39.5-0+deb12u3`, curl `7.88.1-10+deb12u15`, bash installé `5.2.15-2+b7`, candidat `5.2.15-2+b13`.
- `134407` L21 : section « Écart E9 » ajoutée à `mise-en-service.md`. Confirmée à `mise-en-service.md` L312-318.
- `134451` L24 : `./dev audit-npm` rc=1. `134451` L21 et L29 : `./dev build` rc=0 et `./dev policies` rc=0.

## 2. Écarts constatés

**E-a. Date de l'audit citée dans `mise-en-service.md` non à jour.**
- `iterations/002/mise-en-service.md` L316 : « date `2026-11-17T13:40:30+00:00` ».
- `policies/audit-npm.meta.json` L5 : `"date": "2026-11-17T13:45:51+00:00"`.
- Le sha256 du lock est identique dans les deux fichiers (`2bbd9f50…`).

**E-b. Troisième paquet de l'audit non nommé dans `mise-en-service.md`.**
- `mise-en-service.md` L318 : « et un troisième ».
- `policies/audit-npm.json` L39-56 : `@supabase/supabase-js`, low, direct.
- `134407` L27 indique que ce paquet n'était pas identifié par l'agent DevOps.

**E-c. Pinage apt sans policy.**
- Les 31 entrées `POLICY` de `results.json` ne contiennent aucune policy dont le sujet est le pinage des paquets apt de `tools/runner/Dockerfile`.
- `134451` L37 : « Aucun contrôle ne couvre le pinage des paquets apt du Dockerfile runner ».

**E-d. Version bash installée différente de la version pinée.**
- `134407` L15 : bash installé `5.2.15-2+b7`, candidat `5.2.15-2+b13`.
- `tools/runner/Dockerfile` L3 : `bash=5.2.15-2+b13`.
- Aucun journal de build ou fichier de log du build n'est présent dans `iterations/002/` ; l'affirmation « le build a installé les versions épinglées » ne repose que sur `134451` L21.

**E-e. Policy 25 : garde esbuild.**
- `results.json`, entrée `FRONT-audit-npm` : `respectee`, rc 0. Le message mentionne « esbuild, cas A (ADR-010) ».
- Une garde esbuild `serve`/`watch`/`context(` rendrait la policy violée selon l'observation précédente (`134058` E5, qui cite `25-front-audit-npm.sh` L20-22 et L104-105). Je n'ai pas relu le script dans ce tour : seul le statut `respectee` est vérifié.

**E-f. Formulaires repliés non recettés.**
- `iterations/002/rapport-client.md` L81 : le défaut « Formulaires repliés » figure toujours dans le rapport.
- Aucune capture ni journal client postérieur au correctif (`131243`) n'a été relu dans ce tour.

**E-g. Référence `dae9044` en dur.**
- `results.json`, entrée `DB-migrations-additives` : « référence dae9044 ».
- `mise-en-service.md` L114 : « Version de référence : commit `dae9044`, plus des modifications non commitées ».
- `134058` E4 cite `policies/checks/29-db-migrations-additives.sh` L87 (`REF = "dae9044"`) et ADR-015 §6. Je n'ai pas relu ces deux fichiers dans ce tour.

**E-h. Code de sortie et empreinte de l'audit rapportés seulement par journal.**
- `134451` L24 : `./dev audit-npm` rc=1.
- `134451` L26 : « sha256 du méta = `1ab07795…` ». Le fichier `audit-npm.meta.json` ne contient pas de champ de ce type (4 champs : `statut`, `package_lock_sha256`, `image`, `date`) ; la valeur n'existe que dans le journal.

**E-i. Horodatage des résultats de l'observation précédente périmé.**
- `134058` cite `results.json` daté 13:40:39 ; `134230` relève 13:42:21 ; le fichier lu dans ce tour indique 13:46:04.
- Le fichier courant est postérieur à `audit-npm.meta.json` (13:45:51), donc postérieur au dernier audit.

**E-j. Compte rendu du développeur vide (hérité de `134058` E10).**
- Non relu dans ce tour (journal `134015`). Statut : non vérifié, voir section 3.

## 3. Ce qui n'a pas pu être observé et pourquoi

- **Ré-exécution** : lecture seule ; aucune policy, aucun script ni commande n'a été relancé. Les résultats sont ceux consignés dans `results.json`.
- **Empreintes sha256** : je n'ai pas de shell en lecture seule pour recalculer le sha256 du lock ni du méta (valeur `1ab0…` de `134451` non recalculée).
- **Build** : aucun log de `./dev build` dans `iterations/002/` ; le résultat rc=0 et la mention « versions installées » ne sont attestés que par `134451`.
- **Scripts des policies 25, 28, 29, 35** : non relus dans ce tour. Seuls leurs messages dans `results.json` sont vérifiés.
- **Tests (`iterations/002/tests/`)** : non consultés dans ce tour.
- **Captures `client/*.png`** : non ouvertes ; `rapport-client.md` lu uniquement sur les lignes 30, 57, 66 et 81.
- **Journal `134015-developpeur.md`** : non relu dans ce tour.
- **`git status`** : la liste de fichiers modifiés de `134451` L41 et la modification de `mise-en-service.md` ne sont pas confirmées par git (aucune commande git lancée).
- **Garde-fou `tools/guards/guard.py`** : non lu ; le blocage de `docker run` rapporté par `133919` n'est pas vérifié.
