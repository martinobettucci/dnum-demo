# SPEC-006 — Plan de vérification de l'itération 002 (testeur / client / policy / responsable applicatif)

Couvre tous les CA-002-1 à CA-002-36. Chaque CA a au moins un mécanisme de vérification.

> **Amendements tour 1 complément (2026-11-17)** : §1 (le runner ne joint que `http://app`), §2 (ligne CA-002-1),
> §3 (policies 4 et 11), §5 (marqueurs et retrait pour le testeur). Cadre : ADR-007, ADR-008.
>
> **Amendements tour 2 (2026-11-17)** : §2 (CA-002-1, CA-002-2, CA-002-36) ; §3 policy 9 (`env_file` longue,
> `required: false`) ; §3 policies 12 à 14 nouvelles (ADR-009, ADR-010, SPEC-004.17). Les policies sont à écrire
> par l'agent `policy` avant l'action (boucle AOPR).

## 1. Conditions d'exécution des tests automatiques (`testeur`)
- Exécution : `./dev test` (conteneur `runner`, réseau de la pile dev). Base : `APP_URL=http://app`.
  Auth : `$APP_URL/auth/v1`, REST : `$APP_URL/rest/v1` (en-têtes `apikey: <ANON_KEY>` et
  `Authorization: Bearer <jeton>`). Accès interne autorisé **uniquement** pour l'API admin
  GoTrue (`http://auth:9999`) si un test en a besoin ; jamais d'accès direct à `db`.
- **Adresse LAN** : le runner ne joint pas `10.77.0.25` ni aucune autre adresse de l'hôte. La joignabilité LAN est une
  vérification `[R]` de l'hôte (SPEC-001.4, ADR-007 §4).
- Secrets : lus dans `/workspace/.devenv/secrets/dev.env` (lecture seule), jamais affichés ni
  écrits dans les rapports (`iterations/002/tests/`).
- Isolation : chaque test crée ses propres comptes par `/auth/v1/signup` avec des e-mails uniques
  (`t-<uuid>@test.invalid`), les fait activer par l'admin via `admin_set_active`, et ne dépend
  pas de l'ordre ni de données préexistantes (hors compte admin). Aucun nettoyage requis (pile jetable).
  Tout compte de test utilise le domaine `@test.invalid` (SPEC-003.9).
- Dépendances : `pytest` et `requests` déjà épinglés ; tout ajout passe par
  `tools/runner/requirements.txt` à version exacte (demande à `action`).
- Marquage : `@pytest.mark.spec("SPEC-xxx.y")` sur chaque test ; un fichier par spec
  (`tests/test_001_pile.py`, `test_002_modele.py`, `test_003_admin.py`, `test_004_piles.py`).
- Pile non démarrée ⇒ les tests sont `skip` (comme `test_000_socle.py`), pas `fail`.
- Budget de débit (SPEC-001.14) : la pile dev garantit au moins 500 inscriptions par heure. Une passe de `./dev test` en fait environ 184, et le scénario de persistance demande deux passes dans l'heure, ce qui laisse une marge pour la recette client. Le testeur ne dépasse pas **220 inscriptions par passe** ; au-delà, il saisit l'architecte. Toute réponse 429 fait échouer `test_aucune_reponse_429`, pour qu'une limite de débit ne se confonde jamais avec un défaut fonctionnel.

## 2. Matrice CA → vérification
[T] test automatique · [C] recette client · [P] policy · [R] responsable applicatif

| CA | Specs | [T] testeur | [C] client | [P] / [R] |
|---|---|---|---|---|
| CA-002-1 | 001.1/3/4/5/13, 004.1/2/4/7/10/11/17 | `GET $APP_URL/` 200 ; santé auth/rest | — | [P] publication LAN seule (001.3) ; [R] `curl -sI http://10.77.0.25:8080/` (dev) et `:8081` (service), `mise-en-service.md`. **Dérogation** : `127.0.0.1` n'est plus vérifié (ADR-007). |
| CA-002-2 | 001.2/10/15, 003.2/3/6, 004.5, 004.16 | signature des clés ; `service_role` absente des fichiers servis | — | [P] images épinglées (FROM + `image:`), tags par pile (004.16), versions npm exactes, secrets absents des fichiers suivis |
| CA-002-3 | 001.6/7/8/9/10 | relais `/auth/v1`, `/rest/v1` ; 403 `/auth/v1/admin` ; CSP ; aucune URL d'autre port dans les fichiers servis | — (implicite : tout marche sur le seul port) | [P] seul `app` publie un port |
| CA-002-4 | 003.1/4/5/7/9 | connexion admin, `my_status`, unicité du compte, longueur du mot de passe, seul `ADMIN_EMAIL` hors `@test.invalid` | — | [R] transmission hors fichier |
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
| CA-002-36 | 004.7/8/9/16 | backup → reset → restore → relecture (`DEVENV_PILE=service`) | — | [P] `STACK-restart-service` (ADR-009) ; [R] isolation des piles (`docker compose ls`, `docker volume ls`, tags distincts) ; [R] `docker inspect` : `unless-stopped` sur db, auth, rest, app |

## 3. Policies attendues (à écrire par l'agent `policy`, avant l'action)
1. Images épinglées : `FROM` **et** `image:` de `stack/*.yml` (tag exact, pas `latest`).
2. Dépendances npm exactes : `app/web/package.json` sans `^`, `~`, `*`, `latest` ; `package-lock.json` présent ; `@supabase/supabase-js` = `2.47.10`.
3. Aucun secret suivi : motif JWT `eyJ…\.eyJ…`, valeurs de `.devenv/secrets/*.env` absentes des fichiers hors `.git`, `.devenv`, `iterations` ; `.devenv/` dans `.gitignore`.
4. Compose (`STACK-ports-lan`, SPEC-001.3) : seul `app` publie des ports, exactement `${APP_LAN_IP:-10.77.0.25}:${APP_PORT}:80` ; jamais `0.0.0.0`, jamais `127.0.0.1` ; `stack/compose.service.yml` ne déclare pas `ports` ; pas de service Studio/Kong.
5. (QUAND: deployed) RLS forcée sur toutes les tables de `public` et aucun privilège `anon` — via l'API (SPEC-002.2) puisque le runner n'accède pas à `db`.
6. Garde-fou : `./dev backup|restore` refusés hors `responsable-applicatif` (SPEC-004.6).
7. `FRONT-meme-origine` (n° 15), à préciser selon SPEC-001.8. Règle stricte (`localhost`, `:9999`, `:3000`, `:5432`, `http://auth`, `http://rest`) sur `/`, `/app.js`, `/config.js` et `/style.css`. Règle bibliothèque sur `/vendor/supabase.js` : 200, présence de `2.47.10`, absence de `:3000`, `:5432`, `http://auth`, `http://rest`, de JWT et de valeurs secrètes ; `localhost` et `:9999` tolérés. Le test `test_001_pile.py` (SPEC-001.8) suit la même partition.
8. `STACK-auth-debit` (statique, SPEC-001.14) : `GOTRUE_RATE_LIMIT_HEADER` absent ; `GOTRUE_RATE_LIMIT_EMAIL_SENT`, `_TOKEN_REFRESH`, `_VERIFY` et `_OTP` ≥ 1000 dans le service `auth` ; aucun `limit_req` ni `limit_conn` sous `app/nginx/`.
9. `STACK-points-accroche` (statique, SPEC-004.11, 004.13 et 004.14) : services `migrate` et `seed` (profil, image, montages, `env_file` en forme longue `- path: ${DEVENV_SECRETS}` avec `required: false`), healthchecks de `db`, `auth` et `app`, volume `db-data`. Vérification par `docker compose config` ou par analyse YAML de `stack/compose.yml`.
10. `DB-migrations-versionnees` (n° 22) étendue selon SPEC-004.12 : nommage `NNN_[a-z0-9_]+.sql`, versions uniques, aucune instruction de transaction de premier niveau, aucun `CONCURRENTLY`.
11. `STACK-tags-par-pile` (statique, SPEC-004.16, ADR-008) : chaque `image:` construit de `stack/compose.yml` porte le tag `:dev` ; celui de `stack/compose.service.yml` porte `:service` ; aucune paire `nom:tag` commune aux deux fichiers.
12. `STACK-restart-service` (statique, SPEC-004.7, ADR-009) : `docker compose -f stack/compose.yml -f stack/compose.service.yml config` ; `restart` = `unless-stopped` pour `db`, `auth`, `rest`, `app` ; aucune politique pour `migrate`, `seed`, `runner`, `client` ; aucune politique `restart` dans la configuration de la pile `dev` (`stack/compose.yml` seul).
13. `FRONT-audit-npm` (SPEC-001.15, ADR-010) : `npm audit --json` sur `app/web/package-lock.json` dans l'image `node:22.12.0-alpine` (conteneur jetable, pas d'outil sur l'hôte) ; échec si un identifiant d'avis n'est pas listé dans ADR-010, si un avis est de sévérité haute ou critique, ou si la commande n'a pu se connecter au registre (statut « non exécutée », jamais « réussie »).
14. `DEV-sortie-url` (statique, SPEC-004.17) : `grep -nE '127\.0\.0\.1|localhost|0\.0\.0\.0' dev` ne retourne rien ; `dev` exporte `APP_LAN_IP` sur la même ligne que `APP_PORT`.

## 4. Ordre de recette client conseillé
Connexion admin (CA-5) → inscription A et B + erreurs (CA-6, 7) → connexion A non activé (CA-10)
→ admin active A et B (CA-8) → A reconnecté (CA-12) → tâches et erreurs (CA-13 à 15) → temps (CA-18,
19) → jeu de référence (CA-22) → surcharge (CA-23) → B consulte A (CA-17) → réaffectation (CA-25)
→ propositions (CA-27 à 30, 32) → Could (CA-34, 35).

## 5. Marqueurs et retraits pour le testeur (tour 1 complément)
- **Ajouter** `@pytest.mark.spec("SPEC-003.9")` au test de `tests/test_003_admin.py` qui vérifie que, hors comptes
  `@test.invalid`, `admin_list_accounts()` ne retourne que `ADMIN_EMAIL` (SPEC-003.9 devient `[T]`).
- **Retirer** `test_accueil_repond_200_sur_adresse_lan_du_serveur` du runner. Le contrôle LAN passe en `[R]`
  (SPEC-001.4, ADR-007 §4). Ne pas le remplacer par une tentative depuis le runner.
- **SPEC-001.3** : aucun marqueur pytest. Vérification `[P]` (`STACK-ports-lan`) et `[R]` (`ss -ltn`).
- **SPEC-004.16** : aucun marqueur pytest. Vérification `[P]` (`STACK-tags-par-pile`) et `[R]`.
- Les autres marqueurs existants ne changent pas.
