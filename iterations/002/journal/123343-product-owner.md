# product-owner — 2026-11-17T12:33:43+00:00

## Brief
Itération 002, tour 2, arbitrages du chef de projet. Mets à jour iterations/002/perimetre.md : (1) CA-002-9 : on garde les deux vérifications, [C] et [T] (redondance acceptée sur la sécurité d'accès) ; ajoute-la aussi à iterations/002/recette-client.md (accès direct à #/admin refusé pour un membre) ; (2) CA-002-1(c) (absence de 127.0.0.1 dans la sortie de ./dev) passe en [P]. Tu n'écris que dans ces deux fichiers. Compte rendu court.

## Compte rendu
Itération 002, tour 2 : les deux arbitrages sont intégrés, et je n'ai écrit que dans `perimetre.md` et `recette-client.md`.

**(1) CA-002-9 passe en [C] + [T]**
- `perimetre.md` : le critère couvre le [C] (saisie directe de `#/admin` par un membre, sans liste d'attente ni bouton « Activer ») et le [T] (refus par l'API, compte resté non activé). La redondance est notée comme acceptée.
- `recette-client.md` : ajout de l'étape 6 bis (compte 1, accès direct à `#/admin`, capture), ligne de couverture CA-002-9 ajoutée, et couverture [C] portée de 24 à 25 critères.

**(2) CA-002-1 (c) passe en [P]**
- `perimetre.md` : CA-002-1 devient [T] + [R] + [P]. Le [R] se limite à (a) `curl` et (b) `ss -ltn`. Le point ouvert du §2.3 est tranché, et le [P] est défini dans la convention du §4 (contrôle exécuté par `./dev policies`).

Les étapes de recette existantes sont inchangées. Le titre de `perimetre.md` est mis à jour pour refléter ces arbitrages.
