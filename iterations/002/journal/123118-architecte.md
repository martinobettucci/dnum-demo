# architecte — 2026-11-17T12:31:18+00:00

## Brief
Itération 002, tour 2, suite. Écris uniquement dans specs/. (1) SPEC-004 lignes 34 et 44 : remplace tools/deploy/secrets.py par tools/deploy/gen_secrets.py (renommé car il masquait le module standard secrets). (2) ADR-010 : le développeur a produit la preuve (journal iterations/002/journal/122914-developpeur.md, section ADR-010) : whatwg-url, tr46, webidl-conversions absents du bundle ; ws : seul le shim ws/browser.js est inclus (lève une exception à l'appel), importé dynamiquement par realtime-js ; @supabase/node-fetch : seul browser.js (renvoie fetch global) ; app.js n'utilise ni channel, ni subscribe, ni realtime, ni WebSocket. Classe ce que cette preuve permet de classer (cas A/B/C), mets l'ADR à jour, et dis précisément ce qui reste conditionnel (identifiants des 3 avis npm non relevés, le développeur n'ayant pas le droit de lancer docker run ; npm audit doit passer par la policy 13 FRONT-audit-npm ou une autorisation du chef de projet). Compte rendu court : décisions, fichiers modifiés, points ouverts.

## Compte rendu
Compte rendu de l'architecte, itération 002, tour 2 (suite). Écriture limitée à `specs/`.

**Décisions**

- **ADR-010 mis à jour.** La preuve du développeur permet un pré-classement par paquet, mais aucun des trois avis n'est classé, faute d'identifiant. La décision reste « accepté sous conditions, provisoire ».
  - **Cas A** : `whatwg-url`, `tr46`, `webidl-conversions` (absents du bundle) ; `esbuild` et `@esbuild/*` (build seul) ; `@types/*` et `undici-types` (types seuls, à confirmer dans le metafile).
  - **A, par remplacement de champ `browser`** : `ws` (seul le shim `ws/browser.js` est livré, il lève une exception à l'appel) et `@supabase/node-fetch` (seul `browser.js`, qui renvoie le `fetch` global). Réserve : si un avis vise le shim lui-même ou le chemin realtime, réévaluation en B.
  - **B conditionnel** : `realtime-js`, `storage-js`, `functions-js`. Ils ne sont pas appelés par `app.js`, mais la preuve ne suffit pas encore (voir C3).
  - **C par défaut** : `auth-js` et `postgrest-js`, dont les fonctions sont appelées par `app.js`. Un avis sur ces paquets bloque la mise en service sauf preuve de non-appel de la fonction vulnérable.
- **Limite de la preuve** : l'absence de `channel`, `subscribe` et `WebSocket` dans `app.js` est nécessaire mais ne suffit pas à établir que `realtime-js` n'ouvre aucune connexion au chargement.
- **SPEC-004** : `secrets.py` remplacé par `gen_secrets.py`. Les lignes 34 et 44 sont corrigées, ainsi que la ligne 40 (SPEC-004.11), qui contenait la même référence et n'était pas dans ta liste. L'en-tête porte la trace du renommage.

**Fichiers modifiés**

- `specs/SPEC-004-piles-dev-service.md` : trois occurrences renommées, amendement tour 2 complément ajouté.
- `specs/adr/ADR-010-vulnerabilites-npm-front.md` : réécrit (pré-classement, preuve, conditions C1 à C4, points ouverts).
- `specs/README.md` : lignes SPEC-004 et ADR-010 mises à jour, complément tour 2 ajouté.

**Points ouverts**

1. **Identifiants des 3 avis (C1)** : non relevés. Le développeur n'a pas le droit de lancer `docker run`. Passage possible par la policy `FRONT-audit-npm` (exécutée par `action` ou `policy`, sortie dans `iterations/002/policies/`) ou par une autorisation ponctuelle du chef de projet. Si la policy n'existe pas encore, l'autorisation est nécessaire. Si le registre est injoignable, le statut est « non exécutée », qui n'est pas une validation.
2. **Collision de numéro** : « policy 13 » désigne `FRONT-audit-npm` dans SPEC-006 §3, SPEC-001.15 et l'ADR, mais `policies/checks/13-gw-admin-bloque.sh` existe déjà. `policy` doit attribuer un numéro libre, puis SPEC-006 §3 sera corrigé.
3. **Reproduction du metafile (C2)** : l'extraction a été faite dans `/tmp` puis supprimée. Elle doit être rejouée par `./dev build`, et consignée par `policy` ou `testeur`.
4. **Non-ouverture de WebSocket (C3)** : à établir par `testeur` ou `client` (recette réseau, lecture seule). Sans cette preuve, `realtime-js` reste non classé en B.
5. **Hors de mon périmètre** : la policy `ENV-images-epinglees` et la policy `STACK-ports` restent à corriger par `policy` (constats du développeur, points 2 et 3 de son journal). Le journal du développeur signale aussi `policies/lib/secrets.py`, à traiter par `policy`.
