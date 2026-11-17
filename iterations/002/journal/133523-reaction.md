# reaction — 2026-11-17T13:35:23+00:00

## Brief
Itération 002, tour 2, nouvelle passe. Lecture seule. À partir de iterations/002/journal/133418-observation.md (lis-la en entier et vérifie les faits sur results.json), propose le plan de réaction : pour chaque écart restant, action, responsable (équipe, agent), et ce qui conditionne la bascule vers la pile service. Distingue les décisions structure, les travaux policy/action, et ce qui est en recette [R] (DevOps/responsable-applicatif/client). Ne modifie aucun fichier.

## Compte rendu
# Réaction — itération 002, tour 2, nouvelle passe

Lecture seule. Je n'ai rien modifié ni exécuté.

## 0. Vérification des faits

Les faits de l'observation `133418` sont exacts, mais elle ne voit pas le point le plus important : la policy 25 passe au vert sans prouver ce qu'ADR-014 exige.

- **`results.json`** (13:34:07, `pile_demarree: true`) : 31 entrées, toutes `rc: 0`, synthèse `respectee: 31, violee: 0, non_applicable: 0`. La policy 25 (L187-193) porte bien « C2 (metafile) non vérifiée ». La policy 35 (L277-283) ne référence que SPEC-003.10 et 003.12, pas 003.11. Les policies 25, 26, 27, 28 et 29 sont présentes et respectées.
- **`policies/checks/25-front-audit-npm.sh`** : le chemin `iterations/002/...` est figé (L23) ; la comparaison de dates `st_mtime` est toujours là (L40-41) ; le message de succès contient « C2 non vérifiée » en dur (L74) ; la lecture de `audit-npm.meta.json` et la comparaison de sha256 n'existent pas.
- **`iterations/002/policies/`** : seuls `audit-npm.json` et `results.json` existent. Il n'y a pas de `audit-npm.meta.json`.
- **`audit-npm.json`** : 3 entrées, metadata low 2 / moderate 1 / high 0 / critical 0, conforme à l'observation.
- **Le brief `133014`** dit « numéro lu depuis iterations/CURRENT » : c'est faux (voir E3).

## 1. Diagnostic des écarts

**E1 — Nouveau : la policy 25 est verte, mais ne vérifie pas ADR-014 (critique).**
- Preuve : `25…sh` L23, L40-41 ; absence de `audit-npm.meta.json` dans `iterations/002/policies/` ; ADR-014 §2-3 exige `statut` et `package_lock_sha256`, et supprime la comparaison de dates.
- Cause probable : ADR-014 a été accepté après la rédaction de la policy, et le brief d'action `133035` (L5) ne demandait que `audit-npm.json`. Le méta-fichier n'a donc jamais été produit.
- Effet : la ligne « respectee » aux lignes 187-193 ne prouve pas que l'audit correspond au lock courant. C'est le gate de la bascule, et il est vert à tort.

**E2 — Confirmé : C2 (metafile) est affiché comme « non vérifiée » sur un succès.**
- Preuve : `25…sh` L74 ; ADR-010 C2 exige `meta/vendor-metafile.json` produit par `./dev build`, et je n'ai vu aucun metafile dans les fichiers lus.
- Cause : le script n'a aucun contrôle de metafile. Le libellé est un texte fixe.
- Effet : C2 est une réserve de portée (ADR-010), non bloquante pour le cas A. Mais la sortie « respectee » dit une chose qui n'est pas mesurée.

**E3 — Confirmé et corrigé : itération figée à 002.**
- Preuve : `25…sh` L23, L37-74 ; ADR-014 §4 exige `iterations/<NNN>/` lu depuis `CURRENT`. La policy 29 le fait bien (L88).
- Effet : la policy 25 échouera à l'itération 003. L'observation (2.2) a raison sur le fond, mais la justification du brief `133014` est fausse.

**E4 — Nouveau : `./dev audit-npm` ne distingue pas un rapport valide d'un échec.**
- Preuve : `133035` L25 : rc=1 avec un fichier valide. ADR-014 §2 réserve `non_executee` aux cas où la commande échoue ou où la sortie n'est pas un rapport npm.
- Cause : npm rend 1 dès qu'il y a une vulnérabilité, et la commande ne l'interprète pas.

**E5 — Confirmé : SPEC-003.11 sans policy.**
- Preuve : aucune entrée de `results.json` ; ADR-013 D-4 classe 003.11 en [T]. `tests/test_003_admin.py` existe, `tools/deploy/seed.py` L75 lit `email_confirmed_at` ou `confirmed_at`.
- Ce n'est pas une violation. C'est une vérification de test à confirmer.

**E6 — Confirmé : effet réel sur `auth.users` [R].** La policy 35 est statique. La preuve réelle est en S9 et S12 de `mise-en-service.md`.

**E7 — Confirmé : formulaires repliés non recettés [R].** Aucun journal `client` après `123712` (listing vérifié). Le correctif (`131243-developpeur`) est dit « non recetté visuellement ».

**E8 — Nouveau : une bascule est ordonnée avant le verdict.**
- Preuve : `133259-responsable-applicatif` (13:32:59) ordonne `./dev deploy service` avec un contrôle de `email_confirmed_at` à S3. Il n'a pas de compte rendu. ADR-013 D-4 dit que le champ n'est lu que si le compte existe déjà, donc pas sur une pile vierge : le premier contrôle réel est au second déploiement (S12).
- `mise-en-service.md` § 0 et § 1 sont datés du tour 3 (« policies 25 à 28 absentes »). Ils sont obsolètes sur P1 à P4, qui sont désormais satisfaits (policies 25-28, 00, 21 et 27 respectées). P5 (commit) n'est pas vérifiable ici, car je n'ai pas d'accès git.

## 2. Plan de réaction ordonné

### A. Décisions structure (chef de projet)

| # | Décision | Recommandation | Conditionne |
|---|---|---|---|
| S1 | Gate de bascule : tant que E1, E3 et E4 ne sont pas fermés, ne pas dépasser S3 (`deploy service`) | Suspendre `deploy service`. S0-S2 (non destructifs, `backup`, `service.env`) peuvent continuer. S3 est réversible (`teardown service`), mais la preuve du lock doit exister avant | Bascule |
| S2 | Garde esbuild (ADR-013 D-1) : bloquant ou note | Trancher. Tant que ce n'est pas fait, la note reste | Policy 25 finale |
| S3 | Réserve C2 (ADR-010 point 1) : lever avant la recette itération 003, ou libeller la sortie « partielle » | Libeller la sortie (E2), à lever en itération 003 | Libellé de la policy 25 |
| S4 | Confirmation du numéro de policy 35 (ADR-013 point 3) | Confirmer | Traçabilité |
| S5 | Confirmer le P5 (version commitée, `git status` propre) et les décisions D1-D8 consignées | Responsable applicatif le vérifie, chef de projet le confirme | S3 à S14 |

### B. Travaux policy / action (Team AOPR)

| # | Agent | Action | Preuve |
|---|---|---|---|
| T1 | `policy` | Réécrire la policy 25 : lire `audit-npm.meta.json`, vérifier `statut == "reussie"` et `package_lock_sha256` contre `sha256(app/web/package-lock.json)`, retirer `st_mtime`, lire `iterations/CURRENT`, libeller C2 selon S3 | `./dev policies` : 25 respectée avec méta valide ; cas négatif (lock modifié) : non conforme |
| T2 | `action` | `./dev audit-npm` écrit `audit-npm.meta.json` (4 champs ADR-014 §2) et traite rc=1 avec rapport valide comme `reussie` (E4) | `audit-npm.meta.json` présent ; `sha256` identique au lock |
| T3 | `action` | Ajouter `./dev audit-npm` à `./dev help` et au contrat SPEC-004.1 (ADR-013 point 5) | `grep` dans `dev` et `specs/SPEC-004` |
| T4 | `policy` (si S2 bloquant) | Faire de la garde esbuild un blocage ou la laisser en note, selon S2 | Policy 25 : cas négatif si bloquant |
| T5 | `developpeur` / `testeur` | Vérifier que `tests/test_003_admin.py` couvre `email_confirmed_at` / `confirmed_at` et `rc≠0` (E5). Exécution selon le gel : `./dev test` est interdit sur `dev`, à arbitrer par structure | Résultat du test, consigné |
| T6 | `observation` | Au prochain tour, lire `audit-npm.meta.json` et la policy 25 corrigée | Observation |

### C. Recette [R] (Team DevOps)

| # | Agent | Action | Condition |
|---|---|---|---|
| R1 | `responsable-applicatif` | Après T1-T2 : consigner `statut` et `sha256` dans `mise-en-service.md` (ADR-014 [R]), réexécuter policies 25 et 28 avant `deploy service` (ADR-010 point 2) | S1 levée |
| R2 | `responsable-applicatif` | Aligner le brief `133259` sur ADR-013 D-4 : pas de contrôle `email_confirmed_at` à S3 sur pile vierge ; le premier contrôle réel est S12 | Avant S3 |
| R3 | `responsable-applicatif` | S3 à S14 selon `mise-en-service.md` ; CA-002-1, 33, 36 [R] | R1, R2, S5 |
| R4 | `client` | Recette des formulaires repliés (Nouvelle tâche, Modifier, Loguer du temps, Réaffecter, Demander de l'aide) sur `dev`, captures à l'appui. Structure doit confirmer que la recette client est autorisée pendant le gel | Captures + rapport client |
| R5 | `responsable-applicatif` | Vérifier l'effet réel sur `auth.users` (S9, S12) | Condensats égaux, hors admin |

### D. Conditions de la bascule vers la pile service

| Condition | État |
|---|---|
| Policies 25 à 28 existent et sont respectées | Fait (`results.json` L187-221) |
| Policy 25 prouve le lock courant (méta `reussie` + sha256) | **Non fait** (E1) |
| Policy 25 sans cas C (`serve` / `watch` / `context(`) | Fait (pas d'ATTENTION dans L193) |
| Policy 28 réexécutée juste avant `deploy service` | À faire (R1) |
| Gel de `dev` levé | Décidé (feu vert dans `133259`) |
| P5 : version commitée | Non vérifiable ici ; S5 |
| P6 : réservation DHCP de `10.77.0.25` | Utilisateur, non vérifié |
| D1 à D8 consignées | Déclarées validées dans `133259` ; à consigner |
| Garde esbuild décidée (S2) | Ouvert (non bloquant pour A) |

## 3. Ce qui relève de l'utilisateur ou du product owner

- **Utilisateur** : P6 (réservation DHCP), D1 à D8 (validation et consignation), confirmation du déroulé de la bascule.
- **Product owner** : écart CA-002-1 « après reset » (accepté dans ADR-013 D-8, mais à faire valider par le product owner selon `mise-en-service.md` § 5) ; recette client des formulaires repliés (SPEC-005) si elle n'est pas faite avant clôture ; canal API de changement de mot de passe (ADR-013 D-5) : accepter et documenter, ou fermer dans une itération dédiée.

**Ma recommandation au chef de projet** : ne pas clore l'itération. Fermer T1 et T2 (E1, E3, E4) avant toute bascule au-delà de S2, trancher S1 à S3, puis relancer `./dev audit-npm` et `./dev policies`.
