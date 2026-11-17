# ADR-009 — Redémarrage automatique de toute la pile service

Statut : accepté (itération 002, tour 2, 2026-11-17). Amende ADR-004 (surcouche `service`).
Specs touchées : SPEC-004.7 (amendée), SPEC-006 §2 (CA-002-36) et §3 (policy n° 26 `STACK-restart-service`, ex-12 : collision corrigée au tour 2 par arbitrage du chef de projet).
Recommandation du chef de projet retenue.

## Contexte

- La pile `service` est persistante et exposée en continu sur `10.77.0.25:8081` (ADR-004, ADR-007, US-17).
- SPEC-004.7 (tour 1) ne plaçait `restart: unless-stopped` que sur `app`.
- Constat du développeur (`iterations/002/journal/120715-developpeur.md`, point 5) : après un redémarrage de
  l'hôte ou du démon Docker, `app` repart seul alors que `db`, `auth` et `rest` restent arrêtés. La passerelle
  répond, mais `/auth/v1/` et `/rest/v1/` échouent : la pile est joignable et non fonctionnelle.
- `depends_on` avec `condition: service_healthy` ne s'applique pas lors d'un redémarrage automatique par le démon :
  `./dev deploy` n'est pas rejoué. Sans politique de redémarrage, rien ne relance `auth` et `rest`.
- `auth` et `rest` échouent au démarrage tant que `db` n'accepte pas de connexion. Une politique de redémarrage
  les relance donc jusqu'à ce que `db` soit prêt.

## Options étudiées

| Option | Description | Évaluation |
|---|---|---|
| (a) `app` seul | Statu quo de SPEC-004.7 (tour 1). | Rejetée : après redémarrage de l'hôte, la pile répond sans fonctionner. |
| (b) Pile service entière | `restart: unless-stopped` sur `db`, `auth`, `rest` et `app`. | **Retenue.** Chaque service long-running repart seul ; `auth` et `rest` se relancent jusqu'au retour de `db`. |
| (c) Pile dev aussi | Même politique sur la pile `dev`. | Écartée : la pile `dev` est jetable (ADR-000, ADR-004), elle se redéploie à la main et ne doit pas survivre à l'hôte. |
| (d) `restart: always` | Relance même après un `docker stop` manuel. | Écartée : `./dev restore` arrête `auth` et `rest` volontairement ; `unless-stopped` respecte cet arrêt. |

## Décision

1. La surcouche `stack/compose.service.yml` porte `restart: unless-stopped` sur **`db`, `auth`, `rest` et `app`**.
2. `migrate` et `seed` (one-shot, profil `deploy`, SPEC-004.11, SPEC-004.13) **n'ont aucune politique** `restart`.
3. `runner` et `client` ne sont pas démarrés par la pile service (SPEC-004.7).
4. La pile `dev` n'a **aucune** politique `restart` (dans `stack/compose.yml`).
5. `./dev teardown` (`down`) supprime les conteneurs : aucun redémarrage après cette commande. `./dev restore` arrête
   `auth` et `rest` par `stop` : ils ne repartent pas au redémarrage du démon tant qu'ils ne sont pas relancés
   par `./dev` (comportement `unless-stopped`).

## Conséquences

- Après redémarrage de l'hôte, la pile service revient sans intervention, avec un délai de quelques dizaines de
  secondes : `db` d'abord, puis `auth` et `rest` dès qu'ils réussissent à se connecter (backoff du démon).
- Une boucle de redémarrage (par exemple un volume `db-data` corrompu) devient visible par `./dev status` et
  `docker ps` au lieu d'être silencieuse. Le responsable applicatif le consigne dans `mise-en-service.md`.
- `db` avec `unless-stopped` : une panne de `db` est relancée sans intervention. Ce comportement est voulu pour
  une base persistante exposée en continu.
- Le partage du réseau et des volumes avec la pile `dev` ne change pas (SPEC-004.7 : isolation inchangée).
- Vérification : [P] `STACK-restart-service` (analyse de `docker compose config` avec les deux fichiers) et [R]
  `docker inspect` sur les quatre conteneurs. Aucun test de redémarrage de l'hôte n'est exigé cette itération
  (disruptif pour les autres sessions) ; c'est un point ouvert pour le chef de projet.

## Alternatives écartées

- Ajouter un `healthcheck` à `rest` et un script de relance : plus de mécanique pour le même effet ; `rest` n'a pas
  de shell (SPEC-004.14).
- Démarrage manuel après reboot par le responsable applicatif : contraire à US-17 (service continu).
