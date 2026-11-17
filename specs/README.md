# Spécifications (persistées par l'agent `architecte`)

## Spécifications
| Id | Titre | Itération | CA couverts | Statut |
|---|---|---|---|---|
| SPEC-000 | Socle de l'environnement | 001 | — | actif |
| SPEC-001 | Pile Supabase auto-hébergée et passerelle unique | 002 | CA-002-1, 2, 3, 6, 7, 11 | actif |
| SPEC-002 | Modèle de données, RLS, charge projetée, entraide | 002 | CA-002-4, 6, 8 à 36 | actif |
| SPEC-003 | Compte administrateur initial et secrets | 002 | CA-002-2, 4, 5, 33 | actif |
| SPEC-004 | Piles dev / service, persistance, sauvegarde | 002 | CA-002-1, 2, 33, 36 | actif |
| SPEC-005 | Interface web (recette clavier/souris) | 002 | CA-002 [C] | actif |
| SPEC-006 | Plan de vérification (test / client / policy / RA) | 002 | CA-002-1 à 36 | actif |

## Décisions d'architecture
| Id | Titre | Statut |
|---|---|---|
| ADR-000 | Environnement de développement reproductible | accepté |
| ADR-001 | Supabase auto-hébergé minimal derrière nginx (postgres 15.8.1.060, gotrue v2.170.0, postgrest v12.2.8) | accepté |
| ADR-002 | Front HTML/JS natif, supabase-js 2.47.10, construit dans Docker (node 22.12.0) | accepté |
| ADR-003 | Secrets générés hors git (`.devenv/secrets/`) et seed admin idempotent | accepté |
| ADR-004 | Deux piles (dev jetable, service persistante) et sauvegarde | accepté |
| ADR-005 | Sécurité : RLS forcée, écritures sensibles par RPC | accepté |

Notes : SPEC-000.1 reste valable (`/` répond 200) ; la publication du port est précisée par
SPEC-001.3 (127.0.0.1 **et** 10.77.0.25). L'ADR-000 (« pile jetable ») est complété par
l'ADR-004 : la pile `dev` reste jetable, seule la pile `service` est persistante.
