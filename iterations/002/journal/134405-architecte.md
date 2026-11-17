# architecte — 2026-11-17T13:44:05+00:00

## Brief
Itération 002, complément du chef de projet. Écris uniquement dans specs/. (1) ADR-014 : dis explicitement que ./dev audit-npm passe par la toolbox (tools/bin/_dockerized, docker run d'une image épinglée), et que ce canal est autorisé à tout agent : c'est la règle de l'utilisateur « commande absente → conteneur » (tools/toolbox/registry.conf). Le garde-fou bloque volontairement les docker run directs, pas la toolbox. (2) ADR-015 : consigne que dae9044 est la référence figée de l'itération 002 pour les migrations 001 à 005, dfbc020 étant identique sur les migrations (vérifié par le chef de projet). Vérifie que README et SPEC-004.1 restent cohérents. Compte rendu d'une ligne.

## Compte rendu
Fait : ADR-014 (§ « Canal », toolbox autorisée à tout agent, garde-fou visant seulement les `docker run` directs), ADR-015 (§6bis, `dae9044` référence figée, `dfbc020` identique sur `001`–`005`), SPEC-004.1 précisé, README à jour ; cohérence vérifiée par relecture, sans re-contrôle git (pas d'outil shell disponible), la vérification de `dae9044` restant celle du chef de projet.
