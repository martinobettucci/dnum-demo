# observation — 2026-11-17T15:00:01+00:00

## Brief
Mission structure (incident de recette), lecture seule. Restitue au format de ton périmètre : results.json (32 respectées, 1 violée : 36 FRONT-bundle-servi-egal-source, attendue tant que build-sha256.txt n'est pas produit), 37 GW-cache-et-entetes respectée ; diff de ./dev deploy (ligne ajoutée : dc --profile client up -d --force-recreate client, seule pile dev) ; journal 145924-action et 145827-policy. Écarts à signaler : la recréation est ajoutée à la suite d'un up déjà présent, pas dans une fonction dédiée ; la policy 36 dépend d'un fichier que le build ne produit pas encore (Agile sollicitée) ; l'effet réel de la recréation n'est vérifiable qu'à un prochain deploy dev. Ne modifie aucun fichier.

## Compte rendu
**1. Faits vérifiés**

Source : `iterations/002/policies/results.json` (date 2026-11-17T14:59:42, `pile_demarree: true`). Synthèse (l.304-308) : respectee 32, violee 1, non_applicable 0. Toutes les lignes respectées ont `rc: 0`.

*ENV / reproductibilité*
- ENV-images-epinglees (ENV, SPEC-001.2, SPEC-004.16, ADR-008, CA-002-2) : respectee (l.7-13). 14 références d'image vérifiées.
- ENV-dependances-epinglees (ENV) : respectee (l.16-23).
- ENV-pas-de-secret (SPEC-003.3, CA-002-2) : respectee (l.25-32).
- ENV-toolbox-epinglee (ENV) : respectee (l.34-41).
- ENV-npm-epinglees (ADR-002, SPEC-006 §3.2, CA-002-2) : respectee (l.43-50). supabase-js 2.47.10 à version exacte.
- ENV-secrets-valeurs-absentes (SPEC-003.3/.6/.7, SPEC-006 §1, CA-002-2) : respectee (l.52-59).
- ENV-devenv-ignore (SPEC-003.3, ADR-003, CA-002-2) : respectee (l.61-68).
- ENV-secrets-fichier (SPEC-003.1/.2, ADR-003, CA-002-4) : respectee (l.133-140). Droits 0700/0600, 6 clés présentes.

*APP / GW / FRONT*
- APP-repond (ENV) : respectee (l.70-77). GET / → 200.
- GW-relais-auth (SPEC-001.5/.6, CA-002-3) : respectee (l.79-86).
- GW-relais-rest (SPEC-001.5/.6, CA-002-3) : respectee (l.88-95).
- GW-admin-bloque (SPEC-001.7, SPEC-003.6, ADR-001, CA-002-3) : respectee (l.97-104). `/auth/v1/admin/*` → 403.
- GW-csp (SPEC-001.9, ADR-002, CA-002-3) : respectee (l.106-113).
- **GW-cache-et-entetes** (SPEC-001.9, ADR-002, CA-002-3) : respectee (l.295-302). Sortie : « 5 fichiers servis en 200 : Cache-Control no-cache ; CSP, X-Content-Type-Options nosniff, Referrer-Policy présents ».
- FRONT-meme-origine (SPEC-001.8/.10, ADR-002, CA-002-2/3) : respectee (l.115-122).
- FRONT-audit-npm (SPEC-001.15, ADR-010/014, CA-002-2) : respectee (l.187-194).
- FRONT-auth-js-non-appel (SPEC-001.15 (e), ADR-010, CA-002-2) : respectee (l.214-221).
- FRONT-messages-tour3 (SPEC-005.7/.33/.40/.60/.62/.63, CA-002-27/28/34/38/39) : respectee (l.232-239).
- FRONT-barre-fixe (SPEC-005.6, CA-002-37) : respectee (l.241-248).
- **FRONT-bundle-servi-egal-source** (ADR-006 §2, SPEC-001.8, CA-002-2) : **violee** (l.286-293). Détail en section 2.

*API / DB / STACK / GARDE-FOU*
- API-anon-refuse (SPEC-002.1/.2, SPEC-001.12, CA-002-11) : respectee (l.124-131). 27 requêtes anon.
- STACK-services (SPEC-001.1/.2, ADR-001, CA-002-1) : respectee (l.142-149).
- STACK-ports (SPEC-001.3, ADR-007, CA-002-1/3) : respectee (l.151-158).
- STACK-restart-service (SPEC-004.7, ADR-009, CA-002-36) : respectee (l.196-203).
- STACK-tags-par-pile (SPEC-004.16, ADR-008, CA-002-2/36) : respectee (l.250-257).
- STACK-auth-debit (SPEC-001.14, ADR-006 §1, CA-002-6/7/33) : respectee (l.259-266).
- STACK-points-accroche (SPEC-004.11 à .14, ADR-006 §3, CA-002-1/2) : respectee (l.268-275).
- DB-migrations-versionnees (SPEC-001.13, SPEC-002, CA-002-1/33) : respectee (l.160-167).
- DB-rls-privileges-statique (SPEC-002.1, ADR-005, CA-002-11) : respectee (l.169-176).
- DB-migrations-additives (SPEC-004.18/.12, ADR-011/015, CA-002-33) : respectee (l.223-230).
- ADMIN-seed-sans-ecrasement (SPEC-003.10/.12, ADR-012, CA-002-4/33) : respectee (l.277-284).
- GARDE-FOU-mise-en-service (SPEC-004.6, ADR-004, CLAUDE.md §5) : respectee (l.178-185).
- DEV-sortie-url (SPEC-004.17/.15, ADR-007, CA-002-1) : respectee (l.205-212).

**2. Écarts constatés**

- **Policy 36, FRONT-bundle-servi-egal-source : violée** (rc 1).
  - Preuve, `results.json` l.290-292 : « /build-sha256.txt absent ou non servi (statut 200, Content-Type « text/html », repli HTML possible) : empreintes du build non vérifiables, à produire par build.mjs dans dist/ ».
  - Le fichier n'est produit par aucun élément du code hors `iterations/`. Un grep de `build-sha256` sur le dépôt ne renvoie que `policies/checks/36-front-bundle-servi-egal-source.sh` (l.6, 24, 27, 37, 42, 55).
  - Le journal `iterations/002/journal/145827-policy.md` l.29-31 indique que `app/web/build.mjs` et `app/Dockerfile` ne produisent pas ce fichier.
- **Ligne ajoutée dans `./dev`** : `dev` l.144 : `[[ $PILE == dev ]] && dc --profile client up -d --force-recreate client`.
  - La ligne l.143 (`dc --profile client up -d client`) est conservée.
  - La ligne est placée dans la séquence `deploy`, après le démarrage de `app` (l.137 et l.141), et non dans une fonction dédiée.
  - Le journal `145924-action.md` l.4-19 donne le diff correspondant.
  - Le `grep` de `recreate` ne trouve cette occurrence que dans `dev` l.144 et dans les journaux.
- **Non-exécution de la ligne** : `145924-action.md` l.37 : « la nouvelle ligne n'a pas été exécutée ; son effet reste à vérifier au prochain deploy ». Le même journal l.7 indique qu'aucun deploy n'a été lancé.
- **Sortie de `./dev policies`** : rc 1 (`145924-action.md` l.26), en raison de la violation 36.

**3. Ce qui n'a pas pu être observé**

- **Effet de `--force-recreate client`** : la ligne n'a jamais été exécutée. Aucun deploy postérieur à sa modification n'est consigné dans les sources lues. `.devenv/deploy.log` n'a pas été lu (hors sources de ma mission).
- **Contenu servi réel** de `/build-sha256.txt`, `/app.js` et `/vendor/supabase.js` : seul le résumé de la policy est disponible, sans empreintes comparées dans les sources lues.
- **Exécution des policies** : je n'ai pas relancé `./dev policies` (lecture seule). Les résultats sont ceux du fichier `results.json` daté de 14:59:42.
- **Contenu des scripts** `policies/checks/37-gw-cache-et-entetes.sh` et des autres checks : non relus, sauf les lignes de la policy 36 citées par grep.
- **`iterations/002/tests/`** (junit, rapports) et **`rapport-client.md`** : non examinés dans ce périmètre.
- **`iterations/002/journal/150001-observation.md`** : présent, mais non lu (hors périmètre de la mission).
- **`iterations/002/mise-en-service.md`** : lu, mais je n'ai trouvé aucune section consignant un deploy postérieur à l'ajout de la ligne `dev` l.144 ; le déploiement « 14:58 » qui y figure (l.3-11) précède le journal `145924-action` (14:59:24).
