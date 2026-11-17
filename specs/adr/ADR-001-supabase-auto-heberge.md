# ADR-001 — Back-end : Supabase auto-hébergé minimal derrière une passerelle nginx unique

Statut : accepté (itération 002) — couvre CA-002-1, CA-002-2, CA-002-3.

## Contexte
- Besoin : PostgreSQL + authentification + API, « Supabase comme back-end complet » (besoin.md),
  auto-hébergé dans la pile Docker (décision par défaut du chef de projet).
- Contraintes du dépôt (ADR-000) : pile Docker rootless jetable, images à tag exact, tout
  reproductible par `./dev bootstrap` / `./dev deploy`, rien d'installé sur l'hôte.
- Hors périmètre : e-mails/SMTP, temps réel, stockage de fichiers, fonctions edge, SSO.
- Le navigateur ne doit parler qu'à **une seule origine** sur **un seul port HTTP** (CA-002-3).

## Décision
Composants retenus (et eux seuls) :

| Service compose | Image (tag exact) | Rôle |
|---|---|---|
| `db` | `supabase/postgres:15.8.1.060` | PostgreSQL 15 avec rôles Supabase (`anon`, `authenticated`, `service_role`, `authenticator`, `supabase_auth_admin`), `pgcrypto`, `security_invoker` des vues (PG ≥ 15). |
| `auth` | `supabase/gotrue:v2.170.0` | Inscription / connexion e-mail + mot de passe, émission des JWT, API d'administration (interne). |
| `rest` | `postgrest/postgrest:v12.2.8` | API REST `/rest/v1` sur le schéma `public`, RLS appliquée via le rôle du JWT. |
| `app` | construite depuis `app/` sur `nginx:1.27.3-alpine` | **Passerelle unique** : sert le front (ADR-002) et relaie `/auth/v1/` → `auth:9999/`, `/rest/v1/` → `rest:3000/`. |

Justification des versions : ces trois tags forment un **ensemble cohérent publié ensemble** dans le
`docker-compose.yml` officiel de Supabase self-hosting (début 2025) ; ils sont donc testés
ensemble (migrations GoTrue compatibles avec les rôles de cette image Postgres, PostgREST 12
compatible PG 15). `nginx:1.27.3-alpine` est déjà épinglé dans le dépôt (aucune nouvelle image).
Une montée de version se fait en bloc, par un nouvel ADR, en reprenant un ensemble cohérent du
compose officiel. **Vérification préalable par l'agent `action`** : `docker pull` de chaque tag ;
si un tag est indisponible, l'architecte est saisi (pas de substitution silencieuse).

Choix de la passerelle : **nginx plutôt que Kong**.
- Kong (`kong:2.8.1`, déclaratif) n'apporte ici que la vérification de l'en-tête `apikey`, qui
  n'est pas une barrière de sécurité (la clé anonyme est publique par nature). La sécurité repose
  sur les JWT vérifiés par PostgREST/GoTrue et sur la RLS (ADR-005).
- nginx sert en plus les fichiers statiques du front : **un seul conteneur exposé**, déjà connu
  du dépôt, empreinte mémoire minimale, configuration lisible.
- La passerelle **refuse** `/auth/v1/admin/*` (403) : l'API d'administration GoTrue n'est
  joignable que sur le réseau interne de la pile (seed, tests).

Exclus : **Studio** (aucune justification : l'administration fonctionnelle est dans l'appli,
l'exploitation se fait par `psql` dans le conteneur `db` ; Studio ajouterait `pg-meta`, une
surface d'attaque et un second port), Realtime, Storage, Edge Functions, imgproxy, Analytics,
Vector, Supavisor, Inbucket/SMTP.

Réseau : seul `app` publie un port, lié à l'adresse LAN `10.77.0.25` (`APP_LAN_IP`), jamais à `0.0.0.0`.
`db`, `auth`, `rest` ne publient aucun port.
Le reverse proxy HTTPS de `dnum.lelabs.tech` (hors périmètre) visera `10.77.0.25:APP_PORT`.

> **Amendement (ADR-007, itération 002 tour 1 complément)** : la publication sur `127.0.0.1` est supprimée. Sous Docker
> rootless (driver `builtin`), publier le même port sur `127.0.0.1` et `10.77.0.25` échoue. Ports par pile : `dev` 8080,
> `service` 8081. Dérogation à CA-002-1 à valider par le product-owner.

Ordre de démarrage : `db` (sain) → `auth` (applique ses migrations du schéma `auth`, sain) →
migrations applicatives (one-shot, SPEC-002) → `rest` (rechargement du cache de schéma par
`NOTIFY pgrst, 'reload schema'`) → `app` (sain) → seed admin (one-shot, SPEC-003).

## Conséquences
- Le nom de service `app` et `APP_URL=http://app` sont conservés : runner, client, policies
  existants fonctionnent sans modification.
- L'image `supabase/postgres` est volumineuse (~1 Go) : téléchargée une fois au bootstrap.
- Pas d'e-mail : GoTrue en confirmation automatique (`GOTRUE_MAILER_AUTOCONFIRM=true`).
- Les clés `anon` / `service_role` et le secret JWT sont générés hors git (ADR-003).
