# product-owner — 2026-11-17T13:05:13+00:00

## Brief
Itération 002, tour 3 (préparation). Contexte : dnum.lelabs.tech est relayée vers la pile DEV, de vrais utilisateurs s'y inscrivent. GEL : pas de reset, teardown, deploy ni test sur la pile dev ; tout se prépare sans mise en service. Retours de recette client : (1) CA-002-28 : pas de message de confirmation après « Demander de l'aide » ; message « Proposition envoyée » sans nom de tâche ; (2) barre supérieure non fixe ; (3) pas de confirmation sur « Désactiver » ; (4) listes admin sans recherche. Réécris les critères d'acceptation concernés dans iterations/002/perimetre.md (langage utilisateur, vérifiables au clavier/souris, [C]/[T]/[P]), et ajoute les étapes correspondantes à iterations/002/recette-client.md. Tu n'écris que dans ces deux fichiers. Compte rendu court : critères modifiés ou créés.

## Compte rendu
Itération 002, tour 3 : préparation faite, rien exécuté (gel de la pile `dev` respecté). Seuls `perimetre.md` et `recette-client.md` ont été modifiés.

**Critères modifiés (perimetre.md)**
- **CA-002-27** (Proposer mon aide) : réécrit. Message de confirmation qui nomme le collègue et la tâche, « Proposition envoyée » seul refusé.
- **CA-002-28** (Demander de l'aide) : réécrit. Même exigence de message nommé, « Demande d'aide envoyée à … pour « … » », visible sans clic supplémentaire.
- **CA-002-34** (Désactiver) : complété. Fenêtre « Désactiver ce compte ? » avec Confirmer / Annuler (Échap ou Annuler ne change rien). Pas de bouton « Désactiver » sur sa propre ligne.

**Critères créés**
- **CA-002-37** [C] (rattaché à US-9) : barre du haut fixe au défilement, vérifiée à 200–300 % de zoom.
- **CA-002-38** [C] (rattaché à US-4) : champ « Rechercher » dans Administration, filtre les deux listes par nom ou e-mail, sans distinction de casse, avec message « Aucun compte ne correspond à la recherche ».

**Étapes ajoutées ou modifiées (recette-client.md)**
- Étapes 5 et 16 : messages attendus précisés.
- Étape 17 bis : nouvelle, en deux parties (barre fixe, recherche admin).
- Étape 18.1 : confirmation et annulation ajoutées.
- Table de couverture et décompte des critères [C] (27) mis à jour.

**Points à arbitrer**
- CA-002-34 reste en Could (US-15). Je propose de garder CA-002-38 dans la boucle (Must) et de traiter CA-002-37 en Should.
- Il faudra que l'architecte reprenne les SPEC correspondantes (message de confirmation, fenêtre de confirmation, barre fixe, recherche).
