# ADR-010 — Vulnérabilités npm transitives de `app/web` : évaluation et décision

Statut : **accepté, partiellement tranché** (itération 002, tour 2, arbitrage du chef de projet, 2026-11-17).

- **esbuild** (GHSA-67mh-4wv8-2f99) : **cas A**, accepté, **non bloquant**.
- **auth-js / supabase-js** (GHSA-8r88-6cj9-9fh5) : **cas C provisoire** (preuve de non-appel absente). **Bloquant pour
  `./dev deploy service` uniquement** ; non bloquant pour la pile `dev` ni pour la recette `dev` de l'itération 002.

Specs touchées : SPEC-001.15 (d ajouté), SPEC-006 §2 (CA-002-1, CA-002-9, CA-002-36) et §3 (policy n° 25).
Complète ADR-002 (dépendances épinglées).

## Contexte

- **Identifiants** : relevés par le développeur dans `iterations/002/journal/123343-developpeur.md` (sortie
  `npm audit --json` via le wrapper toolbox). Le journal `122914` indiquait un refus de `docker run` ; le relevé de
  `123343`, postérieur, est retenu. C'est un relevé, **pas encore une preuve exécutable** : la policy n° 25 doit le rejouer
  et le consigner dans `iterations/002/policies/` (condition C1).
- **Texte des avis** : absent du dépôt. `npm audit --json` ne donne que titre, CWE, CVSS, plage et correctif.
- **Correction de contexte** : `esbuild` est une dépendance **directe de développement** (`devDependencies` de
  `app/web/package.json`) et figure parmi les avis. Le contexte initial (« non transitive ») ne s'applique qu'à sa nature
  de dépendance, pas à sa présence dans l'audit.

| # | Identifiant | Paquet (version de l'arbre) | Dépendance | Sévérité, CVSS, CWE | Plage vulnérable | Correctif | Cas |
|---|---|---|---|---|---|---|---|
| 1 | GHSA-67mh-4wv8-2f99 | `esbuild` 0.24.2 | directe, `devDependencies` | modérée, 5.3, CWE-346 | ≤ 0.24.2 | 0.28.2 (**majeure**) | **A** |
| 2 | GHSA-8r88-6cj9-9fh5 | `@supabase/auth-js` 2.67.3 | transitive de `@supabase/supabase-js` 2.47.10 | faible, CVSS 0, CWE-22 | ≤ 2.69.1 | via `supabase-js` 2.119.0 (pas de majeure, déclaré par npm) | **C provisoire** |
| — | (entrée npm dérivée de la 2, **pas un identifiant distinct**) | `@supabase/supabase-js` 2.47.10 | directe, `dependencies` | faible | 2.41.1 – 2.49.10 | 2.119.0 | même décision que la 2 |

Un CVSS 0 est la valeur déclarée par la source ; il ne vaut pas preuve d'absence de risque.

## Preuve d'usage — esbuild (cas A)

Faits vérifiés (lecture seule, architecte) :
- `app/Dockerfile`, étape `build` : `npm ci` puis `npm run build`. L'image servie (`nginx:1.27.3-alpine`) ne reçoit que
  `dist/`. Aucun port n'est exposé par l'étape de build.
- `app/web/package.json` : `"build": "node build.mjs"`.
- `app/web/build.mjs` n'utilise que `build()` de l'API esbuild. **Aucune occurrence** de `serve`, `watch`, `context(` ni
  `createServer` dans `app/` (recherche sur tout le répertoire).

Analyse : l'avis vise le **serveur de développement** d'esbuild, qui répond à des requêtes HTTP et dont la réponse est
lisible par un site tiers. Ce serveur n'est **jamais démarré** : ni pendant le build, ni dans l'image livrée. La condition
d'exposition de l'avis n'est pas réalisée. Classe **A**.

Réserve : l'ajout de `serve`, `watch` ou `context` dans le build, ou un outil de développement front qui lance esbuild en
serveur, fait basculer l'avis en **C** et impose une réévaluation. Contrôle recommandé à la policy n° 25 : recherche de ces
motifs dans `app/web/build.mjs` (non bloquant).

**Montée d'esbuild vers 0.28.2 : à demander au chef de projet pour l'itération 003. Non bloquante.** C'est une version
majeure : elle se traite comme une nouvelle décision (API de build, `metafile`, `target`, `define`, `legalComments` à
revalider ; recette : `./dev build` puis `./dev policies`). Le cas A ne la rend pas urgente.

## Preuve d'usage — auth-js / supabase-js (cas C provisoire)

Faits vérifiés (lecture de `app/web/src/app.js`) :
- Appels d'authentification : `sb.auth.getSession()` (l. 87), `signInWithPassword` (l. 182), `signUp` avec
  `options.data` (l. 216), `signOut` (l. 163 et 233).
- Client : `persistSession: true`, `autoRefreshToken: true` (l. 6 à 8) : rafraîchissement automatique du jeton, donc
  appel interne de auth-js en arrière-plan.
- Les saisies utilisateur (e-mail, mot de passe, nom affiché) sont passées en **paramètres de corps** d'appel, pas dans
  un chemin d'URL construit par l'application.
- `app.js` n'appelle **pas** l'API admin, la MFA, l'OAuth, la réinitialisation de mot de passe, ni `getUserById` /
  `updateUserById`.

Ce que la preuve **n'établit pas** :
- Le texte de GHSA-8r88-6cj9-9fh5 n'est pas dans le dépôt : on ignore le **module et la fonction** visés. Le titre
  « Insecure Path Routing from Malformed User Input » (CWE-22) évoque une construction de chemin à partir d'une entrée non
  filtrée. Si la fonction visée prend un identifiant dans le chemin (type admin ou MFA), elle n'est pas appelée. Si elle
  fait partie de `signInWithPassword`, `signUp`, `getSession`, `signOut` ou du rafraîchissement, elle est atteignable. On ne
  peut pas trancher sans le texte.
- Le code de `@supabase/auth-js` 2.67.3 n'a pas été lu (`node_modules` absent du dépôt).

**Classement : C provisoire.** La règle de pré-classement fait de auth-js un cas C sauf preuve de non-appel. Ce n'est pas
une présomption d'exploitabilité : c'est l'absence de preuve.

**Portée du blocage** : la pile `dev` est jetable, réservée à l'équipe, et déjà en service (`mise-en-service.md`). La pile
`service` est destinée à être exposée (US-17). Le blocage ne porte donc que sur `./dev deploy service` (ADR-010 §3). La
recette `dev` de l'itération 002 n'est pas bloquée. CA-002-36 reste **non confirmé** tant que le blocage n'est pas levé.

**Levée** : une des trois voies, consignée dans cet ADR avant tout `deploy service`.

1. **Voie 1 — preuve de non-appel, classement B** (recommandée, coût faible).
   (a) Le chef de projet lit le texte de GHSA-8r88-6cj9-9fh5 (source externe au dépôt) et indique le module et la
   fonction visés. (b) `action` ou `policy` vérifie, en lecture seule dans `node:22.12.0-alpine` (aucun réseau hors
   registre), que cette fonction n'est ni appelée par `app.js`, ni atteignable depuis les fonctions utilisées de
   `supabase-js` tel que bundlé (metafile, condition C2). Si oui : classement B consigné, réévaluation si `app.js` ajoute un
   appel.
2. **Voie 2 — montée** : `@supabase/supabase-js` de 2.47.10 vers **2.119.0** (version exacte, nouvelle décision). Effets :
   nouveau bundle ; recette des parcours d'authentification (CA-002-5, 6, 7, 10, 12) ; amendement de **SPEC-001.8 (b)** et
   de **SPEC-006 §3 item 2**, qui écrivent la version 2.47.10 en dur ; amendement d'ADR-002 et de la policy 2. Non faite ici.
3. **Voie 3 — acceptation écrite du risque** par le chef de projet (motif et date consignés ici). L'architecte
   n'accorde pas cette acceptation.

**Recommandation de l'architecte** : voie 1 d'abord. Si elle ne peut pas aboutir avant la mise en service de `service`,
la voie 2 devient **bloquante** pour `deploy service`, de préférence à la voie 3, car la pile `service` a vocation à être
exposée. **Pas de montée d'office** : la décision appartient au chef de projet.

## Décision

1. **Aucune mise à jour** dans cette itération. Pas de `npm audit fix`, pas d'`overrides`, pas de plage de version. Les
   versions de `package.json` et `package-lock.json` restent celles de SPEC-006 §3.
2. **GHSA-67mh-4wv8-2f99 (esbuild) : cas A, accepté, non bloquant.** Montée 0.28.2 : à demander au chef de projet pour
   l'itération 003.
3. **GHSA-8r88-6cj9-9fh5 (auth-js, et entrée dérivée supabase-js) : cas C provisoire.** Bloque `./dev deploy service`
   jusqu'à levée par la voie 1, 2 ou 3. Ne bloque ni la pile `dev`, ni la recette `dev` de l'itération 002.
4. **Montée de supabase-js** : non décidée. Bloquante pour `deploy service` si la voie 1 n'aboutit pas et que le chef
   de projet choisit la voie 2 ; sinon, à traiter à l'itération 003.
5. **Contrôle continu** : policy **n° 25** `FRONT-audit-npm` (SPEC-001.15 (b), SPEC-006 §3). Numéro réservé le
   2026-11-17 (premier libre dans `policies/checks/`). L'ancien « 13 » est occupé par `13-gw-admin-bloque.sh`. Identifiants
   attendus : `GHSA-67mh-4wv8-2f99` et `GHSA-8r88-6cj9-9fh5`. Échec si un identifiant n'est pas listé ici, ou si la
   sévérité est haute ou critique. Si le registre est injoignable : statut « non exécutée », jamais « réussie ».

## Conditions pour que la décision tienne

- **C1 — Identifiants** : relevés (journal `123343`). **Partiel** : preuve exécutable à produire par la policy n° 25
  dans `iterations/002/policies/`.
- **C2 — Metafile reproductible** : `./dev build` produit `meta/vendor-metafile.json` (hors `dist/`, donc hors image).
  La policy ou le testeur vérifie que `ws/browser.js` et `@supabase/node-fetch/browser.js` sont les seuls paquets Node-only
  du bundle, et que `whatwg-url`, `tr46`, `webidl-conversions`, `esbuild` n'y figurent pas. **Non fait.**
- **C3 — Non-ouverture de WebSocket** : nécessaire seulement pour classer `realtime-js` en B conditionnel. Sans effet sur
  les décisions de cet ADR. **Non fait.**
- **C4 — esbuild build seul** : constat statique fait ici (Dockerfile, `build.mjs`, grep). À rejouer par la policy n° 25
  avec C2.
- **C5 — auth-js (nouvelle)** : voie 1 réalisée, ou voie 2 ou 3 consignée ici. **Non remplie.** Bloque `deploy service`.

## Conséquences

- Le front reste à `@supabase/supabase-js@2.47.10` : aucun changement fonctionnel.
- Les avis restent visibles, datés et relevés à chaque itération (policy n° 25).
- Le blocage est limité à la pile `service` : la recette `dev` n'est pas retardée.
- Si `app.js` ajoute un appel auth non listé (admin, MFA, réinitialisation, OAuth), ou si esbuild démarre un serveur,
  réévaluation obligatoire de A et de C.
- Toute montée de supabase-js impose d'amender SPEC-001.8 (b), SPEC-006 §3 item 2, ADR-002 et la policy 2 (non fait ici).

## Alternatives écartées

- **`npm audit fix` ou `overrides` maintenant** : modifie le lock sans savoir quels paquets sont en cause, hors règle
  « versions épinglées ».
- **Ignorer l'audit** : la policy rend l'acceptation explicite et datée.
- **Montée esbuild 0.28.2 dans cette itération** : version majeure pour un avis de cas A, sans bénéfice pour le build.
- **Accepter auth-js d'office** : décision du chef de projet, pas de l'architecte (voie 3).
- **Retirer supabase-js** : hors périmètre (ADR-002).

## Points ouverts

1. **Chef de projet** : lire GHSA-8r88-6cj9-9fh5 et indiquer la fonction visée (voie 1), ou choisir la voie 2 ou 3.
2. **Chef de projet** : inscrire la montée d'esbuild 0.28.2 au périmètre de l'itération 003 (recommandé).
3. **Policy** : écrire et exécuter la policy n° 25 (identifiants, metafile, recherche de `serve`/`watch`/`context(`).
4. **Divergence de sources** : `122914` (refus de `docker run`) et `123343` (`npm audit` réussi via le wrapper). Rejouer
   le relevé par la policy n° 25 pour que la preuve soit unique.
