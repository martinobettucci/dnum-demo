# ADR-010 — Vulnérabilités npm transitives de `app/web` : évaluation et décision

Statut : **accepté, tranché** (itération 002, tour 2). Décision du chef de projet du 2026-11-17 : voie 1 retenue pour auth-js.

- **esbuild** (GHSA-67mh-4wv8-2f99) : **cas A**, accepté, **non bloquant**.
- **auth-js / supabase-js** (GHSA-8r88-6cj9-9fh5) : **cas A** (non applicable, accepté) par la voie 1. **Le blocage de
  `./dev deploy service` est levé**, sous condition de la policy n° 28 `FRONT-auth-js-non-appel` (SPEC-001.15 (e)).
  Le classement B initialement prévu par la voie 1 n'est pas retenu : le chef de projet tranche en A.

Specs touchées : SPEC-001.15 (b, d amendé, e ajouté), SPEC-006 §2 (CA-002-2, CA-002-36) et §3 (policies 25 et 28).
Tour 4 (mission du chef de projet, 2026-11-17) : contrôle continu de la policy 25 précisé par ADR-014 (audit hors runner) ;
garde esbuild : **tranché** (arbitrage du chef de projet, 2026-11-17, ADR-013 D-1) : note non bloquante, passage en violée si
occurrence de `serve`, `watch` ou `context(`, formule « cas C gardé ». Classement esbuild inchangé : cas A.
Complète ADR-002 (dépendances épinglées).

## Contexte

- **Identifiants** : relevés par le développeur dans `iterations/002/journal/123343-developpeur.md` (sortie
  `npm audit --json` via le wrapper toolbox). Le journal `122914` indiquait un refus de `docker run` ; le relevé de
  `123343`, postérieur, est retenu. C'est un relevé, **pas encore une preuve exécutable** : la policy n° 25 doit le rejouer
  et le consigner dans `iterations/002/policies/` (condition C1).
- **Texte des avis** : absent du dépôt. `npm audit --json` ne donne que titre, CWE, CVSS, plage et correctif. Le texte
  de GHSA-8r88-6cj9-9fh5 a été lu par le chef de projet (source externe au dépôt), voir ci-dessous.
- **Correction de contexte** : `esbuild` est une dépendance **directe de développement** (`devDependencies` de
  `app/web/package.json`) et figure parmi les avis. Le contexte initial (« non transitive ») ne s'applique qu'à sa nature
  de dépendance, pas à sa présence dans l'audit.

| # | Identifiant | Paquet (version de l'arbre) | Dépendance | Sévérité, CVSS, CWE | Plage vulnérable | Correctif | Cas |
|---|---|---|---|---|---|---|---|
| 1 | GHSA-67mh-4wv8-2f99 | `esbuild` 0.24.2 | directe, `devDependencies` | modérée, 5.3, CWE-346 | ≤ 0.24.2 | 0.28.2 (**majeure**) | **A** |
| 2 | GHSA-8r88-6cj9-9fh5 (CVE-2025-48370) | `@supabase/auth-js` 2.67.3 | transitive de `@supabase/supabase-js` 2.47.10 | faible, CVSS 0 relevé par npm ; CVSS v4 2,7 dans l'avis, CWE-22 | ≤ 2.69.1 | 2.70.0 | **A** (voie 1) |
| — | (entrée npm dérivée de la 2, **pas un identifiant distinct**) | `@supabase/supabase-js` 2.47.10 | directe, `dependencies` | faible | 2.41.1 – 2.49.10 | à fixer en itération 003 (auth-js ≥ 2.70.0) | même décision que la 2 |

Un CVSS 0 est la valeur déclarée par npm ; il ne vaut pas preuve d'absence de risque. La valeur de l'avis (CVSS v4 2,7)
est celle relevée par le chef de projet.

## Référence de l'avis — GHSA-8r88-6cj9-9fh5

- Référence : GHSA-8r88-6cj9-9fh5, CVE-2025-48370, CWE-22, CVSS v4 2,7. Affecte `@supabase/auth-js` ≤ 2.69.1 ;
  corrigé en **2.70.0**.
- Fonctions visées (indiquées par le chef de projet après lecture de l'avis) :
  `auth.admin.getUserById`, `auth.admin.deleteUser`, `auth.admin.updateUserById` (API admin) ;
  `auth.mfa.listFactors`, `auth.mfa.deleteFactor` (MFA).
- Faute : `userId` ou `factorId` non validés comme UUID, d'où une traversée de chemin dans l'URL construite par la
  bibliothèque.

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
serveur, fait basculer l'avis en **C** et impose une réévaluation.

**Garde esbuild, formule retenue : « cas C gardé » (arbitrage du chef de projet, 2026-11-17, ADR-013 D-1).**
- Le cas **A** reste valable **tant que** le build n'utilise ni `serve`, ni `watch`, ni `context`.
- La recherche de ces motifs dans `app/web/build.mjs` (policy n° 25, SPEC-001.15 (b)) est une **note non bloquante** tant
  qu'elle est négative.
- Si l'un de ces motifs apparaît, la policy n° 25 passe en **violée** : réévaluation obligatoire de GHSA-67mh-4wv8-2f99,
  avis en cas C. Tant que la réévaluation n'est pas consignée, `./dev deploy service` est bloqué (SPEC-001.15 (d)).
  La pile `dev` n'est pas soumise à ce blocage.

**Montée d'esbuild vers 0.28.x : prévue pour l'itération 003** (décision du chef de projet). C'est une version majeure :
elle se traite comme une nouvelle décision (API de build, `metafile`, `target`, `define`, `legalComments` à revalider ;
recette : `./dev build` puis `./dev policies`). Le cas A ne la rend pas urgente.

## Preuve d'usage — auth-js / supabase-js (cas A, voie 1)

Faits vérifiés (lecture de `app/web/src/app.js`) :
- Appels d'authentification : `sb.auth.getSession()`, `signInWithPassword`, `signUp` avec `options.data`, `signOut`.
  **Aucun autre appel** d'auth-js.
- Client : `persistSession: true`, `autoRefreshToken: true` : rafraîchissement automatique du jeton, appel interne de
  auth-js en arrière-plan. Ce rafraîchissement n'emploie aucune des cinq fonctions visées.
- Recherche statique (architecte, tour 2 complément) sur `app/` : **aucune occurrence** de `.admin.`, `getUserById`,
  `updateUserById`, `deleteUser`, `listFactors`, `deleteFactor`.
- Le front ne détient pas la clé `service_role` (SPEC-001.10) et la passerelle répond `403` à `/auth/v1/admin/*`
  (SPEC-001.7). Une fonction admin ne peut donc être appelée ni depuis le navigateur, ni via la passerelle.
- Les saisies utilisateur (e-mail, mot de passe, nom affiché) sont passées en **paramètres de corps** d'appel, pas dans
  un chemin d'URL construit par l'application.

Classement : **A** (non applicable, accepté). Les fonctions visées par l'avis ne sont pas appelées par l'application.

Divergence avec ADR-010 (version précédente) : la voie 1 prévoyait un classement **B** après vérification de non-appel
dans `node:22.12.0-alpine`. Le chef de projet retient **A** et s'appuie sur la policy n° 28, qui vérifie en continu
l'absence de ces appels dans `app/web/src`.

**Réserve (portée de la preuve)** : la policy n° 28 porte sur le code de `app/web/src`. Elle ne vérifie ni le bundle
`/vendor/supabase.js`, ni la chaîne d'appels interne de la bibliothèque. Si `supabase-js` bundlé atteignait une de ces
fonctions depuis un chemin utilisé par `app.js`, la décision serait à réévaluer. La preuve par metafile (C2) reste à
compléter pour lever ce point ; elle n'est pas une condition du classement A retenu.

## Décision

1. **Aucune mise à jour** dans cette itération. Pas de `npm audit fix`, pas d'`overrides`, pas de plage de version. Les
   versions de `package.json` et `package-lock.json` restent celles de SPEC-006 §3.
2. **GHSA-67mh-4wv8-2f99 (esbuild) : cas A, accepté, non bloquant.** Montée 0.28.x inscrite à l'itération 003.
3. **GHSA-8r88-6cj9-9fh5 (auth-js, et entrée dérivée supabase-js) : cas A par la voie 1, accepté.** Le blocage
   d'ADR-010 §3 de `./dev deploy service` est **levé**, sous condition : la policy n° 28 `FRONT-auth-js-non-appel`
   réussit avant la mise en service (SPEC-001.15 (e)). Si elle échoue, le blocage est rétabli et la décision réévaluée.
4. **Montée de supabase-js : itération 003.** Cible : `@supabase/supabase-js` dans une version dont auth-js est
   **≥ 2.70.0** (version exacte à fixer dans l'ADR de l'itération 003). Cette montée impose les amendements de
   SPEC-001.8 (b), SPEC-006 §3 item 2, ADR-002 et de la policy 2 (version 2.47.10 écrite en dur). Non faite dans
   l'itération 002. Elle est requise pour la recette de l'itération 003 (nouveau bundle, parcours d'authentification
   CA-002-5, 6, 7, 10, 12).
5. **Contrôle continu** : policy **n° 25** `FRONT-audit-npm` (SPEC-001.15 (b), SPEC-006 §3) et policy **n° 28**
   `FRONT-auth-js-non-appel` (SPEC-001.15 (e), SPEC-006 §3). Identifiants attendus par la 25 : `GHSA-67mh-4wv8-2f99` et
   `GHSA-8r88-6cj9-9fh5`. Échec si un identifiant n'est pas listé ici, ou si la sévérité est haute ou critique. Si le
   registre est injoignable : statut « non exécutée », jamais « réussie ».
   **Précisé (tour 4, ADR-014)** : le rapport est produit hors runner par `./dev audit-npm`, dans `iterations/<NNN>/policies/` :
   `audit-npm.json` (sortie brute) et `audit-npm.meta.json` (`statut`, sha256 de `package-lock.json`). La policy 25 vérifie le
   statut et le sha256 du lock ; le contrôle par date de modification est retiré. `BLOQUE_AUTHJS="non"` (ligne 17 de la policy).

## Conditions pour que la décision tienne

- **C1 — Identifiants** : relevés (journal `123343`). **Partiel** : preuve exécutable à produire par la policy n° 25
  dans `iterations/002/policies/`.
- **C2 — Metafile reproductible** : `./dev build` produit `meta/vendor-metafile.json` (hors `dist/`, donc hors image).
  La policy ou le testeur vérifie que `ws/browser.js` et `@supabase/node-fetch/browser.js` sont les seuls paquets Node-only
  du bundle, et que `whatwg-url`, `tr46`, `webidl-conversions`, `esbuild` n'y figurent pas. **Non fait.** Non bloquant pour
  le classement A de auth-js ; à compléter (réserve ci-dessus).
- **C3 — Non-ouverture de WebSocket** : nécessaire seulement pour classer `realtime-js` en B conditionnel. Sans effet sur
  les décisions de cet ADR. **Non fait.**
- **C4 — esbuild build seul** : constat statique fait ici (Dockerfile, `build.mjs`, grep). À rejouer par la policy n° 25
  avec C2.
- **C5 — auth-js** : **voie 1 retenue** par le chef de projet (tour 2, 2026-11-17), classement A. **Remplie sous réserve
  de la policy n° 28** : `deploy service` ne peut être lancé qu'après une exécution réussie de cette policy, consignée dans
  `mise-en-service.md`.

## Conséquences

- Le front reste à `@supabase/supabase-js@2.47.10` pendant l'itération 002 : aucun changement fonctionnel.
- La pile `dev` et la pile `service` ne sont plus bloquées par auth-js. `./dev deploy service` est conditionné au passage
  de la policy n° 28 (et de la policy n° 25 sans cas C).
- Les avis restent visibles, datés et relevés à chaque itération (policies 25 et 28).
- Si `app.js` ajoute un appel à l'une des fonctions visées (ou à `.admin.`, `listFactors`, `deleteFactor`, etc.),
  la policy 28 échoue : réévaluation obligatoire, blocage de `deploy service` rétabli.
- Si esbuild démarre un serveur (`serve`, `watch`, `context`), réévaluation obligatoire de GHSA-67mh-4wv8-2f99 (cas A → C).
- Itération 003 : montée supabase-js (auth-js ≥ 2.70.0) et esbuild 0.28.x ; amendements SPEC-001.8 (b), SPEC-006 §3
  item 2, ADR-002, policy 2 à produire dans ce cadre.

## Alternatives écartées

- **`npm audit fix` ou `overrides` maintenant** : modifie le lock sans savoir quels paquets sont en cause, hors règle
  « versions épinglées ».
- **Ignorer l'audit** : la policy rend l'acceptation explicite et datée.
- **Montée esbuild 0.28.x dans cette itération** : version majeure pour un avis de cas A, sans bénéfice pour le build.
  Reportée à l'itération 003.
- **Voie 2 (montée supabase-js 2.119.0 dans l'itération 002)** : écartée par le chef de projet ; la montée est reportée
  à l'itération 003 (auth-js ≥ 2.70.0).
- **Voie 3 (acceptation écrite du risque)** : non retenue ; la voie 1 suffit.
- **Retirer supabase-js** : hors périmètre (ADR-002).

## Points ouverts

1. **Chef de projet** : lever ou non la réserve de portée (C2, bundle) avant la recette de l'itération 003.
2. **Policy** : exécuter la policy n° 28 `FRONT-auth-js-non-appel` dans `iterations/002/policies/` avant tout `deploy service`.
   *(Tour 4 : résultat « respectée » relevé dans `results.json` lors de la réaction ; à réexécuter avant le déploiement.)*
3. **Policy** : exécuter la policy n° 25 (identifiants, metafile C2, recherche `serve`/`watch`/`context(`).
   *(Tour 4 : mécanisme retenu, ADR-014 (`./dev audit-npm` puis `./dev policies`). Exécution à faire.)*
4. **Divergence de sources** : `122914` (refus de `docker run`) et `123343` (`npm audit` réussi via le wrapper). Rejouer
   le relevé par la policy n° 25 pour que la preuve soit unique.
5. **Itération 003** : inscrire au périmètre la montée supabase-js (auth-js ≥ 2.70.0) et esbuild 0.28.x.
6. ~~**Garde esbuild (tour 4)**~~ **Clos** (arbitrage du chef de projet, 2026-11-17) : note non bloquante, formule « cas C
   gardé » (section ci-dessus, ADR-013 D-1). Aucun point ouvert sur esbuild.

## Historique

- Tour 2, état initial : auth-js en cas C provisoire, bloquant pour `deploy service` (preuve de non-appel absente).
- Tour 2, arbitrage 2026-11-17 (premier) : esbuild cas A ; auth-js cas C provisoire, bloquant pour `deploy service`.
- Tour 2, décision du chef de projet 2026-11-17 : auth-js voie 1 retenue, cas A, blocage levé sous policy 28.
- Tour 4, mission du chef de projet 2026-11-17 : `BLOQUE_AUTHJS="non"` confirmé (policy 25, ligne 17 ; le relevé de réaction
  « oui » était obsolète) ; audit npm hors runner (ADR-014) ; garde esbuild : libellé « cas C esbuild gardé » signalé, non tranché (ADR-013 D-1).
- Itération 002, suite, arbitrage du chef de projet (2026-11-17) : garde esbuild tranché en « cas C gardé » (note non bloquante ;
  violation de la policy 25 si `serve`, `watch` ou `context(` apparaît). Classement esbuild inchangé : cas A.
