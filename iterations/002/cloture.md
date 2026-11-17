# Itération 002 — clôture (chef de projet, 2026-11-17)

## Verdict
**Itération 002 CLÔTURÉE.** L'application « Suivi des tâches d'équipe » est **en production** sur
https://dnum.lelabs.tech, servie par la pile `service` sur 10.77.0.25:8081, persistante et sauvegardée.

## Livré
- Supabase auto-hébergé (Postgres, GoTrue, PostgREST, passerelle nginx). RLS forcée partout, aucun
  droit `anon`, RPC pour les changements d'état.
- Inscription, **activation par l'admin**, compte admin initial, tâches, tâches des autres,
  réaffectation, temps logué, tableau « qui fait quoi » avec charge projetée et « Surchargé » > 7 h,
  propositions d'entraide (proposer / demander, accepter / refuser).
- Deux piles : `dev` jetable (:8080) et `service` persistante (:8081), avec backup et restore.
  Seed admin non destructif. Secrets hors git, hook pre-push anti-secrets.
- Vérification : 33 policies respectées sur 33 ; 192 tests réussis sur 197 (1 échec accepté,
  4 ignorés) ; recette clavier/souris en 3 passes, la passe 3 verte avec réserves.
- Bascule de production : dev → service, 385 comptes de test purgés côté service, 8 comptes réels
  conservés, delta nul. Proxy basculé par l'utilisateur et vérifié (6/6 requêtes marquées sur service).

## Décisions complémentaires du chef de projet
Ce sont les points laissés « NON TRANCHÉ » par l'acceptation du PO (`perimetre.md`).

| Id | Décision |
|---|---|
| C3 | CA-002-40 est couvert par la policy 35 (SEED-sans-ecrasement, SPEC-003.10/.12) et par 3 tests SPEC-003.10 au vert. Le test de SPEC-003.11 passe au backlog 003. |
| C4 | PROUVÉ : au premier deploy service, GoTrue v2.170.0 renvoie `email_confirmed_at` et `confirmed_at` (rapport DevOps) ; le second deploy service sans reset a gardé des empreintes identiques (CA-002-33 [R]). |
| C5 | ACCEPTÉ : aucun test ne s'exécute sur la pile qui porte de vrais utilisateurs (règle permanente). SPEC-004.3, 004.7 et 004.8 sont vérifiées par le responsable applicatif ([R], `mise-en-service.md`). |
| C6 | Ce n'est pas un incident : la clé `anon` est publique par conception (servie par `/config.js`). `resultat.txt` et `junit.xml` sont ignorés par git, et aucun commit ne contient la clé. |
| C7 | Aucune recette après le deploy de 15:55 : non nécessaire. `/app.js` est inchangé (md5 4eb8c08e, policy 36). Seuls nginx et `build-sha256` ont changé, et la policy 37 les couvre. La cohérence de l'étape 15 (charge 6 h) passe au backlog 003. |
| C8 | Test et policy de CA-002-38 : backlog 003. Recette OK en passe 3. |
| E1 | Contradiction entre la passe 2 (KO) et la passe 3 (OK) : elle est expliquée. Le Chromium du client tournait depuis environ 2 h sans recharger la page ; il exécutait l'ancien JavaScript en mémoire. Le bundle servi était déjà correct, le même md5 sur :8080 et :8081. Correction : le client est recréé à chaque deploy dev, nginx est en no-cache, et la policy 36 compare les empreintes. |
| U1 | 8 comptes réels au lieu de 3 : ce sont 5 inscriptions réelles postérieures au premier comptage, toutes conservées. Décisions D1 à D8 de la bascule : validées par l'utilisateur (« choix recommandés »), sauf D5 (sauvegarde hors hôte), reportée en 003. Étapes S5 à S7 (maintenance, blocage LAN) : remplacées par le rattrapage du delta, qui s'est révélé nul. S14 (proxy) : FAIT et vérifié. S15 (validation de l'utilisateur) et P6 (DHCP) : en attente de l'utilisateur. |
| C2 | Relu par le chef de projet dans `junit.xml` : `test_paquet_installee_dans_le_runner_a_la_version_epinglee[git, curl, bash]` exécutés et réussis. |
| C13, C14, C15, E2, E5, E9 | Points de traçabilité documentaire mineurs : ACCEPTÉS en l'état, et repris dans une revue documentaire au backlog 003. |
| C9 / C10 / C12 | Voir ci-dessous. Tout est commité et poussé. L'inscription de 13:00 est un utilisateur réel passé par le proxy, il fait partie des 8 comptes réels. |

## Correction de l'acceptation PO (point 8)
Le point 8 (« mise à jour de la pile service avec les correctifs nginx : FAIT ») est **inexact**.
- La **bascule** vers service est faite (13:33–13:35, commit 3c93a08).
- La **mise à jour de service** avec les correctifs postérieurs (nginx `Cache-Control: no-cache`,
  en-têtes de sécurité par location, `build-sha256`) **n'est PAS faite**. La session DevOps a vu
  son classifieur de permissions refuser l'action sur la pile de production, et elle attend
  l'autorisation de l'utilisateur dans sa session.
- Conséquence pour les utilisateurs : l'interface est **la même** (`/app.js` identique). Seuls
  manquent l'en-tête anti-cache et la répétition des en-têtes de sécurité par location. Le
  premier deploy service autorisé les apportera, avec `./dev backup service` avant.

## En attente de l'utilisateur
1. Autoriser, dans la session spark-docker-f1, `./dev backup service` puis `./dev deploy service`
   (sans reset).
2. Valider ses comptes réels sur dnum.lelabs.tech (S15).
3. Réserver 10.77.0.25 en DHCP.

## Backlog 003
Voir `perimetre.md` §8–§9 :
- US-18 : changer mon mot de passe ;
- US-19 : message visible près de l'action ;
- US-20 : focus visible ;
- US-21 : zoom 200 % ;
- montée de supabase-js et d'esbuild ; alertes Dependabot ;
- policy 07 apt ; `dae9044` en dur ;
- tests de SPEC-003.11 et de CA-002-38 ; SPEC-003.9 réécrite pour service ;
- sauvegarde hors hôte.
