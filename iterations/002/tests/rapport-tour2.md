# Itération 002 — Tour 2 : première passe des tests automatiques (partie 2)

- Rédigé par : `testeur` (équipe DevOps), 2026-11-17.
- Référence : `specs/SPEC-006-plan-verification.md` (§1 conditions, §2 matrice CA, §3 policies).
- Commande : `./dev test` (conteneur `runner`, `APP_URL=http://app`, pile `dev`).
- Pile : **constatée en service, non touchée** (aucun `deploy`, `teardown`, `reset` ni build lancé).
- Sorties brutes : `resultat.txt`, `junit.xml` (même dossier). Rapport du tour 1 conservé dans `rapport.md`.
- Écrit dans `iterations/002/tests/` uniquement. Aucun secret affiché ni écrit.

## 1. Résultat global

`183 passed, 3 skipped` (186 tests collectés), **0 échec, 0 erreur**, 25,6 s.

| Catégorie | Nb | Détail |
|---|---|---|
| Passés | 183 | Tous les tests `test_000` à `test_003` et `test_004` hors skips. |
| Échecs / erreurs | 0 | — |
| Sautés | 3 | Attendus, détaillés au §4 (2 × pile `service`, 1 × relecture de persistance). |

Comparaison avec le tour 1 (`rapport.md`) : 7 échecs réels et 173 erreurs de setup (secrets absents) ; ces écarts sont **résolus** dans la pile actuelle (publication LAN, front servi, secrets présents).

## 2. Matrice SPEC → test → résultat

Légende des tags : `T` test automatique (spec), `P` policy, `R` recette responsable applicatif, `C` recette client.
Les identifiants sans test pytest sont vérifiés par un autre mécanisme (colonne « Remarque »).
Total : **87 identifiants** de spec (SPEC-000 à 005) ; **44** ont au moins un test marqué ; **46** exigences portent `[T]` dans un tableau, dont **5 sans marqueur** (voir §3).

| Id | Tags | Tests (fichier::fonction) | Résultat | Remarque |
|---|---|---|---|---|
| SPEC-000.1 | — | `test_000_socle::test_page_accueil_repond` | PASS | |
| SPEC-000.2 | — | — | — | policies `ENV-*` (hors pytest) |
| SPEC-000.3 | — | — | — | recette RA (hors pytest) |
| SPEC-001.1 | P | — | — | policy (hors pytest) |
| SPEC-001.2 | P | — | — | policy (hors pytest) |
| SPEC-001.3 | P,R | — | — | policy `STACK-ports-lan` + `ss -ltn` RA (hors pytest) |
| SPEC-001.4 | R,T | `test_001_pile::test_accueil_repond_200_en_html` | PASS | LAN : `[R]` |
| SPEC-001.5 | R,T | `test_001_pile::test_rest_racine_pas_5xx`, `test_001_pile::test_sante_auth_200` | PASS | |
| SPEC-001.6 | T | `test_001_pile::test_relais_auth_token_admin_renvoie_access_token`, `test_001_pile::test_relais_rest_team_load_avec_jeton_admin` | PASS | |
| SPEC-001.7 | T | `test_001_pile::test_passerelle_refuse_api_admin_gotrue_403` (8 cas) | PASS | |
| SPEC-001.8 | C,P,T | `test_001_pile::test_fichier_servi_sans_url_vers_autre_port` (4 cas), `test_001_pile::test_front_utilise_window_location_origin` | PASS | |
| SPEC-001.9 | T | `test_001_pile::test_csp_default_et_connect_src_self` | PASS | |
| SPEC-001.10 | T | `test_001_pile::test_cle_service_role_absente_des_fichiers_servis` (4 cas), `test_001_pile::test_config_js_expose_la_cle_anon_courante_et_aucune_autre` | PASS | |
| SPEC-001.11 | T | `test_001_pile::test_inscription_ouvre_une_session_immediate`, `test_inscription_mot_de_passe_8_caracteres_acceptee`, `test_inscription_mot_de_passe_7_caracteres_refusee_422_sans_compte`, `test_inscription_email_deja_utilise_refusee_sans_doublon` | PASS | |
| SPEC-001.12 | T | `test_001_pile::test_fonctions_private_non_exposees_404` (2 cas), `test_001_pile::test_schema_private_non_accessible_par_profil` | PASS | |
| SPEC-001.13 | R,T | `test_001_pile::test_objets_du_schema_presents_via_api` (6 cas) | PASS | deux `deploy` : `[R]` |
| SPEC-001.14 | P,T | — | — | **[T] manquant** : `test_inscriptions_en_rafale` et `test_aucune_reponse_429` absents (§3, E1) |
| SPEC-001.15 | P,R | — | — | policy `FRONT-audit-npm` (hors pytest) |
| SPEC-002.1 | R,T | `test_002_modele::test_anon_lecture_zero_ligne_ou_refus`, `test_anon_ecriture_tache_refusee_sans_effet`, `test_anon_rpc_metier_refusees`, `test_inactif_lecture_zero_ligne_ou_refus` | PASS | `relforcerowsecurity` : `[R]` |
| SPEC-002.2 | T | `test_002_modele::test_anon_lecture_zero_ligne_ou_refus` (8 cas), `test_anon_ecriture_tache_refusee_sans_effet`, `test_anon_ecriture_temps_profil_proposition_refusees_sans_effet`, `test_anon_rpc_metier_refusees` | PASS | |
| SPEC-002.3 | T | `test_002_modele::test_inactif_*` (my_status, création, lecture, RPC, saisie, PATCH profiles) | PASS | |
| SPEC-002.4 | T | `test_002_modele::test_inscription_cree_profil_membre_inactif_visible_admin`, `test_inscrit_non_active_absent_de_team_load` | PASS | |
| SPEC-002.5 | T | `test_002_modele::test_admin_active_un_compte`, `test_membre_non_admin_ne_peut_pas_activer`, `test_membre_non_admin_ne_peut_pas_lister_les_comptes`, `test_membre_patch_profiles_sans_effet` (3 cas) | PASS | |
| SPEC-002.6 | T | `test_002_modele::test_apres_activation_nouveau_jeton_voit_team_load_et_tasks` | PASS | |
| SPEC-002.7 | T | `test_002_modele::test_creation_tache_valide_201_todo_affectee_a_soi`, `test_creation_tache_invalide_400_sans_creation` (6 cas), `test_creation_tache_affectee_a_autrui_refusee`, `test_creation_tache_created_by_usurpe_refusee`, `test_creation_tache_sans_description_acceptee` | PASS | |
| SPEC-002.8 | T | `test_002_modele::test_affecte_modifie_titre_description_estimation_statut`, `test_createur_non_affecte_peut_modifier`, `test_tiers_ne_peut_pas_modifier_la_tache`, `test_patch_direct_assignee_ou_created_by_refuse` (4 cas), `test_admin_ne_peut_pas_patcher_assignee_id`, `test_statut_hors_liste_refuse`, `test_affecte_change_le_statut` (3 cas) | PASS | |
| SPEC-002.9 | T | `test_002_modele::test_membre_lit_les_taches_d_un_collegue_via_task_summary`, `test_logged_hours_compte_toutes_les_saisies_quel_qu_en_soit_l_auteur` | PASS | |
| SPEC-002.10 | T | `test_002_modele::test_saisie_temps_par_affecte_augmente_logged_hours`, `test_saisie_temps_bornes_acceptees` (2 cas), `test_saisie_temps_duree_invalide_400` (3 cas), `test_saisie_temps_par_non_affecte_refusee`, `test_saisie_temps_au_nom_d_autrui_refusee`, `test_saisie_temps_par_createur_apres_reaffectation_refusee`, `test_saisie_temps_date_par_defaut_aujourd_hui`, `test_saisie_temps_date_explicite` | PASS | |
| SPEC-002.11 | T | `test_002_modele::test_jeu_de_reference_charge_projetee_3h`, `test_charge_nulle_sans_tache` | PASS | |
| SPEC-002.12 | T | `test_002_modele::test_arrondi_au_quart_d_heure` (2 cas), `test_seuil_surcharge_7h_strict`, `test_temps_depasse_ne_rend_pas_la_charge_negative` | PASS | |
| SPEC-002.13 | T | `test_002_modele::test_team_load_contient_les_actifs_seulement`, `test_inscrit_non_active_absent_de_team_load` | PASS | |
| SPEC-002.14 | T | `test_002_modele::test_reaffectation_par_affecte_vers_actif_et_charges_recalculees`, `test_reaffectation_par_tiers_refusee`, `test_reaffectation_par_createur_non_affecte_refusee`, `test_reaffectation_tache_terminee_ou_vers_soi_refusee`, `test_reaffectation_vers_compte_inactif_refusee`, `test_reaffectation_vers_compte_inexistant_refusee` | PASS | |
| SPEC-002.15 | T | `test_002_modele::test_offer_help_cree_proposition_visible_emetteur_et_destinataire`, `test_offer_help_doublon_pending_refuse`, `test_offer_help_par_l_affecte_lui_meme_refuse`, `test_offer_help_sur_tache_terminee_refuse`, `test_insertion_directe_help_proposals_refusee` | PASS | |
| SPEC-002.16 | T | `test_002_modele::test_request_help_vers_actif_recue_par_le_destinataire`, `test_request_help_par_non_affecte_ou_vers_soi_refuse`, `test_request_help_tache_terminee_ou_doublon_refuse`, `test_request_help_vers_inactif_refuse` | PASS | |
| SPEC-002.17 | T | `test_002_modele::test_accepter_offer_affecte_la_tache_au_proposant`, `test_accepter_request_affecte_la_tache_au_destinataire`, `test_refuser_laisse_l_affectation_inchangee` (2 cas) | PASS | |
| SPEC-002.18 | T | `test_002_modele::test_seul_le_destinataire_peut_repondre`, `test_admin_non_destinataire_ne_peut_pas_repondre`, `test_proposition_deja_traitee_ne_peut_plus_etre_acceptee` (2 cas), `test_proposition_expiree_apres_reaffectation`, `test_proposition_expiree_apres_passage_a_done`, `test_acceptation_expire_les_autres_propositions_pending`, `test_patch_direct_help_proposals_refuse` | PASS | |
| SPEC-002.19 | T | `test_002_modele::test_compteur_propositions_recues_en_attente` | PASS | |
| SPEC-002.20 | T | `test_002_modele::test_desactivation_retire_l_acces`, `test_admin_ne_peut_pas_se_desactiver_lui_meme`, `test_membre_ne_peut_pas_desactiver_un_compte` | PASS | Could |
| SPEC-002.21 | T | `test_002_modele::test_due_date_facultative_et_modifiable`, `test_filtre_aujourd_hui_sur_due_date` | PASS | Could |
| SPEC-002.22 | T | `test_002_modele::test_suppression_de_tache_refusee`, `test_suppression_de_proposition_et_de_profil_refusees`, `test_suppression_et_modification_de_temps_refusees` | PASS | |
| SPEC-003.1 | R,T | `test_003_admin::test_fichier_secrets_contient_la_cle` (6 cas), `test_droits_fichier_0600_et_repertoire_0700`, `test_jwt_secret_au_moins_40_caracteres`, `test_mot_de_passe_admin_genere_20_alphanumeriques` | PASS | |
| SPEC-003.2 | T | `test_003_admin::test_cle_est_un_jwt_hs256_signe_par_jwt_secret` (2 cas) | PASS | |
| SPEC-003.3 | P | `test_003_admin::test_gitignore_contient_devenv` | PASS | Test ajouté hors tag `[T]` de la spec (§3, E6) |
| SPEC-003.4 | T | `test_003_admin::test_connexion_admin_200`, `test_admin_my_status_actif_et_admin`, `test_connexion_admin_mauvais_mot_de_passe_refusee` | PASS | |
| SPEC-003.5 | R,T | `test_003_admin::test_un_seul_administrateur`, `test_un_seul_compte_admin_email_actif_admin`, `test_004_piles::test_persistance_relire` | PASS, SKIP | SKIP attendu : passe B non faite (§4) |
| SPEC-003.6 | P,R | `test_003_admin::test_deploy_log_sans_secret` | PASS | Test ajouté hors tag `[T]` (§3, E6) |
| SPEC-003.7 | R | — | — | relecture RA (hors pytest) |
| SPEC-003.8 | C | — | — | recette client (hors pytest) |
| SPEC-003.9 | R,T | `test_003_admin::test_seul_admin_email_hors_comptes_de_test` | PASS | |
| SPEC-004.1 | R,T | `test_004_piles::test_app_url_par_defaut_sert_la_pile` | PASS | |
| SPEC-004.2 | R,T | — | — | **[T] indirect** : couvert par `test_003_admin` après `reset` (non marqué, §3, E3) |
| SPEC-004.3 | T | `test_004_piles::test_persistance_ecrire` ; `test_004_piles::test_persistance_relire` | PASS, SKIP | Passe A faite (écriture de `persistance-dev.json`) ; passe B à faire après `deploy` (§4) |
| SPEC-004.4 | R | — | — | recette RA (hors pytest) |
| SPEC-004.5 | P,R | — | — | policies `ENV-*` ; bootstrap RA |
| SPEC-004.6 | P | — | — | policy garde-fou (hors pytest) |
| SPEC-004.7 | P,R,T | `test_004_piles::test_pile_service_repond_avec_ses_propres_secrets` | SKIP | Pile `service` non testée dans cette passe (§4) |
| SPEC-004.8 | R,T | `test_004_piles::test_restauration_service_restitue_le_jeu_marque` | SKIP | Could ; même motif (§4) |
| SPEC-004.9 | R | — | — | recette RA (hors pytest) |
| SPEC-004.10 | R | — | — | recette RA (`mise-en-service.md`) |
| SPEC-004.11 | P,R | — | — | policy `STACK-points-accroche` (hors pytest) |
| SPEC-004.12 | P,R | — | — | policy `DB-migrations-versionnees` ; deux `deploy` RA |
| SPEC-004.13 | P,T | — | — | **[T] sans marqueur** : couvert par `test_003_admin` (003.4, 003.5) (§3, E2) |
| SPEC-004.14 | P,R | — | — | policy `STACK-points-accroche` ; RA |
| SPEC-004.15 | P,R | — | — | policy + relecture RA (hors pytest) |
| SPEC-004.16 | P,R | — | — | policy `STACK-tags-par-pile` ; RA |
| SPEC-004.17 | P,R | — | — | policy `DEV-sortie-url` ; RA |
| SPEC-005.1 | C | — | — | recette client |
| SPEC-005.2 | C | — | — | recette client |
| SPEC-005.3 | C | — | — | recette client |
| SPEC-005.4 | C | — | — | recette client |
| SPEC-005.5 | C | — | — | recette client |
| SPEC-005.10 | C | — | — | recette client |
| SPEC-005.11 | C,T | — | — | **[T] sans marqueur** : côté API couvert par SPEC-001.11 (§3, E4) ; recette client pour le reste |
| SPEC-005.12 | C,T | — | — | **[T] sans marqueur** : côté API couvert par SPEC-002.3 (§3, E4) |
| SPEC-005.13 | C | — | — | recette client |
| SPEC-005.14 | C | — | — | recette client |
| SPEC-005.20 | C | — | — | recette client |
| SPEC-005.21 | C | — | — | recette client |
| SPEC-005.30 | C | — | — | recette client |
| SPEC-005.31 | C | — | — | recette client |
| SPEC-005.32 | C | — | — | recette client |
| SPEC-005.33 | C | — | — | recette client |
| SPEC-005.40 | C | — | — | recette client |
| SPEC-005.50 | C | — | — | recette client |
| SPEC-005.51 | C | — | — | recette client |
| SPEC-005.60 | C | — | — | recette client |
| SPEC-005.61 | C | — | — | recette client |

Les identifiants `SPEC-001.x` à `SPEC-004.x` sans `T` ne sont vérifiables que par policy, recette RA ou recette client : ils n'appellent pas de test pytest, conformément à SPEC-006 §2.

## 3. Écarts (à remonter au chef de projet)

| Id | Écart | Spec | Impact | Action proposée |
|---|---|---|---|---|
| **E1** | **Aucun test pour les débits.** `test_inscriptions_en_rafale` (20 inscriptions → 20 × 200) et `test_aucune_reponse_429` (contrôle de toute 429 relevée pendant `./dev test`) sont annoncés par SPEC-001.14 mais absents de `tests/`. | SPEC-001.14, SPEC-006 §1 | **Bloquant pour la couverture** : l'exigence `[T]` n'est pas vérifiée. Sans ce test, une limitation de débit ne serait pas détectée et la limite de 220 inscriptions par passe (SPEC-006 §1) n'est pas contrôlée. | À écrire par le testeur au tour suivant (hors tour actuel : première passe sans modification de `tests/`). |
| E2 | `SPEC-004.13` porte `[T]` sans marqueur ; la vérification (SPEC-003.4 et 003.5) est faite par `test_003_admin`. | SPEC-004.13 | Couverture réelle, traçabilité absente. | Ajouter le marqueur sur les tests de `test_003_admin` concernés, ou préciser la spec. |
| E3 | `SPEC-004.2` porte `[T]` (SPEC-003.4 après `reset`) ; la partie `reset` est `[R]`, la partie `[T]` n'a pas de marqueur. | SPEC-004.2 | Traçabilité. | Idem E2. |
| E4 | `SPEC-005.11` et `SPEC-005.12` portent une part `[T]` (côté API), couverte par SPEC-001.11 et SPEC-002.3 sans marqueur `SPEC-005`. | SPEC-005.11, 005.12 | Traçabilité. | Décision de l'architecte : marqueur indirect ou nouvelle référence. |
| E5 | `persistance-dev.json` (écrit par la passe A à 12:31) n'est **pas ignoré par git** (`iterations/` est versionné). Il contient les e-mails de test `@test.invalid`, l'identifiant de tâche et une **empreinte tronquée** (SHA-256, 16 car.) de `ADMIN_PASSWORD`. Pas de valeur en clair. | SPEC-003.3, SPEC-004.3 | Hygiène : risque faible, à décider. | Le chef de projet tranche (ajouter une règle `.gitignore` pour `iterations/*/tests/persistance-*.json`, ou accepter le fichier suivi). Le testeur ne modifie pas `.gitignore`. |
| E6 | Deux marqueurs pytest (`SPEC-003.3`, `SPEC-003.6`) portent un tag `[P]`/`[R]` sans `[T]` dans la spec ; le test existe et passe. `SPEC-000.1` est référencé dans un format à puces (hors tableau). | SPEC-003.3, 003.6, 000.1 | Aucun (tests en surplus, bienvenus). | Pour l'architecte : aligner les tags si la vérification automatique est retenue. |
| E7 | **Budget d'inscriptions non mesuré.** SPEC-006 §1 fixe un plafond de 220 inscriptions par passe ; aucun compteur n'existe (voir E1). | SPEC-006 §1, SPEC-001.14 | Non vérifiable pour l'instant. | Traité avec E1. |

Ce qui n'est **pas** un écart : le tour 1 signalait des échecs (publication LAN, front absent, secrets absents). Ils sont corrigés dans la pile actuelle : `./dev test` ne rapporte plus aucun échec.

## 4. Skips (3 tests, 4 marqueurs)

| Test | Motif (texte du skip) | Attendu ? | Ce qu'il faut faire |
|---|---|---|---|
| `test_004_piles::test_persistance_relire` (marqueurs SPEC-003.5, SPEC-004.3) | « aucun jeu marqué… passe d'écriture non encore faite » (fichier absent au début de la passe) ; la passe A a ensuite écrit `persistance-dev.json` (`test_persistance_ecrire`, PASS). | Oui | **Passe B** : le responsable applicatif fait `./dev deploy` (sans `reset`), puis `./dev test`. Le test relira le jeu et vérifiera mot de passe admin, activation, temps et proposition. Le skip restera vrai tant qu'aucun `deploy` n'a eu lieu après 12:31. |
| `test_004_piles::test_pile_service_repond_avec_ses_propres_secrets` (SPEC-004.7) | « à exécuter avec DEVENV_PILE=service » | Oui (pile `dev` active) | `DEVENV_PILE=service ./dev test` après déploiement de la pile `service` par le RA. **SPEC-004.7 n'est donc pas vérifiée dans cette passe.** |
| `test_004_piles::test_restauration_service_restitue_le_jeu_marque` (SPEC-004.8, Could) | « à exécuter avec DEVENV_PILE=service » | Oui | Même passe que ci-dessus, après `backup → reset --confirmer-destruction → deploy → restore` par le RA, entre les passes A et B sur `service`. **SPEC-004.8 non vérifiée.** |

Aucun skip ne masque un échec : les trois sont conditionnés par un état externe (déploiement, pile `service`) et non par une absence de pile.

## 5. Conditions et limites de cette passe

- Pile `dev` démarrée et joignable : `APP_URL=http://app` depuis le runner (pas d'accès à `db`). Aucun `deploy`, `teardown`, `reset` ni `build` lancé par le testeur.
- Les tests créent leurs comptes `@test.invalid` (isolation, SPEC-006 §1) ; la passe n'a pas été mesurée pour le débit (E7).
- Sorties : `resultat.txt` et `junit.xml` ont été régénérés par `./dev test` (le contenu du tour 1 n'existe plus que dans `rapport.md`).
- La matrice ci-dessus est issue de l'analyse des marqueurs (AST) croisée avec `junit.xml`, pas d'une lecture ligne à ligne des assertions.

## 6. Suite proposée (pour le chef de projet)

1. Écrire les tests débit (E1) et les marqueurs manquants (E2 à E4) : tour suivant du testeur, après décision de l'architecte sur E4.
2. Trancher E5 (suivi git de `persistance-dev.json`).
3. Responsable applicatif : `./dev deploy` (passe B de persistance), puis `./dev test` ; déploiement de la pile `service`, puis `DEVENV_PILE=service ./dev test` (SPEC-004.7 et 004.8).
4. Recette client (`[C]`) et policies (`[P]`) : hors de ce rapport, à consigner dans `recette-client.md` et `iterations/002/policies/`.
