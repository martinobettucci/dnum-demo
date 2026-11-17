# product-owner — 2026-11-17T13:15:15+00:00

## Brief
Itération 002, tour 3, arbitrages du chef de projet. Dans iterations/002/perimetre.md et iterations/002/recette-client.md uniquement : (1) SPEC-005 fait foi pour les textes (M-1 à M-6) : aligne CA-002-27 et CA-002-34 dessus ; (2) numérotation CA de l'architecte : 37 barre fixe, 38 recherche, 39 confirmation « Désactiver » ; retire la confirmation de CA-002-34 et crée CA-002-39 [C] ; mets à jour la recette (étape 18.1) et le décompte de couverture ; (3) « Réaffecter » et « Loguer du temps » restent sans confirmation (actions réversibles) : consigne-le ; (4) CA-002-1, partie « après reset » : écart accepté par le chef de projet tant que la pile dev est gelée : consigne-le ; (5) seed : en pile service, le seed crée l'admin s'il n'existe pas et ne réécrit jamais un mot de passe existant (ADR-012, SPEC-003.10 à 003.12) : ajoute le critère correspondant si absent. Compte rendu court.

## Compte rendu
Compte rendu au chef de projet, itération 002, tour 3 (arbitrages).

**Fichiers modifiés** : `iterations/002/perimetre.md` et `iterations/002/recette-client.md` uniquement.

**Fait**
1. **Textes** : CA-002-27, 28, 38 et 39 reprennent les textes exacts M-1, M-2, M-5, M-6 et M-3/M-4 de SPEC-005. CA-002-38 suit aussi SPEC-005.62 : deux champs de recherche, correspondance par mots. Ce dernier point dépasse les seuls textes, à vérifier.
2. **Numérotation** : 37 barre fixe, 38 recherche, 39 confirmation « Désactiver » créé. La confirmation est retirée de CA-002-34. Recette : étapes 5, 7, 9, 10, 12 et 18.1 mises à jour, table de couverture complétée. Décompte [C] : 28.
3. **Arbitrage** : « Réaffecter » et « Loguer du temps » sans confirmation (actions réversibles), consigné dans un tableau « Arbitrages du chef de projet (tour 3) ». « Modifier » n'est pas arbitré et reste ouvert.
4. **CA-002-1** : écart accepté sur la partie « après reset », tant que la pile `dev` est gelée. Consigné dans CA-002-1 et dans les arbitrages.
5. **Seed** : CA-002-40 créé (US-2, [T] + [P]). Il couvre la création conditionnelle, l'absence d'écriture sur un compte existant (SPEC-003.10) et le refus sans e-mail confirmé (SPEC-003.11). Son [R] est couvert par CA-002-33. Ajouté à la recette « hors recette » (couverture).

**Points à traiter**
- SPEC-003.10 prévoit, dans sa vérification [T], un `./dev deploy` sans reset. Or `deploy` est réservé au responsable applicatif (SPEC-004.6). L'architecte doit remplacer ce passage par un appel direct de `seed.py`. CA-002-40 en dépend.
- Le [T] de CA-002-40 suppose de pouvoir changer le mot de passe admin dans un test. À confirmer avec le testeur.
