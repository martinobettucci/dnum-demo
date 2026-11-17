# Spécifications (persistées par l'agent `architecte`)

## Spécifications
| Id | Titre | Itération | CA couverts | Statut |
|---|---|---|---|---|
| SPEC-000 | Socle de l'environnement | 001 | — | actif |
| SPEC-001 | Pile Supabase auto-hébergée et passerelle unique | 002 | CA-002-1, 2, 3, 6, 7, 11, 33 | actif (amendé tour 1 complément : 001.3, 001.4, 001.11) |
| SPEC-002 | Modèle de données, RLS, charge projetée, entraide | 002 | CA-002-4, 6, 8 à 36 | actif |
| SPEC-003 | Compte administrateur initial et secrets | 002 | CA-002-2, 4, 5, 33 | actif (amendé : 003.9 passe en `[T]`) |
| SPEC-004 | Piles dev / service, persistance, sauvegarde | 002 | CA-002-1, 2, 33, 36 | actif (amendé : service retenue, 004.7 à 004.10, 004.16 nouvelle) |
| SPEC-005 | Interface web (recette clavier/souris) | 002 | CA-002 [C] | actif |
| SPEC-006 | Plan de vérification (test / client / policy / RA) | 002 | CA-002-1 à 36 | actif (amendé : §1, §2, §3, §5) |

## Décisions d'architecture
| Id | Titre | Statut |
|---|---|---|
| ADR-000 | Environnement de développement reproductible | accepté |
| ADR-001 | Supabase auto-hébergé minimal derrière nginx (postgres 15.8.1.060, gotrue v2.170.0, postgrest v12.2.8) | accepté (amendé par ADR-007 : réseau) |
| ADR-002 | Front HTML/JS natif, supabase-js 2.47.10, construit dans Docker (node 22.12.0) | accepté |
| ADR-003 | Secrets générés hors git (`.devenv/secrets/`) et seed admin idempotent | accepté |
| ADR-004 | Deux piles (dev jetable, service persistante) et sauvegarde | accepté (amendé par ADR-007 et ADR-008 ; pile service retenue pour l'itération 002) |
| ADR-005 | Sécurité : RLS forcée, écritures sensibles par RPC | accepté |
| ADR-006 | Vérifiabilité de la pile dev : débit GoTrue (≥ 500 inscriptions/h), règle de même origine (code / `vendor/`), contrat `./dev` ↔ application | accepté (amende ADR-002) |
| ADR-007 | Publication des ports : une seule adresse LAN par pile (`${APP_LAN_IP}:${APP_PORT}`), runner hors LAN | accepté ; **dérogation CA-002-1 à valider par le product-owner** |
| ADR-008 | Tags des images construites localement, propres à chaque pile (`:dev`, `:service`) | accepté |

Notes :
- SPEC-000.1 reste valable (`/` répond 200) ; la publication du port est désormais précisée par ADR-007
  (une adresse LAN par pile, `10.77.0.25`, plus de `127.0.0.1`). SPEC-001.3 et SPEC-001.4 suivent ADR-007.
- L'ADR-000 (« pile jetable ») est complété par l'ADR-004 : la pile `dev` reste jetable, seule la pile `service` est persistante.

Tour 1 de l'itération 002 (ADR-006) :
- nouvelles exigences : SPEC-001.14 (débit d'authentification) et SPEC-004.11 à SPEC-004.15 (contrat entre `./dev` et l'application) ;
- exigences précisées : SPEC-001.1, 001.8, 001.11, 001.13, SPEC-003.6, SPEC-004.7, 004.8, SPEC-006 §1 et §3.

Tour 1, complément (arbitrage du chef de projet, 2026-11-17) :
- publication des ports : option (b), une seule publication LAN par pile (ADR-007) ; SPEC-001.3, 001.4, 001.11, 004.10 amendées ;
- runner : ne joint pas `10.77.0.25` ; test LAN retiré du runner, vérification `[R]` (ADR-007 §4, SPEC-006 §5) ;
- tags d'images par pile (ADR-008) : nouvelle SPEC-004.16 ; `stack/compose.service.yml` porte `devenv/app:service` ;
- pile service retenue pour l'itération 002 : SPEC-004.7 à 004.9 ne sont plus « Could » ;
- SPEC-003.9 : vérification passée de `[R]` à `[T]` (marqueur à ajouter par le testeur), énoncé précisé ;
- **Points ouverts** : dérogation CA-002-1 (`127.0.0.1`) à valider par le product-owner ; `perimetre.md` à mettre à jour
  (statut de la pile service) ; `policies/checks/21-stack-ports.sh` et la nouvelle policy `STACK-tags-par-pile` à écrire
  par l'agent `policy` ; adresse LAN de l'hôte à rendre stable (risque R3, responsable applicatif).
