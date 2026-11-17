# Itération 002 — Passe de recette client : numéro de passe des comptes de recette

- Rédigé par : `testeur` (équipe DevOps), 2026-11-17, tour 2, partie 3.
- Référence : `iterations/002/recette-client.md` (§0, comptes de recette).

## 1. Numéro de passe retenu

**N = 1**

Vérifications faites avant le choix (lecture seule dans la base `auth.users` du conteneur `devenv-db-1`,
aucun e-mail ni secret affiché) :

- aucun compte dont l'e-mail commence par `recette-` n'existe (0 compte, tous suffixes confondus) ;
- aucun profil `public.profiles` au nom affiché commençant par « Recette » ;
- les comptes `@test.invalid` existants ont pour préfixe `t-` (181, créés par `./dev test`) et `persist-` (1, passe
  de persistance de `test_004_piles`) : aucun ne peut collisionner avec `recette-<k>-<N>` ;
- aucune passe de recette antérieure n'est consignée dans `iterations/002/journal/` ni dans `iterations/001/`.

Effectif de la base au moment de la vérification : 183 comptes.

## 2. Comptes de recette attendus (sans mot de passe)

| Compte | Nom affiché | E-mail attendu | Statut attendu à l'étape 5 de la recette |
|---|---|---|---|
| 1 | Recette Un | `recette-1-1@test.invalid` | créé, puis activé par l'administrateur (étape 5) |
| 2 | Recette Deux | `recette-2-1@test.invalid` | créé, puis activé par l'administrateur (étape 5) |
| 3 | Recette Trois | `recette-3-1@test.invalid` | créé, **reste non activé** |
| 4 | — (non créé) | `recette-4-1@test.invalid` | **ne doit pas exister** : seule l'inscription refusée (étape 3) la tente |

Le mot de passe est choisi par le client, identique pour les comptes de recette (`recette-client.md` §0).

## 3. Observation : connexion WebSocket (realtime-js) au chargement

Question posée : une connexion WebSocket est-elle ouverte au chargement de la page, avec erreur visible ou non ?

Faits constatés (lecture seule : `GET` sur `http://10.77.0.25:8080/`, `/config.js`, `/app.js`, `/vendor/supabase.js`) :

- la page charge `config.js` et `app.js` ; `app.js` importe `createClient` depuis `/vendor/supabase.js` (bundle servi, 200) ;
- le bundle contient le client temps réel de `@supabase/realtime-js` (`RealtimeClient`, `channel`, `subscribe`, `new WebSocket`),
  instancié par `createClient` ; **`app.js` n'appelle ni `channel(` ni `subscribe(`** : aucun canal n'est souscrit au chargement ;
- la CSP servie est `connect-src 'self'` : seule une connexion vers la même origine est permise ;
- la pile ne contient **aucun service Realtime** (`stack/compose.yml` : db, auth, rest, app, plus outils) et la passerelle
  ne route aucun chemin `realtime` (recherche sans résultat dans `app/` et `stack/`).

Conclusion (**non établie à l'exécution**) : d'après le code, aucune connexion `ws://`/`wss://` n'est attendue au chargement,
car `realtime-js` ne se connecte qu'à la première souscription de canal. Je n'ai **pas** observé le trafic réseau du
navigateur : aucun outil de navigateur n'est disponible dans le conteneur `runner` et la recette navigateur appartient
au `client` (condition C3 de `specs/adr/ADR-010-vulnerabilites-npm-front.md`, toujours ouverte).
Si une connexion était tentée, elle échouerait (aucun service `realtime`, CSP et passerelle sans route) : l'échec
serait une erreur de **console** du navigateur, sans message affiché à l'écran.
Verdict : **pas d'erreur visible attendue à l'écran ; présence d'une WebSocket au chargement : non prouvée, probablement absente.**

## 4. Périmètre de ce tour

- Pile : **non touchée** (aucun `deploy`, `teardown`, `reset`, `build`). Seules des lectures ont été faites.
- Écrit dans `iterations/002/tests/` uniquement. Aucun mot de passe, secret ni e-mail réel affiché ou écrit.
