# testeur — 2026-11-17T13:50:07+00:00

## Brief
Itération 002, clôture, O2 (suite ; pile DEV en production de fait : N'EXÉCUTE PAS ./dev test ni aucun test). Ton test statique ne prouve que la déclaration du Dockerfile. Structure demande une preuve que le runner CONTIENT les versions épinglées. Le test s'exécute dans le conteneur runner, dont l'image est précisément celle à prouver : complète tests/test_000_runner_outillage.py avec un second test qui lance dpkg-query -W -f='${Version}' <paquet> localement (subprocess, sans docker) pour git, curl et bash et compare à la version lue dans tools/runner/Dockerfile (jamais recopiée en dur). Si dpkg-query est absent (exécution hors runner), le test doit être ignoré avec une raison explicite, sans masquer un échec. Marque-le comme le premier. Vérification AST seulement, aucun secret.

## Compte rendu
Warning: no stdin data received in 3s, proceeding without it. If piping from a slow command, redirect stdin explicitly: < /dev/null to skip, or wait longer.
Le second test est ajouté dans `tests/test_000_runner_outillage.py`, en tête de fichier. Je ne l'ai pas exécuté : pytest n'a pas été lancé, conformément à la consigne (pile DEV en production de fait). Seule une vérification AST a été faite.

**Ce qui a été ajouté**

- `test_paquet_installee_dans_le_runner_a_la_version_epinglee`, paramétré sur `git`, `curl`, `bash`, marqué `SPEC-000.2`, placé en premier dans le module.
- Il lance `dpkg-query -W -f=${Version} <paquet>` via `subprocess` (liste d'arguments, sans shell, sans Docker).
- La version attendue est lue dans `tools/runner/Dockerfile` par la fonction `version_epinglee_dockerfile`, qui réutilise l'analyse existante (`instructions`, `paquets_apt_installes`, `epinglage`). Aucune version n'est recopiée en dur.
- Si `dpkg-query` est absent (`shutil.which` renvoie `None`), le test est ignoré avec la raison « exécution hors conteneur runner (Debian) ». Un paquet absent (rc ≠ 0) ou une version différente fait échouer le test, sans être masqué.
- Le test statique existant est inchangé en comportement. Son helper a été extrait dans `version_epinglee_dockerfile`. La docstring du module a été corrigée : elle affirmait qu'aucun paquet n'était interrogé.

**Vérification AST (sans exécution)**

Le fichier se parse correctement. L'ordre des fonctions de test et leurs marqueurs sont conformes : le premier test du module est `test_paquet_installee_dans_le_runner_a_la_version_epinglee`, puis le statique.

**Points à savoir**

- Le résultat réel n'existe pas encore : aucun `iterations/002/tests/` n'a été produit, et aucun résultat pytest n'est établi. Le test ne prouvera quelque chose que lorsqu'il sera exécuté dans le conteneur `runner` (via `./dev test`, à la main du responsable applicatif ou à la reprise de la pile).
- La matrice SPEC → test → résultat reste à produire à ce moment-là. Je n'ai pas vérifié non plus que les autres specs disposent d'un test automatique.
- Aucun secret n'est manipulé.
