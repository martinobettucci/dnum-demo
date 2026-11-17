# product-owner — 2026-11-17T13:37:43+00:00

## Brief
Itération 002, arbitrage du chef de projet : une interface « changer mon mot de passe » (PUT /auth/v1/user avec le JWT de l'utilisateur, chemin standard Supabase, accepté et documenté pour 002, voir ADR-012 §6) est à inscrire au backlog de l'itération 003 dans iterations/002/perimetre.md (user story, priorité à proposer, critères en langage utilisateur). Tu n'écris que dans ce fichier. Compte rendu d'une ligne.

## Compte rendu
Backlog 003 ajouté dans `iterations/002/perimetre.md` (§ 7) : US-18 « changer mon mot de passe » (priorité SHOULD proposée), 8 critères provisoires, et un point à lever : ADR-012 § 6 signale encore le canal `PUT /auth/v1/user` comme « point ouvert » (ADR-013, point 2), à formaliser en spec par l'architecte avant 003.
