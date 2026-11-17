# architecte — 2026-11-17T13:37:43+00:00

## Brief
Itération 002, arbitrages du chef de projet. Écris uniquement dans specs/. (1) esbuild : NOTE non bloquante ; le cas A reste valable tant que le build n'utilise ni serve, ni watch, ni context ; si l'une de ces fonctions apparaît, la policy 25 passe en violée (réévaluation obligatoire) ; c'est la formule « cas C gardé » du chef de projet : consigne-la dans ADR-010 et ADR-013 D-1 (plus de point ouvert). (2) PUT /auth/v1/user : accepté et documenté pour 002 (chemin standard de Supabase : chaque utilisateur change son propre mot de passe avec son JWT) ; une interface « changer mon mot de passe » est au backlog 003 ; mets à jour ADR-012 §6 et ADR-013. (3) Policy 35 SEED-sans-ecrasement : numéro validé. (4) dae9044 existe dans l'historique et les migrations 001 à 005 sont identiques dans dfbc020, dae9044 et HEAD (vérifié par le chef de projet) : consigne-le dans ADR-011 ou ADR-015. (5) Ajoute ./dev audit-npm à SPEC-004.1 (et à la liste de l'aide). Mets à jour README et clos les points ouverts correspondants. Compte rendu très court.

## Compte rendu
