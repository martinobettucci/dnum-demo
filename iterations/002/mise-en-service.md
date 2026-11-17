Mise en service assurée exclusivement par le responsable applicatif. Aucun autre agent ne démarre, n'arrête ni ne détruit la pile : adressez vos demandes au chef de projet.

# Itération 002 — tour 2 : mise en service DEV (SUCCÈS)

- Statut : **succès**. `./dev deploy` (pile `dev` uniquement, sans `reset`) rend la main avec le code 0.
- Date : 2026-11-17, déploiement vers 12:29 — 12:30 UTC.
- Pile : `dev` uniquement. Pile `service` **non déployée** (conformément à la consigne).
- Version déployée : commit `dfbc020` (itération 002 tour 1) + arbre de travail non commité. Correctif appliqué : `tools/deploy/secrets.py` renommé en `tools/deploy/gen_secrets.py` (non commité, `D` + `??` dans git) ; `dev` ligne 98 appelle `gen_secrets.py`.
- Durée : **21 s** (build en cache, démarrage, migrations, seed, santé).
- URL : **http://10.77.0.25:8080/** — répond (HTTP 200).

## 1. Services (`./dev status`)

| Service | Image | État |
|---|---|---|
| app (nginx) | devenv/app:dev | Up, **healthy**, publié sur 10.77.0.25:8080 |
| db | supabase/postgres:15.8.1.060 | Up, **healthy** |
| auth (GoTrue) | supabase/gotrue:v2.170.0 | Up, **healthy** |
| rest (PostgREST) | postgrest/postgrest:v12.2.8 | Up (pas de healthcheck déclaré ; joignable via nginx) |
| client | devenv/client:dev | Up (driver de recette) |
| migrate, seed | — | exécutés (conteneurs ponctuels) |

## 2. Validation exécutée

| Point | Résultat |
|---|---|
| Migrations SQL | **OK** : 5 fichiers appliqués (`001_socle` à `005_rpc`), niveau 005. Ordre : migrations, puis seed, puis re-passage de migration (idempotent). |
| GoTrue | **OK** : `/health` répond v2.170.0 ; `/auth/v1/health` via nginx = 200. |
| PostgREST | **OK** : `/rest/v1/` via nginx = 200. |
| nginx | **OK** : 10.77.0.25:8080 = 200. |
| Seed admin | **OK** : compte admin créé dans `auth.users` ; profil `role=admin` actif. (1 compte, rôle admin confirmé.) |
| Secrets `.devenv/secrets/dev.env` | **OK** : fichier `600` (spark-docker), répertoire `.devenv/secrets` `700`. Clés présentes : POSTGRES_PASSWORD, JWT_SECRET, ANON_KEY, SERVICE_ROLE_KEY, ADMIN_EMAIL, ADMIN_PASSWORD. Ignoré par git (`.gitignore` : `.devenv/`). |
| RLS (psql dans `db`) | **OK** : RLS activée et forcée sur `tasks`, `profiles`, `time_entries`, `help_proposals`. 7 politiques (SELECT/INSERT/UPDATE pour `authenticated` uniquement). Rôle `anon` : `permission denied` sur les 4 tables. Rôle `authenticated` sans JWT : 0 ligne visible sur les 4 tables. |

Localhost : `http://127.0.0.1:8080/` ne répond pas (code 000) car la publication est liée à **10.77.0.25 uniquement**. C'est le comportement voulu pour la pile DEV sur le LAN, mais le message final de `./dev deploy` indique `http://127.0.0.1:8080/` : il faut le corriger (voir section 4).

## 3. Incidents et observations

Aucun échec bloquant pendant ce tour. Journal complet du déploiement : `/tmp/deploy-dev-002-t2.log` (secrets masqués).

Rappel de l'échec du tour 1 : `secrets.py` masquait le module standard `secrets` (AttributeError `choice`). Corrigé par le renommage en `gen_secrets.py`.

Observations non bloquantes, extraites de `./dev logs` :

1. **Message de sortie trompeur** : `Mise en service (dev) OK ... — http://127.0.0.1:8080/` alors que la pile écoute sur 10.77.0.25:8080. À corriger par l'`action` ou le `developpeur` (fichier `dev`).
2. **FATAL TimescaleDB** (`db-1`, 12:29:27) : `terminating background worker "TimescaleDB Background Worker Launcher" due to administrator command`. Arrêt normal de worker lors du redémarrage de la base, sans conséquence observée.
3. **Avertissements GoTrue** (`auth-1`) : `GOTRUE_JWT_ADMIN_GROUP_NAME` et `GOTRUE_JWT_DEFAULT_GROUP_NAME` non supportés, dépréciés. Non bloquant ; à retirer de la configuration de la pile.
4. **Lignes `ERROR permission denied` dans `db-1`** (12:30:00 — 12:30:05) : produites par mon propre test RLS en rôle `anon` et `authenticated`. Comportement attendu, pas une panne.
5. **Ordre des conteneurs** : `seed-run` s'exécute entre deux passages de `migrate-run`. Les migrations ont été appliquées avant le seed, donc l'ordre est correct ; le second passage de migration est idempotent. À documenter si ce n'est pas voulu.

## 4. Points ouverts

- Décision ADR sur la publication 10.77.0.25 (tour 1, section 1) : toujours à trancher par le chef de projet.
- Corriger le message `127.0.0.1` dans `./dev deploy` (observation 1).
- Retirer les variables GoTrue dépréciées (observation 3).

## 5. Accès administrateur

Le mot de passe admin n'est pas reproduit ici. Il se trouve **uniquement** dans `.devenv/secrets/dev.env` (variable `ADMIN_PASSWORD`, fichier `600`, hors git). L'identifiant `ADMIN_EMAIL` figure dans le même fichier.

---

## Plan de bascule dev vers service

Mise en service assurée exclusivement par le responsable applicatif. Aucun autre agent ne démarre, n'arrête ni ne détruit la pile : adressez vos demandes au chef de projet.

- Date de rédaction : 2026-11-17, tour 3 (préparation).
- Statut : **PRÉPARÉ, NON EXÉCUTÉ.** Aucun `deploy`, `teardown`, `reset`, `backup`, `restore`, `test` ni recette n'a été lancé. Aucune commande ne modifie la pile dev, ses volumes, sa base ou ses secrets.
- Version de référence : commit `dae9044`, plus des modifications non commitées (`iterations/002/perimetre.md`, `iterations/002/recette-client.md`, `iterations/002/tests/junit.xml`). Une version commitée est exigée avant la mise en service de `service` (prérequis P5).
- Aucun secret ni adresse e-mail n'est reproduit ici. Les valeurs de `.devenv/secrets/*.env` ne doivent jamais apparaître dans un rapport.

### 0. État constaté (lecture seule, 2026-11-17)

| Élément | Constat |
|---|---|
| Projet compose `devenv` (pile dev) | `running(5)` : `client`, `app` (healthy, publié sur `10.77.0.25:8080`), `rest`, `auth` (healthy), `db` (healthy) |
| Volume | `devenv_db-data` (seul volume présent) |
| Écoute | `10.77.0.25:8080` seul (`ss -ltn`) |
| Pile service | **absente** : aucun projet `dnum-service`, aucun conteneur, aucun volume |
| Secrets | `.devenv/secrets/dev.env` présent (600). **`service.env` absent.** |
| Sauvegardes | aucune (`.devenv/backups/` inexistant) |
| Policies | `policies/checks/` contient **00 à 24**. **Les policies 25 à 28 n'existent pas encore.** Dernier `results.json` (12:30) : 2 violations (00, 21) |
| Code | `dev` ligne 115 imprime encore `http://127.0.0.1:…` (SPEC-004.17 d non respectée) |

### 1. Prérequis bloquants (aucun `./dev deploy service` avant levée)

| Id | Prérequis | Responsable | Preuve attendue |
|---|---|---|---|
| P1 | Policies **25 à 28** écrites par `policy` (Team AOPR) avant l'action, puis exécutées. Elles n'existent pas aujourd'hui. | policy | fichiers `policies/checks/25-*.sh` à `28-*.sh` présents ; `./dev policies` les exécute |
| P2 | Policy **00** : faux positif. `devenv/app:service` (tag local, ADR-008 / SPEC-004.16) est signalé comme image non épinglée. La règle doit exempter les images construites portant le tag de leur pile. | policy / action | `./dev policies` : 00 respectée |
| P3 | Policy **21** : vérifie encore `127.0.0.1` ; ADR-007 impose sa réécriture (publication unique `${APP_LAN_IP}:${APP_PORT}`). | policy | 21 respectée sur `compose.yml` |
| P4 | `dev` ligne 115 : `http://127.0.0.1:${APP_PORT}/` à remplacer par `http://${APP_LAN_IP}:${APP_PORT}/` (SPEC-004.17 c et d ; CA-002-1 [P]). | action / developpeur | `grep -nE '127\.0\.0\.1\|localhost\|0\.0\.0\.0' dev` vide |
| P5 | Version commitée : `perimetre.md`, `recette-client.md`, `junit.xml` et le correctif P4 commités. La version déployée doit être traçable. | chef de projet (décision de commit) | `git status` propre pour le code ; commit noté dans `.devenv/deploy.log` |
| P6 | Adresse LAN stable : `10.77.0.25` est un bail DHCP (ADR-007, risque R3). Réservation DHCP de l'hôte **avant** la bascule. | utilisateur (réseau) | adresse inchangée après réservation |
| P7 | Décisions D1 à D8 (§ 2) tranchées. | utilisateur | consignées dans `iterations/002/besoin.md` ou `journal/` |

### 2. Décisions à prendre par l'utilisateur

| Id | Décision | Option recommandée | Conséquence |
|---|---|---|---|
| D1 | Fenêtre de coupure : date, heure, durée tolérée | 45 min hors heures d'usage (durée à mesurer en répétition) | Pendant la fenêtre, plus aucune écriture ne doit atteindre dev |
| D2 | Méthode de gel des écritures sur dev | **Page de maintenance au proxy** pendant la fenêtre, **et** blocage de l'accès direct `10.77.0.25:8080` depuis le LAN (règle pare-feu) | Sans le blocage direct, un utilisateur qui va sur `:8080` écrit dans dev après la sauvegarde finale : **perte de données** |
| D3 | Clés de session et mot de passe admin du service | **Reprise** de `JWT_SECRET`, `ANON_KEY`, `SERVICE_ROLE_KEY`, `ADMIN_EMAIL`, `ADMIN_PASSWORD` depuis `dev.env` vers `service.env` (`POSTGRES_PASSWORD` peut être neuf) | Sessions existantes conservées, mot de passe admin inchangé. Alternative (régénération) : tous les membres doivent se reconnecter et l'admin reçoit un nouveau mot de passe à transmettre |
| D4 | Durée de conservation de dev après bascule (retour arrière) | 7 jours, puis `reset dev` sur décision du chef de projet | dev reste gelé et intact jusqu'à cette date |
| D5 | Sauvegardes hors de l'hôte | Oui : copie chiffrée de la sauvegarde finale de dev et de service, hors de `10.77.0.25` | Aujourd'hui les sauvegardes ne vivent que sur l'hôte (ADR-004) : une défaillance du disque emporte les données réelles |
| D6 | Accès direct à dev après bascule | Blocage LAN de `:8080` maintenu, ou service `app` de dev arrêté (action à autoriser le jour J) | Empêche toute écriture orpheline sur dev |
| D7 | Message aux utilisateurs pendant la fenêtre | Page d'information « migration en cours » au proxy | Information des utilisateurs |
| D8 | Validation de la bascule : qui valide, sur quels comptes réels | Utilisateur, par connexion d'un membre et de l'admin depuis un poste LAN | Les agents n'utilisent pas de comptes réels (recette automatisée exclue) |

### 3. Méthode de migration des comptes

**Principe.** Le mécanisme existant est repris tel quel : `./dev backup dev` puis `./dev restore service <dump>` (SPEC-004.8, ADR-004). Le dump est en données seules, schémas `auth` et `public`, hors `auth.schema_migrations`.

**Ce qui migre :** `auth.users` (et identités), `public.profiles`, `public.tasks`, `public.time_entries`, `public.help_proposals`, avec les rôles et états d'activation.

**Ce qui ne migre pas :** le schéma (il vient du dépôt, migrations 001 à 005), `private.schema_migrations` (journal propre à chaque pile), les images, les volumes.

**Mots de passe et condensats.** Les mots de passe des membres sont stockés sous forme de condensats bcrypt dans `auth.users`. Ils sont copiés tels quels, jamais en clair. Cela suppose que GoTrue est identique des deux côtés : les deux piles utilisent `supabase/gotrue:v2.170.0` (vérifié dans `stack/compose.yml`). Le dump ne contient donc aucun mot de passe en clair, mais il contient des condensats : c'est une donnée sensible à protéger comme telle.

**Restauration de l'admin.** `./dev restore` rejoue le seed, qui met à jour le mot de passe du compte `ADMIN_EMAIL` avec `ADMIN_PASSWORD` du fichier de la pile cible. Conséquences :
- Si D3 = reprise, le mot de passe admin est inchangé.
- Si D3 = régénération, l'ancien mot de passe admin cesse de fonctionner sur service.
- **Le seed réécrit le condensat de l'admin à chaque `./dev deploy`** (nouveau sel bcrypt, même mot de passe). Un condensat de `auth.users` change donc pour ce seul compte après chaque déploiement : les contrôles de persistance excluent cette ligne et vérifient la connexion à la place.

**Sessions.** Les tables `auth.sessions` et `auth.refresh_tokens` sont restaurées, mais les jetons ne restent valables que si `JWT_SECRET` est identique (D3). Sans reprise, les membres doivent se reconnecter : aucune perte de donnée.

### 4. Ordre des opérations

Chaque étape indique son point d'arrêt. « Attendu » = résultat attendu. Ce document ne lance **aucune** de ces commandes.

**S0. Pré-vol (aucune modification).**
- Vérifier P1 à P7. Arrêt si l'une manque.
- Capturer l'état avant toute opération sur service : `docker compose ls`, `docker volume ls`, `ss -ltn` (sortie brute, à consigner).
- Arrêt si `./dev policies` contient une violation.

**S1. Sauvegarde préalable de dev (non destructive, répétition).**
- Commande : `./dev backup dev`.
- Attendu : `.devenv/backups/dev/<AAAAMMJJ-HHMMSS>.dump` et son `.json` (`"migration": "005"`, pile `dev`, commit).
- Copie hors hôte selon D5. Arrêt si le `.json` est absent ou si le niveau n'est pas `005`.

**S2. Secrets de service.**
- Si D3 = reprise : créer `.devenv/secrets/service.env` (mode 600, répertoire 700) à partir des clés de `dev.env`, par copie de fichier, **sans afficher les valeurs**. `POSTGRES_PASSWORD` peut être généré.
- Si D3 = régénération : laisser `gen_secrets.py` générer le fichier au premier déploiement.
- Vérifications : `ADMIN_EMAIL` identique dans les deux fichiers (comparaison de condensats, sans affichage) ; `JWT_SECRET` d'au moins 40 caractères ; mode 600.

**S3. Déploiement à blanc de service (pile vierge, aucune donnée réelle).**
- Commande : `./dev deploy service` (après P1 à P5).
- Attendu : rc 0 ; migrations 001 à 005 appliquées ; seed admin créé puis promu ; `app` healthy ; ligne finale `Mise en service (service) OK … — http://10.77.0.25:8081/` (P4).
- Durée : à mesurer. Le premier build de `devenv/app:service` est plus long que le build en cache de dev (21 s au tour 2).
- Arrêt si rc ≠ 0. L'état reste sans donnée réelle : `./dev teardown service` est possible.

**S4. Contrôles CA-002-1 et CA-002-36 avant bascule.**
- `curl -sI http://10.77.0.25:8081/` → 200 (CA-002-36 b, CA-002-1 a sur le port service).
- `ss -ltn` : `10.77.0.25:8080` et `10.77.0.25:8081`, sans `127.0.0.1` ni `0.0.0.0` (CA-002-1 b). C'est le premier couple de ports sur une même adresse (ADR-007 §5) : à consigner.
- `docker compose ls` et `docker volume ls` comparés à S0 : projet `devenv` et `devenv_db-data` inchangés (CA-002-36 a).
- Arrêt si le couple de ports échoue (`address already in use`) : repli ADR-007 (a), à soumettre à l'utilisateur.

**S5. Ouverture de la fenêtre de coupure (D1, D2, D7).**
- Activer la page de maintenance au proxy pour `dnum.lelabs.tech` et bloquer `10.77.0.25:8080` pour le LAN.
- Vérifier qu'une écriture ne peut plus atteindre dev (vérification par l'utilisateur, sans compte réel écrit par un agent).

**S6. Sauvegarde finale de dev (après gel effectif).**
- Commande : `./dev backup dev`.
- Attendu : nouveau dump horodaté après l'ouverture de la fenêtre ; `.json` avec `"migration": "005"`.
- Arrêt si l'horodatage est antérieur à S5 : la sauvegarde ne vaut qu'après gel.

**S7. Contrôle de vide avant restauration (garde contre l'écrasement).**
- Sur service, seule la ligne de l'admin seed existe : `count(auth.users) = 1`, `count(public.profiles) = 1`, `tasks`, `time_entries`, `help_proposals` à 0.
- Arrêt si une donnée est présente : quelqu'un a écrit sur service, la restauration écraserait ces données.

**S8. Restauration des comptes et des données.**
- Commande : `./dev restore service .devenv/backups/dev/<AAAAMMJJ-HHMMSS>.dump`.
- Enchaînement réel : contrôle du niveau de migration, arrêt de `auth` et `rest`, vidage (`truncate`) des tables `public` et `auth` hors journal, restauration en **une transaction**, relance de `auth` et `rest`, puis `seed`.
- Attendu : rc 0 et « restauration (service) OK ».
- En cas d'échec : la transaction est annulée, service revient à l'état de S3 (admin seul). Dev n'est pas touché.

**S9. Équivalence dev / service (condensats, sans valeur affichée).**
- Comptes : `count(auth.users)`, `count(profiles)` par `role` et `is_active`, `count(tasks)`, `count(time_entries)`, `count(help_proposals)`.
- Condensats `md5` triés : `(id, email)` de `auth.users` ; `(id, encrypted_password)` de `auth.users` **hors compte admin** ; contenu de `tasks`, `time_entries`, `help_proposals`.
- Attendu : égalité stricte entre dev (gelé) et service.
- Contrôle lecture seule sur les deux bases.
- Arrêt en cas d'écart : ne pas basculer ; R1 ou R2 selon l'état.

**S10. Connexion de l'admin sur service.**
- Connexion à `http://10.77.0.25:8081` avec `ADMIN_EMAIL` et `ADMIN_PASSWORD` (valeurs lues dans le fichier, non affichées).
- Attendu : jeton délivré, profil `role=admin` et `is_active=true`.
- Cette connexion ne crée une session que sur service.

**S11. Contrôle d'accès anonyme.**
- Requête `GET` anonyme sur `tasks`, `profiles`, `time_entries`, `help_proposals` avec la clé anonyme : refus ou zéro ligne (politiques RLS, CA-002-11).

**S12. CA-002-33 : persistance à un second déploiement, sans reset.**
- Relever les condensats de S9, puis `./dev deploy service` une seconde fois.
- Attendu : rc 0 ; horodatages des deux `deploy` consignés ; condensats des membres et des données **identiques** ; condensat de `service.env` identique (`gen_secrets.py` ne réécrit rien) ; connexion admin de S10 toujours valide.
- Le condensat du compte admin change (§ 3) : c'est attendu.

**S13. CA-002-36 (c) : protection de la pile service.**
- Commande : `./dev reset service` **sans** `--confirmer-destruction`.
- Attendu : refus, rc 1, message « Rien n'a été détruit » ; `docker volume ls` et `docker compose ls` identiques à S0.

**S14. Bascule du proxy (utilisateur).**
- Le proxy de `dnum.lelabs.tech` pointe vers `10.77.0.25:8081` (ADR-001, ADR-007). Changement fait par l'utilisateur, hors des agents.
- Vérification : `curl -sI http://10.77.0.25:8081/` → 200 ; l'URL publique répond ; le certificat HTTPS est valide (proxy de l'utilisateur).
- Levée de la page de maintenance après cette vérification.

**S15. Validation par l'utilisateur (D8).**
- Connexion d'un membre et de l'admin depuis le LAN. Membre activé : tableau de bord. Membre non activé : écran d'attente.
- Si D3 = régénération : information des membres sur la reconnexion.
- La recette automatisée est **exclue** ici (règle du chef de projet : pas de compte réel écrit par les agents, pas de `./dev test`).

**S16. Après validation.**
- Dev reste gelé (non servi, non accessible en LAN), intact, jusqu'à la date D4.
- Au-delà de D4 et sur décision du chef de projet : `./dev reset dev` (jetable). Jamais avant la fin de la période de retour.

### 5. Points de contrôle [R]

| Critère | Où dans le plan | Sortie brute à consigner | Résultat |
|---|---|---|---|
| **CA-002-1** [R] (a) `curl` sur le port service → 200 ; (b) `ss -ltn` : adresse seule, sans `127.0.0.1` ni `0.0.0.0` | S4 (et S14 après bascule) | sorties `curl -sI` et `ss -ltn` | à faire |
| CA-002-1, partie « après reset puis deploy » | **Non jouée** : `reset` de dev interdit. Remplacée par le déploiement à blanc S3 de service. Écart à faire valider par le product-owner. | — | écart déclaré |
| **CA-002-33** [R] : `deploy` sans `reset` entre écriture et relecture | S12 : deux `deploy` horodatés, condensats identiques avant/après, connexion admin valide | horodatages des deux `deploy`, condensats S9 et S12 | à faire |
| **CA-002-36** [R] (a) `docker compose ls` et `docker volume ls` identiques avant/après `deploy service` pour `devenv` ; (b) `curl` 8081 → 200 ; (c) `reset service` sans flag refusé | S0, S4, S13 | sorties brutes avant/après | à faire |

Le [T] de CA-002-33 et CA-002-36 (scénario sauvegarde, reset, restauration) n'est pas joué ici : il exige `reset` et `./dev test`, interdits.

### 6. Retour arrière

| Niveau | Quand | Action | Effet sur les données |
|---|---|---|---|
| **R0** | Échec entre S0 et S7 | Corriger, ou `./dev teardown service` (volumes conservés) ; lever la page de maintenance et le blocage LAN si posés | Aucun : dev n'a pas été modifié |
| **R1** | Échec ou écart en S8 ou S9 | La restauration est annulée (une transaction). Relancer S8 après correction, ou revenir à R0 | Dev intact ; service sans donnée réelle |
| **R2** | Problème après S14, **aucune écriture sur service** | Proxy de nouveau vers `10.77.0.25:8080` ; lever le blocage LAN de dev | Aucune perte : dev n'a pas été modifié pendant la fenêtre |
| **R3** | Problème après S14, **des écritures ont eu lieu sur service** | Sauvegarder service (`./dev backup service`), puis `./dev restore dev <dump>` après décision du chef de projet (réécrit dev, même niveau 005). Arbitrer le sort des écritures faites sur service et prévenir les utilisateurs | Perte possible des écritures faites sur service entre la bascule et le retour : à arbitrer au cas par cas |

Règle : aucun `reset` de dev avant la fin de la période D4 et la validation de S15.

### 7. Risques

| Id | Risque | Probabilité / gravité | Parade |
|---|---|---|---|
| R-a | Écriture sur dev après la sauvegarde finale (accès direct LAN `:8080`, proxy mal basculé) : perte de données | Moyenne / élevée | D2 et D6 : page de maintenance **et** blocage LAN ; contrôle S5 |
| R-b | Mot de passe admin changé à la restauration (seed) | Élevée si D3 = régénération | D3 = reprise ; sinon transmettre le nouveau mot de passe par un canal sûr |
| R-c | Perte de mots de passe des membres | Faible : condensats copiés tels quels, GoTrue identique | Contrôle S9 ; ne jamais régénérer `dev.env` |
| R-d | Dump contenant des condensats : fuite | Moyenne / élevée | Répertoire 700, fichiers 600 (umask 077 de `backup`) ; hors dépôt (`.devenv/`) ; aucune copie en clair dans un rapport ; copie hors hôte chiffrée (D5) |
| R-e | Restauration sur un service ayant déjà reçu des écritures : écrasement | Faible (dépend de la fenêtre) | Contrôle S7 (vide) avant S8 ; arrêt si données présentes |
| R-f | Sessions invalidées si `JWT_SECRET` change | Élevée si D3 = régénération | Reprise des clés (D3) ; sinon information des membres |
| R-g | Admin non promu (`ADMIN_EMAIL` différent entre dev et service) : plus d'administrateur | Faible | Contrôles S2 et S10 |
| R-h | Changement d'adresse IP de l'hôte (DHCP) : dev et service injoignables, bascule impossible | Moyenne / élevée | P6 : réservation DHCP avant la bascule |
| R-i | Hôte redémarré : dev n'a aucune politique `restart` ; service oui (ADR-009) | Moyenne / moyenne | Vérifier `docker ps` après reboot ; corriger pour dev si dev reste en service plus longtemps |
| R-j | Policies 25 à 28 absentes ; 00 et 21 en échec ; `dev` imprime `127.0.0.1` | Certaine aujourd'hui | Prérequis P1 à P4 |
| R-k | Premier couple de ports sur une même adresse (8080 et 8081) non éprouvé | Faible / moyenne | S4 : contrôle avant toute bascule ; repli ADR-007 (a) |
| R-l | Sauvegarde unique sur l'hôte (pas de copie hors machine) | Moyenne / élevée | D5 |
| R-m | Durée de fenêtre inconnue (volume de données, build initial) | Moyenne / faible | Répétition S1 à S3 et mesure des durées avant la fenêtre |

### 8. Checklist avant la fenêtre (à cocher par le responsable applicatif)

- [ ] P1 à P7 levés, décisions D1 à D8 consignées
- [ ] `./dev policies` : aucune violation
- [ ] Version commitée, traçable dans `deploy.log`
- [ ] `./dev backup dev` réussi (répétition), `.json` au niveau 005
- [ ] `service.env` présent, mode 600, clés conformes (sans affichage)
- [ ] S3 réussi (déploiement à blanc), S4 consigné
- [ ] Page de maintenance et règle LAN prêtes, testées hors fenêtre
- [ ] Copie hors hôte de la sauvegarde finale préparée (D5)
- [ ] Heure de fenêtre et information des utilisateurs confirmées
