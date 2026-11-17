# ADR-003 — Secrets générés hors git et seed idempotent du compte administrateur

Statut : accepté (itération 002) — couvre CA-002-2, CA-002-4, CA-002-33.
**Amendé par ADR-012 (tour 3)** : le seed ne réécrit plus le mot de passe d'un compte admin existant ; après création,
la base fait foi pour ce mot de passe. Les passages « source de vérité » et « écrasé au déploiement suivant » ci-dessous
ne sont plus valables.

## Contexte
- Aucun secret dans le dépôt (CLAUDE.md). Le mot de passe admin est généré, jamais commité,
  transmis par le responsable applicatif au chef de projet.
- La pile dev doit pouvoir repartir de rien (`./dev reset`) sans état nécessaire.
- `.devenv/` est déjà ignoré par git.

## Décision
- **Un fichier de secrets par pile** : `.devenv/secrets/<pile>.env` (`<pile>` ∈ `dev`, `service`),
  répertoire `0700`, fichier `0600`. Contenu : `POSTGRES_PASSWORD`, `JWT_SECRET` (≥ 40 caractères),
  `ANON_KEY`, `SERVICE_ROLE_KEY`, `ADMIN_EMAIL`, `ADMIN_PASSWORD` (≥ 20 caractères).
- **Génération** par un script exécuté au début de `./dev deploy` avec `python3` de l'hôte
  (bibliothèque standard : `secrets`, `hmac`, `hashlib`, `base64`, `json` — aucune installation) :
  ne génère **que les valeurs absentes** ; un fichier existant n'est jamais écrasé.
  `ANON_KEY` et `SERVICE_ROLE_KEY` sont des JWT HS256 signés avec `JWT_SECRET`
  (`{"role":"anon"|"service_role","iss":"supabase","iat":…,"exp":iat+10 ans}`).
- Les secrets sont injectés dans les conteneurs par `env_file`/variables d'environnement de
  compose ; aucun n'est écrit dans un fichier suivi, une image, ou un journal.
- `ADMIN_EMAIL` par défaut : `admin@dnum.lelabs.tech` (modifiable dans le fichier de secrets).
- **Seed** : étape one-shot de `./dev deploy`, après la mise en service de `auth` et des
  migrations, qui *assure* (crée ou met à jour) le compte admin via l'API d'administration
  GoTrue **interne** (`http://auth:9999/admin/users`, clé `service_role`), e-mail confirmé, mot de
  passe = `ADMIN_PASSWORD` du fichier, puis profil `role='admin'`, `is_active=true`.
  Le fichier de secrets est la **source de vérité** du mot de passe admin.
- `./dev reset` détruit les volumes mais **pas** `.devenv/secrets/` : après reset + deploy, le même
  mot de passe admin est réutilisé. Supprimer `.devenv/secrets/dev.env` force une régénération
  complète (la pile dev reste reconstructible de zéro).

## Conséquences
- Lisible par le responsable applicatif : `grep ADMIN_ .devenv/secrets/dev.env`.
- Le runner monte le dépôt en lecture seule (`/workspace`) et voit donc `.devenv/secrets/` :
  les tests peuvent lire `ADMIN_*` et `SERVICE_ROLE_KEY` ; les policies anti-secret doivent
  exclure `.devenv/` (non suivi) et ne viser que les fichiers suivis.
- Un changement de mot de passe admin depuis l'interface n'est pas prévu ; il serait écrasé au
  déploiement suivant (comportement voulu tant qu'il n'y a pas de gestion de mot de passe).
