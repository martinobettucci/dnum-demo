# ADR-007 — Publication des ports : une seule adresse LAN par pile

Statut : accepté (itération 002, tour 1, complément, 2026-11-17). Amende ADR-001 (réseau) et ADR-004 (ports).
Specs touchées : SPEC-001.3, SPEC-001.4, SPEC-001.11, SPEC-004.7, SPEC-004.10, SPEC-006 §1, §2, §3, §5.
**Dérogation à CA-002-1** (vérification sur `127.0.0.1`) : à valider par le product-owner (`perimetre.md`
appartient au PO ; l'architecte ne le modifie pas). Voir « Conséquences ».

## Contexte

- Constat (`iterations/002/mise-en-service.md` §1, Docker 29.10.0 rootless, driver de port `builtin`) :
  publier un même port sur `127.0.0.1` **et** sur `10.77.0.25` échoue (`address already in use`), dans les deux
  ordres. Publier deux ports différents (un par adresse) fonctionne, et chaque publication seule fonctionne.
- SPEC-001.3 et SPEC-001.4 exigeaient les deux adresses avec le même `APP_PORT` : elles ne sont pas satisfaisables
  avec ce driver. Ce n'est pas un défaut de la pile applicative.
- La cible du reverse proxy HTTPS (hors périmètre) est `10.77.0.25:<port>` (ADR-001).
- `10.77.0.25` est un bail DHCP dynamique (risque R3 du rapport DevOps).
- Le runner de test est sur le réseau compose : il atteint `app` par `http://app`. Son accès à l'adresse LAN de
  l'hôte n'est pas établi (rapport tests §2, point 5).

## Options étudiées

| Option | Description | Évaluation |
|---|---|---|
| (a) Deux ports distincts | Pile dev : `127.0.0.1:8080` et `10.77.0.25:8180` ; pile service : `127.0.0.1:8081` et `10.77.0.25:8181`. Testé OK. | Conserve les deux URL, mais double la surface de publication, impose deux ports par pile, et le « port HTTP annoncé » de CA-002-1 n'est plus unique. Retenue en repli. |
| (b) LAN seul | Une publication par pile : `${APP_LAN_IP}:${APP_PORT}:80`. | Une seule cible pour le proxy, une seule URL par pile. Perd l'accès `127.0.0.1`. **Retenue.** |
| (c) Autre driver | Changer le driver de port du démon rootless (`slirp4netns` ou `pasta`). | Modifie l'hôte, hors périmètre de l'architecte ; exige une validation et un test dédié. **Écartée** pour cette boucle (règle du chef de projet : ne pas changer le driver réseau de l'hôte). |

## Décision

1. **Option (b).** Seul le service `app` publie un port, exactement `${APP_LAN_IP:-10.77.0.25}:${APP_PORT}:80`.
   Aucune publication sur `127.0.0.1`, aucune sur `0.0.0.0`, aucune pour `db`, `auth`, `rest`, `migrate`, `seed`,
   `runner`, `client`.
2. **Ports par pile** : pile `dev` `APP_PORT=8080`, pile `service` `APP_PORT=8081`, exportés par `./dev`
   (SPEC-004.15). La surcouche `stack/compose.service.yml` **ne redéfinit pas** `ports` (les listes sont fusionnées
   par compose, ce qui créerait une seconde publication) : elle hérite de la ligne de la pile de base.
3. **URL publique par défaut** (`APP_PUBLIC_URL`, SPEC-001.11) : `http://${APP_LAN_IP}:${APP_PORT}`.
4. **Runner** : il **ne joint pas** `10.77.0.25`. Il teste `APP_URL=http://app`. La joignabilité LAN est une vérification
   de l'hôte, faite par le responsable applicatif (`[R]`, `curl http://10.77.0.25:<APP_PORT>/`, consigné dans
   `mise-en-service.md`), et la ligne de publication est vérifiée par policy (`[P]`). Motif : le trafic runner →
   IP de l'hôte passe par le NAT de l'hôte, dont le comportement sous rootless n'est pas établi ; un échec réseau ne
   doit pas se confondre avec un défaut applicatif. Le test `test_accueil_repond_200_sur_adresse_lan_du_serveur`
   est retiré du runner (SPEC-006 §5).
5. **Pile service sur la même adresse** : `10.77.0.25:8081` à côté de `10.77.0.25:8080`. Deux ports différents sur
   une même adresse ne sont pas testés à ce jour : la vérification est faite au premier `deploy service`, la pile
   `dev` restant en marche (SPEC-004.7).

## Conséquences

- **CA-002-1 dérogé** : la vérification `127.0.0.1` disparaît. Le product-owner doit valider la dérogation ou demander
  l'option (a). Si l'option (a) est imposée, un nouvel ADR fixera les ports (`8080/8180`, `8081/8181`) et SPEC-001.3
  sera amendée à nouveau.
- La pile `dev` reste joignable depuis le LAN, comme le prévoyait déjà ADR-001. Rien de nouveau n'est exposé.
- **Dépendance à une adresse stable** : si `10.77.0.25` change, le démarrage échoue (liaison impossible). Action hors
  architecte pour le responsable applicatif : adresse fixe ou réservation DHCP de l'hôte, **avant** la première mise
  en service de la pile `service` (risque R3). Le changement passe par `APP_LAN_IP`, jamais par une modification de
  la publication.
- Le reverse proxy cible `10.77.0.25:8081` pour la pile `service`. La pile `dev` n'est pas destinée au proxy public.
- `policies/checks/21-stack-ports.sh` doit être réécrit par l'agent `policy` selon la règle 1 (une publication,
  adresse `${APP_LAN_IP}`). Cette mise à jour est hors écriture de l'architecte.
- Aucun changement de driver, de démon ni de configuration hôte : seul `stack/compose.yml` et l'adresse LAN
  (variable) bougent.
