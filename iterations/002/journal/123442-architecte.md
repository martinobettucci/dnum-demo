# architecte — 2026-11-17T12:34:42+00:00

## Brief
Itération 002, tour 2, arbitrages du chef de projet. Écris uniquement dans specs/. (1) ADR-010 : le développeur a relevé les 3 avis (journal iterations/002/journal/123343-developpeur.md) : GHSA-67mh-4wv8-2f99 esbuild <=0.24.2 modéré (serveur de développement d'esbuild, dépendance directe, correctif 0.28.2 majeur) ; GHSA-8r88-6cj9-9fh5 @supabase/auth-js <=2.69.1 faible, CVSS 0 (Insecure Path Routing from Malformed User Input, transitif) ; avis dérivé sur @supabase/supabase-js 2.41.1-2.49.10 (correctif 2.119.0). Classe chaque avis A/B/C avec la preuve du développeur (journal 122914) et ce qu'on sait du build (esbuild sert-il un serveur de dev ? vérifie app/web/build.mjs et package.json, lecture seule). auth-js est appelé par app.js : tranche honnêtement (cas C ou preuve de non-appel de la fonction vulnérable ; lis l'avis si disponible dans le dépôt, sinon dis ce qui manque). Décide si une montée de version épinglée (esbuild, supabase-js) est à demander au chef de projet pour l'itération 003 ou bloquante pour la mise en service. (2) SPEC-006 §2 : CA-002-9 reste [C] + [T] ; CA-002-1(c) passe en [P] (cf. perimetre.md). Corrige aussi la collision du numéro 13 si la policy FRONT-audit-npm a reçu un autre numéro (vérifie policies/checks/). Compte rendu court : décisions, fichiers, points ouverts.

## Compte rendu
Warning: no stdin data received in 3s, proceeding without it. If piping from a slow command, redirect stdin explicitly: < /dev/null to skip, or wait longer.
Compte rendu de l'architecte, itération 002, tour 2 (arbitrages). Seul `specs/` a été modifié.

## Décisions

**1. ADR-010, esbuild (GHSA-67mh-4wv8-2f99) : cas A, accepté, non bloquant.**
- Le build n'appelle que `build()`. Aucun `serve`, `watch` ni `context(` dans `app/`.
- L'étape de build n'expose aucun port, et l'image servie ne contient que `dist/`. Le serveur de dev visé par l'avis n'est jamais démarré.
- Montée vers 0.28.2 (majeure) : **à demander au chef de projet pour l'itération 003**. Ce n'est pas bloquant.
- Réserve : si `serve`, `watch` ou `context` apparaît dans le build, l'avis repasse en cas C.

**2. ADR-010, auth-js (GHSA-8r88-6cj9-9fh5) : cas C provisoire, bloquant pour `./dev deploy service` uniquement.**
- `app.js` appelle `getSession`, `signInWithPassword`, `signUp`, `signOut` et le rafraîchissement automatique. Les saisies utilisateur passent en corps de requête, pas dans le chemin.
- Je ne peux pas prouver le non-appel de la fonction visée : le texte de l'avis n'est pas dans le dépôt, et `node_modules` est absent. La règle de l'ADR fait donc de auth-js un cas C par défaut.
- L'entrée supabase-js 2.47.10 est le même avis dérivé, pas un troisième identifiant.
- La pile `dev` (déjà déployée) et la recette `dev` ne sont pas bloquées. CA-002-36 reste non confirmé tant que le blocage n'est pas levé.
- Voies de levée, à consigner dans l'ADR :
  - **Voie 1 (recommandée)** : le chef de projet lit l'avis et indique le module et la fonction visés. `action` ou `policy` vérifie le non-appel en lecture seule dans le conteneur node.
  - **Voie 2** : montée de supabase-js vers 2.119.0. Elle implique une recette d'authentification et l'amendement de SPEC-001.8 (b), qui écrit 2.47.10 en dur.
  - **Voie 3** : acceptation écrite du risque par le chef de projet. L'architecte ne l'accorde pas.
- Pas de montée d'office. Si la voie 1 n'aboutit pas, la voie 2 devient bloquante pour `deploy service`.

**3. CA-002-9 et CA-002-1 (c).**
- CA-002-9 reste [C] + [T]. Je lui ajoute SPEC-005.61 dans sa ligne de SPEC-006 §2.
- CA-002-1 (c) passe en [P] (policy 27, `DEV-sortie-url`). Le [R] se limite à `curl` et à `ss -ltn`.

**4. Collision de numéros.**
- Aucune policy `FRONT-audit-npm` n'existe dans `policies/checks/`, donc aucun autre numéro n'a été attribué. La collision n'existait que dans les specs.
- Le 13 est réaffecté à **25**. Par la même logique, 12 devient **26** (`12-gw-relais-rest.sh` occupe 12) et 14 devient **27** (`14-gw-csp.sh` occupe 14). Les numéros 25 à 27 sont libres.
- Aucune référence aux anciens numéros ne subsiste dans `specs/`.

## Fichiers (`specs/` uniquement)

- `specs/adr/ADR-010-vulnerabilites-npm-front.md` : réécrit (statut, tableau nominatif des avis, preuves, décision, conditions C1 à C5).
- `specs/SPEC-001-pile-supabase.md` : en-tête et SPEC-001.15 ((b) avec identifiants, (d) nouvelle, policy 25).
- `specs/SPEC-006-plan-verification.md` : en-tête, lignes CA-002-1, CA-002-9 et CA-002-36, §3 items 12 à 14 (numéros 26, 25, 27).
- `specs/adr/ADR-009-redemarrage-pile-service.md` : référence de policy 12 → 26.
- `specs/README.md` : index réécrit, avec section « Arbitrages tour 2 ».

## Points ouverts

1. **Chef de projet** : lire GHSA-8r88-6cj9-9fh5 (voie 1), ou choisir la voie 2 ou 3. Sans cela, `deploy service` et CA-002-36 restent bloqués.
2. **Chef de projet** : inscrire la montée d'esbuild 0.28.2 à l'itération 003.
3. **Policy** : écrire et exécuter les policies 25, 26 et 27 avec ces numéros. La policy 25 doit rejouer le relevé `npm audit`, car les journaux 122914 et 123343 se contredisent sur la possibilité de lancer `npm audit`.
4. **Non faits** : C2 (metafile reproduit par une policy) et C3 (non-ouverture WebSocket). C3 n'est nécessaire que pour classer `realtime-js` en B.
5. **Limites** : « sans changement majeur » pour 2.119.0 et les versions de correctif viennent du rapport npm, pas d'une lecture de l'avis. Je n'ai pas lu le code de auth-js 2.67.3.
