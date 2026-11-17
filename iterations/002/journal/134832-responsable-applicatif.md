# responsable-applicatif — 2026-11-17T13:48:32+00:00

## Brief
Deux tâches, LECTURE SEULE sur les piles (aucun deploy, reset, restore, teardown). O4 : dans iterations/002/mise-en-service.md corrige la date d'audit périmée (autour de la ligne 316) en 13:45:51 et nomme le troisième paquet de l'audit npm (autour de la ligne 318) : @supabase/supabase-js (sévérité low, dépendance directe, via auth-js), en vérifiant d'abord dans iterations/002/policies/audit-npm.meta.json et le rapport d'audit que ces valeurs sont exactes ; sinon dis ce que tu constates. O2 : prouve que bash est installé en 5.2.15-2+b13 dans l'image runner (build courant, tools/runner/Dockerfile) avec un conteneur jetable, par exemple docker run --rm --entrypoint dpkg-query <image runner> -W bash git curl, sans démarrer la pile ; donne les trois versions installées exactes.

## Compte rendu
Mise en service assurée exclusivement par le responsable applicatif. Aucun autre agent ne démarre, n'arrête ni ne détruit la pile : adressez vos demandes au chef de projet.

Les deux tâches sont faites. Aucune commande de déploiement, reset, restore ou teardown n'a été lancée et les piles n'ont pas été touchées.

**O4 : `iterations/002/mise-en-service.md`**

- **Ligne 316, date :** la date était fausse. `audit-npm.meta.json` indique `2026-11-17T13:45:51+00:00`, et non 13:40:30. Corrigée. Le statut `reussie` et l'image `node:22.12.0-alpine` sont exacts.
- **Ligne 318, troisième paquet :** `audit-npm.json` contient bien 3 paquets (total 3 : 2 low, 1 moderate). Le troisième est `@supabase/supabase-js`, sévérité low, `isDirect: true`, lié à `@supabase/auth-js` (GHSA-8r88-6cj9-9fh5). La ligne nomme désormais ce paquet. Les deux autres mentions (esbuild GHSA-67mh-4wv8-2f99, auth-js GHSA-8r88-6cj9-9fh5) sont exactes.
- Ma première modification a supprimé une parenthèse fermante ; je l'ai rétablie et j'ai vérifié la ligne.
- Non vérifié : le sha256 du lock et le résultat de la policy dans `results.json`. Je n'ai pas relu ces deux points.

**O2 : versions dans l'image runner**

Image : `devenv/runner:dev` (service `runner` de `stack/compose.yml`). Commande : `docker run --rm --entrypoint dpkg-query devenv/runner:dev -W bash git curl`, rc 0.

| Paquet | Version installée | Version épinglée dans `tools/runner/Dockerfile` |
|---|---|---|
| bash | **5.2.15-2+b13** | 5.2.15-2+b13 |
| git | 1:2.39.5-0+deb12u3 | 1:2.39.5-0+deb12u3 |
| curl | 7.88.1-10+deb12u15 | 7.88.1-10+deb12u15 |

Build courant : l'image a été créée à 13:45:34 UTC, et `tools/runner/Dockerfile` a été modifié pour la dernière fois à 13:44:57 UTC. Le fichier est versionné et son arbre git est propre.

Je n'ai écrit aucun fichier hors de `iterations/002/mise-en-service.md`.
