# architecte — 2026-11-17T13:12:43+00:00

## Brief
Itération 002, tour 3 (préparation, GEL de la pile dev : de vrais utilisateurs). Écris uniquement dans specs/. Relevé DevOps : le seed réécrit le mot de passe admin à chaque deploy (change le condensat admin à chaque déploiement, y compris sur un redéploiement sans reset avec données réelles). Lis SPEC-003 et SPEC-004 §deploy et tools/deploy/seed.py (lecture seule). Tranche : le seed doit-il être idempotent sans réécrire le mot de passe d'un compte admin existant (recommandé : créer l'admin seulement s'il n'existe pas, ne jamais écraser un mot de passe changé par l'utilisateur), et comment le fichier de secrets et la base restent cohérents ; écris la spec précise pour le développeur et l'agent action, et dis si un changement de ./dev ou de tools/deploy/ est requis (qui le fait). Compte rendu court : décision, fichiers, points ouverts.

## Compte rendu
**Décision : oui, le seed doit être idempotent sans réécrire le mot de passe d'un admin existant.** Recommandation retenue telle quelle. Specs écrites, aucun code touché, aucune pile touchée.

**Décision sur la cohérence fichier / base**
- `ADMIN_PASSWORD` ne sert qu'à créer un compte absent : c'est un mot de passe initial.
- Après création, la base fait foi. Fichier et base peuvent diverger après un changement de mot de passe, sans resynchronisation automatique.
- `./dev reset` ramène au mot de passe du fichier (base vide). `./dev restore` restitue le mot de passe du dump (`auth.users` y figure).
- Un compte admin existant sans e-mail confirmé fait échouer le seed (rc≠0), sans rien modifier.
- La promotion `db.sh promote-admin` doit être idempotente : une ligne mise à jour, même si l'admin est déjà promu.

**Fichiers**
- Nouveau : `specs/adr/ADR-012-seed-admin-sans-ecrasement.md`
- Amendés : `specs/SPEC-003-admin-secrets.md` (003.5 amendé ; 003.10, 003.11, 003.12 nouvelles), `specs/SPEC-004-piles-dev-service.md` (004.8 et 004.13 amendés), `specs/adr/ADR-003-secrets-et-seed.md` (renvoi vers ADR-012), `specs/README.md` (index et section tour 3 suite)

**Changements requis**
- `tools/deploy/seed.py` : oui, seule la branche « compte absent » doit faire une écriture. Responsable : agent `action`.
- `./dev` : non. La séquence SPEC-004.15 et les variables exportées restent identiques.
- `db.sh` : à vérifier seulement (idempotence de `promote-admin`), pas de changement annoncé.

**Points ouverts**
1. Le relevé ne dit pas si un admin a changé son mot de passe depuis le dernier `deploy`. Si oui, il a été écrasé : à vérifier avant la levée du gel.
2. Le déploiement du seed corrigé se fait sans `reset`, par le responsable applicatif, à la levée du gel.
3. Testeur : `tests/test_003_admin.py` (003.5, 003.10 à 003.12). Policy : contrôle statique de `seed.py` (003.10), numéro à attribuer.
4. Pas de fonction de changement de mot de passe dans cette itération (ADR-012, décision 6). À confirmer par le chef de projet.
5. Hors périmètre : changer `ADMIN_EMAIL` dans le fichier crée un second compte admin, le seed ne supprime rien.
