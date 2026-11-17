# testeur — 2026-11-17T13:48:32+00:00

## Brief
Itération 002, clôture, O2 (pile DEV en production de fait : N'EXÉCUTE PAS ./dev test ni aucun test). Écris dans tests/ un test qui prouve, dans l'image runner, que git, curl et bash sont installés aux versions épinglées par tools/runner/Dockerfile (par exemple par dpkg-query dans l'image, versions lues depuis le Dockerfile et non recopiées en dur). Marque-le avec le @pytest.mark.spec adapté si une spec l'exige, sinon explique. Vérification AST seulement, aucun secret dans les messages. Rapporte le fichier et la fonction.

## Compte rendu
