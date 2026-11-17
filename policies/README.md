# Policies (écrites par l'agent `policy`)
Contraintes de vérification exécutables, lancées par `./dev policies` dans le conteneur `runner`.
Résultats : `iterations/NNN/policies/results.json`, lus par l'agent `observation`.
En-tête obligatoire : `# POLICY:`, `# REF:`, `# QUAND: always|deployed`. Code retour 0 / 1 / 77.

## Inventaire (itération 002)
| Fichier | Policy | QUAND | Référence |
|---|---|---|---|
| 00 | ENV-images-epinglees (FROM + `image:` de `stack/*.yml` ; images locales `devenv/<svc>:<pile>`, ADR-008) | always | SPEC-001.2, SPEC-004.16 |
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
| 21 | STACK-ports (publication unique `${APP_LAN_IP:-10.77.0.25}:${APP_PORT}:80`, ADR-007) | always | SPEC-001.3 |
| 22 | DB-migrations-versionnees | always | SPEC-001.13 |
| 23 | DB-rls-privileges-statique (RLS forcée, aucun grant anon, EXECUTE révoqué) | always | SPEC-002.1 |
| 24 | GARDE-FOU-mise-en-service (JSON simulé, copie isolée du garde-fou) | always | SPEC-004.6 |
| 25 | FRONT-audit-npm (`tools/bin/npm audit --json` ; GHSA listés ADR-010 ; auth-js bloquant pour `deploy service`) | always | SPEC-001.15 (b)(c), ADR-010 |
| 26 | STACK-restart-service (`unless-stopped` sur db, auth, rest, app ; pile service seulement) | always | SPEC-004.7, ADR-009 |
| 27 | DEV-sortie-url (`./dev` sans `127.0.0.1`/`localhost`/`0.0.0.0` ; `APP_LAN_IP` avec `APP_PORT`) | always | SPEC-004.17 |
| 28 | FRONT-auth-js-non-appel (aucun `.admin.`, `getUserById`, `updateUserById`, `deleteUser`, `listFactors`, `deleteFactor` dans `app/web/src`) | always | SPEC-001.15 (e), ADR-010 |
| 29 | DB-migrations-additives (NNN ≥ 006 additives et idempotentes ; 001–005 vs git, « non exécutée » sans git) | always | SPEC-004.18, ADR-011 |
| 30 | FRONT-messages-tour3 (textes M-1 à M-6, libellés, absence de `confirm(`, `alert(`, `innerHTML`) | always | SPEC-005.7, .33, .40, .60, .62, .63 |
| 31 | FRONT-barre-fixe (`.entete` sticky/fixed en `top: 0`, `scroll-padding-top`, z-index du lien d'évitement) | always | SPEC-005.6 |
| 32 | STACK-tags-par-pile (images construites `:dev`, surcouche `:service`, aucune collision) | always | SPEC-004.16, ADR-008 |
| 33 | STACK-auth-debit (`GOTRUE_RATE_LIMIT_*` ≥ 1000, pas de `..._HEADER`, aucun `limit_req`/`limit_conn`) | always | SPEC-001.14, ADR-006 §1 |
| 34 | STACK-points-accroche (`migrate`, `seed`, healthchecks, volume `db-data`) | always | SPEC-004.11 à 004.14 |

Les policies 25 à 34 sont **statiques** (aucun appel réseau vers la pile, aucun compte, aucune écriture) ; la 25
interroge le registre npm via `tools/bin/npm`. Aucune n'est de type `deployed`.

`lib/` : aides partagées (`compose.py` analyse compose sans PyYAML ; `devsecrets.py` lit
`.devenv/secrets/<pile>.env`). Ajout à `sys.path` **en fin** (`append`). Aucune policy n'affiche
une valeur secrète. `lib/secrets.py` est un résidu à supprimer (jamais importé).
