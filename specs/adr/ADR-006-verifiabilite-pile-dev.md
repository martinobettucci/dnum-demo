# ADR-006 — Vérifiabilité de la pile dev : débit GoTrue, règle de même origine, contrat `./dev` ↔ application

Statut : accepté (itération 002, tour 1, avant le développement). Amende ADR-002 (découpage du bundle front).
Complète ADR-001, ADR-003 et ADR-004. Specs touchées : SPEC-001.1, SPEC-001.8, SPEC-001.11, SPEC-001.13,
SPEC-001.14 (nouvelle), SPEC-003.6, SPEC-004.7, SPEC-004.8, SPEC-004.11 à SPEC-004.15 (nouvelles), SPEC-006 §1 et §3.

## Contexte
Trois frictions sont apparues avant le développement :
1. **Débit.** Une passe de `./dev test` fait environ 184 inscriptions (journal du testeur). Le scénario de persistance
   (CA-002-33) en fait deux dans l'heure, et la recette client s'y ajoute. SPEC-001.11 n'exigeait que 100 inscriptions par heure.
   Par ailleurs, toutes les requêtes arrivent à GoTrue par nginx, donc avec la même adresse IP. Un quota par IP serait
   partagé entre les tests et le client.
2. **Même origine.** La policy `FRONT-meme-origine` (n° 15) et le test SPEC-001.8 interdisent `localhost` et `:9999` dans
   `/app.js`. Or `@supabase/supabase-js@2.47.10` contient par construction la valeur par défaut d'auth-js
   `http://localhost:9999`. Un bundle unique ferait donc échouer la règle quel que soit le code de l'application :
   ce serait un faux positif.
3. **Points d'accroche.** `action` a préparé dans `./dev` et `tools/deploy/` (journal `114925-action.md`) les services
   `migrate` et `seed`, les chemins de montage et la séquence de déploiement. Les specs les décrivaient trop
   vaguement pour que le développeur et les policies s'y alignent sans ambiguïté.

## Décision
### §1 — Débit d'authentification (pile dev)
- Exigence mesurable : au moins **500 inscriptions** et **2000 connexions** par heure, sans aucune réponse 429 (SPEC-001.14).
- Configuration explicite, sans se fier aux valeurs par défaut : `GOTRUE_RATE_LIMIT_HEADER` absent (aucun quota par IP),
  `GOTRUE_RATE_LIMIT_{EMAIL_SENT,TOKEN_REFRESH,VERIFY,OTP}` ≥ 1000, et aucune limitation nginx sur `/auth/v1/` ni `/rest/v1/`.
  Les unités sont celles de GoTrue v2.170.0 (par heure ou par 5 minutes selon la clé) : la valeur 1000 dépasse le besoin dans les deux cas.
- D'après le code de GoTrue, la limite d'envoi d'e-mails ne s'applique pas quand la confirmation est automatique.
  Elle est tout de même relevée, par défense en profondeur ; c'est à confirmer au premier deploy par `test_inscriptions_en_rafale`.
- Une réponse 429 pendant les tests est un **échec explicite** (`test_aucune_reponse_429`) et non un défaut fonctionnel masqué.
- Pile `service` : mêmes valeurs pour cette itération (aucun SMTP, pas d'exposition publique décidée). Avant d'exposer
  `dnum.lelabs.tech`, un nouvel ADR fixera des quotas de production, avec un en-tête d'IP fiable transmis par le reverse proxy.

### §2 — Règle de même origine : partition code applicatif / bibliothèque
- Le front est construit en **deux fichiers** par esbuild :
  - `dist/app.js` contient le code de `app/web/` seul ; il importe `/vendor/supabase.js` comme module externe ;
  - `dist/vendor/supabase.js` est le bundle ES de `@supabase/supabase-js@2.47.10` seul (point d'entrée qui réexporte `createClient`).
- **Règle stricte** (`localhost`, `:9999`, `:3000`, `:5432`, `http://auth`, `http://rest`) sur tout ce que nous écrivons :
  `/`, `/app.js`, `/config.js` et `/style.css`.
- **Règle bibliothèque** sur `/vendor/supabase.js` : la version `2.47.10` doit être présente ; `:3000`, `:5432`, `http://auth`,
  `http://rest`, tout JWT et toute valeur secrète sont interdits ; `localhost` et `:9999` sont tolérés, car ce sont des valeurs
  par défaut inertes. Elles sont remplacées par `createClient(window.location.origin, …)` et la CSP `connect-src 'self'`
  (SPEC-001.9) empêche techniquement le navigateur d'appeler une autre origine.
- Aucun autre fichier `.js` n'est servi : la tolérance ne peut pas s'étendre à du code applicatif.
- Alternatives écartées :
  - retirer `localhost` de la règle : on perdrait la détection d'une URL de développement laissée dans notre code ;
  - réécrire la chaîne dans le bundle après le build (`sed`, `--define`) : c'est fragile, et la version servie ne serait plus la version épinglée ;
  - s'appuyer sur la seule CSP : elle ne se vérifie qu'à l'exécution, alors que la règle statique détecte l'erreur au déploiement.

### §3 — Contrat `./dev` ↔ application
- Les chemins et noms préparés par `action` deviennent la **référence** (SPEC-004.11 à SPEC-004.15) :
  - service `migrate` (`supabase/postgres:15.8.1.060`, `bash /ops/db.sh`), avec `tools/deploy` monté sur `/ops:ro` et `app/db/migrations` sur `/migrations:ro` ;
  - service `seed` (`python:3.13.1-slim`, `python3 /ops/seed.py`) ;
  - profil `deploy`, `env_file` en forme longue `- path: ${DEVENV_SECRETS}` avec `required: false` (tour 2, SPEC-004.11 : `teardown` et `reset` sans fichier de secrets) ;
  - séquence secrets → `db` + `auth` → migrations → `rest` + `app` → seed → promote-admin → client (dev).
- Les migrations s'exécutent **après** `auth`, pour que le trigger `on_auth_user_created` puisse viser `auth.users`.
  Une transaction par fichier : aucune instruction de transaction de premier niveau dans les fichiers.
- Chaque côté a son propriétaire. L'outillage (`./dev`, `tools/deploy/`) est maintenu par `action`. La déclaration
  compose, les migrations et la passerelle sont maintenues par le `developpeur`. Un changement de nom ou de chemin passe
  d'abord par SPEC-004.
- Prérequis explicités, car `up --wait` en dépend : healthchecks de `db`, `auth` et `app`, et authentification
  des rôles `supabase_admin`, `supabase_auth_admin` et `authenticator` par `POSTGRES_PASSWORD` depuis un volume vide.

## Conséquences
- **Développeur** :
  - build esbuild à deux sorties ; `index.html` charge `/app.js` (module) ;
  - nginx sert `/vendor/` avec un type `javascript` et la même CSP ;
  - variables de débit dans le service `auth` ;
  - compose conforme à SPEC-004.11 à SPEC-004.14 ;
  - script d'initialisation des mots de passe des rôles si l'image ne le fait pas.
- **Policy** : préciser la n° 15 (deux règles), ajouter `STACK-auth-debit` et `STACK-points-accroche`, étendre la n° 22
  (SPEC-006 §3, points 7 à 10).
- **Testeur** :
  - adapter `test_fichier_servi_sans_url_vers_autre_port` à la partition et ajouter `/vendor/supabase.js` ;
  - ajouter `test_inscriptions_en_rafale`, ainsi que la collecte des 429 dans `conftest.py` et `test_aucune_reponse_429` ;
  - plafond de 220 inscriptions par passe.
- **Action** : aucun changement requis dans `./dev`. Point à confirmer au premier deploy : `supabase_admin` accepte
  `POSTGRES_PASSWORD` (sinon, ajuster `PGUSER` du service `migrate` et mettre à jour SPEC-004.11).
- Contraintes préservées :
  - aucun état requis (pile dev jetable, quotas en mémoire de GoTrue remis à zéro à chaque redémarrage) ;
  - aucune nouvelle image ni dépendance (supabase-js et esbuild déjà épinglés) ;
  - tout se reconstruit par `./dev bootstrap` puis `./dev deploy`.
