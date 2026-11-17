# SPEC-004 — Piles dev / service, persistance, sauvegarde et compatibilité `./dev`

Itération 002. Décision : ADR-004. Couvre CA-002-1, CA-002-33, CA-002-36 (Could).
Contraintes préservées : pile dev jetable (aucun état nécessaire), images épinglées,
reconstruction par `./dev bootstrap`, exclusivité du `responsable-applicatif` (garde-fou).

| Id | Exigence (énoncé vérifiable) | CA | Vérification |
|---|---|---|---|
| SPEC-004.1 | `./dev deploy`, `./dev teardown`, `./dev reset`, `./dev test`, `./dev policies`, `./dev status`, `./dev logs` sans argument agissent sur la pile `dev` (projet compose `devenv`) comme aujourd'hui ; `APP_URL=http://app` reste valable pour `runner` et `client`. | CA-002-1 | [R] ; [T] tests existants (`test_000_socle.py`) verts |
| SPEC-004.2 | Pile dev jetable : depuis un volume vide (`./dev reset` puis `./dev deploy`), migrations + seed produisent un état utilisable sans aucune donnée préalable autre que `.devenv/secrets/dev.env`, lui-même régénérable s'il est absent. | CA-002-1 | [R] ; [T] SPEC-003.4 après reset |
| SPEC-004.3 | Persistance : les données Postgres sont dans le volume nommé `db-data` ; un `./dev deploy` (ou `teardown` puis `deploy`) **sans** `reset` conserve comptes, activations, tâches, temps et propositions ; `ADMIN_PASSWORD` n'est pas régénéré. | CA-002-33 | [T] en deux temps : `test_..._persistance_ecrire` crée un jeu marqué (ex. titre `persist-<horodatage>`) et l'enregistre dans `iterations/NNN/tests/persistance.json` ; après redéploiement, `test_..._persistance_relire` le retrouve et se connecte avec `ADMIN_PASSWORD` |
| SPEC-004.4 | `./dev reset` supprime `db-data` (dev) : après reset + deploy, les données du jeu marqué ont disparu et le compte admin existe à nouveau. | CA-002-1 | [R] |
| SPEC-004.5 | `bootstrap`/`build` construisent aussi l'image `app` multi-étapes (node épinglé) et tirent les images `db`, `auth`, `rest` : aucun outil requis sur l'hôte au-delà de docker, git, python3, curl. | CA-002-2 | [P] `ENV-*` ; [R] bootstrap sur machine vierge |
| SPEC-004.6 | Garde-fou : `./dev deploy|teardown|reset|backup|restore` (avec ou sans argument de pile) restent refusés à tout agent autre que `responsable-applicatif`. | — (règle CLAUDE.md) | [P] test du garde-fou par entrée JSON simulée |
| SPEC-004.7 (Could) | `./dev deploy service` déploie le projet compose `dnum-service` (port `8081` par défaut, volumes et réseau propres, secrets `.devenv/secrets/service.env`) sans redémarrer ni modifier les conteneurs/volumes du projet `devenv`. | CA-002-36 | [R] `docker compose ls` / `docker volume ls` avant-après ; [T] avec `DEVENV_PILE=service` |
| SPEC-004.8 (Could) | `./dev backup [pile]` produit `.devenv/backups/<pile>/<AAAAMMJJ-HHMMSS>.dump` (données de `auth` et `public`) et un `.json` (commit, dernière migration, images) ; `./dev restore <pile> <fichier>` sur une pile vierge au même niveau de migration restitue comptes (membres : anciens mots de passe ; admin : `ADMIN_PASSWORD` du fichier, réappliqué par le seed), tâches, temps et propositions ; niveau de migration différent ⇒ refus explicite. | CA-002-36 | [T] scénario : jeu marqué → backup → reset → deploy → restore → relecture |
| SPEC-004.9 (Could) | `./dev reset service` sans `--confirmer-destruction` ⇒ refus, rien n'est détruit. | CA-002-36 | [R] |
| SPEC-004.10 | `mise-en-service.md` (responsable applicatif) annonce la pile, le port HTTP, les deux URL (`127.0.0.1`, `10.77.0.25`), le commit, l'emplacement du fichier de secrets (pas sa valeur). | CA-002-1, CA-002-4 | [R] |
