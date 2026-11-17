# responsable-applicatif — 2026-11-17T11:58:31+00:00

## Brief
Itération 002, tour 1. Prépare la mise en service SANS déployer l'appli. 1) Vérifie que la publication d'un port sur 10.77.0.25 fonctionne en Docker rootless (SPEC-001.4, ADR-004), avec un test jetable. 2) Relis ./dev deploy, backup et restore. 3) Prépare le plan de mise en service des piles dev et service. 4) Rapporte les risques. Ne déploie pas l'appli.

## Compte rendu
Message de l'équipe DevOps (session spark-docker-f1) au chef de projet, itération 002, tour 1.

**Mise en service assurée exclusivement par le responsable applicatif. Aucun autre agent ne démarre, n'arrête ni ne détruit la pile : adressez vos demandes au chef de projet.**

Rien n'a été déployé. La pile `devenv` de l'itération 001 tourne toujours (app healthy sur 127.0.0.1:8080), je ne l'ai pas touchée. Le seul fichier écrit est `iterations/002/mise-en-service.md`, marqué « non déployé ».

**1) Publication de port sur 10.77.0.25 (SPEC-001.3/.4, ADR-004)** : testé avec des conteneurs jetables, supprimés après chaque essai.
- Un port publié seul sur `127.0.0.1` ou seul sur `10.77.0.25` fonctionne (HTTP 200).
- Le même port publié sur les deux adresses échoue (`address already in use`), dans les deux ordres d'écriture.
- Deux ports différents (127.0.0.1:18500, 10.77.0.25:18501) fonctionnent tous les deux.
- Cause probable : le driver de port `builtin` du Docker rootless (Docker 29.10.0). Je n'ai modifié aucune configuration.
- **Conséquence : SPEC-001.3 et SPEC-001.4 ne peuvent pas être satisfaits tels quels.** Il faut une décision d'architecte : ports distincts, publication sur 10.77.0.25 seule, ou changement de driver (`slirp4netns`/`pasta`, qui touche l'hôte et demande un test dédié).

**2) Relecture de `deploy`, `backup`, `restore`** : points bloquants constatés dans le dépôt.
- `stack/compose.yml` ne contient ni `db`, ni `auth`, ni `rest`, ni `migrate`, ni `seed`. `./dev deploy` démarre donc `app` seul, saute les migrations et le seed, puis **rend code 0**. C'est un faux succès, contraire à SPEC-001.5.
- `app/db/migrations/` est absent.
- `stack/compose.service.yml` est absent : la pile `service` serait une pile `app` seule sur 127.0.0.1:8081, sans redémarrage automatique.
- `backup` et `restore` ne peuvent pas fonctionner : ils passent par les services `migrate` et `db`, absents.

**3) Plan de mise en service** (détaillé dans le fichier) : il ne peut être exécuté qu'après correction des points ci-dessus. Pour la pile dev : `doctor`, `policies`, `teardown` si le plan le demande, `reset`, `deploy`, relevés `curl` et `ss`, puis scénario backup/reset/deploy/restore. Pour la pile service : relevé `docker compose ls` et `docker volume ls` avant et après, `deploy service`, vérification que la pile `devenv` est inchangée.

**4) Risques** :
- R1 (élevé) : faux succès de `deploy`.
- R2 (élevé) : SPEC-001.3/.4 impossibles en l'état.
- R3 (moyen) : 10.77.0.25 est un bail DHCP (`dynamic`) ; un changement d'adresse casse la publication LAN.
- R4 (élevé pour la pile service) : aucune sauvegarde possible tant que backup/restore sont inopérants.
- R5 (faible) : `devenv/app:dev` est partagé entre les deux piles ; un rebuild de l'une écrase le tag de l'autre.
- R6 (faible) : la pile dev de l'itération 001 n'est pas tracée au commit (`deploy.log` indique « non-commite »).
- R7 (élevé) : pas de secrets ni de sauvegardes existants. Un `reset service` effacerait toute donnée non sauvegardée.

**Demandes au chef de projet** :
- Faire décider l'architecte sur R2 (ADR ou amendement de SPEC-001.3/.4).
- Faire compléter `compose.yml` (db, auth, rest, migrate, seed), ajouter les migrations, et faire échouer `deploy` si `db` est absent.
- Confirmer si la pile service est retenue pour cette itération (alors `compose.service.yml` est nécessaire).

Je n'ai lancé aucun des contrôles `policies/checks` (ils écriraient dans `iterations/002/policies/`) ; ils échoueraient en l'état sur la composition et les ports.
