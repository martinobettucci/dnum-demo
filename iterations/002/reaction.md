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

---

## Tour 3 bis (final) — restitution intégrale (source : `journal/134725-reaction.md`)

# Réaction finale AOPR, itération 002

## 0. Vérifications faites

Je n'ai que la lecture (Read, Glob, Grep). Je n'ai donc pas pu recalculer de sha256, lancer git ou relancer une policy. Les faits ci-dessous viennent des fichiers lus.

- **`results.json`** : 31 entrées `respectee`, 0 `violee`, 0 `non_applicable`, daté `13:46:04`. Décompte vérifié : policies 00 à 06, 10 à 17, 20 à 35. Les numéros 07, 08, 09, 18 et 19 sont libres.
- **`tools/runner/Dockerfile`** : ligne 3 épingle `git=1:2.39.5-0+deb12u3`, `curl=7.88.1-10+deb12u15`, `bash=5.2.15-2+b13`. Conforme au journal.
- **Aucune policy ne couvre les `apt-get install` des Dockerfiles.** La policy 00 ne contrôle que les `FROM`. Un grep sur `policies/checks/` ne trouve « apt » que dans 29 et 04, sans rapport.
- **`audit-npm.meta.json`** : `date 13:45:51`, postérieure à l'audit cité dans `mise-en-service.md` L316 (`13:40:30`). Le sha256 du lock est le même dans les deux fichiers.
- **Script 25** : la garde esbuild (`serve|watch|context(` dans les scripts racine) est bien implémentée. Le message de `results.json` indique « build.mjs : aucun serve/watch/context( ». Je n'ai pas relu `build.mjs` lui-même.
- **`mise-en-service.md` L318** : « et un troisième » sans nommer le paquet. Le méta ne mentionne pas `1ab0…`, cette valeur n'existe que dans le journal.

## 1. Ce qui est fermé

| Élément | Preuve | Statut |
|---|---|---|
| Policies automatiques (31/31) | `results.json`, synthèse | Fermé |
| Audit npm : statut, sha256, aucun avis haut ou critique | `audit-npm.meta.json`, script 25 | Fermé |
| Garde esbuild (ancien écart E-e) | Logique du script 25 lue, message « aucun serve/watch/context( » | Fermé |
| Horodatage périmé de l'observation précédente (E-i) | `results.json` 13:46:04 > méta 13:45:51 | Fermé |
| Épinglage des images, des dépendances et des npm | Policies 00, 01, 03, 04 | Fermé |
| Secrets absents du dépôt | Policies 02, 05, 06, 17 | Fermé |
| Versions apt dans le Dockerfile | Dockerfile L3 | Fermé pour le fichier. L'installation effective reste à prouver (voir O2). |

## 2. Ce qui reste ouvert

| Id | Écart | Preuve | Équipe | Action attendue |
|---|---|---|---|---|
| **O1** | Formulaires repliés : défaut toujours listé dans le rapport client, pas de recette postérieure au correctif | `rapport-client.md` L81 | **client** (session f1), **developpeur** si correction nécessaire | Recette clavier et souris sur le build courant. Captures à l'appui. **Bloquant pour la clôture.** |
| **O2** | Bash : installé `b7` lors du contrôle, épinglé `b13`. Pas de log de build dans `iterations/002/` | `134407` L15, Dockerfile L3 | **testeur** (tests/), **action** (build) | Prouver dans l'image runner que `bash` est en `5.2.15-2+b13` (dpkg-query dans un test). **Bloquant pour la clôture**, car l'affirmation « versions épinglées installées » ne repose que sur un journal. |
| **O3** | Compte rendu du développeur vide | `134058` E10, non relu | **developpeur** (session spark-docker-77) | Republier le compte rendu. Non bloquant si O2 est prouvé. |
| **O4** | Doc `mise-en-service.md` : date d'audit périmée (L316), troisième paquet non nommé (L318) | Lignes citées | **responsable-applicatif** (session f1) | Corriger : date `13:45:51`, nommer `@supabase/supabase-js` (low, direct, via auth-js). Non bloquant. |
| **O5** | Pinage apt non contrôlé | Voir section 3 | **policy** (session f70) | Écrire la policy proposée. Peut être reportée à l'itération 003 (voir section 4). |
| **O6** | Référence `dae9044` en dur dans la policy 29, et « modifications non commitées » dans la doc | `results.json` ; `mise-en-service.md` L114 ; policy 29 non relue | **architecte** (ADR-015 §6) | Décider si la référence reste en dur. Non bloquant : la policy est respectée. |

Je n'ai pas pu vérifier `git status`. La liste des fichiers modifiés (journal `134451` L41) reste à confirmer par le chef de projet.

## 3. Pinage apt : proposition de policy (non écrite)

- **Numéro proposé : `07`** (libre, dans la bande ENV 00-06 juste après `06-env-devenv-ignore.sh`). Vérifié : pas de fichier `07-*` dans `policies/checks/`.
- **Fichier** : `policies/checks/07-env-apt-epingle.sh`
- **POLICY** : `ENV-apt-epingle`
- **REF** : `ENV (reproductibilité)`, à compléter par l'architecte (analogie avec ADR-008).
- **QUAND** : `always`
- **Règle** : pour chaque `Dockerfile*` du dépôt (même périmètre que la policy 00, `rglob`), chaque `apt-get install` (ou `apt install`) doit lister des paquets **dont chaque nom porte `=<version>` exacte**. Les options (`-o …`, `-y`, `--no-install-recommends`) et leurs arguments sont ignorés. Un paquet sans `=`, avec `*`, ou sans version est **violée**. Un `apt-get install` sans paquet épinglé est **violée**.
- **Ce qu'elle ne prouve pas** : une version épinglée n'est pas une version installée. Cette preuve relève d'un test d'exécution (`tests/`, testeur), donc de O2.

## 4. Décision de clôture (proposition)

**Clôture conditionnelle, à ne pas prononcer aujourd'hui.** Les 31 policies sont respectées, mais deux éléments bloquent une clôture propre :

1. **O1** : la recette des formulaires repliés n'a pas eu lieu sur le build courant.
2. **O2** : l'installation de bash `b13` n'est pas prouvée dans l'image.

Une fois O1 et O2 traités, je propose la clôture de l'itération 002, avec O3 à O6 reportés en backlog. La policy `07-env-apt-epingle` peut entrer dans l'itération 003 : le Dockerfile est correct aujourd'hui, donc c'est un contrôle préventif et non un correctif d'écart.

## 5. Décisions à remonter (utilisateur ou product owner)

- **Reporter ou non** la policy `07-env-apt-epingle` à l'itération 003 (je recommande le report, le Dockerfile étant déjà conforme).
- **Accepter** une clôture avec la recette client de O1 faite ou reportée à l'itération 003. C'est un arbitrage de périmètre, qui relève du product owner et de l'utilisateur.
- **Décider** si la référence `dae9044` reste codée en dur dans la policy 29 (O6).

---

## Incident recette — restitution intégrale (source : `journal/150050-reaction.md`)

# Plan de réaction — incident de recette itération 002 (structure)

Lecture seule : aucun fichier modifié, rien exécuté. J'ai lu l'observation en entier, `results.json`, et vérifié le code cité (`app/web/build.mjs`, `app/Dockerfile`, `app/.dockerignore`, `app/nginx/default.conf`, `dev`). Je n'ai pas pu inspecter la pile en cours d'exécution (pas de docker ni de curl dans mon périmètre).

## 0. Corrections à l'observation

L'observation contient deux affirmations que le code ne confirme pas. Le chef de projet doit les corriger avant de consigner l'incident.

1. **« build.mjs ne produit pas build-sha256.txt » (journal 145827 l.29-31, reprise par l'observation) : faux dans les sources actuelles.**
   - `app/web/build.mjs` l.52-57 calcule les sha256 de `dist/app.js` et `dist/vendor/supabase.js` et écrit `dist/build-sha256.txt` en dernier. Le format (« `<sha256>  <chemin>` », LF) correspond à ce que vérifie la policy 36.
   - Chaîne complète présente dans les sources : `app/Dockerfile` l.10 (`RUN npm run build`), l.19 (`COPY --from=build /build/dist/`) ; `app/.dockerignore` n'exclut que `web/dist` ; `app/nginx/default.conf` l.68-74 sert `/build-sha256.txt` en `text/plain`.
   - Le grep de l'observation (« ne renvoie que la policy 36 ») est donc périmé, ou les sources ont changé après la policy.
2. **Le constat « 200 text/html » est incompatible avec la configuration actuelle.** Avec `location = /build-sha256.txt { try_files $uri =404; }`, un fichier absent donne **404**, pas un 200 HTML. Un 200 `text/html` suggère que la pile en marche tourne avec une configuration nginx plus ancienne, sans ce bloc, et que c'est un repli générique qui répond.
3. **Date de `results.json`** : le fichier indique `2026-11-17T15:00:08`, et l'observation cite `14:59:42`. À corriger.

## 1. Diagnostic des écarts

| # | Écart | Cause probable | Preuve |
|---|---|---|---|
| E1 | Policy 36 violée (rc 1) | Image `devenv/app:dev` en marche construite avant l'ajout de la production de `build-sha256.txt` (ou avant le bloc nginx). Le code source est correct. | `results.json` l.290-292 ; `build.mjs` l.52-57 ; `Dockerfile` l.10, l.19 ; réponse 200 text/html incompatible avec `default.conf` l.68-74 |
| E2 | Recréation client ajoutée sans effet vérifié | Ligne ajoutée à `deploy`, sans `--build`, donc recréation de l'image existante (`devenv/client:dev`). L'effet réel n'a jamais été observé (aucun deploy postérieur). | `dev` l.143-144 ; `stack/compose.yml` l.122-125 ; observation §3 |
| E3 | Duplication dans `dev` | Deux appels successifs (`up -d client` puis `up -d --force-recreate client`) : redondant, sans danger. | `dev` l.143-144 |
| E4 | Incohérence de traçabilité | Journal 145827 faux sur build.mjs (cf. §0) ; `results.json` daté différemment de l'observation. | cf. §0 |

## 2. Plan ordonné

**Étape 1 — Developpeur (Agile) : établir l'état réel du dépôt.**
- Action : confirmer par `git log` / `git status` que `app/web/build.mjs`, `app/nginx/default.conf` et `app/Dockerfile` sont commités et antérieurs au dernier build de `devenv/app:dev`. Si le code est déjà correct, ne rien changer dans le code.
- Changement attendu : aucun, sauf si un fichier est absent du commit.
- Preuve : le constat est consigné (corrige le journal 145827).

**Étape 2 — Testeur : prouver la production du fichier, hors pile.**
- Action : ajouter dans `tests/` un test qui lance `npm run build` dans `app/web`, puis vérifie que `dist/build-sha256.txt` contient deux lignes `sha256  app.js` et `sha256  vendor/supabase.js` correspondant aux octets de `dist/` (contrôle type `sha256sum -c`).
- Preuve : `./dev test` vert sur ce test.

**Étape 3 — Responsable-applicatif : mise en service dev et vérification de la recréation.**
- Avant `./dev deploy` : noter l'ID d'image de `devenv/app:dev` et `devenv/client:dev`, et la date de création du conteneur `client`.
- Action : `./dev deploy` (seul le responsable-applicatif peut le lancer).
- Après : vérifier que la date de création du conteneur `client` a changé (la recréation a bien eu lieu) ; vérifier la ligne ajoutée dans `.devenv/deploy.log`.
- Preuve : dates et ligne de log consignées dans `mise-en-service.md`.

**Étape 4 — Policy / observation : contrôle de la policy 36.**
- Action : après le deploy, `./dev policies`.
- Attendu : policy 36 `respectee` (rc 0), policy 37 toujours `respectee`, synthèse 33 respectées / 0 violée.
- Si la policy 36 reste en échec : le contenu servi doit être inspecté (configuration nginx effectivement en marche, image réellement reconstruite). Cela revient à l'action, pas à une modification de la policy.

**Étape 5 — Client (recette clavier/souris) : effet réel de la recréation.**
- Action : recette du navigateur de dev après deploy, en rechargement normal (sans rechargement forcé).
- Preuve : captures montrant le nouveau front chargé, et cohérence avec le sha256 servi.

**Étape 6 — Developpeur : consolidation de `dev`, seulement après validation.**
- Action : fusionner l.143-144 en une seule ligne, sans changer la logique. Sans effet sur le comportement.
- Preuve : `./dev test` et policies de l'étape 4 toujours vertes.

## 3. Décisions à remonter (utilisateur / product owner, via le chef de projet)

- **D1** : la recréation du client à chaque deploy dev est-elle voulue ? Elle interrompt une session de recette en cours. Faut-il une option explicite (`--recreate-client`) ?
- **D2** : `./dev deploy` doit-il reconstruire l'image `client` (`--build`) quand `tools/client` a changé ? Sans cela, la recréation ne met pas à jour le navigateur.
- **D3** : la policy 36 est-elle bloquante pour la clôture d'itération ? Le PO doit trancher ; je recommande oui, car elle est la preuve du critère ADR-006 §2.
- **D4** : la correction du journal 145827 (cf. §0) doit être validée par le chef de projet avant consignation.

## 4. Critères de clôture de l'incident

L'incident n'est clos que si **tous** les points suivants sont vérifiés :

1. Policy 36 `respectee` sur un deploy dev **postérieur** à la dernière modification de `build.mjs` / `default.conf` / `Dockerfile`, avec sha256 servis identiques au build (sortie de la policy).
2. Policy 37 toujours `respectee` ; `./dev policies` : 33 respectées, 0 violée.
3. Le test de l'étape 2 est dans `tests/` et vert dans `./dev test`.
4. Recréation du conteneur `client` prouvée (date de création changée, ligne dans `deploy.log`).
5. Recette client confirmant le chargement du nouveau front sans rechargement forcé.
6. Journal 145827 corrigé, date de `results.json` réconciliée, observation restituée à nouveau si besoin.
7. Décisions D1 à D3 tranchées par l'utilisateur ou le product owner.

Tant que le point 1 n'est pas vérifié sur une pile réellement redéployée, l'incident reste **ouvert**. Je ne propose pas de clôture de l'itération.

---

## CLÔTURE — restitution intégrale (source : `journal/160057-reaction.md`)

# Réaction de clôture : itération 002

Lecture seule, aucun fichier modifié. Base : `journal/155630-observation.md`, vérifiée sur `policies/results.json`, `tests/resultat.txt`, `cout.json`, `cout.md`, `rapport-client.md`, `journal/140419-client.md`, `mise-en-service.md`, `reaction.md` (tour 3 bis), `perimetre.md` et le fichier `dev`.

**Verdict.** Je ne propose pas la clôture sans trancher trois points :
1. **O2** (installation de `bash` 5.2.15-2+b13 non prouvée dans l'image) est bloquant selon la réaction du tour 3 bis. L'observation ne le mentionne pas.
2. **SPEC-003.9** échoue en passe finale (8 comptes hors `@test.invalid`, attendu : admin seul).
3. Les réserves de recette et l'écart « reset » de CA-002-1 n'ont pas d'acceptation du product owner dans les sources.

Légende : **[EXÉC]** sortie brute lue ; **[STAT]** vérification statique ; **[DÉCL]** affirmation d'un agent sans sortie brute.

---

## (A) LIVRÉ

| Élément | Preuve | Statut |
|---|---|---|
| Policies : 33 respectées, 0 violée, 0 non applicable, 15:56:04, `pile_demarree: true` | `results.json` l.3-4, l.304-308 | [EXÉC] |
| Policies 36 (bundle servi = sha256 du build) et 37 (`Cache-Control: no-cache` sur 7 chemins) respectées | `results.json` l.286-301 | [EXÉC] |
| Publication sans `127.0.0.1` dans le fichier `dev` (P4 de la mise en service) | Grep vide sur `dev` | [STAT] |
| Tests : 197 collectés, 192 réussis, 1 échec, 4 ignorés | `tests/resultat.txt` l.28 ; `junit.xml` | [EXÉC] |
| **Mise à jour de la pile service : FAIT** (réalisé par le responsable-applicatif) : backup dev 13:33:29 rc 0 ; `service.env` en 600 ; `deploy service` 1er passage 19 s (13:33:58Z), **2e passage sans reset 6 s (13:35:39Z)**, rc 0 ; restore rc 0 ; purge des comptes de test sur service (385 comptes, 173 tâches, 36 temps, 47 propositions) ; policies service 31/0 ; connexion admin 200 ; accès anonyme 401 (RLS) ; ports 8080 et 8081 sur `10.77.0.25` seul ; `restart unless-stopped` sur service ; CA-002-33 [R] (empreintes identiques hors admin, `service.env` inchangé, connexion admin valide) ; CA-002-36 [R] (a)(b)(c), dont le refus de `reset service` sans flag, rc 1 | `mise-en-service.md` l.43-64 | [DÉCL] |
| Preuve de non-intervention sur service après les redéploiements dev (13:57, 14:58, 15:55) | `mise-en-service.md` l.401-403, l.424-426 | [DÉCL], cohérent |
| Recette, passe 2 : **E7 (formulaires repliés) OK** | `journal/140419-client.md` l.292, l.307 | [DÉCL] |
| Recette, passe 1 : 22 critères [C] OK | `rapport-client.md` l.88 | [DÉCL] |
| Recette, passe 3 : CA-002-27 et 28 OK (texte exact, réserve de visibilité), CA-002-38 OK, CA-002-39 OK (focus non vérifié) | `rapport-client.md` l.107-111 | [DÉCL] |
| Audit npm consigné (E9) : statut « reussie », sha256 du lock concordant | `mise-en-service.md` l.347-354 ; `audit-npm.meta.json` | [DÉCL] + métadonnées |
| Versions apt épinglées dans le Dockerfile du runner | `tools/runner/Dockerfile` L3 | [STAT] (le contrôle dans l'image reste O2) |

---

## (B) ÉCARTS ACCEPTÉS ET ÉCARTS À FAIRE ACCEPTER

**B1. Décisions tranchées (perimetre.md l.15-19)**
- **D1** : dérogation CA-002-1, vérification `127.0.0.1` retirée. La partie « après reset puis deploy » n'a pas été jouée ; le responsable-applicatif la déclare « écart accepté » (`mise-en-service.md` l.62), mais le même document demande sa validation par le product owner (l.300). **Validation PO non trouvée.**
- **D2** (pile service retenue), **D3** (US-14 en Must), **D4** (mot de passe admin ≥ 20 caractères) : tranchées.
- **D5** (SPEC-003.9 classée [T] et cohérente) : **contredite par le FAIL de la passe finale** (voir C1).

**B2. Reports proposés, non décidés dans les sources**
- **O3** (compte rendu du développeur vide, `134058`) : non vérifié.
- **O4** (date d'audit et troisième paquet dans `mise-en-service.md`) : non vérifié.
- **O5 = policy 07 `ENV-apt-epingle`** : **non écrite** (aucun fichier `policies/checks/07*`). Le report est recommandé, pas décidé.
- **O6** (référence `dae9044` en dur dans la policy 29, ADR-015 §6 non relu) : `mise-en-service.md` l.149 garde aussi `dae9044` comme référence.

**B3. Réserves de recette, non acceptées par le product owner**
- CA-002-37 : **PARTIEL / BLOQUÉ** en passe 3 (zoom 200 % sans effet).
- CA-002-27 et 28 : message hors écran après clic. CA-002-39 : focus non vérifiable. CA-002-9 : URL non vérifiable.
- Étapes non jouées en passe 3 : 1, 3, 4, 6, 6 bis, 11, 13, 14, 15, 17, 18.2.
- Charge observée 6 h au lieu de 3 h, à cause de l'étape 15 non jouée : la procédure est incohérente sans elle.
- WebSocket au chargement non observée.

**Correction par rapport à la liste de la demande**
- **E7 n'est pas un écart accepté** : la passe 2 le déclare OK (voir A). Le document `rapport-client.md` l.81 est périmé.
- **O1** (recette des formulaires repliés) est donc couvert par déclaration, mais le rapport n'a pas été mis à jour.

---

## (C) BACKLOG 003

| # | Sujet | Équipe responsable | Action | Preuve de sortie | Niveau |
|---|---|---|---|---|---|
| C1 | **SPEC-003.9 en FAIL** : 8 comptes hors test (dev et service), contre 3 comptes réels attendus par le chef de projet | Décision : structure. Puis testeur pour la relance. | Trancher le statut des comptes réels. Le testeur ne doit pas modifier le test pour masquer l'écart. | `./dev test` sans échec | **Bloquant** |
| C2 | **O2** : `bash` 5.2.15-2+b13 non prouvé dans l'image (test AST seulement, `journal/134832` l.19-26) | Testeur (`tests/`, `dpkg-query`), action si le build doit être refait | Ajouter le test d'exécution | Test vert | **Bloquant** |
| C3 | **SPEC-003.11 et 003.12 sans test ; SPEC-004.2 non exécutée** | Testeur ; policy pour 003.10 à 003.12 | Écrire les tests et la policy | Nouvelles entrées dans `results.json` et `resultat.txt` | Élevé |
| C4 | **Vérification `email_confirmed_at` reportée au second deploy service** (ADR-013 D-4) : le second deploy n'en fait pas état | Testeur et responsable-applicatif | Exécuter la vérification au prochain deploy service | Consignée dans `mise-en-service.md` | Élevé |
| C5 | **SPEC-004.3, 004.7, 004.8 non exécutées ou en SKIP** (DEVENV_PILE=service) | Testeur, responsable-applicatif pour la pile service | Exécuter sur la pile service sans reset | `junit.xml` sans SKIP sur ces specs | Moyen |
| C6 | **Fragment de clé anon** dans `resultat.txt` l.7 et `junit.xml`, alors que `rapport-tour2` / `rapport-testeur` §7 affirment 0 occurrence | Testeur (corriger le rapport, purger les sorties) ; policy 05 à revoir | Corriger la sortie et la policy | Policy 05 couvre `tests/` | Élevé (hygiène) |
| C7 | **Recette sur la version finale** : aucune recette après le deploy dev 29a3980 (15:55) ; étapes non jouées ; CA-002-37 à 200 % ; procédure incohérente (étape 15) | Client (session f1). Developpeur si correctif. Product owner pour la procédure. | Rejouer les étapes manquantes sur la version finale | Rapport client daté après 15:55 | Élevé |
| C8 | **Policies** : CA-002-38 et 39 sans test ni policy ; CA-002-27/28/37 statiques, ne prouvent pas l'affichage ; REF 36 et 37 citent des « incidents » non décrits | Policy et testeur ; architecte pour la documentation | Écrire les contrôles manquants | Entrées dans `results.json` | Moyen |
| C9 | **Version du service** : service tourne sur `3c93a08`, dev sur `29a3980` (code identique à `ff6715f`) | Responsable-applicatif, décision de structure | Décider : redéployer service sur la version finale (deploy sans reset) ou accepter l'écart | Version consignée | **À trancher avant toute étape de proxy** |
| C10 | **P5 partiel** : `specs/`, `specs/adr/`, `policies/checks/35-*`, journaux et `results.json` non commités | Chef de projet (décision de commit) | Commit et vérification de `git status` | Commit noté dans `deploy.log` | Élevé |
| C11 | **Coût** : relevé à 14:29, `fin: null` ; coût Opus identique entre deux relevés (7,2888 USD) ; `sous_agents` = 0 partout | Sponsor (`cout.md`) | Relancer `./dev cout` après clôture, expliquer l'anomalie | `cout.json` avec `fin` renseigné | Moyen |
| C12 | **Compte réel inscrit vers 13:00** (domaine réel, non recoupé) | Structure, responsable-applicatif | Identifier, décider du traitement (sans le nommer dans les rapports) | Note de décision | Moyen |
| C13 | **Dev sans politique de redémarrage** (ADR-009, R-i) | Architecte puis responsable-applicatif | Décider et appliquer | Politique dans `stack/compose.yml` | Moyen |
| C14 | **Traçabilité** : `rapport-client.md` sans passe 2, l.81 périmé ; `cout.md` sans passe 2 ; `mise-en-service.md` titré « BASCULE » alors que son statut est « SERVICE PRÊTE (pré-bascule) » ; compte rendu O3 et journal 135 (E8, policy 35) | Chef de projet (consignation), client, responsable-applicatif, developpeur | Mettre les documents à jour | Relecture | Faible |
| C15 | Reliquats : compteur de débit (202 inscriptions depuis le journal de la passerelle, pas de compteur de test) ; variables GoTrue dépréciées ; message `127.0.0.1` (corrigé dans `dev`, à confirmer dans la sortie) | Testeur, action | Vérifier | Sortie consignée | Faible |

---

## (D) DÉCISIONS À REMONTER (structure, product owner, utilisateur)

1. **Structure** : clôture avec ou sans O2 ; statut de SPEC-003.9 (C1) ; version à faire tourner sur le service (C9) ; commit de la P5 (C10).
2. **Product owner** : acceptation de l'écart CA-002-1 « reset » (B1) ; acceptation ou report des réserves de recette (B3) ; report de la policy 07 et de O3 à O6 (B2) ; procédure de recette (C7).
3. **Utilisateur** : le statut des comptes réels (3 attendus, 8 présents) ; les décisions D1 à D8 de `mise-en-service.md` (fenêtre de coupure, gel de dev, sauvegarde hors hôte, durée de conservation de dev) ; la réservation DHCP de `10.77.0.25` (P6). **Hors mise à jour du responsable-applicatif**, ces étapes ne sont pas documentées comme faites : la bascule du proxy (S14), la validation par les utilisateurs (S15), la sauvegarde finale après gel (S5 à S7). Je ne les présente pas comme FAIT.

---

## (E) CONTRADICTIONS ENTRE SOURCES

1. **Recette** : passe 2 (14:04) KO sur CA-002-27, 28, 37, 38 et 39 ; passe 3 (14:59 à 15:17) OK ou partiel. Le seul changement consigné entre les deux est le correctif `Cache-Control` du deploy de 14:58. Aucune source n'explique le passage.
2. **Recette, passe 1** : « 16 étapes sur 18 entièrement conformes » (`rapport-client` l.92) contre un tableau de 18 OK, 1 réserve et 1 KO.
3. **Comptes réels** : 3 attendus par le chef de projet (`mise-en-service` A), 8 hors test sur dev et service (`mise-en-service`, passe finale, `rapport-testeur`), 8 comptes hors test et « 1 admin + 7 membres » (`mise-en-service` tour 3). Le test SPEC-003.9 échoue sur ce point.
4. **SPEC-003.9** : PASS au tour 2 (`rapport-tour2` l.78), FAIL en passe finale ; D5 (`perimetre`) la déclare cohérente.
5. **Testeur §7** : affirme 0 occurrence de secret ; `resultat.txt` l.7 et `junit.xml` contiennent un fragment de clé anon.
6. **Décompte [T]** : 49 specs (`rapport-testeur` l.19) contre 46 (`rapport-tour2` l.26).
7. **SPEC-004.3** : SKIP (passe finale), PASS (passe de 13:59), SKIP (tour 2). Ce sont trois passes distinctes.
8. **Tour 3 bis (reaction)** : « clôture conditionnelle » qui exige O1 et O2. L'observation n'évoque pas O2.
9. **Coût** : `cout.md` dit « 22 critères OK » à partir de la passe 1 seule, sans les 5 KO de la passe 2.
10. **Policies** : 31 (13:46, `cout.md`) contre 33 (15:56) : pas une contradiction, les dates diffèrent. Le passage en mode service a écrasé le fichier `results.json` (`mise-en-service` G).
11. **Versions** : `mise-en-service` donne dev `899ee3e` (13:57), puis `a4d5b4d` plus correctif non commité (14:58), puis `29a3980` (15:55) ; service `3c93a08`. Le lien entre `29a3980` et `ff6715f` n'est pas expliqué.
