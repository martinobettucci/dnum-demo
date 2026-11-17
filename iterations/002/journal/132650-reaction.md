# reaction — 2026-11-17T13:26:50+00:00

## Brief
Itération 002, tour 2, mandat AOPR. Lecture seule. À partir de l'observation consignée dans iterations/002/journal/132439-observation.md (lis-la en entier, et vérifie les faits sur results.json), propose le plan de réaction : pour chaque écart, l'action proposée, le responsable (équipe et agent), et ce qui conditionne la bascule vers la pile service. Distingue : ce qui est à corriger dans les policies, ce qui relève d'une décision de structure, ce qui relève de l'équipe Agile (specs) ou DevOps (pile). Ne modifie aucun fichier.

## Compte rendu
# Plan de réaction — itération 002, tour 2 (lecture seule)

Aucun fichier modifié. Les faits ci-dessous sont vérifiés sur `iterations/002/policies/results.json`, `policies/checks/25-front-audit-npm.sh`, `policies/checks/29-db-migrations-additives.sh`, `specs/adr/ADR-010-vulnerabilites-npm-front.md`, `tools/bin/npm`, `tools/runner/Dockerfile`, `stack/compose.yml` et `dev`.

## 0. Vérification de l'observation

- **Synthèse confirmée** : 30 entrées, 28 respectées, 2 violées, 0 non applicable (`results.json` L277-281).
- **E1 et E2 confirmées** : `FRONT-audit-npm` (L187-194) et `DB-migrations-additives` (L223-230) sont en `violee`, rc 1.
- **Chaîne de E1 confirmée** : `tools/bin/npm` exécute `_dockerized npm` (le contenu de `_dockerized` n'a pas été lu). La policy s'exécute dans le conteneur `runner` (`dev` : `run-policies`). Son image `python:3.13.1-slim` n'installe que `curl` et `bash` (`tools/runner/Dockerfile` L1-3). Ni `docker` ni `git` n'y sont présents.
- **Comportement de E2 déduit du code** : la policy ne liste que les motifs en échec. Seul le motif « git absent » apparaît, donc (a) et (b) passent pour les migrations présentes. Les migrations 001 à 005 sont toutes présentes, sinon le motif « absente » serait listé. En revanche, le nombre de migrations ≥ 006 n'est pas visible, car la sortie ne l'affiche qu'en cas de succès.
- **Piège non signalé par l'observation** : si E1 est corrigée seule, la policy 25 échouera ensuite sur GHSA-8r88-6cj9-9fh5. Le bloc L50-51 est atteint une fois le JSON lu, et `BLOQUE_AUTHJS="oui"` (L13) contredit ADR-010. Le commentaire L10-11 de la policy est lui aussi périmé.

## 1. Diagnostic par écart

**E1 — FRONT-audit-npm (violée)**
- Cause probable : la policy appelle `tools/bin/npm` (L18), qui passe par `docker run`. Le runner n'a pas Docker. Le `2>/dev/null || true` (L18) masque l'erreur, d'où le message générique « npm n'a pas rendu de rapport » (L35).
- Preuve : `results.json` L193 ; `25…sh` L18, L33, L35 ; `tools/bin/npm` L2 ; `tools/runner/Dockerfile` L1-3.
- Remarque : l'audit a été relevé avec succès dans le journal `123343` via le wrapper toolbox (ADR-010 Contexte). La policy doit le rejouer (condition C1).

**E2 — DB-migrations-additives (violée)**
- Cause : `git` absent du runner. Le contrôle (c) ne peut donc pas comparer 001 à 005 à la référence `dae9044`. C'est un échec voulu par conception (« jamais réussie »), la policy n'est pas en faute.
- Preuve : `results.json` L229 ; `29…sh` L96-97 ; `tools/runner/Dockerfile`.

**E3 — BLOQUE_AUTHJS = "oui" (policy 25), contradiction avec ADR-010**
- ADR-010 L3, L6-7 : décision du chef de projet du 2026-11-17, « voie 1 retenue », blocage de `deploy service` levé sous condition de la policy 28. La policy 28 est `respectee` (`results.json` L213-221).
- La policy 25 garde `BLOQUE_AUTHJS="oui"` (L13), avec un commentaire qui renvoie au « mandat… tour 2 » (L10-11). Elle est donc désalignée de l'ADR.

**E4 — Runner sans Docker**
- `tools/runner/Dockerfile` ne fournit pas Docker. L'option « monter le socket Docker dans le runner » est à écarter : elle contredit le principe rootless de CLAUDE.md §1.

**E5 — Runner sans git**
- Même cause que E2. L'option « empreintes à la place de git » est écartée par ADR-011, selon le journal.

**E6 — Secrets dans les sorties de test (hygiène, hors violations)**
- Non vérifié par moi : `131605` L43 et `131505` L74 (fuites dans `junit.xml` et `resultat.txt`).
- Vérification indépendante possible : `rapport-tour2.md` et `passe-1/rapport-tour2.md` contiennent une occurrence des noms de variables (contenu non lu). La policy 05 reste `respectee`, donc aucune valeur n'est présente dans le dépôt selon elle.

**E7 — Étiquettes de tour incohérentes** (process, sans impact technique). Le chef de projet doit corriger les journaux 131243 à 132410.

**E8 — Exigences sans policy ni test exécuté**
- SPEC-003.10 à .12 (seed, CA-002-40) n'ont aucune entrée dans `results.json`. La policy `[P]` annoncée par `131515` L36 et `131849` L9-12 n'existe pas.
- SPEC-003.11 n'est pas couverte (`132025` L30). Les tests `test_003_admin.py` et le stub ne sont pas exécutés (`132025` L7).

**E9 — Non vérifiés** : `email_confirmed_at` (GoTrue v2.170.0), correctif CSS des formulaires repliés non recetté (`131243` L49), seed jamais lancé (`131515` L33-34).

## 2. Plan ordonné

| # | Responsable | Action | Changement attendu | Preuve (policy ou test) |
|---|---|---|---|---|
| 1 | **Structure** (décision) | Confirmer par écrit qu'ADR-010 est la décision finale (auth-js cas A, voie 1, blocage levé sous policy 28). | Lève l'ambiguïté de E3. | ADR-010 « accepté, tranché » (déjà écrit). |
| 2 | **policy** | Mettre `BLOQUE_AUTHJS="non"` (L13) et corriger le commentaire L10-11. Garder le blocage du cas C (esbuild `serve`/`watch`/`context`). | Aligne la policy 25 sur ADR-010. | Une fois la policy 25 exécutable (étape 3 ou 4), `results.json` affiche « avis listés : … GHSA-8r88-6cj9-9fh5 (auth-js…) ». |
| 3 | **Structure** (décision) puis **architecte** | Choisir où l'audit s'exécute : **(a)** installer Node à version épinglée dans `tools/runner` (sans Docker), ou **(b)** faire produire le rapport d'audit hors runner et déposer le JSON dans `iterations/002/policies/`, lu par la policy 25. Écarter le socket Docker. Consigner le choix dans un ADR (amendement d'ADR-010 ou ADR-002). | Décision tracée. | ADR écrit et relu. |
| 4 | **action** | Exécuter l'option retenue à l'étape 3 : image runner, tag épinglé, `tools/bin/regen` si nécessaire, `./dev build`. Si option (a), vérifier aussi que le runner joint le registre npm. | Runner capable d'exécuter `npm audit`. | `./dev policies` : policy 25 `respectee`, rc 0. |
| 5 | **Structure** (décision) puis **architecte** et **action** | Décider si `git` entre dans le runner (paquet `apt` non épinglé, à consigner) ou si une autre preuve est retenue. Vérifier aussi que `/workspace` contient le `.git` monté. Amender ADR-011 si nécessaire. | Décision tracée ; `git` disponible dans le runner. | Policy 29 `respectee` ; sortie « 001 à 005 identiques à la référence dae9044 ». |
| 6 | **policy** | Écrire la policy `[P]` de SPEC-003.10 et .12 (seed idempotent, sans écrasement) et la policy de l'admin (SPEC-003.11 si couvrable). | Couverture des exigences du tour 3. | Nouvelles entrées dans `results.json`. |
| 7 | **testeur** | Exécuter les tests `test_003_*` et le stub GoTrue (`./dev test`). Vérifier le nom du champ GoTrue. Contrôler l'absence de valeurs de secret dans `rapport-tour2.md` et `passe-1/`. Purger les occurrences de valeurs si elles existent. | Tests SPEC-003.10 à .12 exécutés ; secrets absents des sorties. | `./dev test` ; policy 05 `respectee`. |
| 8 | **architecte** | Trancher les points ouverts : `email_confirmed_at` (repli `confirmed_at`), changement de mot de passe admin, `./dev deploy` à la levée du gel (SPEC-003.10 vs seed). | Specs précisées. | Spec amendée, critères testables. |
| 9 | **responsable-applicatif** (seul) | **Uniquement si** les étapes 2, 4 et 5 sont vertes : `./dev deploy service`, puis `mise-en-service.md` consignant la policy 28 réussie (ADR-010 C5). | Mise en service. | `./dev policies` (contrôles « deployed ») ; `iterations/002/mise-en-service.md`. |
| 10 | **client** | Recette clavier/souris des formulaires repliés (CSS, `131243` L49). Non bloquante pour la bascule service si les policies 30 et 31 restent vertes. | Recette tracée. | Captures et rapport `client`. |
| 11 | **chef-de-projet** | Corriger les étiquettes de tour (E7). | Journaux cohérents. | Relecture. |

Note sur l'étape 9 : `results.json` affiche `pile_demarree: true` et des contrôles `deployed` respectés, mais ce fichier ne dit pas si la pile **service** est en ligne. À confirmer par le responsable-applicatif avant toute action. Aucun autre agent ne doit toucher à la pile.

## 3. Ce qui relève d'une décision (à remonter via le chef de projet)

**Décisions de structure**
- Confirmer ADR-010 comme décision finale et lever `BLOQUE_AUTHJS` (étape 1).
- Choisir l'emplacement de l'audit npm : runner avec Node, ou rapport produit hors runner (étape 3). Refuser le socket Docker dans le runner.
- Choisir la preuve de l'intégrité des migrations 001-005 : `git` dans le runner, ou autre (étape 5).

**Décisions utilisateur ou product owner**
- Arbitrages « Réaffecter » et « Loguer du temps » pris sans confirmation (`131515` L14), et « Modifier » (`132022` L7, arbitrage A6). Ces choix sont à confirmer.
- Acceptation de l'écart CA-002-1 « après reset » (`131515` L15).
- Point ouvert sur SPEC-003.10, qui prévoit un `./dev deploy` (`131515` L19).

**Conditions de bascule vers la pile service** (toutes requises) :
1. Policy 25 `respectee` avec `BLOQUE_AUTHJS="non"` et sans cas C (étapes 2 et 4).
2. Policy 28 `respectee` (déjà vérifiée, rc 0, `results.json` L213-221).
3. Policy 29 `respectee` (étape 5).
4. Décisions de structure 1, 3 et 5 tracées dans un ADR.
5. Mise en service lancée par le seul responsable-applicatif, avec consignation dans `mise-en-service.md`.

## 4. Non vérifié

- Le contenu de `tools/bin/_dockerized` (docker supposé, non lu).
- Le nombre de migrations ≥ 006 (non affiché en cas de succès du contrôle (a)/(b)).
- Le montage du `.git` dans `/workspace` (non vérifié).
- Les occurrences de secrets dans `junit.xml`, `resultat.txt` et `rapport-tour2.md` (E6, contenu non lu).
- Le contenu des journaux `131505`, `131605`, `131515` cités.
