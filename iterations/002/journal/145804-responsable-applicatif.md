# responsable-applicatif — 2026-11-17T14:58:04+00:00

## Brief
Fin d'itération, étape 1 de structure : redéploie DEV sans reset (le reset de dev reste INTERDIT 7 jours ; pas de teardown ; service NE DOIT PAS être touchée). La Team Agile a corrigé le build (./dev build reconstruit désormais les tags :dev et :service, et un correctif nginx Cache-Control: no-cache est prêt). Fais : 1) ./dev build si le deploy ne le fait pas, puis ./dev deploy dev, rc et durée. 2) Contrôle que le front servi sur http://10.77.0.25:8080 contient les correctifs, par EMPREINTES et non par grep de texte brut (le bundle minifié échappe les accents) : md5 du /app.js servi, et recherche de la séquence échappée correspondant à « pour la t\xE2che » ou équivalent ; l'attendu côté Team Agile est un md5 4eb8c08e… pour le bundle servi, dis ce que tu mesures. 3) curl -I sur /, /app.js et /vendor/supabase.js de :8080 : relève Cache-Control. 4) Santé des services, et que service n'a pas bougé (conteneurs, volume, comptages en nombres). 5) Rapporte aussi l'image dev et l'image service utilisées (id et date de création). Aucun secret ni e-mail dans la réponse. Mets à jour iterations/002/mise-en-service.md. En cas d'échec : stoppe et donne l'incident avec les logs.

## Compte rendu
Mise en service de DEV réussie, sans reset, teardown ni toucher à service. Un écart mineur est à signaler sur service (voir point 4).

Mise en service assurée exclusivement par le responsable applicatif. Aucun autre agent ne démarre, n'arrête ni ne détruit la pile : adressez vos demandes au chef de projet.

**1. Build et déploiement**
- `./dev build` : rc 0, 5 s. Les tags `devenv/app:dev` et `devenv/app:service` sont reconstruits.
- `./dev deploy dev` : rc 0, **12 s**. Migrations et seed inchangés (admin existant, profil actif).

**2. Contrôle du front sur :8080 (empreintes)**
- md5 de `/app.js` servi : **`4eb8c08e9af484992a63298ad56423c8`** (19 354 octets). Conforme à l'attendu de la Team Agile.
- Séquence échappée `pour la t\xE2che` : 2 occurrences. `pour la t\u00e2che` : 0.

**3. En-têtes HTTP**

| Ressource | Statut | Cache-Control |
|---|---|---|
| `/` | 200 | `no-cache` |
| `/app.js` | 200 | `no-cache` |
| `/vendor/supabase.js` | 200 | `no-cache` |

**4. Santé et non-intrusion de service (:8081)**
- Conteneurs `dnum-service-{app,rest,auth,db}-1` : mêmes ids et mêmes heures de démarrage qu'avant. Tous sont healthy ou up.
- Volume `dnum-service_db-data` : créé le 2026-11-17 13:33:40 UTC, inchangé.
- Comptages avant → après : auth.users 8 → 8, auth.identities 8 → 8, auth.sessions 10 → 10, auth.schema_migrations 61 → 61, public.profiles 8 → 8, public.tasks 3 → 3, public.time_entries 1 → 1, public.help_proposals 1 → 1.
- **Écart** : `auth.refresh_tokens` passe de 10 à 11 pendant la fenêtre. Aucune commande n'a été lancée sur service. Il s'agit probablement d'un rafraîchissement de session ordinaire, mais je ne l'ai pas investigué.
- `GET :8081/` : 200.

**5. Images utilisées**
- `devenv/app:dev` : `sha256:70b36b559a91…`, créée le 2026-11-17 14:56:45 UTC. Conteneur `devenv-app-1` recréé à 14:58:40 UTC.
- `devenv/app:service` : `sha256:20ea576bcb08…`, créée le 2026-11-17 14:56:45 UTC.

**Version déployée** : commit `a4d5b4d` plus des modifications non commitées dans `app/Dockerfile`, `app/nginx/default.conf` et `dev`. Le correctif `no-cache` et le build `:service` ne sont donc pas encore commités.

**Incidents** : aucun. Le fichier `iterations/002/mise-en-service.md` est mis à jour avec cette section ; l'historique précédent est conservé.
