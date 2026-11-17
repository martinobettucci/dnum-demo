# architecte — 2026-11-17T11:42:13+00:00

## Brief
Itération 002. Lis iterations/002/besoin.md, iterations/002/perimetre.md, CLAUDE.md, specs/, stack/compose.yml, dev, tools/runner/, tools/client/. Écris les spécifications et les ADR de l'application de suivi des tâches de l'équipe :
1) ADR stack : Supabase AUTO-HÉBERGÉ, composants minimaux et images à tag exact. Pressentis : supabase/postgres, supabase/gotrue, postgrest/postgrest et une passerelle unique (kong, ou nginx pour plus de légèreté) exposant /auth/v1 et /rest/v1. Le front est servi par la même passerelle, sur un seul port HTTP. Pas de Studio sauf justification. Tu choisis les versions et les justifies.
2) ADR front : technologie simple et construite dans Docker (aucun outil sur l'hôte ; node, si nécessaire, via image épinglée), avec supabase-js épinglé. L'interface doit être utilisable au clavier et à la souris et rester sobre.
3) SPEC modèle de données : tables, contraintes, RLS. Un compte non activé n'a accès à aucune donnée, même par l'API. Activation par l'admin. Calcul de la charge projetée défini par le PO (vue ou fonction SQL). Propositions d'entraide (proposer mon aide, demander de l'aide, accepter, refuser).
4) SPEC compte admin initial : seed idempotent à chaque déploiement, mot de passe généré et stocké hors git (par exemple .devenv/secrets/), clés JWT et secrets générés de même. Aucun secret commité.
5) SPEC piles dev/service : la pile dev reste jetable. Le service est persistant avec sauvegarde et restauration (Could, mais l'architecture doit le permettre). Garde la compatibilité avec ./dev et le garde-fou existant.
6) Indique ce que le testeur vérifie par test automatique (via APP_URL et l'API REST/Auth depuis le conteneur runner) et ce que le client recette au clavier et à la souris.
Chaque exigence SPEC-xxx.y référence les CA-002-x. Mets à jour specs/README.md. Tu n'écris que dans specs/.

## Compte rendu
Les specs et les ADR de l'itération 002 sont écrits dans `specs/`. Rien n'a été exécuté : aucun `docker pull`, aucun test. Les tags d'images doivent donc encore être vérifiés.

## ADR (`specs/adr/`)
- **ADR-001, pile** : je retiens quatre images épinglées :
  - `supabase/postgres:15.8.1.060`
  - `supabase/gotrue:v2.170.0`
  - `postgrest/postgrest:v12.2.8`
  - une passerelle construite sur `nginx:1.27.3-alpine`

  Les trois premières versions sont, à ma connaissance, publiées ensemble dans le compose officiel de Supabase auto-hébergé (début 2025), donc testées ensemble. Je n'ai pas pu le vérifier. J'ai préféré nginx à Kong : la clé `apikey` contrôlée par Kong est publique et ne protège rien ; la sécurité vient des JWT et de la RLS. nginx est déjà épinglé dans le dépôt et sert aussi le front. La passerelle bloque `/auth/v1/admin/*` (403). Studio est exclu, comme les autres composants Supabase non nécessaires. Le service `app` et `APP_URL=http://app` ne changent pas, donc le runner et le client restent compatibles.
- **ADR-002, front** : HTML et JavaScript natifs, sans framework. Seules dépendances, en version exacte avec `package-lock` : `@supabase/supabase-js@2.47.10` et `esbuild@0.24.2`. La construction se fait en plusieurs étapes, avec `node:22.12.0-alpine` puis nginx. Le front appelle sa propre origine (`window.location.origin`), un en-tête CSP `connect-src 'self'` l'impose, et la clé anonyme est servie par `/config.js` au démarrage, pas intégrée à l'image.
- **ADR-003, secrets et seed** :
  - Les secrets sont dans `.devenv/secrets/<pile>.env` (fichier en `0600`). `python3` de l'hôte les génère, uniquement quand ils manquent : il signe lui-même les clés JWT, sans rien installer.
  - Le seed admin passe par l'API admin interne de GoTrue. Il est idempotent et le fichier de secrets fait foi pour le mot de passe.
  - Adresse admin par défaut : `admin@dnum.lelabs.tech`.
- **ADR-004, piles** : la pile `dev` (projet `devenv`) garde son fonctionnement actuel. La pile `service` (projet `dnum-service`, port 8081) a ses propres volumes et réseau. La sauvegarde ne copie que les données de `auth` et `public` ; le schéma vient toujours des migrations du dépôt.
- **ADR-005, sécurité** : RLS activée et forcée partout, aucun droit pour le rôle `anon`. Toute règle commence par vérifier que le compte est activé (`private.is_active_member()`). L'affectation des tâches, les profils et les propositions ne se modifient que par des fonctions SQL appelées par l'API (RPC).

## SPEC
- **SPEC-001, pile et passerelle** (001.1 à 001.13) : services, images, ports publiés sur 127.0.0.1 et 10.77.0.25 uniquement, routage, CSP, réglages GoTrue et PostgREST, migrations versionnées.
- **SPEC-002, modèle de données** (002.1 à 002.22) :
  - tables `profiles`, `tasks`, `time_entries`, `help_proposals` ;
  - vues `task_summary` et `team_load`. La charge projetée est la somme des restes à faire des tâches non terminées, arrondie au 0,25 h. « Surchargé » veut dire plus de 7 h ;
  - fonctions `my_status`, `admin_list_accounts`, `admin_set_active`, `reassign_task`, `offer_help`, `request_help`, `respond_proposal` ;
  - une proposition passe à `expired` si la tâche est réaffectée ou terminée.

  Ces noms sont contractuels : le testeur s'en sert.
- **SPEC-003, admin et secrets**, **SPEC-004, piles dev et service**, **SPEC-005, interface** : la SPEC-005 fixe les libellés exacts, l'usage au clavier et à la souris, et le contenu de chaque écran.
- **SPEC-006, plan de vérification** : pour chacun des CA-002-1 à 36, ce qui relève du test automatique, de la recette client, des policies ou du responsable applicatif. Elle donne aussi la liste des policies attendues et un ordre de recette pour le client.
- `specs/README.md` est mis à jour.

**Répartition test / recette** : le testeur vérifie par l'API, depuis le runner, tout ce qui touche à la sécurité, aux règles de gestion, au calcul de charge (jeu de référence = 3 h), à la persistance (une passe d'écriture et une de relecture, avec un redéploiement entre les deux) et à la sauvegarde. Les identifiants sont lus en lecture seule dans `/workspace/.devenv/secrets/dev.env`. Le client recette l'interface : connexion, inscription, écran d'attente, tâches, temps, tableau de bord, propositions et administration.

## Points à confier à d'autres agents
1. **`action`** : faire un `docker pull` des tags de l'ADR-001. Si un tag n'existe pas, il faut me le renvoyer plutôt que le remplacer.
2. **`action`** : étendre le garde-fou à `./dev backup` et `./dev restore`. Faire évoluer `./dev` : secrets, migrations et seed pendant `deploy`, argument de pile, `backup` et `restore`.
3. **`policy`** : la policy `ENV-images-epinglees` doit aussi contrôler les clés `image:` de compose. La policy anti-secret doit exclure `.devenv/` et chercher en plus les JWT.
4. **Responsable applicatif** : le port est maintenant publié aussi sur 10.77.0.25 ; il doit vérifier que cela fonctionne en Docker rootless. Le contrôle de la RLS dans la base (`psql`) lui revient, car le runner n'accède pas à `db`.
5. **Pour l'utilisateur** : le mot de passe admin du fichier de secrets est réappliqué à chaque déploiement. Un changement de mot de passe fait depuis l'interface serait donc écrasé, mais l'interface n'en propose pas dans cette itération.
