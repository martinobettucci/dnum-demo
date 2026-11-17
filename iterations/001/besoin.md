# Itération 001 — expression du besoin

Mise en place de l'environnement de développement reproductible (demande initiale de l'utilisateur) :
- serveur de développement dédié, entièrement reproductible depuis le dépôt ;
- pile Docker jetable, volumes compris ;
- boucle Action-Observation-Policy-Réaction, un agent dédié par étape (observation/réaction en lecture seule) ;
- équipe agile : chef de projet (seul interlocuteur), product owner, développeur, architecte ;
- DevOps : testeur (automatique), client (clavier/souris uniquement), sponsor (coût), responsable applicatif (seul à mettre en service) ;
- toute commande absente de l'hôte s'exécute dans un conteneur, réutilisé ou créé.
