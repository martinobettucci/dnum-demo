# developpeur — 2026-11-17T12:33:43+00:00

## Brief
Itération 002, tour 2, arbitrage du chef de projet. Relève les 3 avis npm : cd app/web && ../../tools/bin/npm audit --json (la commande npm absente passe par la toolbox Docker déjà au registre). Pas de docker run direct. Si le garde-fou ou la session refuse, n'insiste pas, dis-le. N'applique aucune mise à jour (pas d'audit fix, pas d'overrides). Consigne dans ton compte rendu, pour chaque avis : identifiant (GHSA/CVE), paquet, sévérité, plage vulnérable, chemin de dépendance, correctif disponible. Ne modifie aucun fichier du dépôt.

## Compte rendu
Warning: no stdin data received in 3s, proceeding without it. If piping from a slow command, redirect stdin explicitly: < /dev/null to skip, or wait longer.
## Compte rendu : `npm audit` sur `app/web` (tour 2, arbitrage)

Commande exécutée : `cd app/web && ../../tools/bin/npm audit --json`, via le wrapper toolbox. Pas de `docker run` direct. Le garde-fou n'a pas bloqué la commande. L'audit a retourné 3 avis et sortie 1, ce qui est le comportement normal de npm quand des vulnérabilités sont trouvées. Aucune mise à jour appliquée, aucun `audit fix`, aucun override, aucun fichier du dépôt modifié.

### Les 3 avis

| # | Identifiant | Paquet | Sévérité | Plage vulnérable | Chemin de dépendance | Correctif disponible |
|---|---|---|---|---|---|---|
| 1 | GHSA-67mh-4wv8-2f99 (CWE-346, CVSS 5.3) | `esbuild` | **moderate** | `<= 0.24.2` | Dépendance **directe** (`isDirect: true`), `node_modules/esbuild` | `esbuild` 0.28.2, **changement de version majeure** |
| 2 | GHSA-8r88-6cj9-9fh5 (CWE-22, CVSS 0) | `@supabase/auth-js` | low | `<= 2.69.1` | Transitif, sous `@supabase/supabase-js` (`node_modules/@supabase/auth-js`) | Via `@supabase/supabase-js` 2.119.0 (pas de changement majeur) |
| 3 | (avis dérivé de #2) | `@supabase/supabase-js` | low | `2.41.1 - 2.49.10 \|\| 2.58.1-canary.0` | Dépendance **directe** (`isDirect: true`), dépend de `auth-js` | `@supabase/supabase-js` 2.119.0 (pas de changement majeur) |

Détail des avis :
- **esbuild, GHSA-67mh-4wv8-2f99** : « any website can send any requests to the development server and read the response ». Le risque concerne le serveur de développement d'esbuild. Il est en dépendance directe, probablement de développement, à vérifier dans `app/web/package.json`.
- **auth-js, GHSA-8r88-6cj9-9fh5** : « Insecure Path Routing from Malformed User Input ». Le score CVSS est 0 et la sévérité est low.
- **supabase-js** : n'est qu'un vecteur de l'avis auth-js. Le correctif est le même.

### Points ouverts

1. **Chemin des dépendances** : je me suis appuyé sur les champs `isDirect`, `via` et `effects` du rapport d'audit. Je n'ai pas lancé `npm ls` pour cartographier l'arbre complet. Ce n'était pas demandé.
2. **esbuild** : le correctif est en version majeure (0.28.2). Il demande une décision explicite, car il peut casser le build ou le serveur de développement.
3. **supabase-js / auth-js** : le correctif est en 2.119.0, sans changement majeur. Il reste à décider si le passage est acceptable, car la plage vulnérable est large (2.41.1 à 2.49.10).
4. Aucun avis n'est `high` ou `critical`.

En attente de l'arbitrage du chef de projet sur l'application des correctifs.
