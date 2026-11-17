# architecte — 2026-11-17T13:18:49+00:00

## Brief
Itération 002, tour 3. Écris uniquement dans specs/. Le product-owner relève que SPEC-003.10 prévoit dans sa vérification [T] un ./dev deploy sans reset, alors que deploy est réservé au responsable applicatif (SPEC-004.6) et que la pile dev est gelée. Remplace ce passage par une vérification réalisable par le testeur sans deploy (par exemple appel direct de tools/deploy/seed.py contre une pile de test, ou vérification statique [P] de seed.py : aucun PUT/PATCH/DELETE ; ou [R] au premier deploy par le responsable applicatif), dis pour chaque point de 003.10 à 003.12 quel marqueur ([T], [P], [R]) s'applique. Note aussi dans l'ADR-012 : GoTrue v2.170.0 doit renvoyer email_confirmed_at dans GET /admin/users (repli confirmed_at), à vérifier à la première réponse réelle. Compte rendu très court.

## Compte rendu
Tour 3 mis à jour dans `specs/`. Rien d'autre n'a été touché.

**Marqueurs de SPEC-003.10 à 003.12**
- **003.10** : **[T]** (stub GoTrue local, `seed.py` lancé seul, sans deploy ni reset) + **[P]** (policy sur `seed.py`) + **[R]** (changement de mot de passe puis deploy sans reset, sur la pile réelle à la levée du gel).
- **003.11** : **[T]** uniquement (stub sans confirmation, rc≠0, aucune écriture ; cas de repli `confirmed_at`).
- **003.12** : **[P]** (grep `secrets` dans `seed.py`) + **[R]** (relecture, et `reset` + deploy avec login `ADMIN_PASSWORD`). Pas de [T] : le login exige une vraie base.

**ADR-012** : ajout du point à vérifier. GoTrue v2.170.0 doit renvoyer `email_confirmed_at` dans `GET /admin/users` (repli `confirmed_at`). À vérifier à la première réponse réelle, en recette [R].

Index `specs/README.md` mis à jour pour la ligne ADR-012.

Note : `seed.py` lit déjà `GOTRUE_URL` et n'emploie que GET et POST, ce qui rend le stub possible. Je n'ai pas vérifié le code de `seed.py` au-delà de cette lecture.
