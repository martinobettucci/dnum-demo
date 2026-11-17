# developpeur — 2026-11-17T13:15:15+00:00

## Brief
Itération 002, tour 3, PRIORITAIRE (la bascule approche). GEL : aucun reset, teardown, deploy ni test, aucun conteneur en marche touché ; de vrais utilisateurs sont sur la pile dev. Implémente la décision du chef de projet : le seed ne réécrit plus jamais le mot de passe d'un compte admin existant ; il crée l'admin s'il n'existe pas, sinon ne touche à rien. Lis specs/adr/ADR-012-seed-admin-sans-ecrasement.md, SPEC-003 (003.5, 003.10 à 003.12), SPEC-004.8 et .13. Modifie tools/deploy/seed.py (seule la branche « compte absent » écrit ; un admin existant sans e-mail confirmé fait échouer le seed rc≠0 sans rien modifier) et vérifie que tools/deploy/db.sh promote-admin est idempotent (une ligne mise à jour même si l'admin est déjà promu) ; corrige-le si besoin. Pas de modification de ./dev. Vérifie ce que tu peux sans conteneur (relecture, python3 -I -m py_compile, bash -n) ; ne lance pas le seed. Puis ./dev build et ./dev policies, une commande par appel. Compte rendu court : fichiers modifiés, comportement par cas (admin absent, existant confirmé, existant non confirmé), ce qui reste à valider au premier deploy.

## Compte rendu
Warning: no stdin data received in 3s, proceeding without it. If piping from a slow command, redirect stdin explicitly: < /dev/null to skip, or wait longer.
## Compte rendu développeur — itération 002, tour 3 (seed admin sans écrasement)

**Fichier modifié** : `tools/deploy/seed.py` (seul fichier touché). `db.sh` n'a pas été modifié, `./dev` non plus, rien n'a été lancé ni arrêté.

**Changements dans `seed.py`**
- La branche « compte absent » reste la seule qui écrit (`POST /admin/users`, e-mail confirmé, mot de passe = `ADMIN_PASSWORD`).
- L'appel `PUT /admin/users/{id}` est supprimé. Il n'y a plus aucun `PUT`/`PATCH`/`DELETE` dans le script (vérifié par grep).
- Le script ne lit ni n'écrit le fichier de secrets.

**Comportement par cas**
- **Admin absent** : création, rc=0, message « compte administrateur créé ».
- **Admin existant, e-mail confirmé** : aucune écriture, rc=0, message « existant, inchangé ». Un mot de passe changé dans l'appli est conservé.
- **Admin existant, e-mail non confirmé** : rc=1, message sans secret, rien modifié (SPEC-003.11).

**`db.sh promote-admin`** : idempotent en l'état, pas de correction nécessaire. L'`UPDATE` porte sur la même ligne, le `returning p.id` compte donc exactement 1 ligne même si l'admin est déjà promu, et rc=0. Le `|| true` sur le pipeline ne masque rien : une erreur psql donne `nb=0`, donc sortie en échec.

**Vérifications**
- `python3 -I -m py_compile tools/deploy/seed.py` : OK.
- `bash -n tools/deploy/db.sh` : OK.
- `./dev build` : les trois images sont construites (`app:dev`, `runner:dev`, `client:dev`). Aucun conteneur de la pile touché.
- `./dev policies` : rc=1, 17 respectées, 3 violées (`results.json` mis à jour). Aucune n'est liée au seed :
  - `ENV-images-epinglees` : `stack/compose.service.yml`, service `app` en `devenv/app:service`, non épinglée.
  - `ENV-secrets-valeurs-absentes` : `iterations/002/tests/junit.xml` contient `ADMIN_PASSWORD` et `JWT_SECRET` en clair. C'est un artefact de test, à corriger côté `testeur` ou `action`.
  - `STACK-ports` : `app` non publié sur `127.0.0.1`. À arbitrer avec ADR-007 (publication LAN).

**Points à valider au premier deploy (non testés, je n'ai pas lancé le seed)**
- Le seed suppose que GoTrue v2.170.0 renvoie `email_confirmed_at` dans `GET /admin/users` (fallback `confirmed_at`). Si ce champ manque, un admin confirmé serait refusé à tort, et le déploiement bloquerait. À vérifier sur la première réponse réelle.
- Le seed amendé doit être déployé alors que la base contient encore le mot de passe du fichier : tout changement fait depuis le dernier `deploy` a déjà été écrasé (ADR-012, « Ordre de déploiement »). Le chef de projet doit le savoir avant la levée du gel.
- Les tests SPEC-003.5, 003.10, 003.11 (`tests/test_003_admin.py`) et la policy « seed sans PUT/PATCH/DELETE hors branche de création » restent à écrire par `testeur` et `policy`.
