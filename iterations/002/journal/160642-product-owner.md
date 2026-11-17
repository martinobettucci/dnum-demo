# product-owner — 2026-11-17T16:06:42+00:00

## Brief
Clôture de l'itération 002, suite. Le chef de projet a tranché tous les points restants dans iterations/002/cloture.md, section « Décisions complémentaires » (lis-la, ainsi que iterations/002/reaction.md section CLÔTURE, en lecture seule). Dans iterations/002/perimetre.md, section « Acceptation de clôture 002 » : (1) CORRIGE le point 8 : la mise à jour de la pile service avec les correctifs nginx N'EST PAS FAITE (seule la bascule du proxy l'est) ; elle est en attente d'autorisation de l'utilisateur ; c'était noté « FAIT » par erreur : consigne que c'est un fait (état) et non un écart, et que le travail reste à faire ; (2) référence iterations/002/cloture.md et reprends, point par point, les décisions complémentaires du chef de projet pour C2 à C15, E1 à E9, U1, S14, S15, P6, en citant leur identifiant ; ne reformule pas leur contenu au-delà de ce que dit cloture.md ; (3) vérifie la cohérence avec perimetre.md : CA-002-40 couvert par la policy 35 et 3 tests (vérifie en lecture seule que la policy 35 et les tests existent dans policies/checks/ et iterations/002/tests/ ; sinon signale-le) ; C8 (CA-002-38) en backlog 003 ; (4) prononce l'acceptation formelle de clôture de l'itération 002 si, et seulement si, aucun point n'est resté sans décision ; sinon liste précisément ce qui reste, sans prononcer. Tu n'écris que dans iterations/002/perimetre.md. Compte rendu court : verdict, points restants éventuels.

## Compte rendu
Verdict : **acceptation formelle de clôture de l'itération 002 non prononcée.** Des points restent sans décision. Le détail est dans `iterations/002/perimetre.md`, section « Acceptation de clôture 002 », §C.

**Corrections et vérifications faites**
- Point 8 corrigé : « NON FAIT ». Seule la bascule du proxy est faite. La mise à jour de `service` reste à faire, en attente d'autorisation de l'utilisateur.
- C2 à C15, E1 à E9, U1, S14, S15 et P6 repris par identifiant, en renvoyant à cloture.md.
- Policy 35 présente (`policies/checks/35-admin-seed-sans-ecrasement.sh`).
- Les 3 tests SPEC-003.10 ne sont pas dans `iterations/002/tests/`, qui ne contient que des sorties. Ils sont dans `tests/test_003_admin.py` (l.148, 164, 177) et apparaissent dans `junit.xml`.
- Le sous-cas de CA-002-40 « compte existant sans e-mail confirmé » (code retour non nul) n'a ni test ni policy. C3 de cloture.md ne le couvre pas.

**Points restants**
1. Point 8 : mise à jour de `service`, en attente de l'utilisateur. C'est une action, pas une décision.
2. C9 : écart de version `service` (3c93a08) / `dev` (29a3980). Non tranché, alors que le proxy est déjà basculé.
3. CA-002-40, sous-cas sans e-mail confirmé : décider un report nommé ou exiger une preuve.
4. C11 (coût, `fin: null`) : absent de cloture.md.
5. E6 (décompte [T] 49 contre 46) : absent de cloture.md.
6. E3, E4, E7, E8 : absents de cloture.md sous ces identifiants. Rapprochements proposés, non confirmés : E3 avec U1, E7 avec C5, E8 avec C2. E4 est traité dans la table A, ligne 2.
7. S15 et P6 : en attente de l'utilisateur.
