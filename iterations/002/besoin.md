# Itération 002 — expression du besoin (recueillie par le chef de projet, 2026-11-17)

## Produit
Petit logiciel de **suivi des tâches de l'équipe**, pour savoir qui travaille sur quoi, combien,
et inciter à l'entraide sur les choses à faire de la journée.

## Stack demandée
- PostgreSQL, via **Supabase comme back-end complet** (authentification, base, API).
- Application exposée sur internet à l'adresse **denum.lelabs.tech** (DNS pointé par l'utilisateur ; orthographe à confirmer).

## Comptes et accès
- Les personnes **s'inscrivent** (création de compte).
- L'utilisateur est **administrateur** : compte initial créé pour lui ; il **active** les comptes inscrits.
- Un compte non activé n'accède pas à l'application.
- Les informations de connexion de l'admin sont communiquées dans la conversation.

## Fonctions (comptes activés)
- Tableau de bord personnel : **créer ses tâches**.
- **Voir les tâches des autres**.
- **Se renvoyer / réaffecter** des tâches entre collègues.
- **Loguer du temps** sur une tâche.
- Page d'accueil de chacun : tableau de bord d'équipe **« qui fait quoi »**, avec le **temps projeté** de travail par personne (charge).
- **Entraide / entre-affectation** : proposer de prendre les tâches d'un collègue trop chargé,
  ou proposer à quelqu'un de prendre ses propres tâches (proposition → acceptation).

## Décisions (2026-11-17)
- Adresse publique : **dnum.lelabs.tech** (confirmée par l'utilisateur).
- Par défaut du chef de projet (l'utilisateur n'a pas tranché, révisable) :
  - Supabase **auto-hébergé** dans la pile Docker (Postgres, Auth/GoTrue, PostgREST, passerelle), reproductible depuis le dépôt.
  - **Deux piles** : `dev` jetable (volumes compris) et `service` exposée avec données persistantes + sauvegarde, opérée par le seul responsable applicatif.
  - Exposition : un port HTTP sur ce serveur ; reverse proxy HTTPS vers 10.77.0.25 à la charge de l'utilisateur (à confirmer).
- Mot de passe admin initial : généré, jamais commité, communiqué à l'utilisateur dans la conversation.
