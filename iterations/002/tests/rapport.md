# Itération 002 — Tour 1 : état de référence des tests automatiques

- Rédigé par : `testeur` (équipe DevOps)
- Référence : `specs/SPEC-006-plan-verification.md`, `./dev test` exécuté dans le conteneur `runner` contre la pile **actuelle** (non redémarrée, non reconstruite).
- Sorties brutes : `resultat.txt`, `junit.xml` (même dossier).
- Pile constatée : `app` (healthy), `client` up ; `app` publie uniquement `127.0.0.1:8080->80`.

## 1. Résultat global

`7 failed, 5 passed, 1 skipped, 173 errors` (186 tests collectés).

| Catégorie | Nb | Cause |
|---|---|---|
| Erreurs de fixture (setup) | 173 | Fichier de secrets absent : `/workspace/.devenv/secrets/dev.env` (SPEC-003.1, SPEC-006 §1). |
| Échecs réels | 7 | Écarts d'implémentation (voir §3) + 1 échec conséquence de l'absence des secrets. |
| Passés | 5 | Page d'accueil, HTML de `/`, `.gitignore`, `APP_URL` par défaut, test `/` dans 001.8. |
| Sautés | 1 | `test_restauration_service_restitue_le_jeu_marque` : exige `DEVENV_PILE=service` (SPEC-004.8, Could). |

## 2. Relecture de `tests/` au regard de SPEC-006

Méthode : marqueurs `@pytest.mark.spec` relus par analyse syntaxique (AST) des fichiers `tests/test_*.py`, croisés avec les identifiants `SPEC-xxx.y` définis dans `specs/`. La correspondance CA → test repose sur les marqueurs et les noms de fonctions, pas sur une revue ligne à ligne des assertions.

- **Couverture des CA `[T]` de SPEC-006 §2** : chaque CA ayant une vérification `[T]` dans SPEC-006 §2 (CA-002-1 à CA-002-4, CA-002-6 à CA-002-32, CA-002-33, CA-002-34, CA-002-35, CA-002-36) dispose d'au moins une fonction de test correspondante. CA-002-5 est `[C]` seul. Aucun trou détecté sur les lignes `[T]`.
- **Identifiants de specs sans marqueur de test** : voir la matrice §4. Tous relèvent de `[P]`, `[R]` ou `[C]` dans SPEC-006, sauf les points signalés ci-dessous.
- **Points à signaler (écarts de test, pas d'implémentation)** :
  1. SPEC-003.9 est cité dans un message de skip (`conftest.py`) mais n'a aucun marqueur. SPEC-006 le classe `[R]` : pas de test automatique attendu.
  2. SPEC-001.3 (publication des ports : seul `app`, liaison `127.0.0.1` et LAN) n'a aucun marqueur. La partie LAN est pourtant testée indirectement par `test_accueil_repond_200_sur_adresse_lan_du_serveur` (SPEC-001.4), qui échoue (§3). Un test explicite serait souhaitable : **à ajouter au prochain tour**, il est automatisable depuis le runner (contrôle de la publication côté hôte relevant de `[P]`/`[R]`).
  3. `test_fichier_servi_sans_url_vers_autre_port` et `test_front_utilise_window_location_origin` supposent les fichiers `/app.js`, `/config.js`, `/style.css`. Ces noms **sont** imposés par SPEC-001.8 et ADR-002 : l'assomption est donc conforme aux specs.
  4. SPEC-006 §1 prévoit `skip` quand la pile est arrêtée. Ici la pile est démarrée et les tests **échouent en erreur de setup** faute de secrets : comportement conforme à SPEC-003.1, mais à noter.
  5. `test_accueil_repond_200_sur_adresse_lan_du_serveur` suppose que le conteneur `runner` atteint `10.77.0.25:8080`. Le refus de connexion constaté est cohérent avec une publication absente sur cette adresse (§3), mais il n'est pas établi que le runner soit censé joindre l'hôte par cette IP. À trancher par le responsable applicatif avec l'architecte.

## 3. Échecs réels constatés (à remonter)

| # | Test | Spec | Constat | Interprétation |
|---|---|---|---|---|
| F1 | `test_accueil_repond_200_sur_adresse_lan_du_serveur` | SPEC-001.4 / 001.3 / CA-002-1 | `Connection refused` sur `10.77.0.25:8080` | `stack/compose.yml` ne publie que `127.0.0.1:${APP_PORT:-8080}:80` ; SPEC-001.3 exige aussi `${APP_LAN_IP:-10.77.0.25}:${APP_PORT}:80`. **Écart de publication.** |
| F2 | `test_fichier_servi_sans_url_vers_autre_port[/app.js]` | SPEC-001.8 / CA-002-3 | 404 | Le front n'est pas livré : `app/public/index.html` est un placeholder (« L'application sera réalisée à partir de la première itération »). **Écart d'implémentation (SPEC-001.8, SPEC-005).** |
| F3 | idem `[/config.js]` | SPEC-001.8 / 001.10 | 404 | idem F2 |
| F4 | idem `[/style.css]` | SPEC-001.8 | 404 | idem F2 |
| F5 | `test_front_utilise_window_location_origin` | SPEC-001.8 | Aucun `location.origin` dans `/app.js` ni `/config.js` (404) | Conséquence de F2. |
| F6 | `test_csp_default_et_connect_src_self` | SPEC-001.9 / CA-002-3 | Aucun en-tête `Content-Security-Policy` sur `/` (HTTP 200 vérifié, `Server: nginx/1.27.3`, aucune CSP ; aucune CSP dans `stack/` ni `app/`) | **Écart d'implémentation** : CSP non configurée. |
| F7 | `test_droits_fichier_0600_et_repertoire_0700` | SPEC-003.1 | `FileNotFoundError` : `/workspace/.devenv/secrets/dev.env` | Conséquence de l'absence des secrets (§4, B1). |

Constat complémentaire : `/` répond 200 `text/html` (`test_accueil_repond_200_en_html`, `test_page_accueil_repond`) : seul point de la passerelle réellement fonctionnel par les tests de cette passe.

## 4. Bloquant d'environnement (B1)

- `.devenv/` ne contient que `chef-de-projet.lock` et `deploy.log` (daté 11:21). **Le dossier `.devenv/secrets/` et `dev.env` sont absents.**
- Conséquence : les 173 erreurs de setup (fixtures `secrets_env`, `anon_key`, `admin`, `fabrique`, `jeu`, `anon`) et les tests de SPEC-002, 003, 004.3, 004.7 ne sont pas exécutés en substance. **Aucune conclusion sur SPEC-002 n'est possible à ce stade.**
- Je n'ai ni démarré, ni reconstruit, ni régénéré quoi que ce soit (rôle du `responsable-applicatif`). Il appartient à celui-ci de statuer (SPEC-004.2 indique que `dev.env` est régénérable si absent).

## 5. Matrice SPEC → test → résultat

Légende : **OK** passe · **KO** échec réel · **ERR** erreur de setup (secrets absents, §4) · **SKIP** sauté · **NC** non couvert par un test automatique (spec `[P]`/`[R]`/`[C]` selon SPEC-006).

| SPEC | Tests (fichier) | Résultat | Remarque |
|---|---|---|---|
| SPEC-000.1 | test_000_socle::test_page_accueil_repond | OK | |
| SPEC-000.2 | — | NC | `[P]` / `[R]` (reconstruction bootstrap) |
| SPEC-000.3 | — | NC | `[R]` (reset + deploy) |
| SPEC-001.1 | — | NC | `[P]` compose |
| SPEC-001.2 | — | NC | `[P]` images épinglées |
| SPEC-001.3 | — | NC | `[P]`/`[R]` ; LAN couvert indirectement par 001.4 (F1) — **écart de test à combler** |
| SPEC-001.4 | test_accueil_repond_200_en_html **OK** ; test_accueil_..._lan **KO** (F1) | KO | |
| SPEC-001.5 | test_sante_auth_200, test_rest_racine_pas_5xx | ERR | secrets |
| SPEC-001.6 | test_relais_auth_token_admin…, test_relais_rest_team_load… | ERR | secrets |
| SPEC-001.7 | test_passerelle_refuse_api_admin_gotrue_403 (×8) | ERR | secrets |
| SPEC-001.8 | test_fichier_servi_sans_url… ([/] **OK**, [/app.js], [/config.js], [/style.css] **KO**) ; test_front_utilise_window_location_origin **KO** | KO | F2–F5 |
| SPEC-001.9 | test_csp_default_et_connect_src_self | KO | F6 |
| SPEC-001.10 | test_config_js_expose…, test_cle_service_role_absente… (×4) | ERR | secrets |
| SPEC-001.11 | 4 tests (signup, 7/8 caractères, doublon) | ERR | secrets |
| SPEC-001.12 | test_fonctions_private_non_exposees_404 (×2), test_schema_private… | ERR | secrets |
| SPEC-001.13 | test_objets_du_schema_presents_via_api (×6) | ERR | secrets |
| SPEC-002.1 à 002.22 | test_002_modele.py (≈ 150 cas paramétrés) | ERR | Tous en erreur de setup (`jeu`, `anon`, `fabrique`, secrets). Aucun résultat fonctionnel. |
| SPEC-003.1 | 4 tests (clés, JWT ≥ 40, mdp admin 20 car., droits 0600/0700) | KO | droits 0600 : F7 ; autres ERR |
| SPEC-003.2 | test_cle_est_un_jwt_hs256… (×2) | ERR | secrets |
| SPEC-003.3 | test_gitignore_contient_devenv | OK | |
| SPEC-003.4 | test_connexion_admin_200, my_status, mauvais mdp | ERR | secrets |
| SPEC-003.5 | test_un_seul_compte_admin…, test_un_seul_administrateur, test_persistance_relire | ERR | secrets |
| SPEC-003.6 | test_deploy_log_sans_secret | ERR | secrets (le journal `deploy.log` existe) |
| SPEC-003.7 | — | NC | `[R]` |
| SPEC-003.8 | — | NC | `[C]` |
| SPEC-003.9 | — (mentionné dans un message de skip, sans marqueur) | NC | `[R]` ; écart de marquage mineur |
| SPEC-004.1 | test_app_url_par_defaut_sert_la_pile | OK | |
| SPEC-004.2 | — | NC | `[R]` |
| SPEC-004.3 | test_persistance_relire, test_persistance_ecrire | ERR | secrets ; passe A/B non exécutée (CA-002-33) |
| SPEC-004.4 | — | NC | `[R]` |
| SPEC-004.5 | — | NC | `[P]` / `[R]` |
| SPEC-004.6 | — | NC | `[P]` garde-fou (policy à écrire) |
| SPEC-004.7 (Could) | test_pile_service_repond_avec_ses_propres_secrets | ERR | secrets ; requiert `DEVENV_PILE=service` |
| SPEC-004.8 (Could) | test_restauration_service_restitue_le_jeu_marque | SKIP | requiert `DEVENV_PILE=service` après backup/restore |
| SPEC-004.9 (Could) | — | NC | `[R]` |
| SPEC-004.10 | — | NC | `[R]` |
| SPEC-005.* (toutes, 1 à 61) | — | NC | Recette `[C]` (client) selon SPEC-006 §2. Candidats partiels à une vérification textuelle future : 005.1 (libellés), 005.10–005.14 (routes `#/…`), à traiter quand le front existera. |

Bilan de couverture : **toutes les specs `[T]` de SPEC-006 ont un test** ; les specs non couvertes sont `[P]`, `[R]` ou `[C]` par construction. Écarts de marquage à corriger : SPEC-001.3 (LAN) et SPEC-003.9 (marqueur absent).

## 6. Suite proposée (à décider par le chef de projet)

1. Responsable applicatif : régénérer / restaurer `.devenv/secrets/dev.env` (B1), puis relancer `./dev test` : il faut une passe propre avant toute conclusion sur SPEC-002.
2. Développeur / architecte : publication LAN de `app` (F1), livraison du front `app.js`/`config.js`/`style.css` (F2–F5), en-tête CSP (F6).
3. Testeur (prochain tour, sans modifier les specs) : ajouter un marqueur explicite à SPEC-001.3 et SPEC-003.9 si automatisable ; vérifier l'adresse LAN depuis le runner avec l'architecte.
4. Tests « service » (CA-002-33 passe B, CA-002-36) : à exécuter après `deploy` / `backup`/`restore` par le responsable applicatif.

Aucun test n'a été modifié pendant ce tour. Aucun secret n'apparaît dans ce rapport.
