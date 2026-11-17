# responsable-applicatif — 2026-11-17T13:48:32+00:00

## Brief
Deux tâches, LECTURE SEULE sur les piles (aucun deploy, reset, restore, teardown). O4 : dans iterations/002/mise-en-service.md corrige la date d'audit périmée (autour de la ligne 316) en 13:45:51 et nomme le troisième paquet de l'audit npm (autour de la ligne 318) : @supabase/supabase-js (sévérité low, dépendance directe, via auth-js), en vérifiant d'abord dans iterations/002/policies/audit-npm.meta.json et le rapport d'audit que ces valeurs sont exactes ; sinon dis ce que tu constates. O2 : prouve que bash est installé en 5.2.15-2+b13 dans l'image runner (build courant, tools/runner/Dockerfile) avec un conteneur jetable, par exemple docker run --rm --entrypoint dpkg-query <image runner> -W bash git curl, sans démarrer la pile ; donne les trois versions installées exactes.

## Compte rendu
