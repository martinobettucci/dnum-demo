# SPEC-006 — Plan de vérification de l'itération 002 (testeur / client / policy / responsable applicatif)

Couvre tous les CA-002-1 à CA-002-36. Chaque CA a au moins un mécanisme de vérification.

## 1. Conditions d'exécution des tests automatiques (`testeur`)
- Exécution : `./dev test` (conteneur `runner`, réseau de la pile dev). Base : `APP_URL=http://app`.
  Auth : `$APP_URL/auth/v1`, REST : `$APP_URL/rest/v1` (en-têtes `apikey: <ANON_KEY>` et
  `Authorization: Bearer <jeton>`). Accès interne autorisé **uniquement** pour l'API admin
  GoTrue (`http://auth:9999`) si un test en a besoin ; jamais d'accès direct à `db`.
- Secrets : lus dans `/workspace/.devenv/secrets/dev.env` (lecture seule), jamais affichés ni
  écrits dans les rapports (`iterations/002/tests/`).
- Isolation : chaque test crée ses propres comptes par `/auth/v1/signup` avec des e-mails uniques
  (`t-<uuid>@test.invalid`), les fait activer par l'admin via `admin_set_active`, et ne dépend
  pas de l'ordre ni de données préexistantes (hors compte admin). Aucun nettoyage requis (pile jetable).
- Dépendances : `pytest` et `requests` déjà épinglés ; tout ajout passe par
  `tools/runner/requirements.txt` à version exacte (demande à `action`).
- Marquage : `@pytest.mark.spec("SPEC-xxx.y")` sur chaque test ; un fichier par spec
  (`tests/test_001_pile.py`, `test_002_modele.py`, `test_003_admin.py`, `test_004_piles.py`).
- Pile non démarrée ⇒ les tests sont `skip` (comme `test_000_socle.py`), pas `fail`.

## 2. Matrice CA → vérification
[T] test automatique · [C] recette client · [P] policy · [R] responsable applicatif

| CA | Specs | [T] testeur | [C] client | [P] / [R] |
|---|---|---|---|---|
| CA-002-1 | 001.1/3/4/5/13, 004.1/2/4/10 | `GET $APP_URL/` 200 ; santé auth/rest | — | [P] compose ; [R] `curl` 127.0.0.1 et 10.77.0.25, `mise-en-service.md` |
| CA-002-2 | 001.2/10, 003.2/3/6, 004.5 | signature des clés ; `service_role` absente des fichiers servis | — | [P] images épinglées (FROM + `image:`), versions npm exactes, secrets absents des fichiers suivis |
| CA-002-3 | 001.6/7/8/9/10 | relais `/auth/v1`, `/rest/v1` ; 403 `/auth/v1/admin` ; CSP ; aucune URL d'autre port dans les fichiers servis | — (implicite : tout marche sur le seul port) | [P] seul `app` publie un port |
| CA-002-4 | 003.1/4/5/7/9 | connexion admin, `my_status`, unicité du compte, longueur du mot de passe | — | [R] transmission hors fichier |
| CA-002-5 | 003.8, 005.14/61 | — | connexion admin ⇒ tableau de bord + « Administration » ; membre ⇒ absente | — |
| CA-002-6 | 002.4, 001.11, 005.11 | signup ⇒ profil inactif | formulaire + message d'attente | — |
| CA-002-7 | 001.11, 005.11 | e-mail dupliqué ⇒ 4xx ; mot de passe 7 car. ⇒ 422 | messages d'erreur, pas de compte | — |
| CA-002-8 | 002.4/5, 005.60 | `admin_list_accounts` / `admin_set_active` | clic « Activer » ⇒ ligne déplacée | — |
| CA-002-9 | 002.5 | membre ⇒ `admin_set_active` refusé, `PATCH profiles` sans effet | `#/admin` inaccessible | — |
| CA-002-10 | 002.3, 005.12 | `my_status` inactif | écran d'attente seul | — |
| CA-002-11 | 002.1/2/3, 001.12 | anon et inactif : 0 ligne / refus sur les 4 tables + vues + RPC, aucune écriture | — | [P] RLS forcée, aucun privilège `anon` |
| CA-002-12 | 002.6, 005.13 | nouveau jeton après activation voit les données | reconnexion ⇒ tableau de bord | — |
| CA-002-13 | 002.7, 005.30 | création valide | création + affichage « À faire » | — |
| CA-002-14 | 002.7, 005.30 | titre vide / estimation ≤ 0 ⇒ 400 | messages d'erreur | — |
| CA-002-15 | 002.8, 005.31/5 | PATCH par affecté/créateur | modification + F5 | — |
| CA-002-16 | 002.8 | PATCH par un tiers sans effet ; `assignee_id` non modifiable | — | — |
| CA-002-17 | 002.9, 005.40 | lecture `task_summary` d'un collègue | clic sur le nom ⇒ liste en lecture seule | — |
| CA-002-18 | 002.10, 005.32 | `logged_hours` += minutes/60 | saisie heures/minutes, total mis à jour | — |
| CA-002-19 | 002.10, 005.32 | 0, négatif, > 1440 min ⇒ 400 | messages d'erreur | — |
| CA-002-20 | 002.10 | saisie sur tâche non affectée ⇒ refus | — | — |
| CA-002-21 | 002.13, 005.20 | `team_load` = membres actifs | arrivée sur tableau de bord, cartes | — |
| CA-002-22 | 002.11/12, 005.20 | jeu de référence ⇒ 3.00 ; arrondis | jeu saisi à la main ⇒ « 3 h » | — |
| CA-002-23 | 002.12, 005.20/3 | 7,00 ⇒ false ; 7,25 ⇒ true | « Surchargé » apparaît / disparaît | — |
| CA-002-24 | 002.13, 005.20 | inactif absent de `team_load` | inscrit non activé absent | — |
| CA-002-25 | 002.14, 005.33 | `reassign_task` + charges | réaffectation + charges | — |
| CA-002-26 | 002.14 | vers inactif / par non-affecté ⇒ refus | — | — |
| CA-002-27 | 002.15, 005.40/50 | `offer_help` + visibilité | « Proposer mon aide » ⇒ reçue chez le collègue | — |
| CA-002-28 | 002.16, 005.33/50 | `request_help` | « Demander de l'aide » ⇒ reçue | — |
| CA-002-29 | 002.17, 005.51 | accept ⇒ affectation au preneur | « Accepter » ⇒ statut + charges | — |
| CA-002-30 | 002.17, 005.51 | refus ⇒ affectation inchangée | « Refuser » ⇒ « Refusée » | — |
| CA-002-31 | 002.18 | non-destinataire, déjà traitée, tâche réaffectée/terminée ⇒ refus | message « n'est plus valable » | — |
| CA-002-32 | 002.19, 005.14/20 | compte `pending` | compteur affiché | — |
| CA-002-33 | 004.3, 003.5 | écrire → redéploiement (R) → relire ; mot de passe admin inchangé | — | [R] `./dev deploy` sans reset entre les deux passes |
| CA-002-34 (Could) | 002.20, 005.60 | désactivation, auto-désactivation refusée | « Désactiver » ⇒ écran d'attente | — |
| CA-002-35 (Could) | 002.21, 005.21 | filtre `due_date` | filtre « Aujourd'hui » | — |
| CA-002-36 (Could) | 004.7/8/9 | backup → reset → restore → relecture (`DEVENV_PILE=service`) | — | [R] isolation des piles |

## 3. Policies attendues (à écrire par l'agent `policy`, avant l'action)
1. Images épinglées : `FROM` **et** `image:` de `stack/*.yml` (tag exact, pas `latest`).
2. Dépendances npm exactes : `app/web/package.json` sans `^`, `~`, `*`, `latest` ; `package-lock.json` présent ; `@supabase/supabase-js` = `2.47.10`.
3. Aucun secret suivi : motif JWT `eyJ…\.eyJ…`, valeurs de `.devenv/secrets/*.env` absentes des fichiers hors `.git`, `.devenv`, `iterations` ; `.devenv/` dans `.gitignore`.
4. Compose : seul `app` publie des ports, jamais sur `0.0.0.0` ; pas de service Studio/Kong.
5. (QUAND: deployed) RLS forcée sur toutes les tables de `public` et aucun privilège `anon` — via l'API (SPEC-002.2) puisque le runner n'accède pas à `db`.
6. Garde-fou : `./dev backup|restore` refusés hors `responsable-applicatif` (SPEC-004.6).

## 4. Ordre de recette client conseillé
Connexion admin (CA-5) → inscription A et B + erreurs (CA-6, 7) → connexion A non activé (CA-10)
→ admin active A et B (CA-8) → A reconnecté (CA-12) → tâches et erreurs (CA-13 à 15) → temps (CA-18,
19) → jeu de référence (CA-22) → surcharge (CA-23) → B consulte A (CA-17) → réaffectation (CA-25)
→ propositions (CA-27 à 30, 32) → Could (CA-34, 35).
