# testeur — 2026-11-17T12:33:54+00:00

## Brief
Itération 002, tour 2, partie 3. Fixe le numéro de passe <N> des comptes de recette recette-1..4-<N>@test.invalid pour la recette client : choisis un N qui ne collisionne avec aucun compte existant ni avec ceux créés par ./dev test (vérifie dans la base sans afficher d'e-mails ni de secrets). Écris-le dans iterations/002/tests/passe-recette.md avec les 4 identifiants de compte de recette attendus (sans mot de passe). Réponds par ce N. Ajoute à ton observation : y a-t-il une connexion WebSocket (realtime-js) au chargement de la page, avec erreur visible ou non ? Ne touche pas à la pile.

## Compte rendu
Warning: no stdin data received in 3s, proceeding without it. If piping from a slow command, redirect stdin explicitly: < /dev/null to skip, or wait longer.
**N = 1.**

Le fichier est écrit : `iterations/002/tests/passe-recette.md`. Les identifiants attendus sont `recette-1-1@test.invalid`, `recette-2-1@test.invalid`, `recette-3-1@test.invalid` et `recette-4-1@test.invalid`, sans mot de passe. Le compte 4 ne doit exister qu'après la tentative refusée de l'étape 3 : il ne doit pas exister à l'étape 5.

**Vérifications de collision** (lecture seule dans la base, sans afficher d'e-mail ni de secret) :
- aucun compte `recette-*` n'existe ;
- aucun profil au nom « Recette… » ;
- les comptes `@test.invalid` existants ont les préfixes `t-` (181, créés par `./dev test`) et `persist-` (1, passe de persistance). Ils ne peuvent pas collisionner avec `recette-<k>-<N>` ;
- aucune passe de recette antérieure n'est consignée dans les journaux.

**Observation, connexion WebSocket (realtime-js) au chargement :**
- **Non prouvée à l'exécution.** Je n'ai pas observé le trafic réseau du navigateur : le conteneur `runner` n'a pas de navigateur, et la recette navigateur relève du `client`. La condition C3 de l'ADR-010 reste ouverte.
- **D'après le code, probablement absente.** Le bundle `/vendor/supabase.js` contient le client realtime-js et `app.js` le charge, mais `app.js` n'appelle ni `channel(` ni `subscribe(`. realtime-js ne se connecte qu'à la première souscription.
- **Si elle était tentée, elle échouerait.** Il n'existe aucun service Realtime dans la pile, la CSP est `connect-src 'self'`, et la passerelle ne route aucun chemin realtime. L'échec serait une erreur de console du navigateur, sans message à l'écran.
- **Verdict :** pas d'erreur visible à l'écran attendue ; présence d'une WebSocket au chargement non établie, probablement absente.

Pile non touchée : seules des lectures (SELECT et GET HTTP) ont été faites.
