# developpeur — 2026-11-17T13:09:29+00:00

## Brief
Itération 002, tour 3 (préparation, GEL). dnum.lelabs.tech est relayée vers la pile DEV avec de vrais utilisateurs : aucun reset, teardown, deploy ni test ; ne touche à aucun conteneur en marche. Implémente en FRONT SEUL (app/web/, éventuellement app/nginx si nécessaire) les 4 retours de recette selon SPEC-005 (005.1, .5, .6, .7, .33, .40, .60, .62, .63 et section « Messages exacts » M-1 à M-6) et perimetre.md CA-002-27, 28, 34, 37, 38 : (1) messages de confirmation nommant le collègue et la tâche après « Demander de l'aide » et « Proposer mon aide », affichés une fois et survivant au rechargement ; (2) confirmation inline avant « Désactiver » (Confirmer / Annuler, focus sur Annuler, pas de window.confirm) ; (3) barre supérieure fixe (position: sticky; top: 0, hauteur ≤ 120 px, scroll-padding-top, lien d'évitement) ; (4) recherche côté client dans les listes admin (insensible casse et accents, multi-mots, message « Aucun compte ne correspond à la recherche »). AUCUNE migration SQL (ADR-011 : les migrations 001 à 005 sont figées et ne doivent pas être modifiées ; les RPC restent inchangées). Pas d'URL d'hôte, pas de localhost, pas de service_role, aucun appel .admin./getUserById/updateUserById/deleteUser/listFactors/deleteFactor dans app/web/src. Vérifie avec ./dev build puis ./dev policies, une commande par appel. Attention : ./dev build reconstruit les images devenv/*:dev ; ne recrée ni ne redémarre aucun conteneur. Compte rendu court : fichiers modifiés, specs couvertes, résultats de build et policies, points ouverts.

## Compte rendu
Front de l'itération 002 modifié et construit ; la pile n'a pas été touchée et le nouveau code n'est pas encore servi.

**Fichiers modifiés**
- `app/web/src/app.js`
- `app/web/style.css`

Aucune migration, aucun changement dans `stack/` ni `app/nginx`, aucun appel admin, aucun hôte ou localhost, aucune occurrence de `confirm(`.

**Specs couvertes (implémentées, non recettées)**
- **SPEC-005.7 / M-1, M-2, M-4** : confirmations « Proposition envoyée à {nom} pour la tâche « {titre} ». », « Demande d'aide envoyée à {nom} pour la tâche « {titre} ». » et « Le compte de {nom} est désactivé. ». Elles sont gardées en mémoire, rendues en `role="status"` en tête de page après le rechargement des données, puis effacées à la navigation. Le texte « Proposition envoyée. » a disparu.
- **SPEC-005.63 / M-3** : confirmation inline (`role="group"`, texte M-3, « Confirmer la désactivation » et « Annuler »). Le focus part sur « Annuler », Échap ferme, aucune modale native.
- **SPEC-005.62 / M-5, M-6** : deux champs `type="search"` hors formulaire, un par liste. Filtrage à chaque saisie, insensible à la casse et aux accents, multi-mots sur nom ou e-mail. Le terme est conservé pendant les actions.
- **SPEC-005.6** : `.entete` en `position: sticky; top: 0`, `max-height: 120px`, lien d'évitement au-dessus (`z-index`), `scroll-padding-top` (repli CSS 5.5 rem, puis mesure réelle par `ResizeObserver`).
- **SPEC-005.1, .5, .33, .40, .60** : libellés et comportements associés, rechargement de session conservé.

**Build** : `./dev build` vert. `devenv/app:dev`, `devenv/runner:dev` et `devenv/client:dev` reconstruites, aucun conteneur redémarré.

**Policies** : `./dev policies`, 17 respectées, 3 violées, aucune dans `app/web` :
- `ENV-secrets-valeurs-absentes` : **urgent**. `iterations/002/tests/junit.xml` (suivi par git) contient les valeurs de `ADMIN_PASSWORD` et `JWT_SECRET`. À purger, puis à évaluer pour rotation. Le fichier n'est pas de mon ressort.
- `ENV-images-epinglees` : `devenv/app:service` non épinglée dans `stack/compose.service.yml`. Préexistant.
- `STACK-ports` : `app` n'est pas publié sur `127.0.0.1`. Cela contredit la dérogation D1 (CA-002-1 réécrit). La policy est à mettre à jour.

Les policies `FRONT-messages-tour3` (n° 30) et `FRONT-barre-fixe` (n° 31) n'existent pas dans `policies/checks/` : elles ne sont pas exécutées. Vérification manuelle par grep : `confirm(` absent, « Proposition envoyée. » absent, `position: sticky` et `scroll-padding-top` présents.

**Points ouverts (pour arbitrage du chef de projet)**
1. **Message de recherche vide** : le brief dit « Aucun compte ne correspond à la recherche ». SPEC-005.62 (M-5/M-6) l'impose autrement. J'ai suivi la spec.
2. **Textes CA vs spec** : CA-002-27 et CA-002-34 donnent d'autres formulations (« Proposition d'aide envoyée… », « Confirmer / Annuler », « Désactiver ce compte ? »). J'ai suivi SPEC-005 M-1 à M-6 et les libellés de SPEC-005.63.
3. **« Survivant au rechargement »** : interprété comme rechargement des données, conformément à SPEC-005.7 (pas de stockage). Un F5 efface le message.
4. **« Réaffecter »** : toujours sans message de confirmation (point ouvert 1 de SPEC-005).
5. **Barre fixe** : sur une fenêtre très zoomée, la barre peut atteindre 120 px et défiler en interne (`overflow-y: auto`).
6. **Non recetté** : le build compile, mais aucun test à l'exécution ni capture ; la pile `dev` reste gelée et ne sert pas encore ce code.
