# SPEC-003 — Compte administrateur initial et secrets

Itération 002. Décision : ADR-003. Couvre CA-002-2, CA-002-4, CA-002-5, CA-002-33.

| Id | Exigence (énoncé vérifiable) | CA | Vérification |
|---|---|---|---|
| SPEC-003.1 | `./dev deploy` crée, si absent, `.devenv/secrets/<pile>.env` (répertoire `0700`, fichier `0600`) contenant `POSTGRES_PASSWORD`, `JWT_SECRET` (≥ 40 car.), `ANON_KEY`, `SERVICE_ROLE_KEY`, `ADMIN_EMAIL`, `ADMIN_PASSWORD` (≥ 20 car., généré par `secrets` de python, alphabet alphanumérique). Les valeurs existantes ne sont jamais réécrites. | CA-002-4 | [T] lecture de `/workspace/.devenv/secrets/dev.env` : clés présentes, longueurs ; [R] `stat` des droits |
| SPEC-003.2 | `ANON_KEY` et `SERVICE_ROLE_KEY` sont des JWT HS256 valides signés par `JWT_SECRET`, `role` respectivement `anon` et `service_role`. | CA-002-2 | [T] vérification de signature (stdlib `hmac`) |
| SPEC-003.3 | `.devenv/` est ignoré par git ; aucun fichier suivi ne contient la valeur de `JWT_SECRET`, `POSTGRES_PASSWORD`, `ADMIN_PASSWORD`, `ANON_KEY`, `SERVICE_ROLE_KEY`, ni un JWT (`eyJ[A-Za-z0-9_-]{10,}\.eyJ`). Les images construites ne contiennent aucune de ces valeurs. | CA-002-2 | [P] recherche des valeurs du fichier de secrets et du motif JWT dans le dépôt hors `.git`, `.devenv`, `iterations` ; `.gitignore` contient `.devenv/` |
| SPEC-003.4 | Après le premier `./dev deploy`, `POST $APP_URL/auth/v1/token?grant_type=password` avec `ADMIN_EMAIL`/`ADMIN_PASSWORD` ⇒ 200 ; `my_status()` ⇒ `{is_active: true, role: "admin"}`. | CA-002-4 | [T] |
| SPEC-003.5 | Le seed est idempotent : N déploiements successifs (avec ou sans `reset`) laissent **un seul** compte `ADMIN_EMAIL`, actif, `role='admin'`, dont le mot de passe est `ADMIN_PASSWORD` du fichier (inchangé). | CA-002-4, CA-002-33 | [T] `admin_list_accounts()` : 1 ligne pour `ADMIN_EMAIL` ; [R] deux `./dev deploy` consécutifs |
| SPEC-003.6 | Le seed utilise l'API d'administration GoTrue **interne** (`http://auth:9999`), jamais `$APP_URL/auth/v1/admin` (bloqué, SPEC-001.7) ; il n'écrit aucun secret sur la sortie standard ni dans `.devenv/deploy.log`. | CA-002-2 | [R] relecture des journaux de `./dev deploy` ; [P] recherche de `ADMIN_PASSWORD` dans `.devenv/deploy.log` |
| SPEC-003.7 | Le responsable applicatif transmet `ADMIN_EMAIL` et `ADMIN_PASSWORD` au chef de projet **hors fichier suivi** (message), et `mise-en-service.md` indique seulement l'emplacement du fichier. | CA-002-4 | [R] relecture de `mise-en-service.md` (aucun mot de passe) |
| SPEC-003.8 | Avec ces identifiants, l'admin se connecte dans l'interface, arrive sur le tableau de bord et voit l'entrée « Administration » ; un membre ordinaire activé ne la voit pas. | CA-002-5 | [C] |
| SPEC-003.9 | Aucun autre compte n'est créé par le seed ; aucun compte de test n'est créé dans la pile `service`. | CA-002-4 | [R] (dev) `admin_list_accounts()` juste après `reset`+`deploy`, avant tout test = 1 compte |
