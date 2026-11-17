# product-owner — 2026-11-17T12:07:15+00:00

## Brief
Itération 002, tour 1. L'architecte a arbitré dans specs/ (ADR-007, ADR-008, SPEC-001.3, SPEC-004.7 à 004.10). Mets à jour iterations/002/perimetre.md : (1) valide ou refuse la dérogation à CA-002-1 : publication LAN seule sur 10.77.0.25, plus de 127.0.0.1 (si refus, indique le repli : deux ports distincts) ; (2) la pile service est retenue pour l'itération 002 (statut à reporter) ; (3) cohérence avec SPEC-003.9 passée en [T]. Tu n'écris que dans iterations/002/perimetre.md. Compte rendu : décisions, points ouverts.

## Compte rendu
Compte rendu du product owner au chef de projet — itération 002, tour 1 (complément architecte). Seul `iterations/002/perimetre.md` a été modifié.

## Décisions

**1. Dérogation à CA-002-1 : validée.** La vérification sur `127.0.0.1` est retirée. Seule la publication `10.77.0.25:<APP_PORT>` (option (b), ADR-007) est exigée. Vérifié dans le dépôt :
- le runner et le client utilisent `http://app` (`stack/compose.yml`, `tools/client/driver.py`) ;
- le reverse proxy cible `10.77.0.25` (ADR-001) ;
- la seule mention de `127.0.0.1` vers l'application est l'affichage de `./dev` (ligne 115), à corriger par `action`.

Repli (option (a), deux ports distincts), déclenché si au premier `deploy` : `10.77.0.25:8080` ne répond pas 200 depuis l'hôte, ou si `:8080` et `:8081` n'écoutent pas ensemble. Dans ce cas, nouvel ADR de l'architecte et réécriture de CA-002-1.

**2. Pile service : retenue.** US-17 passe de COULD à MUST. SPEC-004.7 à 004.9 sont exigibles, avec CA-002-36 en [T] + [R].

**3. Cohérence SPEC-003.9 ([T]) : cohérente.** Le seed ne crée que l'admin, ce qui est compatible avec CA-002-4, CA-002-8 (la recette crée elle-même le compte à activer) et CA-002-24.

**Corrections et ajustements de ma part :**
- **D3 :** US-14 (persistance) passe de SHOULD à MUST, prérequis de la pile service.
- **D4 :** CA-002-4 passe de « ≥ 16 » à « ≥ 20 » caractères, aligné sur SPEC-003.1.
- CA-002-2 intègre le tag par pile (ADR-008) ; CA-002-1 a été réécrit pour l'adresse LAN.

## Points ouverts (à trancher par le chef de projet)

1. **Périmètre alourdi.** Les Must passent de 9 à 11 stories, avec la pile service et la persistance. Si l'équipe ne peut pas tout livrer, US-14 et US-17 sont les candidates au report vers l'itération 003.
2. **Critères [R].** Certains critères de vérification d'hôte (`ss -ltn`, `docker compose ls`, `curl` LAN) ne sont ni [C] ni [T], alors que la règle de l'itération dit « clavier/souris ou test automatique ». Je les ai introduits explicitement comme [R], consignés dans `mise-en-service.md`. Merci de confirmer.
3. **Actions hors PO** : `policy` doit réécrire `21-stack-ports.sh` et créer `STACK-tags-par-pile` ; `action` doit corriger `./dev` (ligne 115) ; `responsable-applicatif` doit fixer l'adresse LAN `10.77.0.25` (bail DHCP, risque R3) avant le premier `deploy service`.
4. **Mot de passe admin** : le chiffre de 20 caractères (D4) est une correction de ma part. À confirmer si vous préférez garder 16.
