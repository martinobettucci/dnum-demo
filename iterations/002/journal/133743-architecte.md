# architecte — 2026-11-17T13:37:43+00:00

## Brief
Itération 002, arbitrages du chef de projet. Écris uniquement dans specs/. (1) esbuild : NOTE non bloquante ; le cas A reste valable tant que le build n'utilise ni serve, ni watch, ni context ; si l'une de ces fonctions apparaît, la policy 25 passe en violée (réévaluation obligatoire) ; c'est la formule « cas C gardé » du chef de projet : consigne-la dans ADR-010 et ADR-013 D-1 (plus de point ouvert). (2) PUT /auth/v1/user : accepté et documenté pour 002 (chemin standard de Supabase : chaque utilisateur change son propre mot de passe avec son JWT) ; une interface « changer mon mot de passe » est au backlog 003 ; mets à jour ADR-012 §6 et ADR-013. (3) Policy 35 SEED-sans-ecrasement : numéro validé. (4) dae9044 existe dans l'historique et les migrations 001 à 005 sont identiques dans dfbc020, dae9044 et HEAD (vérifié par le chef de projet) : consigne-le dans ADR-011 ou ADR-015. (5) Ajoute ./dev audit-npm à SPEC-004.1 (et à la liste de l'aide). Mets à jour README et clos les points ouverts correspondants. Compte rendu très court.

## Compte rendu
Itération 002 : arbitrages consignés dans `specs/`, rien d'autre modifié.

- **(1) esbuild** : « cas C gardé » inscrit dans ADR-010 et ADR-013 D-1. Cas A valable tant qu'il n'y a ni `serve`, ni `watch`, ni `context`. Garde en note non bloquante ; une occurrence fait passer la policy 25 en violée. Reflété dans SPEC-001.15 (b) et (d) et SPEC-006 §3 item 13. Point ouvert clos.
- **(2) PUT /auth/v1/user** : accepté et documenté pour 002 dans ADR-012 §6 et ADR-013 D-5. Interface « changer mon mot de passe » au backlog 003. Point ouvert clos.
- **(3) Policy 35** : validée dans SPEC-006 §3 item 19 et ADR-013.
- **(4) dae9044** : consigné dans ADR-015 §5 (existe ; `001` à `005` identiques dans `dfbc020`, `dae9044`, `HEAD`). Point ouvert clos.
- **(5) `./dev audit-npm`** : ajouté à SPEC-004.1 avec ses vérifications ; SPEC-004 et ADR-014 mis à jour.
- **README** : index à jour, points ouverts clos, section « Arbitrages du chef de projet, suite » ajoutée.

Reste ouvert : version apt de git (ADR-015, ADR-013 point 6). Côté `app/`, la policy 25 doit passer en violée sur `serve`/`watch`/`context` et `./dev` doit afficher `audit-npm` dans `help` ; ces changements relèvent de l'équipe AOPR, non de moi.
