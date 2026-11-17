# testeur — 2026-11-17T13:20:25+00:00

## Brief
Itération 002, tour 2, partie 7 (pile DEV gelée : N'EXÉCUTE PAS ./dev test ni aucun test, ne touche pas à la pile). Écris dans tests/ le stub GoTrue pour SPEC-003.10 (ADR-012 : le seed ne réécrit plus le mot de passe admin ; il refuse, rc=1, sans rien modifier, un admin existant non confirmé ; il lit email_confirmed_at, ou à défaut confirmed_at, dans GET /admin/users). Lis SPEC-003 et ADR-012 d'abord. Aucun secret dans les messages, repr ou ids (voir les règles de masquage de conftest.py). Vérifie par AST seulement et rapporte les fichiers et fonctions ajoutés.

## Compte rendu
Stub GoTrue et tests SPEC-003.10 écrits dans `tests/`. Rien n'a été exécuté : ni `./dev test`, ni aucun test, ni la pile. La vérification est uniquement par AST, et elle passe.

**Fichiers**

- `tests/stub_gotrue.py` (nouveau)
  - `class StubGoTrue` : serveur HTTP sur 127.0.0.1 (port éphémère), gestionnaire de contexte. Méthodes : `__init__`, `url`, `ecritures`, `hors_attendu`, `__enter__`, `__exit__`, `_gestionnaire`.
    - `GET /health` → 200 ; `GET /admin/users` → liste fournie ; `POST /admin/users` → 201 (seule écriture admise) ; tout le reste → 405, et tout est enregistré.
  - `environnement_factice()` : e-mail en `@test.invalid`, mot de passe et clé factices, générés à chaque appel. Rien n'est lu dans le fichier de secrets.
  - `compte(email, confirme=True, champ="email_confirmed_at")` : entrée de `GET /admin/users`. Le paramètre `champ` permet le repli `confirmed_at` (utile pour SPEC-003.11).
  - `lancer_seed(url, env)` : exécute `tools/deploy/seed.py` avec `sys.executable` et un environnement minimal pointant sur le stub.
- `tests/test_003_admin.py` (modifié) : deux lignes d'import ajoutées (`masquer` depuis conftest, et les helpers du stub), puis 3 fonctions de test, toutes marquées `@pytest.mark.spec("SPEC-003.10")` :
  - `test_seed_compte_existant_confirme_rc0_sans_aucune_ecriture` : rc=0, zéro écriture, zéro requête hors `GET /health` et `GET /admin/users`.
  - `test_seed_rejoue_n_fois_sur_compte_existant_sans_ecriture` : trois passages successifs, rc=0 à chaque fois, zéro écriture cumulée.
  - `test_seed_compte_absent_cree_par_post_seul_sans_put_ni_patch_ni_delete` : témoin positif, un seul `POST /admin/users` et aucune autre écriture. Il prouve que le stub détecte bien les écritures.

**Contrôles AST**

- Les deux fichiers se parsent.
- Aucun doublon de fonction.
- Les 3 tests portent le marqueur SPEC-003.10.

**Points à signaler**

1. **Couverture** : SPEC-003.10 est couverte. SPEC-003.11 (compte non confirmé, rc≠0) ne l'est pas encore : le stub sait déjà produire ce cas avec `compte(confirme=False)`, mais aucun test ne l'utilise.
2. **Skip de conftest** : le fixture autouse `_skip_si_pile_arretee` de `conftest.py` s'applique aussi à ces tests. Ils seront donc « skip » si `APP_URL` est injoignable, alors qu'ils n'en ont pas besoin. Je n'ai pas modifié `conftest.py` (hors de mon périmètre). Si le chef de projet veut que ces tests tournent sans pile, il faudra un choix sur ce point.
3. **Point ouvert d'ADR-012** : le nom réel du champ de confirmation de GoTrue v2.170.0 n'est pas vérifié. Le stub reproduit `email_confirmed_at`, comme prévu par l'ADR. Seule la recette `[R]` le confirmera.
4. **Masquage** : les messages d'assertion ne contiennent que des codes retour et des compteurs. Les sorties du seed passent par `masquer()`. Aucune valeur, aucun identifiant de compte, aucun e-mail n'apparaît dans les assertions.
