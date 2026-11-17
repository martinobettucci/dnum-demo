# responsable-applicatif — 2026-11-17T13:44:07+00:00

## Brief
Deux tâches en LECTURE SEULE sur les piles (aucun deploy, reset, restore, teardown ; dev et service restent intactes). 1) Relève les versions apt exactes de git, curl et bash disponibles dans python:3.13.1-slim, par exemple : docker run --rm python:3.13.1-slim sh -c 'apt-get -o APT::Sandbox::User=root update >/dev/null && apt-cache policy git curl bash'. Donne dans ta réponse, pour chaque paquet, la version candidate exacte (Candidate). 2) Ajoute à iterations/002/mise-en-service.md (écart E9) le méta de l'audit npm : statut et sha256 du fichier lock, relevés dans les résultats existants des policies (iterations/002/policies/) et le fichier lock du dépôt ; si une valeur n'existe pas, dis-le au lieu de l'inventer. Aucun secret ni e-mail dans la réponse.

## Compte rendu
Les deux tâches sont faites. Aucune commande de déploiement, reset, restore ou teardown n'a été lancée. Les piles `dev` et `service` n'ont pas été touchées.

## 1. Versions apt candidates dans `python:3.13.1-slim` (Debian bookworm)

| Paquet | Installé dans l'image | Candidate (Candidate) | Source |
|---|---|---|---|
| git | non installé | **1:2.39.5-0+deb12u3** | deb.debian.org bookworm/main |
| curl | non installé | **7.88.1-10+deb12u15** | deb.debian.org bookworm/main |
| bash | 5.2.15-2+b7 | **5.2.15-2+b13** | deb.debian.org bookworm/main |

Les versions précédentes disponibles sont git `1:2.39.5-0+deb12u2` (bookworm-security), curl `7.88.1-10+deb12u5` (bookworm-security) et bash `5.2.15-2+b7` (installée, sans candidat plus récent côté sécurité).

## 2. Écart E9 ajouté à `iterations/002/mise-en-service.md`

Une section « Écart E9 — Empreinte de l'audit npm consignée » est ajoutée en fin de fichier, avec la ligne d'exclusivité en tête.

- **Statut de l'audit** : `reussie` (`iterations/002/policies/audit-npm.meta.json`, daté du 2026-11-17T13:40:30+00:00, image `node:22.12.0-alpine`).
- **sha256 du lock** : `2bbd9f50bff63cd1e3a5dfc333ae786690fccdc4753c3470c70d410ce53f9eb9` (`app/web/package-lock.json`). Il est identique à la valeur du méta et au fichier actuel, donc pas de dérive depuis l'audit.
- **Résultat de la policy** `FRONT-audit-npm` dans `results.json` : respectée, rc 0. Le rapport remonte 3 paquets (GHSA-67mh-4wv8-2f99 sur esbuild, GHSA-8r88-6cj9-9fh5 sur auth-js, et un troisième).

Le troisième paquet n'est pas identifié dans les données que j'ai lues. Je ne l'ai pas nommé dans le fichier.

Pour l'ensemble de l'écart E9, la vérification [R] prévue par ADR-014 reste à faire pour relire ces deux valeurs.

Message d'exclusivité à diffuser par le chef de projet : « Mise en service assurée exclusivement par le responsable applicatif. Aucun autre agent ne démarre, n'arrête ni ne détruit la pile : adressez vos demandes au chef de projet. »
