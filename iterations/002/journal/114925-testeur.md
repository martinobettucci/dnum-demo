# testeur — 2026-11-17T11:49:25+00:00

## Brief
Itération 002. Lis specs/ (SPEC-002, SPEC-003, SPEC-006 en priorité), iterations/002/perimetre.md, tests/ et tools/runner/. Écris les tests automatiques pytest de tous les CA-002-x marqués [T], via l'API Auth et REST de la passerelle, depuis le runner (APP_URL, secrets dans /workspace/.devenv/secrets/dev.env). Utilise des fixtures qui créent des comptes de test uniques, actifs ou non, via l'admin, pour que les tests soient rejouables sur une base non vide. Marque chaque test avec @pytest.mark.spec. Si une dépendance Python manque au runner, n'édite pas tools/runner : liste-la dans ton compte rendu. L'application n'existe pas encore, les tests échoueront : c'est normal. Ne lance pas la pile.

## Compte rendu
J'ai écrit les tests automatiques de l'itération 002, mais ils n'ont pas encore tourné. Le garde-fou m'interdit tout `docker run`, y compris un runner isolé sans réseau : je n'ai donc vérifié que la syntaxe des fichiers et la présence d'un marqueur `@pytest.mark.spec` sur chaque test (aucun n'en manque). Je n'ai rien démarré.

État actuel : la pile de l'itération 001 tourne (`devenv-app-1` healthy) et `.devenv/secrets/dev.env` n'existe pas. `./dev test` donnera donc des **échecs** et des **erreurs**, pas des skips. Les skips ne se produisent que si `APP_URL` ne répond pas. C'est attendu tant que l'application 002 n'est pas livrée.

## Fichiers (tous dans `tests/`)
| Fichier | Contenu |
|---|---|
| `conftest.py` (réécrit) | Client API (auth et REST via la passerelle). Skip de tous les tests si la pile est arrêtée. Lecture de `/workspace/.devenv/secrets/<pile>.env` (`DEVENV_PILE`, par défaut `dev`). Fixtures `admin`, `anon`, `fabrique`, `membre`, `collegue`, `tiers`, `inactif` : chaque compte est créé par `/auth/v1/signup` avec un e-mail `t-<uuid>@test.invalid`, puis activé par l'admin via `admin_set_active` (sauf `inactif`). La fixture `jeu` crée une tâche, du temps et une proposition, pour que les vérifications « zéro ligne » des comptes anonymes et inactifs portent sur une base qui contient réellement des données. |
| `test_001_pile.py` | SPEC-001 |
| `test_002_modele.py` | SPEC-002 |
| `test_003_admin.py` | SPEC-003 |
| `test_004_piles.py` | SPEC-004, dont la persistance en deux passes |

Au total : 186 cas paramétrés. Aucune valeur secrète n'apparaît dans les messages d'assertion.

## Matrice CA [T] → SPEC → tests (résultat : non exécuté)
| CA | SPEC couvertes | Tests principaux |
|---|---|---|
| CA-002-1 | 000.1, 001.4, 001.5, 001.13, 004.1 | `test_accueil_repond_200_en_html`, `…_sur_adresse_lan_du_serveur` (10.77.0.25:`APP_PORT` vu depuis le runner), santé auth et REST, présence des 6 objets du schéma |
| CA-002-2 | 001.10, 003.1, 003.2, 003.3 (partie [T]), 003.6 (partie [T]) | signature HS256 des clés (`hmac`), clé `service_role` et `JWT_SECRET` absentes des fichiers servis, `.gitignore`, aucun secret dans `deploy.log` |
| CA-002-3 | 001.6 à 001.10, 001.12 | relais auth et REST, 403 sur `/auth/v1/admin/*` (avec la clé anon et la clé service), aucune URL vers un autre port, CSP, fonctions `private` en 404 |
| CA-002-4 | 003.1, 003.4, 003.5 | clés présentes, mot de passe admin ≥ 20 caractères alphanumériques, droits 0600/0700, connexion admin, `my_status` admin, un seul compte `ADMIN_EMAIL` |
| CA-002-6, 7 (côté API) | 001.11, 002.4 | session immédiate à l'inscription ; mot de passe de 7 caractères → 422 ; e-mail en double → 4xx ; aucun compte créé dans ces deux cas |
| CA-002-9 | 002.5 | un membre ne peut ni appeler `admin_set_active` ni `admin_list_accounts` ; `PATCH profiles` sans effet (sur soi, sur un autre actif, sur un inactif) |
| CA-002-10, 11, 12 | 002.1, 002.2, 002.3, 002.6 | anonyme (avec et sans Bearer) et inactif : lectures des 4 tables et 2 vues, écritures, 6 RPC métier, auto-activation par `PATCH` ; nouveau jeton après activation |
| CA-002-13 à 16 | 002.7, 002.8 | création valide et 6 cas invalides → 400 sans création ; `PATCH` par l'affecté ou le créateur ; `PATCH` par un tiers sans effet ; `assignee_id` et `created_by` non modifiables, même par l'admin |
| CA-002-17 | 002.9 | `task_summary` d'un collègue ; `logged_hours` compte les saisies de tous les auteurs |
| CA-002-18 à 20 | 002.10 | +minutes/60, date du jour par défaut, bornes 1 et 1440 acceptées, 0 / −30 / 1441 → 400 ; saisie refusée pour un non-affecté, pour le créateur après réaffectation, et au nom d'autrui |
| CA-002-21 à 24 | 002.11, 002.12, 002.13 | **jeu de référence → 3,00 h** (non surchargé, 2 tâches ouvertes) ; seuil 7,00 / 7,25 / retour sous le seuil ; arrondis 1,25 et 1,00 ; reste jamais négatif ; seuls les actifs dans `team_load` |
| CA-002-25, 26 | 002.14 | réaffectation et recalcul des deux charges ; refus vers un inactif, un compte inexistant, soi-même, une tâche terminée ; refus par un tiers ou par le créateur non affecté |
| CA-002-27 à 32 | 002.15 à 002.19 | `offer_help` et `request_help` (visibilité, refus, doublons) ; acceptation et refus ; seul le destinataire répond ; propositions expirées après réaffectation, passage à « terminée » ou acceptation d'une autre ; compteur `count=exact` |
| CA-002-33 | 004.3, 003.5 | `test_persistance_ecrire` puis `test_persistance_relire` (voir plus bas) |
| CA-002-34, 35 (Could) | 002.20, 002.21 | désactivation, auto-désactivation refusée ; filtre `due_date` |
| CA-002-36 (Could) | 004.7, 004.8 | skip sauf avec `DEVENV_PILE=service` |
| hors périmètre §4 | 002.22 | `DELETE` et `PATCH time_entries` refusés |

Les tests Could portent aussi le marqueur `@pytest.mark.could`.

**Persistance (CA-002-33).** Le test s'appuie sur le fichier `iterations/002/tests/persistance-dev.json`. Ce fichier ne contient aucun mot de passe : celui du compte persistant est recalculé à partir d'un secret hors git, et le mot de passe admin n'y figure que sous forme d'empreinte sha256 tronquée. Déroulé :
1. Première passe de `./dev test` : écriture du jeu marqué.
2. `./dev deploy` sans reset, par le responsable applicatif.
3. Deuxième passe de `./dev test` : relecture. Ce test reste en skip tant que `.devenv/deploy.log` n'a pas d'entrée postérieure à l'écriture.

## Specs non couvertes en [T]
- **SPEC-001.1, 001.2, 001.3** : à vérifier par policy (compose, images) et par le responsable applicatif.
- **SPEC-001.4 côté 127.0.0.1 de l'hôte** : inaccessible depuis le conteneur, donc à vérifier par le responsable applicatif.
- **SPEC-003.3, recherche de secrets dans les fichiers suivis** : relève d'une policy.
- **SPEC-003.7, 003.9, 004.2, 004.4, 004.5, 004.9, 004.10** : à vérifier par le responsable applicatif ou par policy. SPEC-003.9 (un seul compte après reset) est d'ailleurs incompatible avec des tests qui créent des comptes.
- **SPEC-004.6** : relève d'une policy.
- **SPEC-002.1, partie `pg_class`** : se vérifie par `psql` dans `db`, auquel le runner n'a pas accès.
- **SPEC-005** : uniquement en recette [C].

## Points à remonter
- **Dépendances Python : aucune à ajouter.** `pytest` et `requests` suffisent, le reste vient de la bibliothèque standard.
- **Limite d'inscriptions :** une passe fait environ 184 inscriptions. SPEC-001.11 ne demande qu'un minimum de 100 par heure. Si GoTrue limite effectivement les inscriptions à ce niveau, les tests échoueront en 429. À signaler à l'architecte et au développeur : il faut un seuil d'environ 500 par heure ou plus.
- **Hypothèses d'implémentation :**
  - Une RPC peut renvoyer un objet ou une liste d'une ligne : les deux sont acceptés.
  - `offer_help` et `request_help` renvoient l'identifiant de la proposition.
  - Le fuseau de la base est UTC (date du jour pour `work_date` et `due_date`).
  - `test_accueil_repond_200_sur_adresse_lan_du_serveur` suppose `APP_PORT` à 8080 par défaut et que le conteneur atteint 10.77.0.25. Un échec de ce test peut donc venir du réseau et pas de l'application.
- **Rapport :** il sera produit par `./dev test` dans `iterations/002/tests/junit.xml` et `resultat.txt`. Aucune exécution n'a encore eu lieu ; je n'ai pas écrit dans `iterations/` moi-même.
