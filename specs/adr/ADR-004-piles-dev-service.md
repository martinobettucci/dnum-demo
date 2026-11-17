# ADR-004 — Deux piles (dev jetable, service persistante) sur un seul fichier compose

Statut : accepté (itération 002) — couvre CA-002-1, CA-002-33, CA-002-36 (Could).

> **Amendements (tour 1 complément, 2026-11-17)** : la publication des ports suit ADR-007 (une adresse LAN par pile,
> pas de `127.0.0.1`). Les images locales portent un tag par pile (`devenv/app:dev`, `devenv/app:service`, ADR-008).
> La pile `service` est **retenue pour cette itération** par décision du chef de projet (statut Could levé dans
> SPEC-004 ; `perimetre.md` à mettre à jour par le product-owner).
>
> **Amendement (tour 2, 2026-11-17, ADR-009)** : la politique `restart: unless-stopped` de la surcouche `service`
> porte sur **db, auth, rest et app** (et non plus sur `app` seul). La pile `dev` n'en a aucune.

## Contexte
- ADR-000 : la pile est jetable volumes compris. Le besoin ajoute une pile `service` exposée,
  à données persistantes avec sauvegarde (décision par défaut du chef de projet, révisable).
- `./dev` et `tools/guards/guard.py` doivent rester compatibles : seul le
  `responsable-applicatif` démarre / arrête / détruit une pile.

## Décision
- Un seul `stack/compose.yml` décrit tous les services ; la pile est sélectionnée par
  `DEVENV_PILE` (défaut `dev`) ou un argument de `./dev` (`./dev deploy service`).
  - `dev` : projet compose `devenv` (inchangé), port `APP_PORT=8080`, secrets `.devenv/secrets/dev.env`.
  - `service` : projet compose `dnum-service`, surcouche `stack/compose.service.yml`
    (port `8081`, `restart: unless-stopped`, secrets `.devenv/secrets/service.env`), sans
    services `runner`/`client` attachés par défaut.
  Des projets compose distincts ⇒ réseaux et volumes distincts : aucune interaction entre piles.
- Les données de Postgres vivent dans le volume nommé `db-data` du projet. Il survit à
  `./dev deploy` et `./dev teardown`, et disparaît avec `./dev reset` (dev). Rien de nécessaire
  n'y vit pour la pile dev : migrations + seed reconstruisent un état utilisable à vide.
- **Sauvegarde / restauration** (Could, l'architecture le permet dès maintenant) :
  - `./dev backup [pile]` : `pg_dump -Fc --data-only --schema=auth --schema=public` exécuté dans
    le conteneur `db`, vers `.devenv/backups/<pile>/<horodatage>.dump` + fichier `.json` de
    métadonnées (commit, dernière migration appliquée, versions d'images).
  - `./dev restore <pile> <fichier>` : sur une pile déployée au même niveau de migration
    (refus sinon), arrête `auth` et `rest`, vide les tables applicatives et `auth`, restaure
    (`--disable-triggers`), relance, puis rejoue le seed admin.
  - Sauvegarde **données seules** : le schéma vient toujours du dépôt (migrations), ce qui
    garde le dépôt comme source de vérité.
- `./dev reset service` exige une confirmation explicite (`--confirmer-destruction`).
- Garde-fou : la liste des commandes réservées s'étend à `./dev restore` (destructrice) ;
  `./dev backup` reste réservé au responsable applicatif par cohérence d'exploitation.

## Conséquences
- `./dev deploy`, `teardown`, `reset` sans argument conservent exactement leur sens actuel (dev).
- Évolution du garde-fou `tools/guards/guard.py` (motif `restore|backup`) à confier à `action`.
- Le runner et le client restent attachés à la pile `dev` ; tester `service` passe par
  `DEVENV_PILE=service ./dev test` (même mécanisme, autre projet compose).
- Les sauvegardes vivent hors git, sur l'hôte : leur copie hors machine est hors périmètre.
