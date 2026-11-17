# observation — 2026-11-17T13:34:18+00:00

## Brief
Itération 002, tour 2, nouvelle passe (après policies 25, 29, 35 et audit-npm). Lecture seule. Restitue au format de ton périmètre : faits de iterations/002/policies/results.json (31 respectées, 0 violée), audit-npm.json, les journaux du tour depuis 132904 (policy), 133014 (policy), 133035 (action), 133231 (policy), 133356 (action). Écarts : la policy 25 est verte mais son contrôle C2 (metafile) est signalé non vérifié ; SPEC-003.11 n'a pas de policy (vérification [T]) ; l'effet réel sur auth.users reste [R] ; le client n'a pas recetté les formulaires repliés. Vérifie les faits sur results.json, ne modifie aucun fichier.

## Compte rendu
**1. Faits vérifiés**

Source : `iterations/002/policies/results.json`, date 2026-11-17T13:34:07, `pile_demarree: true`, synthèse `respectee: 31, violee: 0, non_applicable: 0`. Les 31 entrées ont `rc: 0`.

Policies à REF SPEC-001 / ENV / ADR (`results.json` L7-L23, L70-L104, L115-L121, L142-L157, L196-L212, L232-L248) :

| Policy (fichier) | Statut | REF | Sortie (résumé) |
|---|---|---|---|
| ENV-images-epinglees (00) | respectee | ENV, SPEC-001.2, SPEC-004.16, ADR-008, CA-002-2 | 14 références d'image, tags exacts |
| ENV-dependances-epinglees (01) | respectee | ENV | dépendances Python épinglées (==) |
| ENV-pas-de-secret (02) | respectee | SPEC-003.3, CA-002-2 | aucun motif de secret dans le dépôt |
| ENV-toolbox-epinglee (03) | respectee | ENV | images toolbox épinglées |
| ENV-npm-epinglees (04) | respectee | ADR-002, SPEC-006 §3.2, CA-002-2 | 2 dépendances npm exactes, supabase-js 2.47.10 |
| ENV-secrets-valeurs-absentes (05) | respectee | SPEC-003.3/.6/.7, SPEC-006 §1, CA-002-2 | 5 valeurs secrètes absentes de 211 fichiers et de deploy.log |
| ENV-devenv-ignore (06) | respectee | SPEC-003.3, ADR-003, CA-002-2 | `.gitignore` ignore `.devenv/` |
| APP-repond (10) | respectee | ENV (mise en service) | GET / → 200 |
| GW-relais-auth (11) | respectee | SPEC-001.5/.6, CA-002-3 | /auth/v1/health → 200 JSON (GoTrue v2.170.0) |
| GW-relais-rest (12) | respectee | SPEC-001.5/.6, CA-002-3 | /rest/v1/ → 200 (PostgREST) |
| GW-admin-bloque (13) | respectee | SPEC-001.7, SPEC-003.6, ADR-001, CA-002-3 | /auth/v1/admin/* refusé (403) |
| GW-csp (14) | respectee | SPEC-001.9, ADR-002, CA-002-3 | CSP présente sur / |
| FRONT-meme-origine (15) | respectee | SPEC-001.8/.10, ADR-002, CA-002-2/3 | 4 fichiers servis sans URL d'autre hôte ; /config.js = ANON_KEY seule |
| API-anon-refuse (16) | respectee | SPEC-002.1/.2, SPEC-001.12, CA-002-11 | 27 requêtes anon refusées |
| ENV-secrets-fichier (17) | respectee | SPEC-003.1/.2, ADR-003, CA-002-4 | dev.env 0700/0600, 6 clés, HS256 |
| STACK-services (20) | respectee | SPEC-001.1/.2, ADR-001, CA-002-1 | services conformes |
| STACK-ports (21) | respectee | SPEC-001.3, ADR-007, CA-002-1/3 | seul app publie un port |
| DB-migrations-versionnees (22) | respectee | SPEC-001.13, SPEC-002, CA-002-1/33 | 5 migrations 001→005 |
| DB-rls-privileges-statique (23) | respectee | SPEC-002.1, SPEC-002 §5-6, ADR-005, CA-002-11 | RLS activée et forcée sur 4 tables |
| GARDE-FOU-mise-en-service (24) | respectee | SPEC-004.6, ADR-004 | 70 cas simulés conformes |
| **FRONT-audit-npm (25)** | **respectee** | SPEC-001.15 (b)(c), ADR-010, CA-002-2 | « 3 paquet(s) remonté(s), avis : GHSA-67mh-4wv8-2f99 (esbuild, cas A), GHSA-8r88-6cj9-9fh5 (auth-js, cas A voie 1) ; aucun haut ni critique ; **C2 (metafile) non vérifiée** » (L193) |
| STACK-restart-service (26) | respectee | SPEC-004.7, ADR-009, CA-002-36 | restart unless-stopped conforme |
| DEV-sortie-url (27) | respectee | SPEC-004.15/.17, ADR-007, CA-002-1 | sortie http://${APP_LAN_IP}:${APP_PORT}/ |
| FRONT-auth-js-non-appel (28) | respectee | SPEC-001.15 (e), ADR-010 voie 1, CA-002-2 | aucun appel admin dans app/web/src |
| **DB-migrations-additives (29)** | **respectee** | SPEC-004.18/.12, ADR-011, CA-002-33 | aucune migration ≥ 006 ; 001-005 identiques à dae9044 |
| FRONT-messages-tour3 (30) | respectee | SPEC-005.7/.33/.40/.60/.62/.63, CA-002-27/28/34/38/39 | M-1 à M-6 exacts |
| FRONT-barre-fixe (31) | respectee | SPEC-005.6, CA-002-37 | barre .entete sticky |
| STACK-tags-par-pile (32) | respectee | SPEC-004.16, ADR-008, CA-002-2/36 | tags dev/service distincts |
| STACK-auth-debit (33) | respectee | SPEC-001.14, ADR-006 §1, CA-002-6/7/33 | débits GoTrue ≥ 1000 |
| STACK-points-accroche (34) | respectee | SPEC-004.11-.14, ADR-006 §3, CA-002-1/2 | migrate et seed conformes |
| **ADMIN-seed-sans-ecrasement (35)** | **respectee** | SPEC-003.10, SPEC-003.12, ADR-012, CA-002-4/33 | seed.py : aucun PUT/PATCH/DELETE ; POST seulement si compte absent ; aucun accès au fichier de secrets (L283) |

Fichier `iterations/002/policies/audit-npm.json` (lu tel quel) :
- `vulnerabilities` : 3 entrées.
  - `@supabase/auth-js` : severity low, `isDirect: false`, avis GHSA-8r88-6cj9-9fh5 (CWE-22, range ≤2.69.1), fix via supabase-js 2.119.0.
  - `@supabase/supabase-js` : severity low, `isDirect: true`, range `2.41.1 - 2.49.10 || 2.58.1-canary.0`, fix 2.119.0.
  - `esbuild` : severity moderate, `isDirect: true`, avis GHSA-67mh-4wv8-2f99 (CWE-346, CVSS 5.3), range ≤0.24.2, fix 0.28.2 (`isSemVerMajor: true`).
- `metadata.vulnerabilities` : info 0, low 2, moderate 1, high 0, critical 0, total 3.
- `metadata.dependencies` : prod 16, dev 26, optional 25, total 41.
- Le fichier ne contient pas de champ de date.

Journaux du tour (heure du nom de fichier) :
- **132904-policy** : brief de modification de la policy 25 (BLOQUE_AUTHJS, lecture de l'audit). Compte rendu : policy non exécutée, aucun outil Bash.
- **133014-policy** : renommage `npm-audit.json` → `audit-npm.json` dans la policy 25 (8 occurrences). Le compte rendu annonce « numéro d'itération lu depuis iterations/CURRENT » (voir écart 2.2). `bash -n` non lancé.
- **133035-action** : `./dev build` rc 0 ; `./dev audit-npm` rc 1, fichier écrit (2654 octets annoncés), métadonnées info 0 / low 2 / moderate 1 / high 0 / critical 0 / total 3, avis par GHSA identiques à audit-npm.json. `./dev policies` rc 0, résultat `{respectee: 30, violee: 0, non_applicable: 0}` à ce moment. Policy 25 et policy 29 respectées.
- **133231-policy** : policy 35 écrite (SPEC-003.10 et SPEC-003.12). SPEC-003.11 non couvert par une policy. Non exécutée à ce stade ; `chmod +x` demandé.
- **133356-action** : `chmod +x` de la policy 35 (rc 0), puis `./dev policies` rc 0 → `{respectee: 31, violee: 0, non_applicable: 0}`. Policy 35 respectée (même message que results.json L283).

**2. Écarts constatés**

2.1 **Policy 25 verte avec C2 non vérifiée.** `results.json` L193 : statut `respectee` et sortie se terminant par « C2 (metafile) non vérifiée ». Dans `policies/checks/25-front-audit-npm.sh`, le message de succès (L74) contient ce libellé en dur et est affiché sur toute sortie réussie. Le script ne contient aucun contrôle de metafile : la seule vérification sur `app/web/build.mjs` (L65-70) cherche `serve|watch|context(` et produit une note « ATTENTION », non bloquante. Le journal 123442-architecte (L51) et 123940-architecte (L22) indiquent aussi que C2 reste à compléter.

2.2 **Numéro d'itération de la policy 25.** Le compte rendu 133014 indique « numéro lu depuis iterations/CURRENT ». Dans le script, le chemin est écrit en dur : L5 (commentaire), L23 `AUDIT_PATH = ROOT / "iterations/002/policies/audit-npm.json"`, et L37-L74 (messages). Aucune lecture de `iterations/CURRENT` n'apparaît dans le script.

2.3 **SPEC-003.11 sans policy.** Le journal 133231 (L22) indique : « La spec le classe [P] et [R] : néant ; sa vérification est [T] ». Aucune entrée de `results.json` ne porte SPEC-003.11 (REF L278 : SPEC-003.10 | SPEC-003.12 seulement).

2.4 **Effet réel sur `auth.users` : [R].** La policy 35 vérifie statiquement (`results.json` L283) que `seed.py` n'effectue pas de PUT/PATCH/DELETE et que migrations et `db.sh` n'écrivent pas dans `auth.users`. Le journal 133231 (L24) indique que l'effet réel reste hors statique, donc non vérifié. Le journal 131849 (L14) reporte la vérification de `email_confirmed_at` (GoTrue v2.170.0) à la recette [R].

2.5 **Formulaires repliés non recettés.** `iterations/002/rapport-client.md` L81 (passe 1, source `journal/123712-client.md` L339) décrit le défaut : les formulaires « Nouvelle tâche », « Modifier », « Loguer du temps », « Réaffecter » et « Demander de l'aide » se déplient au-dessus ou au-dessous du contenu. Le correctif CSS/app.js est décrit dans `journal/131243-developpeur.md` (L21-24), avec la mention « non recetté visuellement » (L49). Aucun journal `client` postérieur à 123712 n'existe dans l'itération (glob `journal/13*`).

**3. Ce qui n'a pas pu être observé, et pourquoi**

- **Métadonnées de fichiers** : je n'ai que la lecture de contenu. Je ne peux pas vérifier la comparaison d'horodatage de la policy 25 (`audit-npm.json` postérieur à `app/web/package-lock.json`), la taille annoncée de 2654 octets, ni les droits `+x` de la policy 35.
- **Métadonnées du metafile** : `app/web/build.mjs` et le metafile ne sont pas lus. C2 n'est donc pas observable depuis ces sources.
- **Ré-exécution** : aucune policy ni `./dev` n'a été relancé ; les statuts sont ceux de `results.json` à 13:34:07.
- **Effet sur `auth.users`, `email_confirmed_at`** : pas d'accès à la base ni à la pile (recette [R], hors périmètre de lecture de fichiers).
- **Rendu des formulaires repliés** : aucun navigateur ; les captures PNG de `iterations/002/client/` n'ont pas été ouvertes, et aucune ne documente un formulaire replié après correctif.
- **Journaux hors liste** : `132918-architecte`, `133259-responsable-applicatif`, `133418-observation` et `132439`/`132650` n'ont pas été lus (hors liste fournie).
