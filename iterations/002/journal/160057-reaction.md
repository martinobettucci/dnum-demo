# reaction — 2026-11-17T16:00:57+00:00

## Brief
CLÔTURE de l'itération 002, lecture seule. À partir de iterations/002/journal/155630-observation.md (lis-la en entier, vérifie les faits sur les sources citées), rédige la réaction de clôture en trois parties distinctes : (A) LIVRÉ : ce qui est fait et prouvé (policies, tests, bascule service, recette) ; (B) ÉCARTS ACCEPTÉS : ce qui est connu, non fait, et accepté par structure ou le product owner (ex. recette ou décisions déjà tranchées : D1 à D5, O3 à O6, E7, la policy 07 reportée) ; (C) BACKLOG 003 : ce qui reste à faire, avec l'équipe responsable. Marque explicitement comme FAIT la mise à jour de la pile service, qui a été réalisée par le responsable-applicatif (bascule 13:35, second deploy service sans reset), et ne la présente pas comme un écart technique. Signale toute contradiction entre sources. Ne modifie aucun fichier.

## Compte rendu
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
