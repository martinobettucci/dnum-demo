# architecte — 2026-11-17T12:03:05+00:00

## Brief
Itération 002, tour 1, complément. Arbitre dans specs/ (tu n'écris que dans specs/, ADR si besoin) : (1) Ports : sous Docker rootless, publier le même port sur 127.0.0.1 ET sur 10.77.0.25 échoue (address already in use) ; SPEC-001.3 et SPEC-001.4 ne sont pas satisfaisables telles quelles. Recommandation du chef de projet : ne publier que sur 10.77.0.25 (cible du reverse proxy), ou deux ports distincts ; ne pas changer le driver réseau de l'hôte. Décide aussi si le runner de test doit joindre 10.77.0.25. (2) Le tag d'image devenv/app:dev est partagé entre piles dev et service : prescris un tag par pile. (3) Pile service retenue pour cette itération. (4) Signale explicitement tout changement de SPEC-001.3 ou SPEC-003.9 (aucun marqueur de test n'existe pour elles, le testeur devra en ajouter). Rapports DevOps à lire : iterations/002/mise-en-service.md, iterations/002/tests/rapport.md. Compte rendu : décisions, fichiers modifiés, points ouverts.

## Compte rendu
Arbitrage rendu et écrit dans `specs/` uniquement. Je n'ai touché ni `iterations/`, ni `policies/`, ni `tests/`, ni `app/`, ni `stack/`.

## Décisions

**(1) Ports : option (b), une seule publication LAN par pile** (ADR-007)
- `app` publie exactement `${APP_LAN_IP:-10.77.0.25}:${APP_PORT}:80`, et rien d'autre. Pas de `127.0.0.1`, pas de `0.0.0.0`.
- Ports : dev `8080`, service `8081`, exportés par `./dev`. La surcouche `compose.service.yml` ne redéfinit pas `ports` : compose fusionne les listes, ce qui créerait une seconde publication.
- `APP_PUBLIC_URL` par défaut devient `http://10.77.0.25:${APP_PORT}`.
- Option (a), deux ports distincts, retenue en repli si le product-owner refuse la perte de `127.0.0.1`. Option (c), changement de driver, écartée.
- **Runner : il ne joint pas `10.77.0.25`.** Il reste sur `http://app`. La joignabilité LAN devient une vérification `[R]` faite depuis l'hôte, avec `curl` consigné dans `mise-en-service.md`. Motif : le trafic runner → IP de l'hôte passe par le NAT, comportement non établi sous rootless. Le test `test_accueil_repond_200_sur_adresse_lan_du_serveur` est retiré du runner.

**(2) Tags par pile** (ADR-008, SPEC-004.16)
- Pile dev : `devenv/<service>:dev`, par exemple `devenv/app:dev`.
- Pile service : `devenv/app:service`, fixé par la clé `image:` de `compose.service.yml`.
- Les images de base restent épinglées par tag exact.

**(3) Pile service retenue pour l'itération 002**
- SPEC-004.7 à 004.9 ne sont plus « Could ». Le product-owner doit le reporter dans `perimetre.md`.
- Premier contrôle à faire au premier `deploy service` : `10.77.0.25:8080` et `10.77.0.25:8081` doivent écouter ensemble. Ce couple n'est pas testé à ce jour.

**(4) Changements explicites**
- **SPEC-001.3 modifiée** : passe de deux publications (`127.0.0.1` et LAN) à une seule (LAN). Vérification : `[P]` sur `docker compose config`, `[R]` sur `ss -ltn`.
- **SPEC-003.9 modifiée** : passe de `[R]` à `[T]`. Énoncé précisé : hors comptes `@test.invalid`, seul `ADMIN_EMAIL` existe, sur `dev` après reset et sur `service` avant le scénario CA-002-36.

Je ne suis pas d'accord avec l'attente d'un marqueur pytest pour SPEC-001.3. La publication est un fait de l'hôte, invisible depuis le runner : elle reste `[P]` + `[R]`. Le testeur ajoute seulement le marqueur à SPEC-003.9 (SPEC-006 §5).

## Fichiers modifiés (dans `specs/`)
- Créés : `adr/ADR-007-publication-ports-lan.md`, `adr/ADR-008-tags-images-par-pile.md`.
- Réécrits : `SPEC-001-pile-supabase.md` (001.3, 001.4, 001.11 amendées ; 001.2 précisée), `SPEC-004-piles-dev-service.md` (service retenue, 004.7 à 004.10 amendées, 004.15 précisée avec `APP_LAN_IP`, 004.16 nouvelle), `SPEC-006-plan-verification.md` (§1, §2 ligne CA-002-1, §3 policies 4 et 11, §5 nouvelle), `README.md`.
- Éditées : `SPEC-003-admin-secrets.md` (003.9), `adr/ADR-001-supabase-auto-heberge.md` et `adr/ADR-004-piles-dev-service.md` (notes d'amendement).

## Points ouverts
1. **Dérogation CA-002-1** (vérification sur `127.0.0.1`) : à valider par le product-owner, qui possède `perimetre.md`. Sans validation, il faut passer à l'option (a) et un nouvel ADR.
2. **Mise à jour de `perimetre.md`** : statut de la pile service.
3. **Policies** (agent `policy`) : réécrire `21-stack-ports.sh` selon SPEC-006 §3 point 4 ; créer `STACK-tags-par-pile` (SPEC-004.16).
4. **Adresse LAN stable** (risque R3) : si `10.77.0.25` change, le démarrage échoue. Réservation DHCP ou adresse fixe à faire par le responsable applicatif avant le premier `deploy service`.
5. **`./dev`** (action) : ne doit pas afficher d'URL `127.0.0.1` dans ses sorties ; aucun autre changement attendu.
6. **Testeur** : retirer le test LAN du runner, ajouter le marqueur `SPEC-003.9` (SPEC-006 §5).
