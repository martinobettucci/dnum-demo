# Policies (écrites par l'agent `policy`)
Contraintes de vérification exécutables, lancées par `./dev policies` dans le conteneur `runner`.
Résultats : `iterations/NNN/policies/results.json`, lus par l'agent `observation`.
En-tête obligatoire : `# POLICY:`, `# REF:`, `# QUAND: always|deployed`. Code retour 0 / 1 / 77.

## Inventaire (itération 002)
| Fichier | Policy | QUAND | Référence |
|---|---|---|---|
| 00 | ENV-images-epinglees (FROM + `image:` de `stack/*.yml`) | always | SPEC-001.2 |
| 01 | ENV-dependances-epinglees (Python) | always | ENV |
| 02 | ENV-pas-de-secret (motifs, dont JWT ; hors .git/.devenv/iterations) | always | SPEC-003.3 |
| 03 | ENV-toolbox-epinglee | always | ENV |
| 04 | ENV-npm-epinglees (versions exactes, supabase-js 2.47.10, lock, `npm ci`) | always | ADR-002, SPEC-006 §3.2 |
| 05 | ENV-secrets-valeurs-absentes (valeurs de `.devenv/secrets/*.env` ; 77 sans fichier) | always | SPEC-003.3/6/7 |
| 06 | ENV-devenv-ignore | always | SPEC-003.3 |
| 10 | APP-repond | deployed | SPEC-001.4 |
| 11 | GW-relais-auth | deployed | SPEC-001.5/6 |
| 12 | GW-relais-rest | deployed | SPEC-001.5/6 |
| 13 | GW-admin-bloque (avec clé service_role, variantes de chemin) | deployed | SPEC-001.7 |
| 14 | GW-csp | deployed | SPEC-001.9 |
| 15 | FRONT-meme-origine (fichiers servis, `/config.js` = ANON_KEY seule) | deployed | SPEC-001.8/10 |
| 16 | API-anon-refuse (tables, vues, écritures, RPC, `private` non exposé) | deployed | SPEC-002.1/2, SPEC-001.12 |
| 17 | ENV-secrets-fichier (droits, clés, longueurs, signatures JWT) | deployed | SPEC-003.1/2 |
| 20 | STACK-services | always | SPEC-001.1/2 |
| 21 | STACK-ports | always | SPEC-001.3 |
| 22 | DB-migrations-versionnees | always | SPEC-001.13 |
| 23 | DB-rls-privileges-statique (RLS forcée, aucun grant anon, EXECUTE révoqué) | always | SPEC-002.1 |
| 24 | GARDE-FOU-mise-en-service (JSON simulé, copie isolée du garde-fou) | always | SPEC-004.6 |

`lib/` : aides partagées (`compose.py` analyse compose sans PyYAML ; `devsecrets.py` lit
`.devenv/secrets/<pile>.env`). Ajout à `sys.path` **en fin** (`append`). Aucune policy n'affiche
une valeur secrète. `lib/secrets.py` est un résidu à supprimer (jamais importé).
