# ADR-010 — Vulnérabilités npm transitives de `app/web` : évaluation et décision

Statut : **accepté sous conditions, provisoire** (itération 002, tour 2, mis à jour le 2026-11-17 après la preuve du
développeur). Specs touchées : SPEC-001.15 (dépendances npm du front), SPEC-006 §3 (policy `FRONT-audit-npm`).
Complète ADR-002 (dépendances épinglées).

**État au 2026-11-17** : la preuve de bundle est obtenue (section « Preuve de bundle »). Le classement par paquet
est établi pour les paquets Node-only. **Les identifiants des trois avis ne sont toujours pas relevés** : la décision
reste provisoire tant que la section « Liste des avis » n'est pas complétée.

## Contexte

- `app/web/package.json` épingle `@supabase/supabase-js@2.47.10` et `esbuild@0.24.2` ; `package-lock.json` (v3)
  fige l'arbre complet avec intégrité `sha512` (SPEC-006 §3, policy 2).
- Un `npm audit` remonte **3 vulnérabilités : 2 faibles et 1 modérée** (signalement du développeur,
  `iterations/002/journal/120715-developpeur.md`, point 8).
- **Limite** : les identifiants (GHSA/CVE) des trois avis, leurs paquets et leurs versions de correctif ne sont
  consignés nulle part dans le dépôt. L'architecte n'exécute aucun outil et ne peut pas relancer l'audit. Le
  développeur n'a pas non plus le droit de lancer `docker run` : sa tentative `npm audit` dans
  `node:22.12.0-alpine` a été refusée par le garde-fou (journal `122914-developpeur.md`, point 1).
- **Paquets de l'arbre concernés par hypothèse** :
  - runtime navigateur : `@supabase/*` (auth-js 2.67.3, postgrest-js 1.17.7, realtime-js 2.11.2, storage-js 2.7.1,
    functions-js 2.4.4), `@supabase/node-fetch` 2.6.15 et ses dépendances `whatwg-url` 5.0.0, `tr46` 0.0.3,
    `webidl-conversions` 3.0.1, `ws` 8.23.0 (dépendance de `realtime-js`) ;
  - build seulement : `esbuild` 0.24.2 (dépendance **directe** de développement, et non transitive : si elle figure
    parmi les trois avis, la formulation du contexte est à corriger) ; `@esbuild/*` (binaires optionnels) ;
  - types seulement : `@types/node` 26.6.6, `@types/ws`, `@types/phoenix`, `undici-types`.

## Ce qui est livré au navigateur (faits vérifiés)

- `app/Dockerfile` est multi-étapes : `node:22.12.0-alpine` ne sert qu'à construire ; l'image finale est
  `nginx:1.27.3-alpine` et ne reçoit que `dist/` (`app.js`, `vendor/supabase.js`, `index.html`, `style.css`).
  **`node_modules`, esbuild et tous les paquets de développement ne sont pas livrés**, et aucun processus Node
  ne tourne en production.
- Le bundle `dist/vendor/supabase.js` est minifié (esbuild, `platform` navigateur, `legalComments: none`). Seuls les
  modules **effectivement importés** par `src/vendor.js` y figurent. Un paquet Node-only n'y figure que sous la forme
  de son champ `browser` quand esbuild le remplace.
- La CSP de nginx (`default-src 'self'; connect-src 'self'; script-src 'self'`, SPEC-001.9) interdit au navigateur
  de se connecter ailleurs que sur la même origine et d'exécuter un script tiers.
- Le front n'ouvre aucun canal temps réel (SPEC-005, périmètre).

## Preuve de bundle (tour 2, développeur)

Source : `iterations/002/journal/122914-developpeur.md`, section ADR-010. Extraction du `metafile` d'esbuild
(`app/web/build.mjs`, `metafile: true`, écrit dans `meta/vendor-metafile.json`, hors `dist/`, donc hors image). Le
fichier extrait a été consulté dans `/tmp` puis supprimé ; **la preuve est reproductible par `./dev build`**, et la
lecture de `meta/vendor-metafile.json` doit être refaite à chaque build (voir Conditions).

| Paquet | Constat dans le bundle |
|---|---|
| `whatwg-url`, `tr46`, `webidl-conversions` | présents dans le lock, **absents du bundle** |
| `ws` 8.23.0 | **seul `ws/browser.js` est inclus** : c'est un shim qui lève une exception à l'appel. Il est importé dynamiquement par `realtime-js/RealtimeClient.js`. Le `ws` Node n'est pas dans le bundle. |
| `@supabase/node-fetch` 2.6.15 | **seul `browser.js` est inclus** : c'est un shim qui renvoie le `fetch` global. |
| `esbuild` | absent du bundle |
| `app/src/app.js` | n'utilise ni `channel`, ni `subscribe`, ni `realtime`, ni `WebSocket` |

Ce que la preuve établit : le code Node de `whatwg-url`, `tr46`, `webidl-conversions`, `ws` et
`@supabase/node-fetch` **n'est pas livré au navigateur**. Ce qu'elle n'établit **pas** : que `realtime-js` n'ouvre
aucune connexion au chargement de `supabase-js` (l'absence de `channel`/`subscribe` dans `app.js` est nécessaire,
non suffisante). Ce point reste à confirmer (Conditions).

## Évaluation (cas A / B / C de la décision)

Définitions, inchangées : **A** = le paquet de l'avis n'est pas exécuté par le bundle (absent, build seul, ou remplacé
par son champ `browser`) ; **B** = il est dans le bundle mais la fonction vulnérable n'est pas atteignable depuis le
front ; **C** = il est dans le bundle **et** atteignable, ou sévérité haute ou critique.

Ce tableau est une **règle de pré-classement** : il permet de classer un avis dès que son paquet est connu, sans
attendre une nouvelle analyse.

| Paquet visé par l'avis | Constat | Cas | Réserve |
|---|---|---|---|
| `whatwg-url`, `tr46`, `webidl-conversions` | absents du bundle (preuve) | **A** | aucune |
| `esbuild`, `@esbuild/*` | build seul, hors `dist/` | **A** | `@esbuild/*` : à confirmer dans `meta/vendor-metafile.json` |
| `@types/*`, `undici-types` | types seuls, hors bundle | **A** | à confirmer dans le metafile |
| `ws` 8.x | seul le shim `ws/browser.js` est livré (exception à l'appel) | **A** (remplacé par champ `browser`, exemple de l'ADR) | si l'avis vise le shim lui-même ou le chemin realtime : réévaluation en **B** |
| `@supabase/node-fetch` 2.x | seul le shim `browser.js` est livré (`fetch` global) | **A** | idem ci-dessus |
| `realtime-js` 2.11.2 | présent dans le bundle, importé ; non emprunté par `app.js` | **B conditionnel** | B seulement après preuve qu'aucune WebSocket n'est ouverte au chargement |
| `auth-js` 2.67.3, `postgrest-js` 1.17.7 | présents, fonctions utilisées par `app.js` (connexion, appels `rest`) | **C** par défaut | B seulement si la fonction vulnérable est prouvée non appelée |
| `storage-js` 2.7.1, `functions-js` 2.4.4 | présence dans le bundle à confirmer dans le metafile ; non appelés par `app.js` | **B conditionnel** | preuve : metafile + non-appel |
| `supabase-js` (cœur) | dépend des modules ci-dessus | selon le module touché | — |

Pour les trois avis actuels, la sévérité est « faible » ou « modérée » : **aucun n'est classé à ce jour**, faute
d'identifiant. Si l'un d'eux porte sur `auth-js` ou `postgrest-js` sans preuve de non-appel, il est de **cas C** et
bloque (Décision 3).

## Décision

1. **Aucune mise à jour dans cette itération.** Pas de `npm audit fix`, pas de `overrides` ni de plage de version,
   pas de nouveau `^` ou `~`. Les versions de `package.json` et `package-lock.json` restent celles de SPEC-006 §3.
   Une correction éventuelle est une montée de version **exacte**, traitée comme une nouvelle décision.
2. Les trois avis sont **acceptés conditionnellement** : chacun doit être classé A ou B dans la liste nominative
   ci-dessous (identifiant, paquet, cas, motif). Le classement suit le tableau de pré-classement.
3. Un avis de cas C, ou de sévérité haute ou critique, **bloque** la mise en service de la pile service tant qu'il
   n'est pas traité.
4. Contrôle continu : la policy `FRONT-audit-npm` (SPEC-001.15, SPEC-006 §3) exécute `npm audit --json` sur le lock
   dans l'image `node:22.12.0-alpine` et échoue si un avis n'est pas listé ici, ou s'il est de sévérité haute ou
   critique. Si le registre npm est injoignable, la policy n'est **pas réussie** : statut « non exécutée », ce qui
   n'est pas une validation.

## Conditions pour que la décision tienne

- **C1 — Identifiants** : les trois identifiants sont relevés et classés **avant** la recette client. Source
  attendue : sortie `npm audit --json` de la policy `FRONT-audit-npm` dans `iterations/002/policies/`, ou autorisation
  ponctuelle du chef de projet (voir Points ouverts 1).
- **C2 — Metafile reproductible** : `./dev build` produit `meta/vendor-metafile.json` ; la policy (ou le testeur)
  vérifie que `ws/browser.js` et `@supabase/node-fetch/browser.js` sont les seuls paquets Node-only du bundle, et que
  `whatwg-url`, `tr46`, `webidl-conversions`, `esbuild` n'y figurent pas. Le fichier n'est pas copié dans l'image.
- **C3 — Non-ouverture de WebSocket** : la recette réseau (ou un test) établit qu'aucune connexion `ws://`/`wss://`
  n'est ouverte au chargement de la page et pendant les parcours de SPEC-005. Sans cette preuve, `realtime-js` reste
  non classé en B.
- **C4 — `esbuild` confirmé build seul** : absent de `dist/` (acquis par le constat du développeur, à rejouer via C2).

## Conséquences

- Le front reste à la version exacte de supabase-js (ADR-002) ; aucun changement fonctionnel.
- Les avis restent visibles au niveau du dépôt : ils ne sont pas masqués, et la policy les relève à chaque itération.
- Le risque résiduel est documenté : un avis découvert plus tard dans un paquet du bundle impose une réévaluation
  (nouvelle entrée de la liste, cas A/B/C).
- Le choix ne modifie ni la pile, ni la passerelle, ni les variables d'environnement.

## Alternatives écartées

- **`npm audit fix` ou overrides maintenant** : modifie le lock sans que l'on sache quels paquets sont en cause,
  hors règle « versions épinglées » et hors bornes de validation de cette boucle.
- **Ignorer l'audit** : la policy rend l'acceptation explicite et datée.
- **Retirer supabase-js** : hors périmètre (ADR-002).

## Liste des avis (à compléter, Condition C1)

| Identifiant | Paquet (version de l'arbre) | Sévérité | Cas (A/B/C) | Motif |
|---|---|---|---|---|
| à relever | à relever | faible | à classer | — |
| à relever | à relever | faible | à classer | — |
| à relever | à relever | modérée | à classer | — |

Règle à appliquer dès relevé : paquet dans la première partie du tableau de pré-classement → A ; `realtime-js` /
`storage-js` / `functions-js` → B conditionnel (C2, C3) ; `auth-js` / `postgrest-js` / cœur `supabase-js` → C
sauf preuve de non-appel.

## Points ouverts

1. **Relever les trois identifiants** (`npm audit --json` dans `node:22.12.0-alpine`, sur `app/web/package-lock.json`)
   et les consigner dans la table ci-dessus. Passage autorisé : **policy `FRONT-audit-npm`** exécutée par `action` ou
   `policy` (`./dev policies`), ou **autorisation ponctuelle du chef de projet** si la policy n'existe pas encore. Le
   développeur ne peut pas lancer `docker run` (garde-fou). Confirmer si `esbuild` en fait partie.
2. **Numéro de policy en collision** : SPEC-006 §3 et cet ADR désignent `FRONT-audit-npm` par le numéro **13**, déjà
   occupé par `policies/checks/13-gw-admin-bloque.sh`. Décision à prendre par `policy` (numéro libre) avec mise à jour
   de SPEC-006 §3 et de SPEC-001.15 par l'architecte. Tant que la policy n'est pas écrite, `FRONT-audit-npm` n'existe pas.
3. **Preuve non persistée** : l'extraction du metafile a été faite en `/tmp` puis supprimée. Condition C2 : la
   vérification doit être rejouée et consignée dans `iterations/002/policies/` ou dans le rapport de `policy`.
4. **Condition C3** (non-ouverture de WebSocket) : à établir par `testeur` ou `client` (recette réseau, lecture seule).
5. **`metafile` d'esbuild** : ajouté au build par le développeur (`app/web/build.mjs`) ; reste à le faire vérifier par
   une policy (C2).
