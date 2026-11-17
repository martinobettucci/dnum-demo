# Itération 002 — reaction (tour 2)

> Restitution intégrale de l'agent reaction (Team AOPR, lecture seule), consignée par le chef de projet. Source : `journal/132650-reaction.md`.

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

---

## Tour 3 — restitution intégrale (source : `journal/134230-reaction.md`)

# Plan de réaction — itération 002, tour 3 AOPR

Lecture seule : aucun fichier modifié, aucune commande lancée hors lectures.

## 0. Vérification des faits

Le résultat global tient : `results.json` donne 31 respectées, 0 violée, 0 non applicable, tous les `rc` à 0, pile démarrée. Quatre points de l'observation ne collent pas aux fichiers :

- **Horodatage** : `results.json` est daté **13:42:21**, et non 13:40:39 comme l'observation le dit. L'observation (13:40:58) cite donc un résultat plus récent que son propre horodatage. Il faut confirmer quel passage de `./dev policies` fait référence.
- **Comptage** : la policy 05 annonce « 224 fichiers » dans `results.json`, l'observation écrit 223.
- **Policy 29** : `REF = "dae9044"` est bien en dur à `policies/checks/29-db-migrations-additives.sh` L87. Je n'ai pas relu ADR-015 §6.
- **Audit** : `audit-npm.meta.json` est conforme (statut reussie, sha256 `2bbd9f50…`, image `node:22.12.0-alpine`, date 13:40:30). `./dev audit-npm` écrit bien le méta (`dev` L102-120).

Autre fait relevé en lisant le journal `134002` : l'agent `action` a lancé `./dev audit-npm`, qui passe par `docker run` (`tools/bin/_dockerized`), alors que son propre brief (L8) interdisait toute commande `docker run`. Le garde-fou n'a pas bloqué cette commande, alors qu'il a bloqué `docker run python:3.13.1-slim` au tour précédent (`133919` L18). Je n'ai pas lu `tools/guards/guard.py`, donc je ne sais pas laquelle des deux situations est voulue.

## 1. Diagnostic des écarts restants

| # | Écart | Cause probable | Preuve |
|---|---|---|---|
| E1 | Étape 1 non faite : `tools/runner/Dockerfile` n'est pas épinglé | Le garde-fou refuse le `docker run` nécessaire pour interroger apt dans l'image `python:3.13.1-slim`, et l'action n'a pas le droit de le lancer. | `Dockerfile` L3 : `install -y --no-install-recommends curl bash git`, sans version. `133919` L17-21. |
| E2 | Étape 3 non faite : pas de `./dev build` | Dépend de E1 : le runner doit être reconstruit avec les paquets épinglés. | `134002` L4, L11. Aucun journal de build. |
| E3 | Incohérence « docker run » : `audit-npm` contourne l'interdiction de l'action | ADR-014 prescrit l'appel via `tools/bin/npm` (donc `docker run`), mais le brief de l'action l'interdit. Le garde-fou ne bloque pas ce chemin. | `134002` L8, L27 ; `dev` L103 ; `_dockerized` L16 ; ADR-014 L27-28. |
| E4 | Policy 29 : référence `dae9044` en dur | Non conforme à ADR-015 §6, qui veut que la policy lise le commit dans `mise-en-service.md`. | Policy 29 L87 ; `mise-en-service.md` L114 indique « dae9044 plus des modifications non commitées », alors que l'observation rapporte `dfbc020` pour la version déployée (non vérifié). |
| E5 | Garde esbuild bloquante (policy 25) | Changement de statut voulu par ADR-013 (D-1), mais l'état actuel est conforme. | Policy 25 L20-22, L104-105 ; aucune occurrence de `serve`/`watch`/`context(` relevée. |
| E6 | SPEC-003.11 sans policy ni test | Spec classée vérification [T] ; le test n'est pas écrit. La vérification `email_confirmed_at` est reportée au second `deploy service` (ADR-013 D-4). | `133231-policy` L22 ; `observation.md` L107 ; `ADR-013` L28. |
| E7 | Formulaires repliés : correctif non recetté | La recette client n'a pas été refaite après le correctif. Le rapport client liste encore le défaut. | `131243-developpeur` L21-24 ; `rapport-client.md` L81 ; dernier journal client `123712`, antérieur au correctif. |
| E8 | Modification de policy 35 incertaine | Le journal `133755` dit « aucune modification », le brief de session dit le contraire. Non tranchable faute de dates de modification. | `133755-policy` L28. |
| E9 | Empreinte de l'audit non consignée dans `mise-en-service.md` | Le document de mise en service ne reprend ni le statut ni le sha256 de l'audit, alors qu'ADR-014 le demande. | Recherche sur `2bbd9f50` et « statut » : aucune occurrence. |
| E10 | Compte rendu du développeur vide | Le journal `134015-developpeur` (modifs `seed.py` et messages de log) n'a aucun compte rendu. Impossible de savoir si ces modifs précèdent `./dev policies`. | `134015-developpeur.md`. |

Il faut aussi noter qu'**aucune policy ne vérifie le pinage apt** : seule la policy 29 contient le mot « apt », et ce n'est pas un contrôle de version. Une fois l'étape 1 faite, rien ne prouvera le résultat sans une nouvelle policy.

## 2. Plan ordonné

Les équipes suivent le découpage de `CLAUDE.md` §4bis (une session par équipe). Les agents rendent compte à leur chef de projet, qui consigne.

**Étape A — Décision du chef de projet sur l'étape 1 (bloquant, voir §3 D1).**
- Responsable : chef de projet (session `structure`).
- Changement : choisir entre (a) relevé des versions par le responsable-applicatif, puis reprise par l'action ; (b) exception explicite au garde-fou pour cette seule requête en lecture.
- Preuve : le choix est consigné dans `iterations/002/journal/`.

**Étape B — Relevé des versions apt (option a, recommandée).**
- Responsable : `responsable-applicatif` (session `spark-docker-f1`).
- Action : une seule requête en lecture dans l'image `python:3.13.1-slim` (`apt-get update` puis `apt-cache policy git curl bash`), sans rien démarrer. Transmettre les versions à la session `spark-docker-70`.
- Preuve : la sortie est consignée dans le journal ; les versions sont transmises.

**Étape C — Pinage du Dockerfile (étape 1).**
- Responsable : `action` (session `spark-docker-70`), en s'appuyant sur les versions de l'étape B.
- Changement : ajouter `=<version>` à `git`, `curl` et `bash` sur la ligne `apt-get install` de `tools/runner/Dockerfile`. Rien d'autre.
- Preuve : **nouvelle policy à écrire avant l'action** par `policy` (session `spark-docker-70`) : contrôle statique que chaque paquet apt du Dockerfile porte un `=version`. Vérifiable par `./dev policies`.

**Étape D — Build (étape 3).**
- Responsable : `action` si le garde-fou autorise `./dev build` pour l'agent action ; sinon `responsable-applicatif`. Le chef de projet tranche (D2).
- Changement : `./dev build` (images seulement, aucune pile démarrée).
- Preuve : journal de build avec rc 0 ; policies 00 (images épinglées), 32 (tags par pile) et la nouvelle policy de l'étape C passent. Ces contrôles tournent sur l'état **après** build.

**Étape E — Clarifier le statut de `audit-npm` (E3).**
- Responsable : `architecte` (session `spark-docker-77`), avec décision du chef de projet (D3).
- Changement : soit ADR-014 est amendé pour préciser que `audit-npm` est une exception au `docker run` interdit, soit le brief de l'action et le garde-fou sont alignés. Dans les deux cas, le garde-fou doit décider explicitement.
- Preuve : ADR à jour, et test du garde-fou (`policies/checks/24`) qui couvre le cas `audit-npm`.

**Étape F — Policy 29 (E4).**
- Responsable : `policy` (session `spark-docker-70`) pour le code de la policy ; `architecte` pour confirmer ADR-015 §6.
- Changement : lire le commit de référence dans `mise-en-service.md` au lieu de `dae9044` en dur, ou acter par ADR que `dae9044` reste la référence de l'itération 002.
- Preuve : policy 29 relancée et respectée ; `mise-en-service.md` consigne une référence cohérente avec la version déployée (conflit `dae9044` / `dfbc020` à régler).

**Étape G — Consigner l'audit dans `mise-en-service.md` (E9).**
- Responsable : `responsable-applicatif`.
- Changement : ajouter le statut (`reussie`) et le sha256 du lock (`2bbd9f50…`) dans `mise-en-service.md`.
- Preuve : policy 25 et une vérification [R] (ADR-014 L66) qui relit ces deux valeurs.

**Étape H — SPEC-003.11 (E6).**
- Responsable : `testeur` (session `spark-docker-f1`), à écrire dans `tests/` uniquement ; `policy` ajoute la policy correspondante si la spec l'exige.
- Changement : test de la vérification `email_confirmed_at`, à exécuter au second `deploy service` (ADR-013 D-4).
- Preuve : test vert au prochain `./dev test` ; policy dédiée passant dans `results.json`.

**Étape I — Recette des formulaires repliés (E7).**
- Responsable : `client` (session `spark-docker-f1`) pour la recette clavier/souris et la capture ; `developpeur` (session `spark-docker-77`) si un correctif complémentaire est nécessaire.
- Changement : recette sur la version déployée ; mise à jour de `rapport-client.md` L81.
- Preuve : captures dans `iterations/002/client/` et journal `client` postérieur à `131243`.

**Étape J — Compte rendu du développeur (E10) et E8.**
- Responsable : `developpeur` (session `spark-docker-77`) : compte rendu de `134015` (fichiers touchés, horodatages).
- Responsable : `policy` (session `spark-docker-70`) : consigner dans son journal si la policy 35 a été modifiée ce tour.
- Preuve : journaux à jour ; l'observation peut trancher.

**Étape K — Relance.**
- Responsable : `action` (`./dev policies` et `./dev audit-npm`) puis `observation` (session `spark-docker-70`).
- Preuve : `results.json` daté après toutes les modifs, avec `violee: 0`. L'horodatage de l'observation doit correspondre au fichier lu (E0).

Ordre : A → B → C → D (ou D avant C si le garde-fou l'impose, mais après C pour que le build reflète les versions pinées) ; E, F, G, H, I et J peuvent avancer en parallèle ; K en dernier.

## 3. Décisions à remonter au chef de projet (puis au product owner / utilisateur)

- **D1 — Étape 1 (pinage apt)** : option (a) (relevé par le responsable-applicatif, recommandée) ou option (b) (exception ponctuelle au garde-fou pour une requête de lecture). L'option (c) du tour précédent reste possible pour l'audit seul, mais ne règle pas E1.
- **D2 — Étape 3 (build)** : qui exécute `./dev build`. Le chef de projet doit trancher, en lien avec le garde-fou.
- **D3 — Contradiction `docker run`** : faut-il autoriser `audit-npm` via `docker run` pour l'action (ADR-014), ou le garde-fou doit-il le bloquer ? Décision d'architecture, à prendre avec l'architecte.
- **D4 — Référence `dae9044` (E4)** : garder la référence figée pour l'itération 002, ou la lire dans `mise-en-service.md` (ADR-015 §6) ? À trancher par le product owner avec l'architecte.
- **D5 — SPEC-003.11 (E6)** : accepter le report au second `deploy service` (ADR-013 D-4) comme critère de bascule, ou exiger un test avant bascule ? Décision du product owner.
- **D6 — Bascule vers le service** : conditions dans `mise-en-service.md`. Le responsable-applicatif ne peut pas vérifier la réservation DHCP de `10.77.0.25` (B, P6) : c'est une action réseau de l'utilisateur. La fenêtre de coupure (D1 du document, 45 min) et la conservation de dev 7 jours (D4) relèvent aussi de l'utilisateur.

## 4. Ce qui conditionne la bascule

La bascule peut se faire quand, **sur l'état final** :
1. Étapes 1 et 3 faites, avec une policy qui prouve le pinage apt et un build rc 0.
2. `./dev policies` relancé après la dernière modification de fichier, avec `violee: 0` et un horodatage cohérent avec le rapport d'observation.
3. Décisions D3 et D4 prises et consignées dans les ADR.
4. Recette client des formulaires repliés faite (E7).
5. SPEC-003.11 couvert selon la décision D5.
6. Points D6 validés par l'utilisateur (fenêtre de coupure, adresse LAN).

Si ces points sont tenus, la bascule relève de la mise en service du `responsable-applicatif` (`./dev deploy`), sur décision du chef de projet et de l'utilisateur. Hors ces conditions, l'itération reste ouverte : je ne propose pas de clôture.
