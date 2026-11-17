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
