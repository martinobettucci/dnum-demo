# Itération 002 — Périmètre (product owner, 2026-11-17)

## 1. Objectif de la boucle

Livrer, déployée par `./dev deploy` sur un port HTTP de ce serveur prêt à être proxifié, une
application de suivi des tâches d'équipe adossée à Supabase auto-hébergé, utilisable de bout en
bout par une petite équipe : inscription → activation par l'admin → tâches, temps, tableau de bord
« qui fait quoi » avec charge projetée → propositions d'entraide.

## 2. User stories retenues (priorisées, MoSCoW)

Règle de livraison : les **Must** forment le cœur et sont réalisés, déployés et recettés en
premier. Les **Should** suivent dans la même boucle si le temps le permet. Les **Could** ne sont
réalisés que si tout le reste est vert. Une story non livrée passe à l'itération 003, sans
bloquer la recette du reste.

### MUST — cœur utilisable

- **US-1 — Socle déployable.** En tant que responsable applicatif, je veux mettre en service
  l'application complète (Supabase auto-hébergé : Postgres, Auth, API, passerelle + interface web)
  avec `./dev deploy` depuis le seul dépôt, afin que l'équipe y accède par un port HTTP que
  l'utilisateur proxifiera ensuite en HTTPS.
- **US-2 — Compte administrateur initial.** En tant qu'utilisateur (administrateur), je veux qu'un
  compte admin activé existe dès la première mise en service, avec un mot de passe généré et jamais
  commité, afin d'administrer l'application dès le premier jour.
- **US-3 — Inscription.** En tant que collègue, je veux créer mon compte (nom affiché, e-mail, mot
  de passe) afin de demander l'accès à l'application.
- **US-4 — Activation par l'admin.** En tant qu'administrateur, je veux voir les comptes en attente
  et les activer, afin que seules les personnes que j'ai validées accèdent à l'application.
- **US-5 — Accès refusé aux comptes non activés.** En tant qu'administrateur, je veux qu'un compte
  non activé ne voie aucune donnée de l'équipe, ni par l'interface ni par l'API, afin de protéger
  les informations de l'équipe.
- **US-6 — Mes tâches.** En tant que membre activé, je veux créer, modifier et changer le statut
  (à faire / en cours / terminée) de mes tâches, avec une estimation en heures, afin de déclarer ce
  sur quoi je travaille et combien de temps cela doit prendre.
- **US-7 — Tâches des autres.** En tant que membre activé, je veux consulter les tâches de mes
  collègues, afin de savoir qui travaille sur quoi.
- **US-8 — Temps passé.** En tant que membre activé, je veux loguer du temps sur une tâche qui
  m'est affectée, afin que le temps réellement passé et le reste à faire soient connus.
- **US-9 — Tableau de bord « qui fait quoi ».** En tant que membre activé, je veux arriver après
  connexion sur un tableau de bord d'équipe montrant, par personne, ses tâches en cours et sa
  charge projetée, afin de repérer d'un coup d'œil qui est chargé.

### SHOULD — collaboration

- **US-10 — Réaffectation directe.** En tant que personne affectée à une tâche, je veux la
  renvoyer directement à un collègue activé, afin de transmettre un travail convenu de vive voix.
- **US-11 — Proposer mon aide.** En tant que membre activé, je veux proposer de prendre une tâche
  d'un collègue (notamment un collègue signalé surchargé), afin de l'aider ; la tâche ne change de
  main que s'il accepte.
- **US-12 — Demander de l'aide.** En tant que membre activé, je veux proposer à un collègue de
  prendre l'une de mes tâches, afin d'alléger ma charge ; la tâche ne change de main que s'il accepte.
- **US-13 — Mes propositions.** En tant que membre activé, je veux voir les propositions reçues
  (accepter / refuser) et envoyées (en attente / acceptée / refusée), afin de suivre l'entraide.
- **US-14 — Persistance des données.** En tant qu'équipe, je veux que nos données survivent à un
  redéploiement ordinaire (`./dev deploy` sans `reset`), afin de pouvoir réellement utiliser l'outil.

### COULD — confort

- **US-15 — Désactivation.** En tant qu'administrateur, je veux désactiver un compte activé, afin
  de retirer l'accès à une personne qui quitte l'équipe.
- **US-16 — Tâches du jour.** En tant que membre activé, je veux donner une échéance à une tâche et
  filtrer le tableau de bord sur « aujourd'hui », afin de cibler l'entraide sur les choses à faire
  de la journée.
- **US-17 — Pile « service » et sauvegarde.** En tant que responsable applicatif, je veux une pile
  `service` distincte de la pile `dev` jetable, à données persistantes et dotée d'une commande de
  sauvegarde/restauration, afin de préparer l'exposition publique.

## 3. Critères d'acceptation

Conventions : « membre activé » = compte activé par l'admin. **Charge projetée** d'une personne =
somme, sur ses tâches non terminées, de `max(estimation − temps logué, 0)`, en heures, arrondie à
0,25 h. **Surchargé** = charge projetée strictement supérieure à **7 h** (seuil fixe pour cette
boucle). [C] = vérifiable par le client au clavier/souris ; [T] = vérifiable par test automatique.

### US-1 — Socle déployable
- **CA-002-1** [T] Après `./dev reset` puis `./dev deploy`, la page d'accueil de l'application
  répond `200` sur le port HTTP annoncé dans `mise-en-service.md`, à la fois sur `127.0.0.1` et sur
  l'adresse `10.77.0.25` du serveur (prêt à être proxifié).
- **CA-002-2** [T] Toutes les images de la pile sont épinglées par tag exact (aucun `latest`) et
  aucun secret (mot de passe, clé JWT, clé de service) n'est présent dans les fichiers suivis par git.
- **CA-002-3** [T] L'interface web n'appelle l'API Supabase que via la même origine (passerelle
  derrière le port HTTP unique) : aucun autre port n'est requis côté navigateur.

### US-2 — Compte administrateur initial
- **CA-002-4** [T] Après une première mise en service, un compte admin existe, activé et doté du
  rôle administrateur ; son mot de passe est généré aléatoirement (≥ 16 caractères), stocké hors
  du suivi git et lisible par le responsable applicatif pour transmission au chef de projet.
- **CA-002-5** [C] Avec les identifiants admin transmis, le client se connecte et voit le tableau
  de bord d'équipe ainsi qu'une entrée de menu « Administration » absente pour un membre ordinaire.

### US-3 — Inscription
- **CA-002-6** [C] Depuis l'écran de connexion, un lien « Créer un compte » mène à un formulaire
  (nom affiché, e-mail, mot de passe) ; à la validation, un message indique que le compte est en
  attente d'activation par l'administrateur. Aucun e-mail de confirmation n'est requis.
- **CA-002-7** [C] Une inscription avec un e-mail déjà utilisé, ou un mot de passe de moins de
  8 caractères, est refusée avec un message d'erreur lisible, sans création de compte.

### US-4 — Activation par l'admin
- **CA-002-8** [C] Dans « Administration », l'admin voit la liste des comptes en attente (nom,
  e-mail, date d'inscription) et un bouton « Activer » par compte ; après clic, le compte disparaît
  de la liste des comptes en attente et apparaît dans la liste des comptes actifs.
- **CA-002-9** [T] Un membre non administrateur qui tente d'activer un compte (par l'API) reçoit un
  refus et le compte reste non activé.

### US-5 — Accès refusé aux comptes non activés
- **CA-002-10** [C] Un compte inscrit mais non activé qui se connecte ne voit qu'un écran
  « Compte en attente d'activation » et un bouton de déconnexion ; aucune tâche, aucun nom de
  collègue n'est affiché.
- **CA-002-11** [T] Avec le jeton d'un compte non activé, puis sans jeton (clé anonyme seule), les
  lectures et écritures des tables tâches, temps, propositions et profils via l'API renvoient zéro
  ligne ou un refus (politiques RLS en vigueur).
- **CA-002-12** [C] Après activation par l'admin, ce même compte, à sa connexion suivante, accède
  au tableau de bord d'équipe.

### US-6 — Mes tâches
- **CA-002-13** [C] Un membre activé crée une tâche (titre obligatoire, description facultative,
  estimation en heures obligatoire > 0) ; elle apparaît aussitôt dans « Mes tâches », au statut
  « à faire », affectée à lui-même.
- **CA-002-14** [C] Un titre vide ou une estimation absente, nulle ou négative est refusé avec un
  message d'erreur, sans création.
- **CA-002-15** [C] Le membre modifie le titre, la description, l'estimation et le statut
  (à faire / en cours / terminée) de sa tâche ; les changements sont visibles après rechargement
  de la page.
- **CA-002-16** [T] Un membre ne peut pas modifier une tâche dont il n'est ni l'affecté ni le
  créateur (refus de l'API).

### US-7 — Tâches des autres
- **CA-002-17** [C] Depuis le tableau de bord, un clic sur le nom d'un collègue affiche la liste de
  ses tâches (titre, statut, estimation, temps logué), en lecture seule.

### US-8 — Temps passé
- **CA-002-18** [C] Sur une tâche qui lui est affectée, le membre saisit une durée (heures et/ou
  minutes, > 0 et ≤ 24 h) et une date (par défaut aujourd'hui) ; le total de temps logué de la tâche
  augmente d'autant.
- **CA-002-19** [C] Une durée nulle, négative ou supérieure à 24 h est refusée avec un message
  d'erreur.
- **CA-002-20** [T] Un membre ne peut pas loguer du temps sur une tâche qui ne lui est pas
  affectée (refus de l'API).

### US-9 — Tableau de bord « qui fait quoi »
- **CA-002-21** [C] Après connexion, un membre activé arrive sur le tableau de bord d'équipe : une
  ligne ou carte par membre activé, avec son nom, ses tâches non terminées (titre, statut) et sa
  charge projetée en heures.
- **CA-002-22** [T] [C] Jeu de référence : tâche A estimée 4 h avec 1 h loguée, tâche B estimée 2 h
  avec 3 h loguées, tâche C terminée estimée 5 h ⇒ la charge projetée affichée est **3 h**.
- **CA-002-23** [C] Un membre dont la charge projetée dépasse 7 h porte un indicateur visible
  « Surchargé » ; il disparaît quand sa charge repasse à 7 h ou moins (ex. après passage d'une tâche
  à « terminée »).
- **CA-002-24** [C] Les comptes non activés n'apparaissent pas sur le tableau de bord.

### US-10 — Réaffectation directe
- **CA-002-25** [C] Sur une tâche qui lui est affectée, le membre choisit un collègue activé dans
  une liste et valide ; la tâche disparaît de ses tâches, apparaît chez le collègue, et les charges
  projetées des deux personnes sont mises à jour sur le tableau de bord.
- **CA-002-26** [T] Une réaffectation vers un compte non activé, ou par une personne qui n'est pas
  l'affectée de la tâche, est refusée.

### US-11 / US-12 / US-13 — Propositions d'entraide
- **CA-002-27** [C] Sur une tâche non terminée d'un collègue, un bouton « Proposer mon aide » crée
  une proposition ; le collègue la voit dans « Propositions reçues » avec le nom du proposant et la
  tâche.
- **CA-002-28** [C] Sur l'une de ses tâches non terminées, un bouton « Demander de l'aide » permet
  de choisir un collègue activé ; celui-ci voit la proposition dans « Propositions reçues ».
- **CA-002-29** [C] Le destinataire clique « Accepter » : la tâche est affectée à celui qui la
  prend (le proposant pour « Proposer mon aide », le destinataire pour « Demander de l'aide »), la
  proposition passe à « acceptée » côté émetteur, et les charges du tableau de bord sont mises à jour.
- **CA-002-30** [C] Le destinataire clique « Refuser » : l'affectation ne change pas et la
  proposition passe à « refusée » côté émetteur.
- **CA-002-31** [T] Seul le destinataire peut accepter ou refuser une proposition ; une
  proposition déjà traitée, ou portant sur une tâche réaffectée/terminée entre-temps, ne peut plus
  être acceptée.
- **CA-002-32** [C] Le tableau de bord affiche le nombre de propositions reçues en attente pour le
  membre connecté.

### US-14 — Persistance
- **CA-002-33** [T] Des données créées (compte activé, tâche, temps logué) sont toujours présentes
  après un `./dev deploy` effectué sans `./dev reset` ; le mot de passe admin n'est pas régénéré.

### US-15 — Désactivation (Could)
- **CA-002-34** [C] L'admin clique « Désactiver » sur un compte actif ; ce compte, reconnecté, ne
  voit plus que l'écran « Compte en attente d'activation » ; l'admin ne peut pas se désactiver
  lui-même.

### US-16 — Tâches du jour (Could)
- **CA-002-35** [C] Une tâche peut recevoir une échéance facultative ; un filtre « Aujourd'hui » du
  tableau de bord ne montre que les tâches non terminées échues aujourd'hui ou en retard.

### US-17 — Pile service et sauvegarde (Could)
- **CA-002-36** [T] Une pile `service` distincte se déploie sans affecter la pile `dev` ; une
  sauvegarde puis une restauration sur une pile vierge restitue comptes, tâches, temps et
  propositions.

## 4. Hors périmètre explicite (itération 002)

- Exposition publique HTTPS sur **dnum.lelabs.tech** : certificat, reverse proxy, DNS (à la charge
  de l'utilisateur, à confirmer) ; la boucle livre uniquement le port HTTP prêt à être proxifié.
- Envoi d'e-mails (confirmation d'inscription, notifications, mot de passe oublié) et SMTP.
- Connexion par fournisseurs tiers (SSO, OAuth), authentification à deux facteurs.
- Notifications temps réel / push ; une mise à jour au rechargement de page suffit.
- Multi-équipes, projets, étiquettes, sous-tâches, commentaires, pièces jointes, historique d'audit.
- Rapports, exports (CSV, PDF), statistiques au-delà de la charge projetée.
- Seuil de surcharge paramétrable, calendrier de disponibilités, temps de travail par personne.
- Modification ou suppression des saisies de temps déjà enregistrées ; suppression de tâches.
- Gestion de plusieurs administrateurs ou de rôles autres que admin / membre.
- Application mobile native, mode hors-ligne, internationalisation (interface en français uniquement).
- Les stories Could non réalisées (US-15 à US-17) sont reportées à l'itération 003 sans bloquer la recette.
