# ADR-014 — Audit npm produit hors runner (`./dev audit-npm`)

Statut : accepté (itération 002, 2026-11-17). Décision D-2 de ADR-013.
Amende : ADR-010 (§ Décision 5, contrôle continu), SPEC-001.15 (b), SPEC-006 §3 (policy n° 25).
Complète : ADR-010 (cadre de l'audit), ADR-002 (dépendances épinglées).

## Contexte

- La policy 25 (`FRONT-audit-npm`) appelait `tools/bin/npm` depuis le runner, qui passe par `docker run`.
- Le runner (`tools/runner/Dockerfile` : `python:3.13.1-slim` avec `curl` et `bash`) n'a ni Docker, ni Node. L'appel échoue.
  L'erreur était masquée (`2>/dev/null || true`), d'où le message « npm n'a pas rendu de rapport » (`results.json`,
  policy 25 en violation).
- La policy 25 lit déjà un fichier produit ailleurs : `iterations/002/policies/audit-npm.json`, sans aucun appel réseau
  ni conteneur (commentaire d'en-tête de la policy). Il manque seulement la commande qui le produit.
- Le relevé de l'audit a réussi dans le journal `123343` via le wrapper de la toolbox, depuis l'hôte.

## Options étudiées

| Option | Description | Évaluation |
|---|---|---|
| (a) Node dans le runner | Node épinglé dans `tools/runner`, le runner joint le registre npm. | Rejetée : duplique l'image `node:22.12.0-alpine`, ajoute un accès réseau au runner et un second outil à maintenir. |
| (b) Socket Docker dans le runner | Monter `/var/run/docker.sock` dans le runner pour qu'il lance `npm`. | Rejetée : le runner obtiendrait le contrôle de l'hôte. Contraire à CLAUDE.md §1 (Docker rootless, pas de privilège hôte). |
| (c) Rapport produit hors runner | `./dev audit-npm` tourne sur l'hôte et écrit le rapport ; la policy le lit et le vérifie. | **Retenue** (décision chef de projet, D-2). |

## Décision

1. **Commande** `./dev audit-npm`, exécutée sur l'hôte (Docker est une dépendance de l'hôte, SPEC-004.5). Elle lance
   `npm audit --json` dans `app/web` via `tools/bin/npm`, dans l'image `node:22.12.0-alpine` (tag exact, SPEC-001.2).
   Elle n'installe pas `node_modules` et ne modifie aucun fichier de `app/web`.
2. **Sorties** dans `iterations/<NNN>/policies/`, où `<NNN>` est lu dans `iterations/CURRENT` (même règle que
   `./dev policies`, `dev` ligne 5) :
   - `audit-npm.json` : sortie brute de `npm audit --json`. Absent ou vide si la commande n'a pas produit de rapport.
   - `audit-npm.meta.json` : objet JSON à quatre champs :
     - `statut` : `"reussie"` ou `"non_executee"` ;
     - `package_lock_sha256` : sha256 de `app/web/package-lock.json` au moment de l'audit ;
     - `image` : `"node:22.12.0-alpine"` ;
     - `date` : date et heure au format ISO 8601.
   `statut` vaut `"non_executee"` si le registre est injoignable, si la commande échoue, ou si la sortie n'est pas un
   rapport npm. Dans ce cas, `audit-npm.json` ne contient pas de rapport valide.
3. **Lecture par la policy 25** : la policy échoue (statut « non exécutée », jamais « réussie ») si :
   - l'un des deux fichiers manque ;
   - `statut` n'est pas `"reussie"` ;
   - `package_lock_sha256` diffère du sha256 actuel de `app/web/package-lock.json`.
   La comparaison de dates (`st_mtime`) est retirée : elle échoue après un `git checkout` et ne prouve pas que le rapport
   correspond au lock.
4. **Itération courante** : la policy 25 lit `iterations/<NNN>/` de l'itération courante. Le chemin `002` figé dans la
   policy est à remplacer (sinon la policy échoue à l'itération 003).
5. **Relance obligatoire** de `./dev audit-npm` après toute modification de `package-lock.json`, et avant
   `./dev deploy service` (ADR-010, SPEC-001.15 (e)).
6. **Runner** : inchangé. Il n'a ni Docker, ni Node, ni accès réseau au registre.

## Canal de l'audit : la toolbox (précision, complément du chef de projet, 2026-11-17)

- `./dev audit-npm` appelle `tools/bin/npm`, c'est-à-dire `tools/bin/_dockerized npm …` : le wrapper lit
  `tools/toolbox/registry.conf` (ligne `npm node:22.12.0-alpine`) et exécute `docker run --rm … node:22.12.0-alpine`
  avec le dépôt monté sur le répertoire courant. Le lancement de `docker run` est donc **interne à la toolbox**.
- Ce canal est **autorisé à tout agent** (ou à l'hôte). C'est la règle de l'utilisateur : une commande absente de l'hôte
  s'exécute dans son conteneur, image épinglée au tag exact, déclarée dans `tools/toolbox/registry.conf` (CLAUDE.md §1).
- Le garde-fou (`tools/guards/guard.py`, motif `docker\s+(run|…)`) bloque les `docker run` **directs** saisis dans une
  commande d'agent. Il ne bloque pas la toolbox : la commande vue par le garde-fou est `tools/bin/npm` (ou `./dev audit-npm`),
  qui ne contient pas la chaîne `docker run`. Ce n'est pas un contournement : c'est le canal prévu.
- Conséquence : aucun agent ne doit appeler `docker run` directement pour auditer `npm`. Passer par `tools/bin/npm` ou
  `./dev audit-npm`. Une nouvelle commande suit la même voie : entrée dans le registre, puis `tools/bin/regen`.
- Le wrapper n'ajoute pas de socket Docker au runner (option (b) rejetée) : le runner n'appelle pas la toolbox.

## Conséquences

- Deux étapes, dans cet ordre : `./dev audit-npm`, puis `./dev policies`. Sans la première, la policy 25 est en échec
  (« non exécutée »).
- **Limite de confiance** : le rapport est produit par l'hôte et lu par le runner. Le sha256 prouve que le rapport
  correspond au lock lu ; il ne prouve pas que l'hôte n'a pas été altéré. C'est un contrôle d'inventaire des
  dépendances, pas une frontière de sécurité.
- `./dev` : nouvelle commande. Elle figure dans `./dev help` et dans le contrat SPEC-004.1 (arbitrage du chef de projet,
  2026-11-17, ADR-013 point 5 : clos).
- Le rapport ne contient aucune valeur de secret : il ne lit ni `.devenv/` ni l'environnement.

## Vérification

- **[P]** policy 25 `FRONT-audit-npm` (SPEC-001.15 (b)) : lecture des deux fichiers, statut, sha256 du lock.
- **[R]** `./dev audit-npm` exécuté, `statut` `"reussie"` et sha256 consignés dans `iterations/<NNN>/mise-en-service.md`
  avant `./dev deploy service`.

## Alternatives écartées

- Ignorer l'audit : la policy rend l'acceptation explicite et datée (ADR-010).
- Exécuter `npm audit` dans `./dev policies` : relancerait le problème (le runner n'a pas Node ni Docker).
