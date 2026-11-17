# Itération 002 — observation (tour 2)

> Restitution intégrale de l'agent observation (Team AOPR, lecture seule), consignée par le chef de projet. Source : `journal/132439-observation.md`.

# Observation — itération 002, tour 2 (lecture seule)

Sources lues : `iterations/002/policies/results.json` (daté 2026-11-17T13:24:22), les 12 journaux `*131*`/`*132*`, et, pour les écarts, `policies/checks/25-front-audit-npm.sh`, `policies/checks/29-db-migrations-additives.sh`, `specs/adr/ADR-010…`, `specs/README.md`, `specs/SPEC-001…`, `specs/SPEC-006…`. Aucun fichier modifié. Les secrets n'ont pas été lus.

## 1. Faits vérifiés

Synthèse de `results.json` : 30 entrées, 28 respectées, 2 violées, 0 non applicable (lignes 277-281). Ce résultat remplace les deux précédents (17 respectées / 3 violées) cités dans les journaux `131243`, `131515` et `131605`.

**ENV (SPEC-001.2, SPEC-003, SPEC-006, ADR-002/003/008)**
- ENV-images-epinglees : respectée, 14 références (L7-13).
- ENV-dependances-epinglees : respectée (L16-22).
- ENV-pas-de-secret (SPEC-003.3, CA-002-2) : respectée (L25-31).
- ENV-toolbox-epinglee : respectée (L34-40).
- ENV-npm-epinglees (ADR-002, SPEC-006 §3.2) : respectée, 2 dépendances exactes (L43-49).
- ENV-secrets-valeurs-absentes (SPEC-003.3/.6/.7) : respectée, 5 valeurs absentes de 198 fichiers et de deploy.log (L52-58).
- ENV-devenv-ignore : respectée (L61-67).
- ENV-secrets-fichier (SPEC-003.1/.2, QUAND deployed) : respectée (L132-140).

**Mise en service, passerelle, front, API (QUAND deployed)**
- APP-repond : GET / → 200 (L70-76).
- GW-relais-auth (SPEC-001.5/.6) : respectée (L79-86).
- GW-relais-rest (SPEC-001.5/.6) : respectée (L88-95).
- GW-admin-bloque (SPEC-001.7, SPEC-003.6, ADR-001) : respectée, 403 (L97-104).
- GW-csp (SPEC-001.9) : respectée (L106-113).
- FRONT-meme-origine (SPEC-001.8/.10) : respectée (L115-122).
- API-anon-refuse (SPEC-002.1/.2) : respectée, 27 requêtes (L124-131).
- FRONT-auth-js-non-appel (SPEC-001.15 (e), ADR-010 voie 1) : respectée (L213-221).

**STACK / DEV (SPEC-004, ADR-006/007/008/009)**
- STACK-services (SPEC-001.1/.2) : respectée (L142-149).
- STACK-ports (SPEC-001.3, ADR-007) : respectée, publication `${APP_LAN_IP:-10.77.0.25}:${APP_PORT}:80` (L151-158).
- STACK-restart-service (SPEC-004.7, ADR-009) : respectée (L196-203).
- DEV-sortie-url (SPEC-004.17) : respectée (L205-212).
- STACK-tags-par-pile (SPEC-004.16, ADR-008) : respectée (L250-257).
- STACK-auth-debit (SPEC-001.14, ADR-006 §1) : respectée (L259-266).
- STACK-points-accroche (SPEC-004.11 à .14) : respectée (L268-275).

**DB (SPEC-001.13, SPEC-002)**
- DB-migrations-versionnees : respectée, 001→005 (L159-167).
- DB-rls-privileges-statique (SPEC-002.1, ADR-005) : respectée (L168-176).

**Garde-fou et front tour 3 (SPEC-005)**
- GARDE-FOU-mise-en-service (SPEC-004.6, ADR-004) : respectée, 70 cas (L177-185).
- FRONT-messages-tour3 (SPEC-005 M-1 à M-6) : respectée (L231-239).
- FRONT-barre-fixe (SPEC-005.6, CA-002-37) : respectée (L240-248).

**Journaux du tour (faits, par agent)**
- **architecte 131243** (13:12:43, « tour 3 ») : ADR-012, seed idempotent sans écrasement, SPEC-003/004 amendées. Points ouverts : le relevé ne dit pas si un admin a changé son mot de passe (L26) ; déploiement sans reset à la levée du gel (L27).
- **architecte 131849** (13:18:49, « tour 3 ») : marqueurs [T]/[P]/[R] pour SPEC-003.10 (L9-10), 003.11 (L11), 003.12 (L12). Vérification `email_confirmed_at` (repli `confirmed_at`) reportée à la recette [R] (L14).
- **developpeur 131243** (13:12:43, « tour 3 ») : `GOTRUE_JWT_DEFAULT_GROUP_NAME` conservée, car sans effet de remplacement (L16). `GOTRUE_JWT_ADMIN_GROUP_NAME` absente du dépôt, l'avertissement vient du défaut (L17). Avertissement de dépréciation maintenu dans les logs (L19). Correctif CSS/app.js des formulaires repliés (L21-24). `./dev build` vert (L41). Non recetté visuellement (L49).
- **developpeur 131515** (13:15:15, « tour 3 ») : `tools/deploy/seed.py` modifié, `PUT` retiré, aucun PUT/PATCH/DELETE (L14). Cas par cas (L18-20). `db.sh promote-admin` jugé idempotent, non modifié (L22). `py_compile` OK (L25). Seed non lancé (L33-34).
- **product-owner 131515** (13:15:15) : CA-002-40 créé, [T]+[P] (L16). Arbitrages « Réaffecter » et « Loguer du temps » sans confirmation (L14). Écart CA-002-1 « après reset » accepté (L15). Point ouvert : SPEC-003.10 prévoit un `./dev deploy` (L19).
- **product-owner 132022** (13:20:22, « tour 3 ») : « Modifier » sans confirmation, arbitrage A6 (L7).
- **testeur 131505** (13:15:05, « tour 2 ») : audit des secrets dans `tests/`, correctifs écrits, rien exécuté (L9). Les fichiers `junit.xml` et `resultat.txt` contiennent encore les valeurs de l'incident, purge à faire (L74). Fichiers modifiés listés (L30-63).
- **testeur 132025** (13:20:25, « tour 2 ») : stub GoTrue `tests/stub_gotrue.py` et 3 tests SPEC-003.10 écrits, non exécutés, vérifiés par AST (L7, L11-20). SPEC-003.11 non couverte (L30). Fixture `_skip_si_pile_arretee` appliquée (L31). Nom du champ GoTrue non vérifié (L32).
- **policy 131736** (13:17:36, « tour 2 ») : policies 25 à 34 écrites, corrections des policies 00 et 21 (L6-7). Prévisions : 25 et 29 violées (L36, L40), reconnues comme non vérifiées (L21). `./dev policies` non lancé à ce moment, faute d'outil Bash (L21). Interprétations (L53-59).
- **action 131605** (13:16:05, « tour 2 ») : `policies/lib/secrets.py` supprimé (index git seulement), `dev` modifié (L20-22). Exécution de `./dev policies` à 17 respectées, 3 violées (L38-45).
- **action 132410** (13:24:10, « tour 2 ») : chmod +x sur les 34 scripts (L10). `./dev policies` rc=1, 28/2/0 (L14). Aucun script non exécuté (L50).
- **observation 132439** (13:24:39) : contient uniquement le brief, sans compte rendu (L6 vide).

## 2. Écarts constatés

**E1. Violation FRONT-audit-npm** (SPEC-001.15 (b)(c), ADR-010, CA-002-2)
- Preuve : `results.json` L187-194 (`violee`, rc 1) : « audit npm non exécutée (échec, pas « réussie ») : npm n'a pas rendu de rapport d'audit ».
- Source : `25-front-audit-npm.sh` L18 (`2>/dev/null) || true`), L33 (message « docker absent du conteneur »), L35 (sortie en échec).
- Journal `131736` L36 et L49 : `tools/bin/npm` passe par `docker run` ; le runner n'a pas Docker. Cette affirmation n'est pas vérifiée dans `tools/bin/npm`.
- Manque : un rapport `npm audit --json` exploitable. Aucun avis n'a été évalué, donc ni GHSA-67mh-4wv8-2f99 ni GHSA-8r88-6cj9-9fh5 n'ont été confirmés.

**E2. Violation DB-migrations-additives** (SPEC-004.18, ADR-011, CA-002-33)
- Preuve : `results.json` L223-230 (`violee`, rc 1) : « 001–005 : git absent du conteneur runner, comparaison à dae9044 non exécutée ».
- Source : `29-db-migrations-additives.sh` L96-97 (`git` absent ; `shutil.which("git")`). La référence `dae9044` a bien été résolue (L94 non déclenchée).
- Journal `131736` L40 et L50 : même constat.
- Manque : la comparaison (c) de 001 à 005 au commit de référence. Les contrôles (a) et (b) ne produisent aucun message dans la sortie, ce qui suggère qu'ils passent, sans que la sortie le dise explicitement.

**E3. Décision ouverte BLOQUE_AUTHJS (policy 25) : contradiction avec ADR-010**
- Preuve, policy : `25-front-audit-npm.sh` L13 (`BLOQUE_AUTHJS="oui"`) ; L50-51 (bloc conditionnel si `GHSA-8r88-6cj9-9fh5` est présent et que la variable vaut « oui »).
- Preuve, instruction : `131736` L9 : « auth-js reste bloquant pour un déploiement service tant que structure n'a pas tranché ».
- Preuve, décision : `specs/adr/ADR-010-vulnerabilites-npm-front.md` L6-7 : « blocage de `./dev deploy service` levé, sous condition de la policy n° 28 ». `specs/README.md` L116-118 : « voie 1 retenue ». `specs/SPEC-001-pile-supabase.md` L16-17 : « blocage levé ». `specs/SPEC-006-plan-verification.md` L17-18.
- Journal `131736` L51 reconnaît l'écart : « va à l'encontre de ADR-010 ».
- Non observable dans ce run : la sortie s'arrête à `25…sh` L35, avant L50. L'effet de BLOQUE_AUTHJS n'est donc pas constaté.

**E4. Décision ouverte : runner sans Docker (policy 25)**
- Preuve : `results.json` L193 ; `25…sh` L33 ; journal `131736` L49, qui liste trois options sans en retenir une.
- Statut : ouvert, aucune décision consignée dans les journaux du tour.

**E5. Décision ouverte : runner sans git (policy 29)**
- Preuve : `results.json` L229 ; `29…sh` L96-97 ; journal `131736` L50, qui liste deux options (ajouter `git` à l'image runner, ou remplacer par des empreintes, écartées par ADR-011 selon le journal).
- Statut : ouvert, aucune décision consignée.

**E6. Incohérence sur les secrets dans les sorties de test**
- `131605` L43 : deux fuites dans `iterations/002/tests/junit.xml` (au moment de ce run, vers 13:16).
- `131505` L74 : `junit.xml` et `resultat.txt` contiennent encore les valeurs, purge à faire.
- `results.json` L52-58 (13:24:22) : ENV-secrets-valeurs-absentes respectée.
- Aucun journal ne consigne une purge. Constat à la date de l'observation : une recherche des noms `ADMIN_PASSWORD|JWT_SECRET` dans `iterations/002/tests/` ne trouve aucune occurrence dans `junit.xml` ni `resultat.txt`. Une occurrence unique figure dans `tests/rapport-tour2.md` et une dans `tests/passe-1/rapport-tour2.md`. Je n'ai pas lu le contenu de ces lignes.

**E7. Étiquettes de tour incohérentes dans la fenêtre 131–132**
- « tour 3 » : `131243` architecte et développeur, `131515` développeur et product-owner, `131849` architecte, `132022` product-owner.
- « tour 2 » : `131505` testeur, `131605` action, `131736` policy, `132025` testeur, `132410` action.
- Le brief de l'observation annonce « tour 2 ».

**E8. Exigences sans policy ni test exécuté**
- SPEC-003.10 à 003.12 (seed, CA-002-40) : aucune entrée dans `results.json`. Le développeur (`131515` L36) et l'architecte (`131849` L9-12) attribuent une policy `[P]` à écrire, non présente dans `131736`.
- SPEC-003.11 : pas de test (`132025` L30).
- Les tests `test_003_admin.py` et le stub : non exécutés (`132025` L7).

**E9. Éléments déclarés non vérifiés**
- `email_confirmed_at` dans GET /admin/users (GoTrue v2.170.0) : non vérifié (`131849` L14 ; `131515` L34).
- Avertissement GoTrue de dépréciation : maintenu dans les logs (`131243` L16-19). Action 1 du développeur : pas de changement.
- Correctif CSS des formulaires repliés : non recetté dans un navigateur (`131243` L49).

## 3. Ce qui n'a pas pu être observé, et pourquoi

- **Tests automatiques (`tests/`, `./dev test`)** : aucun test exécuté pendant le tour (`131505`, `132025`). `tests/rapport.md` et les rapports `tests/passe-*` n'ont pas été lus, ils sont hors des sources demandées pour ce mandat.
- **Résultat réel de `npm audit`** : aucune sortie JSON produite, donc aucun avis évalué (E1).
- **Effet de BLOQUE_AUTHJS** : non atteint dans ce run (E3).
- **Dépendance de `tools/bin/npm` à Docker** : affirmée par le journal `131736` L49, non vérifiée dans `tools/bin/npm`.
- **Comparaison (c) de la policy 29** : non exécutée (E2). La référence `dae9044` n'a pas été vérifiée dans `mise-en-service.md`, que je n'ai pas lu.
- **Contrôles (a) et (b) de la policy 29** : statut déduit de l'absence de message, non explicitement confirmé.
- **Seed** : jamais exécuté (`131515` L33-34). Comportement réel de `seed.py` non observé.
- **Modes d'exécution des 34 scripts** : déclarés par `132410` L10, non revérifiés.
- **Recette client** : aucun journal `client` dans la fenêtre 131–132. Les captures d'écran n'ont pas été examinées.
- **Résultats de `./dev policies` avant 13:24:22** : écrasés. Les résultats antérieurs ne sont connus que par les journaux.
- **Comptes rendus des agents `observation` précédents** : `132439` est vide, aucune restitution antérieure à comparer.

---

## Tour 3 — restitution intégrale (source : `journal/134058-observation.md`)

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

---

## Tour 3 bis (final) — restitution intégrale (source : `journal/134627-observation.md`)

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

---

## Incident recette — restitution intégrale (source : `journal/150001-observation.md`)

**1. Faits vérifiés**

Source : `iterations/002/policies/results.json` (date 2026-11-17T14:59:42, `pile_demarree: true`). Synthèse (l.304-308) : respectee 32, violee 1, non_applicable 0. Toutes les lignes respectées ont `rc: 0`.

*ENV / reproductibilité*
- ENV-images-epinglees (ENV, SPEC-001.2, SPEC-004.16, ADR-008, CA-002-2) : respectee (l.7-13). 14 références d'image vérifiées.
- ENV-dependances-epinglees (ENV) : respectee (l.16-23).
- ENV-pas-de-secret (SPEC-003.3, CA-002-2) : respectee (l.25-32).
- ENV-toolbox-epinglee (ENV) : respectee (l.34-41).
- ENV-npm-epinglees (ADR-002, SPEC-006 §3.2, CA-002-2) : respectee (l.43-50). supabase-js 2.47.10 à version exacte.
- ENV-secrets-valeurs-absentes (SPEC-003.3/.6/.7, SPEC-006 §1, CA-002-2) : respectee (l.52-59).
- ENV-devenv-ignore (SPEC-003.3, ADR-003, CA-002-2) : respectee (l.61-68).
- ENV-secrets-fichier (SPEC-003.1/.2, ADR-003, CA-002-4) : respectee (l.133-140). Droits 0700/0600, 6 clés présentes.

*APP / GW / FRONT*
- APP-repond (ENV) : respectee (l.70-77). GET / → 200.
- GW-relais-auth (SPEC-001.5/.6, CA-002-3) : respectee (l.79-86).
- GW-relais-rest (SPEC-001.5/.6, CA-002-3) : respectee (l.88-95).
- GW-admin-bloque (SPEC-001.7, SPEC-003.6, ADR-001, CA-002-3) : respectee (l.97-104). `/auth/v1/admin/*` → 403.
- GW-csp (SPEC-001.9, ADR-002, CA-002-3) : respectee (l.106-113).
- **GW-cache-et-entetes** (SPEC-001.9, ADR-002, CA-002-3) : respectee (l.295-302). Sortie : « 5 fichiers servis en 200 : Cache-Control no-cache ; CSP, X-Content-Type-Options nosniff, Referrer-Policy présents ».
- FRONT-meme-origine (SPEC-001.8/.10, ADR-002, CA-002-2/3) : respectee (l.115-122).
- FRONT-audit-npm (SPEC-001.15, ADR-010/014, CA-002-2) : respectee (l.187-194).
- FRONT-auth-js-non-appel (SPEC-001.15 (e), ADR-010, CA-002-2) : respectee (l.214-221).
- FRONT-messages-tour3 (SPEC-005.7/.33/.40/.60/.62/.63, CA-002-27/28/34/38/39) : respectee (l.232-239).
- FRONT-barre-fixe (SPEC-005.6, CA-002-37) : respectee (l.241-248).
- **FRONT-bundle-servi-egal-source** (ADR-006 §2, SPEC-001.8, CA-002-2) : **violee** (l.286-293). Détail en section 2.

*API / DB / STACK / GARDE-FOU*
- API-anon-refuse (SPEC-002.1/.2, SPEC-001.12, CA-002-11) : respectee (l.124-131). 27 requêtes anon.
- STACK-services (SPEC-001.1/.2, ADR-001, CA-002-1) : respectee (l.142-149).
- STACK-ports (SPEC-001.3, ADR-007, CA-002-1/3) : respectee (l.151-158).
- STACK-restart-service (SPEC-004.7, ADR-009, CA-002-36) : respectee (l.196-203).
- STACK-tags-par-pile (SPEC-004.16, ADR-008, CA-002-2/36) : respectee (l.250-257).
- STACK-auth-debit (SPEC-001.14, ADR-006 §1, CA-002-6/7/33) : respectee (l.259-266).
- STACK-points-accroche (SPEC-004.11 à .14, ADR-006 §3, CA-002-1/2) : respectee (l.268-275).
- DB-migrations-versionnees (SPEC-001.13, SPEC-002, CA-002-1/33) : respectee (l.160-167).
- DB-rls-privileges-statique (SPEC-002.1, ADR-005, CA-002-11) : respectee (l.169-176).
- DB-migrations-additives (SPEC-004.18/.12, ADR-011/015, CA-002-33) : respectee (l.223-230).
- ADMIN-seed-sans-ecrasement (SPEC-003.10/.12, ADR-012, CA-002-4/33) : respectee (l.277-284).
- GARDE-FOU-mise-en-service (SPEC-004.6, ADR-004, CLAUDE.md §5) : respectee (l.178-185).
- DEV-sortie-url (SPEC-004.17/.15, ADR-007, CA-002-1) : respectee (l.205-212).

**2. Écarts constatés**

- **Policy 36, FRONT-bundle-servi-egal-source : violée** (rc 1).
  - Preuve, `results.json` l.290-292 : « /build-sha256.txt absent ou non servi (statut 200, Content-Type « text/html », repli HTML possible) : empreintes du build non vérifiables, à produire par build.mjs dans dist/ ».
  - Le fichier n'est produit par aucun élément du code hors `iterations/`. Un grep de `build-sha256` sur le dépôt ne renvoie que `policies/checks/36-front-bundle-servi-egal-source.sh` (l.6, 24, 27, 37, 42, 55).
  - Le journal `iterations/002/journal/145827-policy.md` l.29-31 indique que `app/web/build.mjs` et `app/Dockerfile` ne produisent pas ce fichier.
- **Ligne ajoutée dans `./dev`** : `dev` l.144 : `[[ $PILE == dev ]] && dc --profile client up -d --force-recreate client`.
  - La ligne l.143 (`dc --profile client up -d client`) est conservée.
  - La ligne est placée dans la séquence `deploy`, après le démarrage de `app` (l.137 et l.141), et non dans une fonction dédiée.
  - Le journal `145924-action.md` l.4-19 donne le diff correspondant.
  - Le `grep` de `recreate` ne trouve cette occurrence que dans `dev` l.144 et dans les journaux.
- **Non-exécution de la ligne** : `145924-action.md` l.37 : « la nouvelle ligne n'a pas été exécutée ; son effet reste à vérifier au prochain deploy ». Le même journal l.7 indique qu'aucun deploy n'a été lancé.
- **Sortie de `./dev policies`** : rc 1 (`145924-action.md` l.26), en raison de la violation 36.

**3. Ce qui n'a pas pu être observé**

- **Effet de `--force-recreate client`** : la ligne n'a jamais été exécutée. Aucun deploy postérieur à sa modification n'est consigné dans les sources lues. `.devenv/deploy.log` n'a pas été lu (hors sources de ma mission).
- **Contenu servi réel** de `/build-sha256.txt`, `/app.js` et `/vendor/supabase.js` : seul le résumé de la policy est disponible, sans empreintes comparées dans les sources lues.
- **Exécution des policies** : je n'ai pas relancé `./dev policies` (lecture seule). Les résultats sont ceux du fichier `results.json` daté de 14:59:42.
- **Contenu des scripts** `policies/checks/37-gw-cache-et-entetes.sh` et des autres checks : non relus, sauf les lignes de la policy 36 citées par grep.
- **`iterations/002/tests/`** (junit, rapports) et **`rapport-client.md`** : non examinés dans ce périmètre.
- **`iterations/002/journal/150001-observation.md`** : présent, mais non lu (hors périmètre de la mission).
- **`iterations/002/mise-en-service.md`** : lu, mais je n'ai trouvé aucune section consignant un deploy postérieur à l'ajout de la ligne `dev` l.144 ; le déploiement « 14:58 » qui y figure (l.3-11) précède le journal `145924-action` (14:59:24).

---

## CLÔTURE — restitution intégrale (source : `journal/155630-observation.md`)

**Clôture itération 002 : restitution Observation (lecture seule, aucun fichier modifié)**

Légende des preuves : **[EXÉC]** sortie brute présente dans les sources lues ; **[STAT]** vérification statique (texte de code) ; **[SIM]** simulation ; **[DÉCL]** affirmation d'un agent (rapport ou journal) sans sortie brute dans les sources. Heures UTC, sauf mention contraire.

## 1. Faits vérifiés

### 1.1 Policies (`policies/results.json`, date 15:56:04, `pile_demarree: true`)
- Synthèse : respectee 33, violee 0, non_applicable 0 (l.304-308) [EXÉC]. Les 33 entrées (00 à 37) sont « respectee », rc 0.
- Par référence :
  - **CA-002-1** : STACK-services 20 (l.142-149), STACK-ports 21 (l.151-158), DEV-sortie-url 27 (l.205-212) [STAT].
  - **CA-002-2** : ENV-images-epinglees 00 (14 références, l.8-13), FRONT-meme-origine 15, FRONT-audit-npm 25, FRONT-auth-js-non-appel 28 [STAT].
  - **CA-002-3** : GW-relais-auth 11 (200), GW-relais-rest 12 (200), GW-csp 14, GW-cache-et-entetes 37 (7 chemins, Cache-Control no-cache) [EXÉC, déployé].
  - **CA-002-4** : ENV-secrets-fichier 17 (droits 0700/0600, HS256) [EXÉC] ; ENV-secrets-valeurs-absentes 05 [STAT].
  - **CA-002-6/7, CA-002-33** : STACK-auth-debit 33 (config, pas de limit_req) [STAT] ; DB-migrations-versionnees 22, DB-migrations-additives 29, ADMIN-seed-sans-ecrasement 35 [STAT].
  - **CA-002-11** : API-anon-refuse 16 (27 requêtes avec clé anon, l.130) [EXÉC] ; DB-rls-privileges-statique 23 [STAT].
  - **CA-002-36** : STACK-restart-service 26, STACK-tags-par-pile 32 [STAT].
  - **SPEC-001.7** : GW-admin-bloque 13 (403, variantes de chemin) [EXÉC].
  - **Garde-fou (SPEC-004.6)** : GARDE-FOU-mise-en-service 24 : « conforme sur 70 cas simulés » (l.184) [SIM].
  - **CA-002-27/28/29/30/32** : FRONT-messages-tour3 30 : gabarits M-1 à M-6 présents, pas de confirm(), alert() ni innerHTML (l.238) [STAT]. Ne prouve pas l'affichage à l'écran.
  - **CA-002-37** : FRONT-barre-fixe 31 : barre sticky, top 0 (l.247) [STAT].
  - Incidents cités par les REF : 36 (bundle servi = sha256 du build, l.292) [EXÉC] ; 37 (l.301) [EXÉC].
  - **CA-002-38 et CA-002-39** : aucune policy.

### 1.2 Tests (passe finale, dev, 13:59-14:02)
- `resultat.txt` l.28 et `junit.xml` (attributs tests=197, failures=1, skipped=4) [EXÉC] : **197 collectés, 192 réussis, 1 échec, 4 ignorés**. Rapport testeur, l.12 : concordant.
- **FAIL SPEC-003.9** `test_seul_admin_email_hors_comptes_de_test` : « comptes hors @test.invalid : 8 (attendu : ADMIN_EMAIL seul) » (resultat.txt l.20-21) [EXÉC].
- **SKIP SPEC-004.3** (`test_persistance_relire`, `test_persistance_ecrire`) : « aucun ./dev deploy depuis l'écriture du jeu marqué » et « en attente de relecture » (junit) [EXÉC].
- **SKIP SPEC-004.7 et SPEC-004.8** : « à exécuter avec DEVENV_PILE=service » (junit) [EXÉC].
- **PASS SPEC-001.14** : `test_inscriptions_en_rafale` (20 × 200), `test_aucune_reponse_429` (junit) [EXÉC]. Le total de 202 inscriptions et 0 × 429 vient du journal de la passerelle, pas d'un compteur de test (rapport §4, l.102-107) [DÉCL].
- **PASS** : SPEC-001.4/5/6/7 (8 cas)/8/9/10/11/12/13 ; SPEC-002.1 à 002.22 (tests `test_002_modele`) ; SPEC-003.1/2/4/5/9 (sauf 003.9 en FAIL) ; SPEC-003.10 (seed sans écriture) ; SPEC-004.1 ; paquets git, curl, bash à la version épinglée (6 cas) [EXÉC junit].
- **Sans test marqué ou non exécuté** (rapport §2-3) [DÉCL, analyse AST] : SPEC-003.11, 003.12 (sans test) ; SPEC-004.2 (non exécuté, reset interdit) ; SPEC-004.13 (partiel, dépend de 003.11). Couverts sans marqueur : SPEC-005.11 et 005.12.
- **Passe du tour 2** (`tests/passe-1/resultat.txt` l.5, [EXÉC]) : 183 réussis, 3 ignorés, 186 collectés, 0 échec. SPEC-003.9 y est PASS (`tests/rapport-tour2.md` l.78). E1 (aucun test de débit, l.124) est résolu dans la passe finale.
- **Passe intermédiaire** (13:59, rapport testeur l.14) : 194 réussis, 1 échec, 2 ignorés [DÉCL].

### 1.3 Recette client (critères [C])
- **Passe 1** (`rapport-client.md`, l.10-33 et bilan l.86-92) [DÉCL] :
  - OK : CA-002-5, 6, 7, 8, 10, 12, 13, 14, 15, 17, 18, 19, 21, 22, 23, 24, 25, 29, 30, 32, 34, 35 (22 critères).
  - OK avec réserve : CA-002-9 (étape 6 bis, URL non vérifiable) ; CA-002-27 (l.89).
  - KO partiel : CA-002-28 (étape 16.12, aucun message, l.57).
- **Passe 2** (`journal/140419-client.md`, compte rendu l.286-306, N=2, 14:04) [DÉCL] — absente de `rapport-client.md` :
  - KO : CA-002-27 (message « Proposition envoyée. » sans nom, l.302) ; CA-002-28 (aucun message, l.303) ; CA-002-37 (barre disparaît au défilement, zoom 200 % sans effet, l.304) ; CA-002-38 (aucun champ de recherche, l.305) ; CA-002-39 (désactivation immédiate, l.306).
  - E7 OK ; le reste « OK avec réserves » (l.292).
- **Passe 3** (`rapport-client.md`, l.96-111, N=3, pile DEV, ~14:59-15:17) [DÉCL] :
  - CA-002-27 : OK, texte exact, réserve de visibilité (l.107) ; CA-002-28 : OK, même réserve (l.108).
  - CA-002-37 : **PARTIEL / BLOQUÉ** (barre fixe OK au défilement, 200 % impossible, l.109).
  - CA-002-38 : OK sur les points observés (l.110) ; CA-002-39 : OK, focus non vérifiable (l.111).
  - Étapes non jouées : 1, 3, 4, 6, 6 bis, 11, 13, 14, 15, 17, 18.2 (l.153).
- **N = 1** retenu pour la passe 1 (`tests/passe-recette.md` l.8). Aucun document lu ne consigne le choix de N pour les passes 2 et 3.

### 1.4 Mise en service (`mise-en-service.md`, déclaré par le responsable applicatif)
- **Tour 2** : deploy dev dfbc020, 12:29-12:30, 21 s, rc 0 (l.85-90).
- **Tour 3** (en-tête « BASCULE dev vers service (exécution) », l.38) :
  - backup dev 13:33:29, rc 0 (l.50) ; restore service rc 0 (l.54) ;
  - purge sur service de 385 comptes, 173 tâches, 36 temps, 47 propositions (l.55) ;
  - deploy service : 1er passage 19 s, 2e passage 6 s, horodatages 13:33:58Z et **13:35:39Z**, rc 0 chacun (l.43, l.63) ;
  - CA-002-33 [R] : empreintes avant/après identiques hors admin, service.env inchangé, connexion admin valide (l.63) ;
  - CA-002-36 [R] (a) (b) (c) : (c) « reset service sans flag » rc 1, « Rien n'a été détruit » (l.64) ; CA-002-1 [R] (a) curl 200, (b) ss -ltn (l.62).
- **Tour 4** (13:57-13:59) : dump dev 135659, delta migré = 0, deploy dev 899ee3e rc 0 10 s, service non modifié (l.358-403).
- **14:58** : build et deploy dev, commit a4d5b4d + correctif Cache-Control non commité, rc 0, 12 s (l.3-36).
- **15:55** : deploy dev commit 29a3980, rc 0, 11 s ; **policies 33/33** (l.419) ; app démarré 15:55:47, client 15:55:54 (l.415-428).

### 1.5 Coût (`cout.json` brut, `cout.md`)
- `cout.json` : `fin: null` (l.4) ; durée 170,7 min ; total 12,6858 USD (l.28) ; haiku 2 192 requêtes, 5,397 USD ; opus 103 requêtes, 7,2888 USD (l.6-26) [EXÉC].
- `cout.md` : relevé à 14:29, itération non clôturée (l.3) [DÉCL].

### 1.6 Partie réalisée de la mise à jour de la pile service (présentée comme FAIT)
- Déjà réalisé et consigné : préparation de service (service.env, deploy service à deux reprises, restore, purge des comptes de test sur service, connexion admin, accès anonyme refusé, ports, restart unless-stopped) ; **deuxième `deploy service` sans reset à 13:35:39Z**, CA-002-33 [R] consigné (l.63).
- Le reste (gel de dev, sauvegarde après gel, proxy, validation utilisateur) est traité au point 2.4.

## 2. Écarts constatés

### 2.1 Recette : variations de verdict et chronologie
- **a.** CA-002-27, 28, 37, 38, 39 : KO en passe 2 (journal l.302-306, 14:04, dev 899ee3e) ; OK ou partiel en passe 3 (rapport-client l.107-111, après le deploy de 14:58). Le document du 14:58 ne décrit que le correctif Cache-Control (mise-en-service l.6). Aucune source lue ne décrit les changements qui feraient passer « champ de recherche », « confirmation de désactivation » et « barre fixe » de absent à présent.
- **b.** CA-002-27, passe 1 : verdict « OK, réserve » (rapport-client l.89). Le message observé est « Proposition envoyée. » sans nom (l.55). La procédure dit qu'un message sans nom du collègue ni de la tâche est KO (`recette-client.md` l.191). La passe 2 classe le même message KO (journal l.302).
- **c.** Passe 1, comptage : « 16 étapes sur 18 entièrement conformes » (rapport-client l.92). Le tableau (l.12-33) compte 18 lignes OK sans réserve, 1 réserve (6 bis) et 1 KO (16).
- **d.** Passe 1, capture `124949-223` citée pour l'étape 13 (l.41, « D terminée ») et pour l'étape 15 (l.43, « avant réaffectation »).
- **e.** Passe 3, écarts déclarés par le client : charge 6 h au lieu de 3 h (l.131), attribuée à l'étape 15 non jouée ; statut non enregistré au premier essai (l.133) ; mot de passe de 14 caractères au lieu de 12 prévus (l.101 contre `recette-client.md` l.23) ; adresse de la pile non lue (l.101).
- **f.** Passe 1, anomalie : inscription d'une personne réelle (domaine gouv.fr) vers 13:00 (rapport-client l.72). Non recoupée : mise-en-service l.69 et rapport testeur l.81 mentionnent 8 comptes hors test, sans identité ni domaine.

### 2.2 Tests
- **g.** SPEC-003.9 : PASS au tour 2 (rapport-tour2 l.78, passe-1 à 0 échec), FAIL dans la passe finale (resultat.txt l.20-21). Le testeur attribue l'échec à l'état des données (8 comptes hors test, rapport §3.1 l.79-83).
- **h.** Confidentialité : rapport §7 (l.132) affirme 0 occurrence d'ANON_KEY dans resultat.txt et junit.xml. resultat.txt l.7 et junit contiennent `'ANON_KEY': 'eyJhbGciO...St-xXTfWEntjP8GpW94mhsGoNAt_7U'` : un fragment, pas la valeur complète [EXÉC]. Le rapport parle de valeurs complètes.
- **i.** Décomptes [T] divergents : rapport testeur final « 49 specs portent un [T] » (l.19) ; rapport tour 2 « 46 exigences portent [T] » (l.26). Aucune explication dans les sources.
- **j.** SPEC-004.3 : SKIP en passe finale (rapport §2 l.66), PASS dans la passe de 13:59 (rapport §4 l.109), SKIP au tour 2 (rapport-tour2 l.74, 138). Ce sont trois passes différentes.
- **k.** Chronologie : la passe finale (13:59-14:02) et la passe 2 (14:04) précèdent les deploys de 14:58 (a4d5b4d) et 15:55 (29a3980). Aucun test ni recette n'est documenté après 15:55. Seule la policy de 15:56 (33/33) vérifie la version finale.

### 2.3 Preuves de policies et de recette
- **l.** Policies 30 et 31 sont statiques (texte de code). Pour CA-002-27, 28 et 37, la recette constate un affichage différé, absent, ou une barre non fixe à 200 % (rapport-client l.107-109, l.135 ; journal l.302-304). Les deux types de preuve ne se contredisent pas, mais la policy ne prouve pas l'affichage.
- **m.** REF des policies 36 et 37 citent des « incidents de recette itération 002 » (results.json l.287, l.296). Aucun de ces incidents n'est décrit dans les sources lues.
- **n.** CA-002-38 et CA-002-39 n'ont ni test ni policy. Leur preuve est uniquement déclarative (recette).

### 2.4 Mise en service : libellés et étapes
- **o.** L'en-tête du tour 3 dit « BASCULE dev vers service (exécution) » (l.38). Le statut dit « SERVICE PRÊTE (pré-bascule) » et « Les étapes de coupure (gel de dev, sauvegarde finale après gel, proxy, validation utilisateur : S5 à S16) ne sont pas jouées dans ce tour » (l.40). Le plan porte « PRÉPARÉ, NON EXÉCUTÉ » (l.148). Aucun document lu ne consigne ensuite S5 (gel), S6 (sauvegarde après gel), S7 (contrôle de vide), S14 (bascule du proxy) ni S15 (validation utilisateur). Dev a été redéployé le 13:57, le 14:58 et le 15:55 et servait encore la recette des 14:04 et 15:00 (l.361, l.5, l.418).
- **p.** Version dev : 899ee3e (l.361), puis a4d5b4d + correctif non commité (l.6), puis 29a3980 « code identique à ff6715f » (l.415). L'identité entre 29a3980 et ff6715f n'est pas expliquée.
- **q.** Horodatage : le « deploy à 15:55:54 » de la demande correspond à l'heure de démarrage du conteneur client (l.425). Le deploy dure 11 s et démarre avant (l.416).
- **r.** Policies : cout.md l.13 cite « 31 respectées (13:46) » ; results.json donne 33 à 15:56. mise-en-service l.56 et l.75 (écart G) notent le même passage de 31 à la version antérieure. Chiffres de dates différentes, pas de contradiction.
- **s.** Écarts déclarés par le RA : CA-002-1 partie « après reset puis deploy » non jouée, « écart accepté » (l.62). CA-002-36 (c) : sortie consignée par le RA (l.64), sans fichier brut ; la policy 24 est une simulation (l.184).

### 2.5 Coût
- **t.** cout.md l.56 : « La recette du tour 3 … n'a pas été exécutée (gel de la pile dev) ». Le journal de la passe 2 (14:04-14:27) a exécuté CA-002-27, 28, 37, 38, 39 ; la passe 3 (14:59-15:17) les a aussi exécutées. Le relevé du coût date de 14:29.
- **u.** cout.md l.14 : « 22 critères OK » ne reprend que la passe 1 ; la passe 2 (5 KO) n'est pas intégrée.
- **v.** cout.md l.60-62 (déclaré par le sponsor) : coût Opus identique à 4 décimales (7,2888 USD) entre 54,7 et 170,7 min. `sous_agents` vaut 0 partout (cout.json l.10, l.20).

## 3. Ce qui n'a pas pu être observé, et pourquoi

- **Passe 2** : son compte rendu n'est que dans `journal/140419-client.md`, hors de la liste de sources. `rapport-client.md` ne contient que les passes 1 et 3. Je l'ai lu pour cette restitution.
- **Captures** (`client/*.png`) : non ouvertes. Les verdicts reposent sur les déclarations du client.
- **Fuseau des captures** : le fuseau n'est pas indiqué ; je compare sur la base UTC supposée des journaux.
- **Sorties brutes des commandes du responsable applicatif** (deploy, backup, restore, purge, rc) : citées (`.devenv/deploy.log`, `.devenv/backups`, `.devenv/delta`) mais absentes des sources lues. Les faits du point 1.4 sont déclaratifs.
- **Tests non exécutés** : SPEC-004.7 et 004.8 (pile service), SPEC-004.2 (reset interdit), relecture de persistance après le dernier deploy ; SPEC-003.11 et 003.12 (pas de test).
- **Preuves absentes** : affichage des messages P1/P2 à l'écran, barre à 200 %, CA-002-38 et CA-002-39 (uniquement recette client). Reset refusé (CA-002-36 c) : seulement la sortie déclarée et une simulation.
- **WebSocket au chargement** : non observée (`tests/passe-recette.md` l.45-51, « non établie à l'exécution »).
- **Compteur de débit** : 202 inscriptions issues du journal de la passerelle, pas d'un compteur de test.
- **Coût** : pas de relevé final (`fin: null`), pas d'attribution par agent.
- **Inscription du 13:00** : non recoupée avec les sources.
- **Commits** (29a3980, ff6715f, 899ee3e, a4d5b4d) : non vérifiés dans git ; seule l'affirmation de `mise-en-service.md`.
- **Autorisation de la mise à jour de la pile service** dans la session DevOps : pas de trace dans les sources lues. Le statut est celui indiqué par le chef de projet.
