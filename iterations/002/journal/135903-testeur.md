# testeur — 2026-11-17T13:59:03+00:00

## Brief
Itération 002, fin d'itération, étape c. Dev n'est plus en production : tu PEUX lancer ./dev test complet sur dev (jamais sur service). Inclus les tests de SPEC-001.14 (rafale et 429), SPEC-003.10 et les deux tests de versions du runner (statique et dpkg-query). Écris le rapport dans iterations/002/tests/ (matrice SPEC → test → résultat, échecs avec causes probables, écarts, nombre d'inscriptions de la passe par rapport au plafond de 220, résultat des preuves de versions git, curl, bash). Aucun secret ni e-mail dans les rapports, junit.xml et resultat.txt ; vérifie par recherche que ADMIN_PASSWORD et JWT_SECRET n'y figurent pas. Ne démarre, n'arrête ni ne reconstruis la pile.

## Compte rendu
Passe complète sur `dev` faite : **197 tests, 192 réussis, 1 échec, 4 ignorés**. Le rapport est dans `iterations/002/tests/rapport-testeur.md` (avec `resultat.txt` et `junit.xml`). La pile n'a été ni démarrée, ni arrêtée, ni reconstruite.

**Échec : SPEC-003.9** (`test_seul_admin_email_hors_comptes_de_test`). Le test trouve 8 comptes hors `@test.invalid` sur `dev`, alors que la spec n'admet que `ADMIN_EMAIL`. La cause probable est l'état des données, pas le code : ces 8 comptes réels sont présents sur `dev` depuis l'équivalence dev/service (cf. `mise-en-service.md` §6), et la spec suppose une pile fraîche (reset + deploy), que je ne peux pas faire ici. C'est à trancher par l'architecte ou le responsable applicatif.

**Specs `[T]` sans test ou non exécutées :**
- SPEC-003.11 et SPEC-003.12 : aucun test marqué. Écart à combler.
- SPEC-004.13 : partiel, il dépend de 003.11.
- SPEC-004.2 : non exécuté, il demande un reset interdit sur `dev`.
- SPEC-004.3 : relire ignoré en passe finale (pas de deploy depuis l'écriture du jeu). Il était vert en passe précédente.
- SPEC-004.7 et 004.8 : pile `service` seule, ignorées comme prévu.
- SPEC-005.11 et 005.12 : couvertes seulement indirectement, par 001.11 et 002.3.

**SPEC-001.14 :** `test_inscriptions_en_rafale` et `test_aucune_reponse_429` passent. La passe finale compte 202 inscriptions (plafond 220) et 0 réponse 429. Le journal de la passerelle donne ce chiffre ; la passe n'affiche pas son propre compteur.

**SPEC-003.10 :** les trois tests passent.

**Versions du runner :** git `1:2.39.5-0+deb12u3`, curl `7.88.1-10+deb12u15`, bash `5.2.15-2+b13`. Les preuves `dpkg-query` (dans le runner) et statique (Dockerfile) passent pour les trois paquets. Les versions relevées par `dpkg-query` ne sont pas inscrites dans les sorties.

**Correction faite dans `tests/` :** le bloc d'échec affichait `ADMIN_EMAIL` en clair dans `resultat.txt` et `junit.xml`. J'ai ajouté le masquage des adresses e-mail dans `tests/conftest.py`, puis relancé la passe. Aucun autre code de test n'a changé.

**Confidentialité :** `ADMIN_PASSWORD` et `JWT_SECRET` n'apparaissent dans aucun fichier de `iterations/002/tests/`, et aucune adresse e-mail n'apparaît dans `resultat.txt`, `junit.xml` ni le rapport.

**Point ouvert :** `persistance-dev.json` contient une adresse `…@test.invalid` (champ `membre_email`), écrite par le test. Ce fichier n'est pas dans la liste des sorties à protéger, mais il est modifié par rapport à la version commitée. Le chef de projet doit trancher avant commit.
