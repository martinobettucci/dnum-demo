# Itération 002 — Rapport du testeur (passe complète sur `dev`)

Date : 2026-11-17 (passe finale 13:59–14:02 UTC, durée 30 s) · Pile : **dev** (`DEVENV_PILE` non défini, `APP_URL` = `http://app`).
Commande : `./dev test` (sans argument), dans le conteneur `runner`.
Artefacts : `iterations/002/tests/resultat.txt`, `iterations/002/tests/junit.xml` (passe finale).
La pile `service` n'a été ni démarrée, ni arrêtée, ni reconstruite ; la pile `dev` non plus (aucune commande de cycle de vie lancée).

## 1. Résultat global

| Total | Réussis | Échecs | Ignorés |
|---|---|---|---|
| 197 | 192 | **1** | 4 |

Passe précédente de la même itération (même code, avant correction du masquage, voir §5) : 194 réussis, 1 échec (le même), 2 ignorés.

## 2. Matrice SPEC → test → résultat (specs `[T]`)

Source : marqueurs `@pytest.mark.spec` (analyse AST des tests) et tags `[T]` des lignes de `specs/*.md`.
49 specs portent un `[T]`. Résultat : **39 couvertes et réussies**, **1 échec**, **3 ignorées**, **4 sans test marqué**, **2 couvertes seulement indirectement**.

| SPEC | Tests (fichier `tests/`) | Résultat |
|---|---|---|
| 001.4 | test_accueil_repond_200_en_html | PASS |
| 001.5 | test_sante_auth_200, test_rest_racine_pas_5xx | PASS |
| 001.6 | test_relais_auth_token_admin_renvoie_access_token, test_relais_rest_team_load_avec_jeton_admin | PASS |
| 001.7 | test_passerelle_refuse_api_admin_gotrue_403 (8 cas) | PASS |
| 001.8 | test_fichier_servi_sans_url_vers_autre_port (4), test_front_utilise_window_location_origin | PASS |
| 001.9 | test_csp_default_et_connect_src_self | PASS |
| 001.10 | test_config_js_expose_la_cle_anon_courante_et_aucune_autre, test_cle_service_role_absente_des_fichiers_servis (4) | PASS |
| 001.11 | 4 tests d'inscription (session immédiate, 7 car. → 422, 8 car. acceptés, e-mail déjà utilisé) | PASS |
| 001.12 | test_fonctions_private_non_exposees_404 (2), test_schema_private_non_accessible_par_profil | PASS |
| 001.13 | test_objets_du_schema_presents_via_api (6) | PASS |
| 001.14 | test_inscriptions_en_rafale (20 inscriptions), test_aucune_reponse_429 (plafond et 429) | PASS (voir §4) |
| 002.1 | test_anon_* / test_inactif_* (lecture, écriture, RPC : 27 cas) | PASS |
| 002.2 | test_anon_* (21 cas) | PASS |
| 002.3 | test_inactif_* (16 cas) | PASS |
| 002.4 | test_inscription_cree_profil_membre_inactif_visible_admin, test_inscrit_non_active_absent_de_team_load | PASS |
| 002.5 | test_admin_active_un_compte, test_membre_non_admin_ne_peut_pas_activer, test_membre_*  (7 cas) | PASS |
| 002.6 | test_apres_activation_nouveau_jeton_voit_team_load_et_tasks | PASS |
| 002.7 | test_creation_tache_* (10 cas) | PASS |
| 002.8 | test_affecte_*, test_tiers_*, test_patch_direct_* (12 cas) | PASS |
| 002.9 | test_membre_lit_les_taches_d_un_collegue_via_task_summary, test_logged_hours_compte_toutes_les_saisies | PASS |
| 002.10 | test_saisie_temps_* (11 cas) | PASS |
| 002.11 | test_jeu_de_reference_charge_projetee_3h, test_charge_nulle_sans_tache | PASS |
| 002.12 | test_seuil_surcharge_7h_strict, test_arrondi_au_quart_d_heure (2), test_temps_depasse_ne_rend_pas_la_charge_negative | PASS |
| 002.13 | test_inscrit_non_active_absent_de_team_load, test_team_load_contient_les_actifs_seulement | PASS |
| 002.14 | test_reaffectation_* (6 tests) | PASS |
| 002.15 | test_offer_help_* (4), test_insertion_directe_help_proposals_refusee | PASS |
| 002.16 | test_request_help_* (4) | PASS |
| 002.17 | test_accepter_offer_*, test_accepter_request_*, test_refuser_laisse_l_affectation_inchangee (2) | PASS |
| 002.18 | test_seul_le_destinataire_peut_repondre et 6 autres tests de réponse et d'expiration | PASS |
| 002.19 | test_compteur_propositions_recues_en_attente | PASS |
| 002.20 | test_desactivation_retire_l_acces, test_admin_ne_peut_pas_se_desactiver_lui_meme, test_membre_ne_peut_pas_desactiver_un_compte | PASS |
| 002.21 | test_filtre_aujourd_hui_sur_due_date, test_due_date_facultative_et_modifiable | PASS |
| 002.22 | test_suppression_de_tache_refusee, test_suppression_et_modification_de_temps_refusees, test_suppression_de_proposition_et_de_profil_refusees | PASS |
| 003.1 | test_fichier_secrets_contient_la_cle (6), test_jwt_secret_au_moins_40_caracteres, test_mot_de_passe_admin_genere_20_alphanumeriques, test_droits_fichier_0600_et_repertoire_0700 | PASS |
| 003.2 | test_cle_est_un_jwt_hs256_signe_par_jwt_secret (2) | PASS |
| 003.4 | test_connexion_admin_200, test_admin_my_status_actif_et_admin, test_connexion_admin_mauvais_mot_de_passe_refusee | PASS |
| 003.5 | test_un_seul_compte_admin_email_actif_admin, test_un_seul_administrateur | PASS |
| **003.9** | test_seul_admin_email_hors_comptes_de_test | **FAIL** (§3) |
| 003.10 | test_seed_compte_existant_confirme_rc0_sans_aucune_ecriture, test_seed_rejoue_n_fois_sur_compte_existant_sans_ecriture, test_seed_compte_absent_cree_par_post_seul_sans_put_ni_patch_ni_delete | PASS |
| **003.11** | **aucun test marqué** | **SANS TEST** (§3) |
| **003.12** | **aucun test marqué** | **SANS TEST** (§3) |
| 004.1 | test_app_url_par_defaut_sert_la_pile | PASS |
| 004.2 | — (`[T]` = SPEC-003.4 après `reset` : `reset` interdit sur `dev`) | **NON EXÉCUTÉ** |
| 004.3 | test_persistance_relire, test_persistance_ecrire | **SKIP** (§4) |
| 004.7 | test_pile_service_repond_avec_ses_propres_secrets | SKIP (pile `service` seule) |
| 004.8 | test_restauration_service_restitue_le_jeu_marque | SKIP (pile `service` seule) |
| 004.13 | `[T]` renvoie à 003.4, 003.5, 003.10 **et 003.11** (sans test) | **PARTIEL** (003.11 manquant) |
| 005.11 | `[T]` côté API = SPEC-001.11 (non marqué) | couvert indirectement, PASS |
| 005.12 | `[T]` côté API = SPEC-002.3 (non marqué) | couvert indirectement, PASS |

Autres marqueurs présents, réussis : SPEC-000.1 (test_page_accueil_repond), SPEC-000.2 (6 cas, §6), SPEC-003.3 (test_gitignore_contient_devenv), SPEC-003.6 (test_deploy_log_sans_secret).

Tests sans marqueur : aucun. Tous les tests portent un `spec`.

## 3. Échecs, sans-test et écarts

### 3.1 SPEC-003.9 — échec (test `test_seul_admin_email_hors_comptes_de_test`)
- Message : `comptes hors @test.invalid : 8 (attendu : ADMIN_EMAIL seul)`.
- **Cause probable : état des données, pas le code.** La base `dev` contient 8 comptes réels hors `@test.invalid` (393 comptes au total, dont 385 de test). Le constat est documenté dans `iterations/002/mise-en-service.md` (§ 6, « Comptes hors test : 8 sur dev, 8 sur service »). Ces comptes ont été repris tels quels par l'équivalence dev/service.
- La formulation de SPEC-003.9 (« hors comptes `@test.invalid`, seul `ADMIN_EMAIL` existe ») suppose une pile `dev` fraîche (reset + deploy), comme le précise `perimetre.md` § 2.2. `reset` est interdit sur `dev` à cette étape : le test ne peut pas passer sans reset.
- Ce qui est établi : le test vérifie bien la règle écrite. Ce qui reste à trancher : soit la spec doit être amendée pour exclure les comptes réels connus (décision de l'architecte), soit la règle est acceptée comme non vérifiable sur `dev` avec données réelles. Je ne modifie ni la spec ni les données.

### 3.2 SPEC-003.11 — sans test
Le `[T]` décrit un test dans `tests/test_003_admin.py` (stub GoTrue, compte `ADMIN_EMAIL` non confirmé, `seed.py` rc ≠ 0, aucune écriture). Le fichier `stub_gotrue.py` existe mais **aucun test marqué SPEC-003.11 n'existe**. Écart à combler (action du testeur, hors de cette passe).

### 3.3 SPEC-003.12 — sans test
Le `[T]` cité (« le login exige une vraie base, `reset` interdit sur `dev` gelée ») n'a pas de test marqué. Écart à combler.

### 3.4 SPEC-004.2 — non exécuté
Vérification `[T]` après `reset` + `deploy` : impossible sur `dev` gelée (reset interdit). Non couvert par la passe.

### 3.5 SPEC-004.13 — partiel
Son `[T]` s'appuie sur SPEC-003.11 (sans test, §3.2). Les autres renvois (003.4, 003.5, 003.10) sont couverts.

### 3.6 Couverture indirecte non marquée
SPEC-005.11 et SPEC-005.12 ont un `[T]` côté API, couvert par des tests d'autres SPEC (001.11 et 002.3). Le lien n'est pas porté par un marqueur `spec("SPEC-005.x")`. Non bloquant, mais à signaler à l'architecte.

## 4. SPEC-001.14 (débit) et comptage des inscriptions

- `test_inscriptions_en_rafale` : **PASS** (20 × 200 avec session immédiate).
- `test_aucune_reponse_429` : **PASS**, exécuté en dernier.
- Inscriptions de la passe finale (journal de la passerelle `devenv-app-1`, requêtes `POST /auth/v1/signup`, environ 14:01:40 → 14:02:10) : **202** au total (200 × 200 et 2 × 422). Le plafond est de **220** : marge de 18.
- Passe précédente (environ 13:59:16 → 13:59:46) : **204** inscriptions (202 × 200, 2 × 422). Marge de 16.
- Réponses **429** sur `/auth/v1/*` : **0** sur les deux passes. Statuts observés sur `/auth/v1` : 200, 400, 403 (refus de `/auth/v1/admin/*` par la passerelle, SPEC-001.7), 422.
- Le compteur interne de `conftest.py` n'est pas affiché par la passe : le chiffre ci-dessus est celui du journal de la passerelle, et `test_aucune_reponse_429` a validé le plafond (≤ 220) sans le signaler.

**SPEC-004.3 (persistance) :** en passe précédente, `test_persistance_relire` a **réussi** (jeu écrit avant le déploiement vérifié). En passe finale, il est **ignoré** : « aucun ./dev deploy depuis l'écriture du jeu marqué ». `test_persistance_ecrire` est ignoré car le jeu attend sa relecture. Ce test ne vérifie donc la persistance qu'après un nouveau `./dev deploy` ; c'est le fonctionnement prévu, pas une régression.

## 5. Corrections de la passe (tests/ uniquement)

- Le bloc d'échec de `test_seul_admin_email_hors_comptes_de_test` réaffichait `secrets_env` avec `ADMIN_EMAIL` en clair, dans `resultat.txt` et `junit.xml`. Le masquage de `tests/conftest.py` ne couvrait que les clés secrètes. **Correction** : ajout d'un motif d'e-mail dans `masquer()` (`<e-mail masqué>`). Aucune autre modification du code de test.
- Après correction, la passe finale ne contient plus d'adresse e-mail (vérifié par recherche sur `resultat.txt` et `junit.xml`).

## 6. Preuves de versions (SPEC-000.2, ADR-015)

Versions épinglées dans `tools/runner/Dockerfile` (ligne `apt-get install`) :

| Paquet | Version épinglée | Preuve dynamique `dpkg-query` (dans le runner) | Preuve statique (Dockerfile) |
|---|---|---|---|
| git | 1:2.39.5-0+deb12u3 | PASS (3/3 cas) | PASS |
| curl | 7.88.1-10+deb12u15 | PASS | PASS |
| bash | 5.2.15-2+b13 | PASS | PASS |

- `test_paquet_installee_dans_le_runner_a_la_version_epinglee` : **PASS** pour les 3 paquets. Exécuté dans le runner, non ignoré. Il compare la version `dpkg-query` à la version du Dockerfile.
- `test_paquet_runner_installe_en_version_epinglee` : **PASS** pour les 3 paquets (analyse statique du Dockerfile).
- Les versions retournées par `dpkg-query` ne sont pas inscrites dans les sorties du test (le test ne les affiche pas) ; la preuve est l'égalité réussie avec les versions du Dockerfile.

## 7. Contrôles de confidentialité des sorties

- `ADMIN_PASSWORD` et `JWT_SECRET` (valeurs lues dans `.devenv/secrets/dev.env`, non affichées) : **0 occurrence** dans `resultat.txt`, `junit.xml`, `rapport-testeur.md`. Vérifié de même pour `ANON_KEY`, `SERVICE_ROLE_KEY`, `POSTGRES_PASSWORD` : 0 occurrence.
- Adresses e-mail dans `resultat.txt` et `junit.xml` : **0** (après correction du §5).
- **Point ouvert** : `iterations/002/tests/persistance-dev.json` (écrit par `test_persistance_ecrire`) contient une adresse de test `…@test.invalid` (champ `membre_email`). Ce fichier n'est pas une sortie listée (`resultat.txt`, `junit.xml`, rapports), et le domaine est réservé aux comptes de test. Je ne l'ai pas modifié : le chef de projet doit trancher si ce fichier doit suivre la même règle. Ce fichier diffère de la version commitée (`ecrit_le` 12:31 dans git) : il a été réécrit par `test_persistance_ecrire` à 13:59:46, pendant la passe précédente. Il n'est pas à committer tel quel sans décision.

## 8. Synthèse pour le chef de projet

1. **Échec SPEC-003.9** : données réelles présentes sur `dev` (8 comptes) ; décision de spec ou d'environnement à prendre (architecte, responsable applicatif).
2. **Sans test** : SPEC-003.11 et SPEC-003.12 (et SPEC-004.13 partiel). À écrire au tour suivant.
3. **Non exécuté** : SPEC-004.2 (reset interdit sur `dev`). SPEC-004.7 et 004.8 : pile `service` seule, non jouées (conformément à la consigne).
4. **SPEC-004.3** : vérifié en passe précédente, à réexécuter après le prochain `./dev deploy`.
5. **SPEC-001.14** : vert ; 202 inscriptions (≤ 220), 0 × 429.
6. **Versions git, curl, bash** : épinglées et prouvées dans le runner (PASS).
