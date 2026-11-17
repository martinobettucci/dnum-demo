# architecte — 2026-11-17T11:58:26+00:00

## Brief
Itération 002, tour 1 (mission relayée par le chef de projet). Arbitre avant le développement, en mettant à jour specs/ et en ajoutant un ADR dans specs/adr/ : (a) limite d'inscriptions GoTrue : le testeur fait environ 184 inscriptions par passe, il faut au moins 500 par heure en dev (SPEC-001.11) ; (b) la policy 15 interdit « localhost » dans /app.js, ce qui risque de bloquer le bundle supabase-js : faut-il préciser la règle ? (c) aligne les points d'accroche de ./dev (chemins des migrations et du seed) décrits dans le dernier journal iterations/002/journal/*-action.md avec les specs. Tu n'écris que dans specs/. Compte rendu : décisions, fichiers modifiés, points ouverts.

## Compte rendu
J'ai tranché les trois sujets dans `specs/` et ajouté l'ADR-006. Rien n'a été lancé : ce sont des décisions écrites, et les nouvelles règles ne sont encore ni dans les policies ni dans les tests.

## Décisions

**(a) Limite d'inscriptions GoTrue — nouvelle exigence SPEC-001.14**
- La pile dev doit accepter au moins 500 inscriptions et 2000 connexions par heure, sans aucune réponse 429.
- Réglage du service `auth` :
  - `GOTRUE_RATE_LIMIT_HEADER` absent. Toutes les requêtes passent par nginx avec la même adresse, donc un quota par adresse serait partagé entre les tests et le client.
  - `GOTRUE_RATE_LIMIT_EMAIL_SENT`, `_TOKEN_REFRESH`, `_VERIFY` et `_OTP` à 1000 ou plus. Cette valeur couvre le besoin quelle que soit l'unité de chaque clé.
  - Aucune limitation de débit dans nginx.
- Vérification :
  - une policy `STACK-auth-debit`, qui relit la configuration ;
  - un test `test_inscriptions_en_rafale` : 20 inscriptions de suite doivent toutes réussir ;
  - un test `test_aucune_reponse_429` : il échoue si une seule réponse 429 a été reçue pendant `./dev test`.
- Le testeur reste à 220 inscriptions maximum par passe (SPEC-006 §1), pour que deux passes dans l'heure tiennent sous 500.
- Pile `service` : mêmes valeurs pour cette itération. Il faudra des quotas de production, via un nouvel ADR, avant de l'exposer sur dnum.lelabs.tech.

**(b) Policy 15 et « localhost » — la règle est précisée (SPEC-001.8, ADR-002 amendé)**
- Le risque est réel : supabase-js 2.47.10 contient par défaut `http://localhost:9999`. Avec un seul fichier JS, la règle échouerait quoi que fasse notre code.
- Décision : le front est servi en deux fichiers.
  - `/app.js` ne contient que notre code. La règle stricte s'applique à lui, ainsi qu'à `/`, `/config.js` et `/style.css`.
  - `/vendor/supabase.js` ne contient que supabase-js. Il doit contenir le numéro de version `2.47.10`. `localhost` et `:9999` y sont tolérés, car notre code passe l'URL de la page à la bibliothèque et l'en-tête de sécurité CSP bloque toute autre origine. `:3000`, `:5432`, `http://auth`, `http://rest`, les jetons JWT et les secrets restent interdits.
  - Aucun autre fichier `.js` n'est servi : la tolérance ne peut pas s'étendre à notre code.
- Alternatives écartées : supprimer `localhost` de la règle, ou réécrire la chaîne dans le fichier après sa construction.

**(c) Points d'accroche de `./dev` — alignés sur le journal de l'agent `action`**
- Ce qui est déjà dans `./dev` et `tools/deploy/` devient la référence (nouvelles exigences SPEC-004.11 à SPEC-004.15) :
  - services `migrate` et `seed` : image, commande, dossiers montés, fichier de secrets `${DEVENV_SECRETS}` ;
  - migrations `app/db/migrations/NNN_<sujet>.sql`, une transaction par fichier, sans `BEGIN;`/`COMMIT;` au premier niveau, appliquées après `auth` ;
  - seed admin en deux temps : `seed.py`, puis `db.sh promote-admin`, qui doit mettre à jour exactement un profil ;
  - ordre du déploiement : secrets, `db` et `auth`, migrations, `rest` et `app`, seed, puis le navigateur `client` en dev ;
  - prérequis : contrôles de santé sur `db`, `auth` et `app`, et mots de passe des rôles de base fixés dès un volume vide.
- Syntaxe de restauration alignée : `./dev restore [pile] <fichier>`.
- Aucune modification de `./dev` n'est demandée.

## Fichiers modifiés (tous dans `specs/`)
- `SPEC-001-pile-supabase.md` : exigences 001.1, 001.8, 001.11 et 001.13 précisées ; 001.14 ajoutée.
- `SPEC-003-admin-secrets.md` : 003.6 renvoie au seed en deux temps.
- `SPEC-004-piles-dev-service.md` : 004.7 et 004.8 précisées ; nouvelle section « Contrat `./dev` ↔ application » (004.11 à 004.15).
- `SPEC-006-plan-verification.md` : plafond d'inscriptions par passe (§1) ; policies 7 à 10 à écrire ou modifier (§3).
- `adr/ADR-002-front.md` : amendé pour le découpage en deux fichiers.
- `adr/ADR-006-verifiabilite-pile-dev.md` : créé.
- `README.md` : index mis à jour.

## Points ouverts
1. **Policy** : préciser la policy 15 en deux règles, écrire `STACK-auth-debit` et `STACK-points-accroche`, et étendre la policy 22 sur les migrations (SPEC-006 §3).
2. **Testeur** :
   - adapter `test_001_pile.py` aux deux règles et ajouter `/vendor/supabase.js` ;
   - écrire `test_inscriptions_en_rafale`, `test_aucune_reponse_429` et la collecte des 429 dans `conftest.py` ;
   - rester sous 220 inscriptions par passe.
3. **Développeur** :
   - construire le front en deux fichiers ;
   - servir `/vendor/` comme du JavaScript avec la même CSP ;
   - régler les limites de débit du service `auth` ;
   - écrire le compose conforme à SPEC-004.11 à 004.14.
4. **À confirmer au premier déploiement** (responsable applicatif) :
   - que `supabase_admin`, `supabase_auth_admin` et `authenticator` acceptent `POSTGRES_PASSWORD` dès un volume vide. Sinon, il faudra un script d'initialisation versionné ; pour `supabase_admin`, changer l'utilisateur du service `migrate` et mettre à jour SPEC-004.11 ;
   - que la limite d'e-mails de GoTrue est bien inactive en confirmation automatique : d'après le code de GoTrue, mais non vérifié ;
   - que `/vendor/supabase.js` ne contient pas `:3000`. Sinon, l'architecte est saisi.
5. **Pile `service`** : un ADR sur les quotas de production sera nécessaire avant toute exposition publique.
