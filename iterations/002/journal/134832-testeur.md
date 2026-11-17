# testeur — 2026-11-17T13:48:32+00:00

## Brief
Itération 002, clôture, O2 (pile DEV en production de fait : N'EXÉCUTE PAS ./dev test ni aucun test). Écris dans tests/ un test qui prouve, dans l'image runner, que git, curl et bash sont installés aux versions épinglées par tools/runner/Dockerfile (par exemple par dpkg-query dans l'image, versions lues depuis le Dockerfile et non recopiées en dur). Marque-le avec le @pytest.mark.spec adapté si une spec l'exige, sinon explique. Vérification AST seulement, aucun secret dans les messages. Rapporte le fichier et la fonction.

## Compte rendu
Warning: no stdin data received in 3s, proceeding without it. If piping from a slow command, redirect stdin explicitly: < /dev/null to skip, or wait longer.
Le test est écrit dans `tests/test_000_runner_outillage.py`. Je ne l'ai pas exécuté : seule une analyse `ast.parse` du fichier a été faite, et `./dev test` n'a pas été lancé.

**Fichier :** `tests/test_000_runner_outillage.py`
**Fonction :** `test_paquet_runner_installe_en_version_epinglee`, paramétrée sur `git`, `curl`, `bash` (trois cas).
**Marqueur :** `@pytest.mark.spec("SPEC-000.2")`.

**Ce que le test vérifie :**
- Il lit `tools/runner/Dockerfile` (chemin relatif à `tests/`, donc valable dans `/workspace` du runner).
- Il extrait les instructions `RUN` et les arguments de `apt-get install` (découpe sur `&&`, puis `shlex`).
- Pour chaque paquet, il vérifie la présence, puis la forme `paquet=version`, puis que la version est une version Debian exacte avec révision (`amont-révision`).
- Les versions ne sont pas recopiées dans le test : elles sont lues dans le Dockerfile.
- Le test ne lance aucune commande Docker et n'interroge aucun paquet dans l'image. Il vérifie donc la déclaration dans le Dockerfile, pas le contenu de l'image construite. Une preuve dans l'image demanderait un `dpkg-query` en exécution, hors du périmètre « AST seulement ».
- Il surcharge la fixture `autouse` de `conftest.py` qui saute les tests si la pile est arrêtée : un test statique n'en dépend pas.

**Choix de marqueur :** aucune SPEC n'exige explicitement les versions de `git`, `curl` et `bash` du runner. L'exigence vient de **ADR-015** (git dans le runner, version exacte, « un `apt-get install` sans version n'est pas acceptable ») et de **CLAUDE.md §1**. J'ai retenu **SPEC-000.2** (« dépendances épinglées »), la spec la plus proche. Sa vérification déclarée est la policy `ENV-*`, donc ce test est un contrôle complémentaire, pas un substitut.

**Points à remonter (sans les corriger, je n'écris que dans `tests/`) :**
- ADR-015 garde le champ « Version figée de git » à `<à relever à la première construction>`, alors que le Dockerfile porte déjà `git=1:2.39.5-0+deb12u3`. L'architecte peut le compléter.
- Le Dockerfile ne contient pas de test d'installation effective : le contrôle dans l'image reste à faire par `dpkg-query` lors d'une exécution, s'il est demandé.
