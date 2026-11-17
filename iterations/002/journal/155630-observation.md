# observation — 2026-11-17T15:56:30+00:00

## Brief
CLÔTURE de l'itération 002, lecture seule. Restitue au format de ton périmètre, sur l'ensemble de l'itération : (1) policies : iterations/002/policies/results.json (33/33 à 15:56:04, deploy dev 29a3980 à 15:55:54) ; (2) tests : iterations/002/tests/rapport-testeur.md (et junit.xml / resultat.txt pour les chiffres) ; (3) recette : iterations/002/rapport-client.md et recette-client.md, et passe-recette.md, passes 1 à 3 ; (4) mise en service : iterations/002/mise-en-service.md ; (5) coût : cout.md / cout.json. Signale les écarts entre ces sources (chiffres, dates, statuts), et ce qui est prouvé par preuve exécutable versus déclaré. La mise à jour de la pile service attend l'autorisation de l'utilisateur dans la session DevOps : à présenter comme FAIT pour la partie déjà réalisée (bascule service 13:35, deuxième deploy service sans reset, CA-002-33 [R]), et non comme écart technique. Ne modifie aucun fichier.

## Compte rendu
**Clôture itération 002 : restitution Observation (lecture seule, aucun fichier modifié)**

Légende des preuves : **[EXÉC]** sortie brute présente dans les sources lues ; **[STAT]** vérification statique (texte de code) ; **[SIM]** simulation ; **[DÉCL]** affirmation d'un agent (rapport ou journal) sans sortie brute dans les sources. Heures UTC, sauf mention contraire.

## 1. Faits vérifiés

### 1.1 Policies (`policies/results.json`, date 15:56:04, `pile_demarree: true`)
- Synthèse : respectee 33, violee 0, non_applicable 0 (l.304-308) [EXÉC]. Les 33 entrées (00 à 37) sont « respectee », rc 0.
- Par référence :
  - **CA-002-1** : STACK-services 20 (l.142-149), STACK-ports 21 (l.151-158), DEV-sortie-url 27 (l.205-212) [STAT].
  - **CA-002-2** : ENV-images-epinglees 00 (14 références, l.8-13), FRONT-meme-origine 15, FRONT-audit-npm 25, FRONT-auth-js-non-appel 28 [STAT].
  - **CA-002-3** : GW-relais-auth 11 (200), GW-relais-rest 12 (200), GW-csp 14, GW-cache-et-entetes 37 (7 chemins, Cache-Control no-cache) [EXÉC, déployé].
  - **CA-002-4** : ENV-secrets-fichier 17 (droits 0700/0600, HS256) [EXÉC] ; ENV-secrets-valeurs-absentes 05 [STAT].
  - **CA-002-6/7, CA-002-33** : STACK-auth-debit 33 (config, pas de limit_req) [STAT] ; DB-migrations-versionnees 22, DB-migrations-additives 29, ADMIN-seed-sans-ecrasement 35 [STAT].
  - **CA-002-11** : API-anon-refuse 16 (27 requêtes avec clé anon, l.130) [EXÉC] ; DB-rls-privileges-statique 23 [STAT].
  - **CA-002-36** : STACK-restart-service 26, STACK-tags-par-pile 32 [STAT].
  - **SPEC-001.7** : GW-admin-bloque 13 (403, variantes de chemin) [EXÉC].
  - **Garde-fou (SPEC-004.6)** : GARDE-FOU-mise-en-service 24 : « conforme sur 70 cas simulés » (l.184) [SIM].
  - **CA-002-27/28/29/30/32** : FRONT-messages-tour3 30 : gabarits M-1 à M-6 présents, pas de confirm(), alert() ni innerHTML (l.238) [STAT]. Ne prouve pas l'affichage à l'écran.
  - **CA-002-37** : FRONT-barre-fixe 31 : barre sticky, top 0 (l.247) [STAT].
  - Incidents cités par les REF : 36 (bundle servi = sha256 du build, l.292) [EXÉC] ; 37 (l.301) [EXÉC].
  - **CA-002-38 et CA-002-39** : aucune policy.

### 1.2 Tests (passe finale, dev, 13:59-14:02)
- `resultat.txt` l.28 et `junit.xml` (attributs tests=197, failures=1, skipped=4) [EXÉC] : **197 collectés, 192 réussis, 1 échec, 4 ignorés**. Rapport testeur, l.12 : concordant.
- **FAIL SPEC-003.9** `test_seul_admin_email_hors_comptes_de_test` : « comptes hors @test.invalid : 8 (attendu : ADMIN_EMAIL seul) » (resultat.txt l.20-21) [EXÉC].
- **SKIP SPEC-004.3** (`test_persistance_relire`, `test_persistance_ecrire`) : « aucun ./dev deploy depuis l'écriture du jeu marqué » et « en attente de relecture » (junit) [EXÉC].
- **SKIP SPEC-004.7 et SPEC-004.8** : « à exécuter avec DEVENV_PILE=service » (junit) [EXÉC].
- **PASS SPEC-001.14** : `test_inscriptions_en_rafale` (20 × 200), `test_aucune_reponse_429` (junit) [EXÉC]. Le total de 202 inscriptions et 0 × 429 vient du journal de la passerelle, pas d'un compteur de test (rapport §4, l.102-107) [DÉCL].
- **PASS** : SPEC-001.4/5/6/7 (8 cas)/8/9/10/11/12/13 ; SPEC-002.1 à 002.22 (tests `test_002_modele`) ; SPEC-003.1/2/4/5/9 (sauf 003.9 en FAIL) ; SPEC-003.10 (seed sans écriture) ; SPEC-004.1 ; paquets git, curl, bash à la version épinglée (6 cas) [EXÉC junit].
- **Sans test marqué ou non exécuté** (rapport §2-3) [DÉCL, analyse AST] : SPEC-003.11, 003.12 (sans test) ; SPEC-004.2 (non exécuté, reset interdit) ; SPEC-004.13 (partiel, dépend de 003.11). Couverts sans marqueur : SPEC-005.11 et 005.12.
- **Passe du tour 2** (`tests/passe-1/resultat.txt` l.5, [EXÉC]) : 183 réussis, 3 ignorés, 186 collectés, 0 échec. SPEC-003.9 y est PASS (`tests/rapport-tour2.md` l.78). E1 (aucun test de débit, l.124) est résolu dans la passe finale.
- **Passe intermédiaire** (13:59, rapport testeur l.14) : 194 réussis, 1 échec, 2 ignorés [DÉCL].

### 1.3 Recette client (critères [C])
- **Passe 1** (`rapport-client.md`, l.10-33 et bilan l.86-92) [DÉCL] :
  - OK : CA-002-5, 6, 7, 8, 10, 12, 13, 14, 15, 17, 18, 19, 21, 22, 23, 24, 25, 29, 30, 32, 34, 35 (22 critères).
  - OK avec réserve : CA-002-9 (étape 6 bis, URL non vérifiable) ; CA-002-27 (l.89).
  - KO partiel : CA-002-28 (étape 16.12, aucun message, l.57).
- **Passe 2** (`journal/140419-client.md`, compte rendu l.286-306, N=2, 14:04) [DÉCL] — absente de `rapport-client.md` :
  - KO : CA-002-27 (message « Proposition envoyée. » sans nom, l.302) ; CA-002-28 (aucun message, l.303) ; CA-002-37 (barre disparaît au défilement, zoom 200 % sans effet, l.304) ; CA-002-38 (aucun champ de recherche, l.305) ; CA-002-39 (désactivation immédiate, l.306).
  - E7 OK ; le reste « OK avec réserves » (l.292).
- **Passe 3** (`rapport-client.md`, l.96-111, N=3, pile DEV, ~14:59-15:17) [DÉCL] :
  - CA-002-27 : OK, texte exact, réserve de visibilité (l.107) ; CA-002-28 : OK, même réserve (l.108).
  - CA-002-37 : **PARTIEL / BLOQUÉ** (barre fixe OK au défilement, 200 % impossible, l.109).
  - CA-002-38 : OK sur les points observés (l.110) ; CA-002-39 : OK, focus non vérifiable (l.111).
  - Étapes non jouées : 1, 3, 4, 6, 6 bis, 11, 13, 14, 15, 17, 18.2 (l.153).
- **N = 1** retenu pour la passe 1 (`tests/passe-recette.md` l.8). Aucun document lu ne consigne le choix de N pour les passes 2 et 3.

### 1.4 Mise en service (`mise-en-service.md`, déclaré par le responsable applicatif)
- **Tour 2** : deploy dev dfbc020, 12:29-12:30, 21 s, rc 0 (l.85-90).
- **Tour 3** (en-tête « BASCULE dev vers service (exécution) », l.38) :
  - backup dev 13:33:29, rc 0 (l.50) ; restore service rc 0 (l.54) ;
  - purge sur service de 385 comptes, 173 tâches, 36 temps, 47 propositions (l.55) ;
  - deploy service : 1er passage 19 s, 2e passage 6 s, horodatages 13:33:58Z et **13:35:39Z**, rc 0 chacun (l.43, l.63) ;
  - CA-002-33 [R] : empreintes avant/après identiques hors admin, service.env inchangé, connexion admin valide (l.63) ;
  - CA-002-36 [R] (a) (b) (c) : (c) « reset service sans flag » rc 1, « Rien n'a été détruit » (l.64) ; CA-002-1 [R] (a) curl 200, (b) ss -ltn (l.62).
- **Tour 4** (13:57-13:59) : dump dev 135659, delta migré = 0, deploy dev 899ee3e rc 0 10 s, service non modifié (l.358-403).
- **14:58** : build et deploy dev, commit a4d5b4d + correctif Cache-Control non commité, rc 0, 12 s (l.3-36).
- **15:55** : deploy dev commit 29a3980, rc 0, 11 s ; **policies 33/33** (l.419) ; app démarré 15:55:47, client 15:55:54 (l.415-428).

### 1.5 Coût (`cout.json` brut, `cout.md`)
- `cout.json` : `fin: null` (l.4) ; durée 170,7 min ; total 12,6858 USD (l.28) ; haiku 2 192 requêtes, 5,397 USD ; opus 103 requêtes, 7,2888 USD (l.6-26) [EXÉC].
- `cout.md` : relevé à 14:29, itération non clôturée (l.3) [DÉCL].

### 1.6 Partie réalisée de la mise à jour de la pile service (présentée comme FAIT)
- Déjà réalisé et consigné : préparation de service (service.env, deploy service à deux reprises, restore, purge des comptes de test sur service, connexion admin, accès anonyme refusé, ports, restart unless-stopped) ; **deuxième `deploy service` sans reset à 13:35:39Z**, CA-002-33 [R] consigné (l.63).
- Le reste (gel de dev, sauvegarde après gel, proxy, validation utilisateur) est traité au point 2.4.

## 2. Écarts constatés

### 2.1 Recette : variations de verdict et chronologie
- **a.** CA-002-27, 28, 37, 38, 39 : KO en passe 2 (journal l.302-306, 14:04, dev 899ee3e) ; OK ou partiel en passe 3 (rapport-client l.107-111, après le deploy de 14:58). Le document du 14:58 ne décrit que le correctif Cache-Control (mise-en-service l.6). Aucune source lue ne décrit les changements qui feraient passer « champ de recherche », « confirmation de désactivation » et « barre fixe » de absent à présent.
- **b.** CA-002-27, passe 1 : verdict « OK, réserve » (rapport-client l.89). Le message observé est « Proposition envoyée. » sans nom (l.55). La procédure dit qu'un message sans nom du collègue ni de la tâche est KO (`recette-client.md` l.191). La passe 2 classe le même message KO (journal l.302).
- **c.** Passe 1, comptage : « 16 étapes sur 18 entièrement conformes » (rapport-client l.92). Le tableau (l.12-33) compte 18 lignes OK sans réserve, 1 réserve (6 bis) et 1 KO (16).
- **d.** Passe 1, capture `124949-223` citée pour l'étape 13 (l.41, « D terminée ») et pour l'étape 15 (l.43, « avant réaffectation »).
- **e.** Passe 3, écarts déclarés par le client : charge 6 h au lieu de 3 h (l.131), attribuée à l'étape 15 non jouée ; statut non enregistré au premier essai (l.133) ; mot de passe de 14 caractères au lieu de 12 prévus (l.101 contre `recette-client.md` l.23) ; adresse de la pile non lue (l.101).
- **f.** Passe 1, anomalie : inscription d'une personne réelle (domaine gouv.fr) vers 13:00 (rapport-client l.72). Non recoupée : mise-en-service l.69 et rapport testeur l.81 mentionnent 8 comptes hors test, sans identité ni domaine.

### 2.2 Tests
- **g.** SPEC-003.9 : PASS au tour 2 (rapport-tour2 l.78, passe-1 à 0 échec), FAIL dans la passe finale (resultat.txt l.20-21). Le testeur attribue l'échec à l'état des données (8 comptes hors test, rapport §3.1 l.79-83).
- **h.** Confidentialité : rapport §7 (l.132) affirme 0 occurrence d'ANON_KEY dans resultat.txt et junit.xml. resultat.txt l.7 et junit contiennent `'ANON_KEY': 'eyJhbGciO...St-xXTfWEntjP8GpW94mhsGoNAt_7U'` : un fragment, pas la valeur complète [EXÉC]. Le rapport parle de valeurs complètes.
- **i.** Décomptes [T] divergents : rapport testeur final « 49 specs portent un [T] » (l.19) ; rapport tour 2 « 46 exigences portent [T] » (l.26). Aucune explication dans les sources.
- **j.** SPEC-004.3 : SKIP en passe finale (rapport §2 l.66), PASS dans la passe de 13:59 (rapport §4 l.109), SKIP au tour 2 (rapport-tour2 l.74, 138). Ce sont trois passes différentes.
- **k.** Chronologie : la passe finale (13:59-14:02) et la passe 2 (14:04) précèdent les deploys de 14:58 (a4d5b4d) et 15:55 (29a3980). Aucun test ni recette n'est documenté après 15:55. Seule la policy de 15:56 (33/33) vérifie la version finale.

### 2.3 Preuves de policies et de recette
- **l.** Policies 30 et 31 sont statiques (texte de code). Pour CA-002-27, 28 et 37, la recette constate un affichage différé, absent, ou une barre non fixe à 200 % (rapport-client l.107-109, l.135 ; journal l.302-304). Les deux types de preuve ne se contredisent pas, mais la policy ne prouve pas l'affichage.
- **m.** REF des policies 36 et 37 citent des « incidents de recette itération 002 » (results.json l.287, l.296). Aucun de ces incidents n'est décrit dans les sources lues.
- **n.** CA-002-38 et CA-002-39 n'ont ni test ni policy. Leur preuve est uniquement déclarative (recette).

### 2.4 Mise en service : libellés et étapes
- **o.** L'en-tête du tour 3 dit « BASCULE dev vers service (exécution) » (l.38). Le statut dit « SERVICE PRÊTE (pré-bascule) » et « Les étapes de coupure (gel de dev, sauvegarde finale après gel, proxy, validation utilisateur : S5 à S16) ne sont pas jouées dans ce tour » (l.40). Le plan porte « PRÉPARÉ, NON EXÉCUTÉ » (l.148). Aucun document lu ne consigne ensuite S5 (gel), S6 (sauvegarde après gel), S7 (contrôle de vide), S14 (bascule du proxy) ni S15 (validation utilisateur). Dev a été redéployé le 13:57, le 14:58 et le 15:55 et servait encore la recette des 14:04 et 15:00 (l.361, l.5, l.418).
- **p.** Version dev : 899ee3e (l.361), puis a4d5b4d + correctif non commité (l.6), puis 29a3980 « code identique à ff6715f » (l.415). L'identité entre 29a3980 et ff6715f n'est pas expliquée.
- **q.** Horodatage : le « deploy à 15:55:54 » de la demande correspond à l'heure de démarrage du conteneur client (l.425). Le deploy dure 11 s et démarre avant (l.416).
- **r.** Policies : cout.md l.13 cite « 31 respectées (13:46) » ; results.json donne 33 à 15:56. mise-en-service l.56 et l.75 (écart G) notent le même passage de 31 à la version antérieure. Chiffres de dates différentes, pas de contradiction.
- **s.** Écarts déclarés par le RA : CA-002-1 partie « après reset puis deploy » non jouée, « écart accepté » (l.62). CA-002-36 (c) : sortie consignée par le RA (l.64), sans fichier brut ; la policy 24 est une simulation (l.184).

### 2.5 Coût
- **t.** cout.md l.56 : « La recette du tour 3 … n'a pas été exécutée (gel de la pile dev) ». Le journal de la passe 2 (14:04-14:27) a exécuté CA-002-27, 28, 37, 38, 39 ; la passe 3 (14:59-15:17) les a aussi exécutées. Le relevé du coût date de 14:29.
- **u.** cout.md l.14 : « 22 critères OK » ne reprend que la passe 1 ; la passe 2 (5 KO) n'est pas intégrée.
- **v.** cout.md l.60-62 (déclaré par le sponsor) : coût Opus identique à 4 décimales (7,2888 USD) entre 54,7 et 170,7 min. `sous_agents` vaut 0 partout (cout.json l.10, l.20).

## 3. Ce qui n'a pas pu être observé, et pourquoi

- **Passe 2** : son compte rendu n'est que dans `journal/140419-client.md`, hors de la liste de sources. `rapport-client.md` ne contient que les passes 1 et 3. Je l'ai lu pour cette restitution.
- **Captures** (`client/*.png`) : non ouvertes. Les verdicts reposent sur les déclarations du client.
- **Fuseau des captures** : le fuseau n'est pas indiqué ; je compare sur la base UTC supposée des journaux.
- **Sorties brutes des commandes du responsable applicatif** (deploy, backup, restore, purge, rc) : citées (`.devenv/deploy.log`, `.devenv/backups`, `.devenv/delta`) mais absentes des sources lues. Les faits du point 1.4 sont déclaratifs.
- **Tests non exécutés** : SPEC-004.7 et 004.8 (pile service), SPEC-004.2 (reset interdit), relecture de persistance après le dernier deploy ; SPEC-003.11 et 003.12 (pas de test).
- **Preuves absentes** : affichage des messages P1/P2 à l'écran, barre à 200 %, CA-002-38 et CA-002-39 (uniquement recette client). Reset refusé (CA-002-36 c) : seulement la sortie déclarée et une simulation.
- **WebSocket au chargement** : non observée (`tests/passe-recette.md` l.45-51, « non établie à l'exécution »).
- **Compteur de débit** : 202 inscriptions issues du journal de la passerelle, pas d'un compteur de test.
- **Coût** : pas de relevé final (`fin: null`), pas d'attribution par agent.
- **Inscription du 13:00** : non recoupée avec les sources.
- **Commits** (29a3980, ff6715f, 899ee3e, a4d5b4d) : non vérifiés dans git ; seule l'affirmation de `mise-en-service.md`.
- **Autorisation de la mise à jour de la pile service** dans la session DevOps : pas de trace dans les sources lues. Le statut est celui indiqué par le chef de projet.
