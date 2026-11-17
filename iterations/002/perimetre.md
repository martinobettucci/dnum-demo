# Itération 002 — Périmètre (product owner, 2026-11-17, tour 2 — arbitrages du chef de projet intégrés : CA-002-9 en [C]+[T], CA-002-1 (c) en [P])

## 1. Objectif de la boucle

Livrer, par `./dev deploy`, une application de suivi des tâches d'équipe adossée à Supabase auto-hébergé,
publiée sur l'adresse LAN du serveur (`10.77.0.25`, pile `dev` sur le port 8080, pile `service` à données
persistantes sur le port 8081, prêtes à être proxifiées), utilisable de bout en bout par une petite équipe :
inscription → activation par l'admin → tâches, temps, tableau de bord « qui fait quoi » avec charge projetée →
propositions d'entraide.

## 2. Décisions du tour 1 (complément architecte, ADR-007, ADR-008, SPEC-003.9, SPEC-004.7 à 004.10)

| # | Décision | Motif |
|---|---|---|
| D1 | **Dérogation à CA-002-1 validée** : la vérification sur `127.0.0.1` est retirée. Seule la publication `10.77.0.25:<APP_PORT>` (option (b), ADR-007) est exigée. Repli défini ci-dessous. | Voir § 2.1. |
| D2 | **Pile `service` retenue pour l'itération 002** (décision du chef de projet). US-17 passe de COULD à MUST. SPEC-004.7 à 004.9 deviennent exigibles. | Statut reporté de l'architecte. |
| D3 | **US-14 (persistance) passe de SHOULD à MUST**, prérequis de la pile `service` (données persistantes). | Sans elle, US-17 n'a pas de sens. |
| D4 | **CA-002-4 corrigé** : mot de passe admin généré de **≥ 20 caractères** (et non 16), aligné sur SPEC-003.1. | Incohérence relevée entre perimetre et spec ; 20 satisfait aussi l'ancien seuil. |
| D5 | **SPEC-003.9 passée en [T] : cohérente** avec CA-002-4, CA-002-8 et CA-002-24 (§ 2.2). | Vérification de cohérence. |
| D6 | **US-14 et US-17 restent en MUST**, confirmé au tour 2 (décision utilisateur, via le chef de projet). | Prérequis de la pile `service`. |
| D7 | **CA-002-33 passe de [T] à [T] + [R]** : le redéploiement sans `reset` est une opération réservée au responsable applicatif (SPEC-004.6) ; un test ne peut pas la déclencher. Aligné sur SPEC-006 § 2. | Vérifiabilité. |

### 2.1 Dérogation CA-002-1 : validation et repli

**Validée**, pour les raisons suivantes, vérifiées dans le dépôt :
- Aucun consommateur ne dépend de `127.0.0.1` : le runner et le client utilisent `APP_URL=http://app`
  (`stack/compose.yml`, `tools/client/driver.py`). Le reverse proxy HTTPS cible `10.77.0.25` (ADR-001).
- La seule mention de `127.0.0.1` vers l'application est l'affichage de `./dev` (ligne 115), à corriger par
  `action`. Le port 9000 de `tools/client` est le contrôle du pilote de recette, pas l'application.
- Publier `127.0.0.1` et `10.77.0.25` sur un même port échoue sous Docker rootless (constat de
  `iterations/002/mise-en-service.md` §1). Il n'y a donc pas de solution sans perte.

**Repli (option (a), deux ports distincts)**, déclenché si, au premier `./dev deploy` :
- `curl -sI http://10.77.0.25:8080/` depuis l'hôte n'répond pas 200 (vérification `[R]`) ; ou
- `10.77.0.25:8080` et `10.77.0.25:8081` n'écoutent pas ensemble (`ss -ltn`, premier test de ce couple, ADR-007 §5).

Dans ce cas, l'architecte écrit un nouvel ADR (ports fixés par lui), et CA-002-1 est réécrit par le PO.
Le repli ne change pas le périmètre fonctionnel de la boucle.

### 2.2 Cohérence avec SPEC-003.9 (passée en [T])

- SPEC-003.9 : le seed ne crée que `ADMIN_EMAIL` ; hors comptes `@test.invalid`, `admin_list_accounts()` ne
  retourne que cet administrateur, sur `dev` après reset + deploy et sur `service` avant tout scénario d'écriture.
- Compatible avec CA-002-4 (un seul admin initial) et avec CA-002-8 : la liste « comptes en attente » ne contient
  que les comptes créés par la recette via CA-002-6. Le client doit donc **s'inscrire lui-même** avant de tester
  l'activation. Aucun compte n'est pré-créé.
- Compatible avec CA-002-24 (les comptes non activés n'apparaissent pas au tableau de bord).
- Le marqueur `spec("SPEC-003.9")` relève du testeur (`tests/test_003_admin.py`), comme convenu avec l'architecte.

### 2.3 Règle des critères [R] (tour 2)

**Liste exhaustive des [R] de l'itération 002** (seuls critères dont la vérification exige l'hôte) :

| CA | Vérification [R] | Preuve à consigner |
|---|---|---|
| CA-002-1 | (a) `curl -sI http://10.77.0.25:8080/` → 200 ; (b) `ss -ltn` : `10.77.0.25:8080` seul, sans `127.0.0.1:8080` ni `0.0.0.0:8080` ; (c) **passé en [P]** (voir « Tranché » ci-dessous) | sorties brutes de `curl` et `ss -ltn` |
| CA-002-33 | `./dev deploy` **sans** `./dev reset` entre l'écriture de données et leur relecture (le [T] lit avant et après) | horodatages des deux `deploy` |
| CA-002-36 | (a) `docker compose ls` et `docker volume ls` identiques avant/après `./dev deploy service` pour le projet `devenv` ; (b) `curl -sI http://10.77.0.25:8081/` → 200 ; (c) `./dev reset service` sans `--confirmer-destruction` refusé, rien détruit | sorties brutes avant/après |

**Pourquoi ces critères ne peuvent être ni [C] ni [T]** :
- *Pas [C]* : le client n'agit qu'au clavier et à la souris et ne voit que ses captures d'écran (garde-fou technique).
  Une page affichée dans son navigateur ne révèle ni l'adresse d'écoute, ni les conteneurs, ni la sortie de `./dev`.
- *Pas [T]* : le runner est un conteneur du réseau de la pile dev (`APP_URL=http://app`). Il ne doit pas joindre
  `10.77.0.25` (ADR-007 § 4, SPEC-006 § 1), et un succès depuis l'intérieur du réseau ne prouverait pas l'accessibilité
  LAN, objet même de la dérogation D1. `ss` et `docker compose ls` interrogent l'hôte et le daemon Docker, hors de portée
  d'un conteneur de test ; le socket Docker n'est pas ouvert au runner. Enfin `deploy`, `reset` et `backup`/`restore` sont
  réservés au responsable applicatif (SPEC-004.6, `tools/guards/guard.py`) : aucun test ne peut les déclencher.

**Règle** :
1. Un [R] est exécuté **uniquement** par le responsable applicatif, après le `deploy` du tour, et consigné dans
   `iterations/002/mise-en-service.md` (commande, sortie brute, horodatage, aucun secret).
2. Un [R] ne remplace jamais un [C] ni un [T] : un critère n'est acquis que si ses parties [T]/[C] **et** [R] sont vertes.
3. Un [R] non exécuté est « **non confirmé** », jamais « réussi ». Il bloque la clôture de l'itération tant qu'il n'est pas consigné.

**Statut au tour 2 : non confirmé.** Le product owner n'a pas d'outil d'exécution dans sa session : `ss -ltn`,
`docker compose ls` et `curl` n'ont pas été lancés par lui. Dernière observation consignée (tour 1,
`mise-en-service.md` §1 et §5, **périmée**) : pile dev publiée sur `127.0.0.1:8080` seule, `10.77.0.25` non publié,
bail DHCP `dynamic`. À reconfirmer après le `deploy` du tour 2.

**Tranché (tour 2, arbitrage du chef de projet)** : CA-002-1 (c) (absence de `127.0.0.1` dans la sortie de `./dev`) est un contrôle statique du texte de `./dev` ; il passe en **[P]**, exécuté par `./dev policies`. Le [R] de CA-002-1 se limite à (a) et (b).

## 3. User stories retenues (priorisées, MoSCoW)

Règle de livraison : les **Must** forment le cœur et sont réalisés, déployés et recettés en premier. Les **Should**
suivent dans la même boucle si le temps le permet. Les **Could** ne sont réalisés que si tout le reste est vert.
Une story non livrée passe à l'itération 003, sans bloquer la recette du reste.

Ordre de réalisation des Must : US-1 → US-2 → US-14 → US-3 → US-4 → US-5 → US-6 → US-7 → US-8 → US-9 → US-17.

### MUST — cœur utilisable et pile service

- **US-1 — Socle déployable.** En tant que responsable applicatif, je veux mettre en service l'application
  complète (Supabase auto-hébergé : Postgres, Auth, API, passerelle + interface web) avec `./dev deploy` depuis le
  seul dépôt, afin que l'équipe y accède sur l'adresse LAN `10.77.0.25` au port annoncé dans `mise-en-service.md`,
  prête à être proxifiée.
- **US-2 — Compte administrateur initial.** En tant qu'utilisateur (administrateur), je veux qu'un compte admin
  activé existe dès la première mise en service, avec un mot de passe généré et jamais commité, afin d'administrer
  l'application dès le premier jour.
- **US-14 — Persistance des données.** En tant qu'équipe, je veux que nos données survivent à un redéploiement
  ordinaire (`./dev deploy` sans `reset`), afin de pouvoir réellement utiliser l'outil. *(passée en Must, D3)*
- **US-3 — Inscription.** En tant que collègue, je veux créer mon compte (nom affiché, e-mail, mot de passe) afin de
  demander l'accès à l'application.
- **US-4 — Activation par l'admin.** En tant qu'administrateur, je veux voir les comptes en attente et les activer,
  afin que seules les personnes que j'ai validées accèdent à l'application.
- **US-5 — Accès refusé aux comptes non activés.** En tant qu'administrateur, je veux qu'un compte non activé ne
  voie aucune donnée de l'équipe, ni par l'interface ni par l'API, afin de protéger les informations de l'équipe.
- **US-6 — Mes tâches.** En tant que membre activé, je veux créer, modifier et changer le statut (à faire / en cours /
  terminée) de mes tâches, avec une estimation en heures, afin de déclarer ce sur quoi je travaille et combien de
  temps cela doit prendre.
- **US-7 — Tâches des autres.** En tant que membre activé, je veux consulter les tâches de mes collègues, afin de
  savoir qui travaille sur quoi.
- **US-8 — Temps passé.** En tant que membre activé, je veux loguer du temps sur une tâche qui m'est affectée, afin
  que le temps réellement passé et le reste à faire soient connus.
- **US-9 — Tableau de bord « qui fait quoi ».** En tant que membre activé, je veux arriver après connexion sur un
  tableau de bord d'équipe montrant, par personne, ses tâches en cours et sa charge projetée, afin de repérer d'un
  coup d'œil qui est chargé.
- **US-17 — Pile « service » et sauvegarde.** En tant que responsable applicatif, je veux une pile `service`
  distincte de la pile `dev` jetable, à données persistantes et dotée d'une commande de sauvegarde/restauration,
  afin de préparer l'exposition publique. *(passée en Must, D2)*

### SHOULD — collaboration

- **US-10 — Réaffectation directe.** En tant que personne affectée à une tâche, je veux la renvoyer directement à un
  collègue activé, afin de transmettre un travail convenu de vive voix.
- **US-11 — Proposer mon aide.** En tant que membre activé, je veux proposer de prendre une tâche d'un collègue
  (notamment un collègue signalé surchargé), afin de l'aider ; la tâche ne change de main que s'il accepte.
- **US-12 — Demander de l'aide.** En tant que membre activé, je veux proposer à un collègue de prendre l'une de mes
  tâches, afin d'alléger ma charge ; la tâche ne change de main que s'il accepte.
- **US-13 — Mes propositions.** En tant que membre activé, je veux voir les propositions reçues (accepter / refuser)
  et envoyées (en attente / acceptée / refusée), afin de suivre l'entraide.

### COULD — confort

- **US-15 — Désactivation.** En tant qu'administrateur, je veux désactiver un compte activé, afin de retirer l'accès à
  une personne qui quitte l'équipe.
- **US-16 — Tâches du jour.** En tant que membre activé, je veux donner une échéance à une tâche et filtrer le
  tableau de bord sur « aujourd'hui », afin de cibler l'entraide sur les choses à faire de la journée.

## 4. Critères d'acceptation

Conventions : « membre activé » = compte activé par l'admin. **Charge projetée** d'une personne = somme, sur ses
tâches non terminées, de `max(estimation − temps logué, 0)`, en heures, arrondie à 0,25 h. **Surchargé** = charge
projetée strictement supérieure à **7 h** (seuil fixe pour cette boucle). [C] = vérifiable par le client au
clavier/souris ; [T] = vérifiable par test automatique ; [P] = contrôle statique exécuté par `./dev policies` (policies/checks) ; [R] = vérification de l'hôte par le responsable applicatif
(réseau, processus, `docker`), consignée dans `mise-en-service.md`. Les [R] sont des vérifications d'infrastructure
que l'hôte seul peut faire : elles ne sont pas des critères fonctionnels et ne remplacent aucun [C] ou [T].

### US-1 — Socle déployable
- **CA-002-1** [T] + [R] + [P] — *dérogé et validé (D1)*. Après `./dev reset` puis `./dev deploy` : `GET http://app/` depuis
  le runner répond `200` ([T]). L'application répond `200` sur `http://10.77.0.25:<APP_PORT>/` (8080 pour `dev`) ;
  `ss -ltn` montre cette adresse seule pour ce port, sans écouteur `127.0.0.1` ni `0.0.0.0` ([R]). La sortie de
  `./dev` n'affiche aucune URL `127.0.0.1` ([P]). Le runner ne joint pas `10.77.0.25` (ADR-007 §4).
  **Écart accepté (arbitrage du chef de projet, tour 3) :** la partie « après `reset` » n'est pas vérifiée tant que la pile `dev` est gelée ; elle reste exigible à la levée du gel.
- **CA-002-2** [T] + [P] — Toutes les images de la pile sont épinglées par tag exact (aucun `latest`). Les images
  construites portent le tag de leur pile (`devenv/app:dev` pour `dev`, `devenv/app:service` pour `service`,
  ADR-008). Aucun secret (mot de passe, clé JWT, clé de service, JWT) n'est présent dans les fichiers suivis par git.
- **CA-002-3** [T] — L'interface web n'appelle l'API Supabase que via la même origine (passerelle derrière le port
  HTTP unique) : aucun autre port n'est requis côté navigateur.

### US-2 — Compte administrateur initial
- **CA-002-4** [T] — Après une première mise en service, un compte admin existe, activé et doté du rôle
  administrateur ; son mot de passe est généré aléatoirement (**≥ 20 caractères**, D4), stocké hors du suivi git et
  lisible par le responsable applicatif pour transmission au chef de projet. Hors comptes `@test.invalid`, seul
  `ADMIN_EMAIL` existe, sur `dev` après reset + deploy et sur `service` avant tout scénario d'écriture (SPEC-003.9,
  [T] désormais).
- **CA-002-5** [C] — Avec les identifiants admin transmis, le client se connecte et voit le tableau de bord d'équipe
  ainsi qu'une entrée de menu « Administration » absente pour un membre ordinaire.

### US-3 — Inscription
- **CA-002-6** [C] — Depuis l'écran de connexion, un lien « Créer un compte » mène à un formulaire (nom affiché,
  e-mail, mot de passe) ; à la validation, un message indique que le compte est en attente d'activation par
  l'administrateur. Aucun e-mail de confirmation n'est requis.
- **CA-002-7** [C] — Une inscription avec un e-mail déjà utilisé, ou un mot de passe de moins de 8 caractères, est
  refusée avec un message d'erreur lisible, sans création de compte.

### US-4 — Activation par l'admin
- **CA-002-8** [C] — Dans « Administration », l'admin voit la liste des comptes en attente (nom, e-mail, date
  d'inscription) et un bouton « Activer » par compte ; après clic, le compte disparaît de la liste des comptes en
  attente et apparaît dans la liste des comptes actifs. *(La recette crée elle-même le compte à activer, via CA-002-6.)*
- **CA-002-9** [C] + [T] — Un membre non administrateur ne peut pas activer un compte. [C] : il saisit directement
  `#/admin` dans la barre d'adresse et n'obtient ni la liste des comptes en attente ni de bouton « Activer »
  (refus ou retour au tableau de bord). [T] : par l'API, il tente d'activer un compte et reçoit un refus ; le compte
  reste non activé. *Redondance [C]/[T] acceptée sur la sécurité d'accès (arbitrage du chef de projet, tour 2).*

### US-5 — Accès refusé aux comptes non activés
- **CA-002-10** [C] — Un compte inscrit mais non activé qui se connecte ne voit qu'un écran « Compte en attente
  d'activation » et un bouton de déconnexion ; aucune tâche, aucun nom de collègue n'est affiché.
- **CA-002-11** [T] — Avec le jeton d'un compte non activé, puis sans jeton (clé anonyme seule), les lectures et
  écritures des tables tâches, temps, propositions et profils via l'API renvoient zéro ligne ou un refus (politiques
  RLS en vigueur).
- **CA-002-12** [C] — Après activation par l'admin, ce même compte, à sa connexion suivante, accède au tableau de
  bord d'équipe.

### US-6 — Mes tâches
- **CA-002-13** [C] — Un membre activé crée une tâche (titre obligatoire, description facultative, estimation en
  heures obligatoire > 0) ; elle apparaît aussitôt dans « Mes tâches », au statut « à faire », affectée à lui-même.
- **CA-002-14** [C] — Un titre vide ou une estimation absente, nulle ou négative est refusé avec un message
  d'erreur, sans création.
- **CA-002-15** [C] — Le membre modifie le titre, la description, l'estimation et le statut (à faire / en cours /
  terminée) de sa tâche ; les changements sont visibles après rechargement de la page.
- **CA-002-16** [T] — Un membre ne peut pas modifier une tâche dont il n'est ni l'affecté ni le créateur (refus de
  l'API).

### US-7 — Tâches des autres
- **CA-002-17** [C] — Depuis le tableau de bord, un clic sur le nom d'un collègue affiche la liste de ses tâches
  (titre, statut, estimation, temps logué), en lecture seule.

### US-8 — Temps passé
- **CA-002-18** [C] — Sur une tâche qui lui est affectée, le membre saisit une durée (heures et/ou minutes, > 0 et
  ≤ 24 h) et une date (par défaut aujourd'hui) ; le total de temps logué de la tâche augmente d'autant.
- **CA-002-19** [C] — Une durée nulle, négative ou supérieure à 24 h est refusée avec un message d'erreur.
- **CA-002-20** [T] — Un membre ne peut pas loguer du temps sur une tâche qui ne lui est pas affectée (refus de l'API).

### US-9 — Tableau de bord « qui fait quoi »
- **CA-002-21** [C] — Après connexion, un membre activé arrive sur le tableau de bord d'équipe : une ligne ou carte par
  membre activé, avec son nom, ses tâches non terminées (titre, statut) et sa charge projetée en heures.
- **CA-002-22** [T] [C] — Jeu de référence : tâche A estimée 4 h avec 1 h loguée, tâche B estimée 2 h avec 3 h loguées,
  tâche C terminée estimée 5 h ⇒ la charge projetée affichée est **3 h**.
- **CA-002-23** [C] — Un membre dont la charge projetée dépasse 7 h porte un indicateur visible « Surchargé » ; il
  disparaît quand sa charge repasse à 7 h ou moins (ex. après passage d'une tâche à « terminée »).
- **CA-002-24** [C] — Les comptes non activés n'apparaissent pas sur le tableau de bord.

### US-10 — Réaffectation directe (Should)
- **CA-002-25** [C] — Sur une tâche qui lui est affectée, le membre choisit un collègue activé dans une liste et valide ;
  la tâche disparaît de ses tâches, apparaît chez le collègue, et les charges projetées des deux personnes sont mises à
  jour sur le tableau de bord.
- **CA-002-26** [T] — Une réaffectation vers un compte non activé, ou par une personne qui n'est pas l'affectée de la
  tâche, est refusée.

### US-11 / US-12 / US-13 — Propositions d'entraide (Should)
- **CA-002-27** [C] — *(réécrit au tour 3 : message de confirmation)* Sur une tâche non terminée d'un collègue, le bouton
  « Proposer mon aide » crée une proposition. Après le clic, un message apparaît à l'écran, sans recharger la page, et
  affiche le texte exact M-1 de SPEC-005 : « Proposition envoyée à <nom du collègue> pour la tâche « <titre de la tâche> ». »
  Le texte « Proposition envoyée » seul, sans nom du collègue ni de tâche, ne satisfait pas ce critère. Le collègue voit la proposition
  dans « Propositions reçues » avec le nom du proposant et la tâche.
- **CA-002-28** [C] — *(réécrit au tour 3 : message de confirmation)* Sur l'une de ses tâches non terminées, le bouton
  « Demander de l'aide » ouvre le choix d'un collègue activé. Après validation, un message apparaît à l'écran, sans
  recharger la page, et affiche le texte exact M-2 de SPEC-005 : « Demande d'aide envoyée à <nom du collègue> pour la tâche
  « <titre de la tâche> ». » Ce message reste visible sans clic supplémentaire, jusqu'à ce que la page change. Le
  collègue voit la demande dans « Propositions reçues ».
- **CA-002-29** [C] — Le destinataire clique « Accepter » : la tâche est affectée à celui qui la prend (le proposant
  pour « Proposer mon aide », le destinataire pour « Demander de l'aide »), la proposition passe à « acceptée » côté
  émetteur, et les charges du tableau de bord sont mises à jour.
- **CA-002-30** [C] — Le destinataire clique « Refuser » : l'affectation ne change pas et la proposition passe à
  « refusée » côté émetteur.
- **CA-002-31** [T] — Seul le destinataire peut accepter ou refuser une proposition ; une proposition déjà traitée, ou
  portant sur une tâche réaffectée/terminée entre-temps, ne peut plus être acceptée.
- **CA-002-32** [C] — Le tableau de bord affiche le nombre de propositions reçues en attente pour le membre connecté.

### US-14 — Persistance (Must)
- **CA-002-33** [T] + [R] — Des données créées (compte activé, tâche, temps logué) sont toujours présentes après un
  `./dev deploy` effectué sans `./dev reset` ; le mot de passe admin n'est pas régénéré (SPEC-004.3, SPEC-003.5).

### US-15 — Désactivation (Could)
- **CA-002-34** [C] — *(confirmation retirée au tour 3 : elle est traitée par CA-002-39)* Dans « Administration », « Comptes actifs », l'admin désactive un compte (bouton « Désactiver », puis validation selon CA-002-39) : le compte n'apparaît plus comme compte actif et, reconnecté, ne voit plus que l'écran « Compte en attente d'activation ». Sur la ligne de son propre compte, l'admin ne voit pas de bouton « Désactiver ».

### US-16 — Tâches du jour (Could)
- **CA-002-35** [C] — Une tâche peut recevoir une échéance facultative ; un filtre « Aujourd'hui » du tableau de bord ne
  montre que les tâches non terminées échues aujourd'hui ou en retard.

### US-17 — Pile service et sauvegarde (Must, D2)
- **CA-002-36** [T] + [R] — Une pile `service` (projet `dnum-service`, `APP_PORT=8081`, image `devenv/app:service`) se
  déploie sans affecter la pile `dev` : conteneurs, volumes et réseau de `devenv` inchangés (`docker compose ls` et
  `docker volume ls` avant/après, [R]). `GET http://10.77.0.25:8081/` répond `200` ([R]). Une sauvegarde
  (`./dev backup service`) puis une restauration après reset sur une pile au même niveau de migration restituent
  comptes, tâches, temps et propositions ([T]). `./dev reset service` sans `--confirmer-destruction` est refusé sans rien
  détruire ([R]). Une restauration vers un niveau de migration différent est refusée ([T]).

### Arbitrages du chef de projet (tour 3)

| # | Arbitrage | Effet dans ce document |
|---|---|---|
| A1 | SPEC-005 fait foi pour les textes (M-1 à M-6, SPEC-005 § « Messages exacts »). | CA-002-27, 28, 38 et 39 alignés sur les textes exacts ; recette étapes 5, 7, 9, 10, 12 et 18.1 alignées. CA-002-38 aligné aussi sur la règle de SPEC-005.62 (deux champs, correspondance par mots), au-delà des seuls textes. |
| A2 | Numérotation de l'architecte : 37 barre fixe, 38 recherche, 39 confirmation « Désactiver ». | CA-002-39 créé ; la confirmation est retirée de CA-002-34. Recette étape 18.1 et décompte de couverture mis à jour (28 critères [C]). |
| A3 | « Réaffecter » et « Loguer du temps » restent **sans confirmation** : actions réversibles. | Aucun CA de confirmation pour ces deux actions (points ouverts 1 et 2 de SPEC-005 clos pour ces deux actions). |
| A4 | CA-002-1, partie « après `reset` » : **écart accepté** tant que la pile `dev` est gelée. | Mention ajoutée à CA-002-1 ; la partie reste exigible à la levée du gel. |
| A5 | Seed (ADR-012) : en pile service, le seed crée l'admin s'il est absent et ne réécrit jamais un mot de passe existant. | CA-002-40 créé (US-2, [T] + [P]), rattaché à SPEC-003.10 à 003.12. |
| A6 | « Modifier » (tâche) reste **sans confirmation** : action réversible, comme « Réaffecter » et « Loguer du temps » (A3). | Aucun CA de confirmation pour « Modifier » (CA-002-15 inchangé). Point ouvert retiré de A3. |

### Retours de recette, tour 3 (rattachés aux stories existantes)

Modifications du tour 3 : CA-002-27, CA-002-28, CA-002-34 et CA-002-38 réécrits ; CA-002-37 et CA-002-39 créés ;
CA-002-40 créé (arbitrage A5). Statut : **non recettés**. Le gel de la pile `dev` est actif : aucun `deploy`, `reset` ou `test`
n'est lancé pour vérifier ces critères avant levée du gel. Priorité proposée : CA-002-38 dans la boucle (US-4, Must) ;
CA-002-37 (Should) livré si le reste est vert. CA-002-40 (US-2, Must) est réalisé avec le seed ; CA-002-39 (Could) suit CA-002-34.

- **CA-002-37** [C] — *(créé au tour 3, rattaché à US-9 : interface commune)* Sur toute page connectée (tableau de bord,
  « Mes tâches », « Administration », tâches d'un collègue), la barre du haut (nom de l'application, liens de navigation,
  déconnexion) reste affichée en haut de l'écran quand la page défile. Vérification : sur une page plus longue que
  l'écran (zoom du navigateur à 200 % ou 300 % avec Ctrl + « + »), la barre reste visible après défilement à la molette
  ; un lien de la barre, activé pendant le défilement, fonctionne toujours.
- **CA-002-38** [C] — *(créé au tour 3, rattaché à US-4 : listes d'administration ; textes et règle alignés sur SPEC-005.62, M-5 et M-6)* Dans « Administration », deux champs de recherche, libellés « Rechercher dans les comptes en attente » et « Rechercher dans les comptes actifs », sont placés chacun au-dessus de sa liste ; chacun ne filtre que sa liste. Taper un nom ou une partie d'e-mail, sans distinction de majuscules, filtre la liste pendant la saisie : seuls les comptes correspondants restent affichés, avec leurs boutons « Activer » ou « Désactiver ». Le terme est découpé en mots : un compte correspond si chaque mot figure dans son nom ou son e-mail. Effacer le champ rétablit la liste complète. Si aucun compte ne correspond, la liste affiche « Aucun compte en attente ne correspond à « <terme> ». » (liste d'attente) ou « Aucun compte actif ne correspond à « <terme> ». » (liste active). Chacun des deux champs est atteint à la touche Tab depuis le haut de la page d'administration.
- **CA-002-39** [C] — *(créé au tour 3, rattaché à US-15 : confirmation de la désactivation, SPEC-005.63, M-3 et M-4)* Clic sur « Désactiver » : sous la ligne du compte s'ouvre un bloc affichant le texte exact « Désactiver le compte de <nom> ? Cette personne ne verra plus les données de l'équipe. », avec les boutons « Confirmer la désactivation » et « Annuler ». Le focus est placé sur « Annuler ». « Annuler » ferme le bloc : le compte reste actif, la liste ne change pas. « Confirmer la désactivation » désactive le compte et affiche le message exact « Le compte de <nom> est désactivé. ». Aucune fenêtre native ni modale n'est utilisée. (Échap ferme aussi le bloc : recommandé par SPEC-005.63, non exigé ici.)
- **CA-002-40** [T] + [P] — *(créé au tour 3, rattaché à US-2 : seed sans écrasement, ADR-012, SPEC-003.10 et 003.11)* Le seed crée le compte `ADMIN_EMAIL` seulement s'il est absent. Quand il existe, il ne modifie ni son mot de passe, ni son e-mail, ni sa confirmation : après changement du mot de passe admin en une valeur de test `X`, un nouveau passage du seed laisse la connexion avec `X` réussie et la connexion avec `ADMIN_PASSWORD` refusée ; `encrypted_password` et `updated_at` sont inchangés. Si le compte existe sans e-mail confirmé, le seed s'arrête avec un code de retour non nul, sans secret dans sa sortie et sans rien modifier. [T] : `tests/test_003_admin.py`. [P] : dans `tools/deploy/seed.py`, tout appel `PUT`, `PATCH` ou `DELETE` vers `/admin/users` figure dans la seule branche « compte absent ». [R] : couvert par CA-002-33 (`./dev deploy` sans `reset`).

## 5. Hors périmètre explicite (itération 002)

- Exposition publique HTTPS sur **dnum.lelabs.tech** : certificat, reverse proxy, DNS (à la charge de l'utilisateur) ;
  la boucle livre uniquement la publication LAN `10.77.0.25:<APP_PORT>`.
- Publication sur `127.0.0.1` (retirée par D1), publication sur `0.0.0.0`, changement du driver réseau de Docker
  rootless (ADR-007, option (c)). Les deux ports par pile ne sont réalisés qu'en cas de repli (§ 2.1).
- Envoi d'e-mails (confirmation d'inscription, notifications, mot de passe oublié) et SMTP.
- Connexion par fournisseurs tiers (SSO, OAuth), authentification à deux facteurs.
- Notifications temps réel / push ; une mise à jour au rechargement de page suffit.
- Multi-équipes, projets, étiquettes, sous-tâches, commentaires, pièces jointes, historique d'audit.
- Rapports, exports (CSV, PDF), statistiques au-delà de la charge projetée.
- Seuil de surcharge paramétrable, calendrier de disponibilités, temps de travail par personne.
- Modification ou suppression des saisies de temps déjà enregistrées ; suppression de tâches.
- Gestion de plusieurs administrateurs ou de rôles autres que admin / membre.
- Application mobile native, mode hors-ligne, internationalisation (interface en français uniquement).
- Adresse LAN dynamique : la stabilité de `10.77.0.25` (bail DHCP, risque R3) est une action du responsable applicatif
  avant le premier `deploy service`, pas une story.
- Les stories Could non réalisées (US-15, US-16) sont reportées à l'itération 003 sans bloquer la recette.

## 6. Report / backlog de l'itération 003 (tour 2, décision du chef de projet)

Ces deux points ne sont **pas** réalisés dans l'itération 002. Ils sont inscrits au backlog de l'itération 003 :

- **BL-003-1 — Monter `supabase-js` à une version embarquant `auth-js` ≥ 2.70.0.**
  Corrige GHSA-8r88-6cj9-9fh5 / CVE-2025-48370. Périmètre : mise à jour de la dépendance, puis **recette
  d'authentification** (inscription, connexion, activation, accès refusé aux comptes non activés : CA-002-4 à
  CA-002-12 et CA-002-31 rejoués) et **amendement de SPEC-001.8(b)** par l'architecte, à la charge de la boucle 003.
- **BL-003-2 — Monter `esbuild` à 0.28.x.** Corrige GHSA-67mh-4wv8-2f99. Vérification : contrôle [P] de la
  version résolue dans le lockfile, et build de l'application vert ([T]).

Ces points ne modifient ni le périmètre fonctionnel de la boucle 002 ni son objectif (§ 1).

## 7. Backlog de l'itération 003 — changer mon mot de passe (arbitrage du chef de projet, 2026-11-17)

Inscrit au backlog de 003, **non réalisé dans 002**. Priorité **proposée : SHOULD** (à confirmer par le chef de projet à l'ouverture de 003).
Canal : `PUT /auth/v1/user` avec le jeton de l'utilisateur (chemin standard Supabase), accepté et documenté pour 002 par ADR-012 § 6 (complément tour 4, ADR-013 D-5).

**Point à lever avant 003 :** le complément d'ADR-012 § 6 indique encore ce canal comme « point ouvert » (ADR-013, point 2 : l'accepter ou le fermer). Le chef de projet l'a arbitré « accepté pour 002 ». L'architecte doit donc formaliser cet arbitrage dans une spec (SPEC-003 ou SPEC-001) avant que 003 ne le réalise.

**US-18 — Changer mon mot de passe.** En tant que membre activé (administrateur compris), je veux changer mon mot de passe depuis l'application, afin de garder un accès sûr à mon compte sans passer par l'administrateur.

Critères provisoires (numérotation définitive à la charge du product owner de 003 : `CA-003-x`) :

- **CA-003-a** [C] — Depuis la barre du haut, un lien « Mon mot de passe » ouvre un formulaire avec trois champs : mot de passe actuel, nouveau mot de passe, confirmation du nouveau mot de passe.
- **CA-003-b** [C] — Un nouveau mot de passe de moins de 8 caractères, ou une confirmation différente du nouveau mot de passe, est refusé avec un message d'erreur lisible ; le mot de passe reste inchangé (même règle que CA-002-7).
- **CA-003-c** [C] — Un mot de passe actuel incorrect est refusé avec un message d'erreur lisible ; le mot de passe reste inchangé.
- **CA-003-d** [C] — Un changement réussi affiche « Votre mot de passe a été modifié. ». À la déconnexion puis à la reconnexion, le nouveau mot de passe est accepté et l'ancien refusé.
- **CA-003-e** [C] — Après le changement, mes tâches, mes temps et mes propositions restent accessibles à l'identique, sans perte.
- **CA-003-f** [C] — Un compte en attente d'activation ne voit pas le lien « Mon mot de passe » (il ne voit que l'écran « Compte en attente d'activation », CA-002-10).
- **CA-003-g** [T] — Le changement n'est accepté que pour la session de l'utilisateur connecté : sans jeton valide, ou avec le jeton d'un autre compte, aucun mot de passe n'est modifié.
- **CA-003-h** [T] — Après un `./dev deploy` sans `reset` suivant le changement, le mot de passe modifié reste valide : le seed ne le rétablit pas (CA-002-40, ADR-012).

Dépendances : la mise à jour `supabase-js` de BL-003-1 peut modifier l'appel ; la recette d'authentification de 003 rejoue CA-002-4 à 002-12 et CA-003-a à 003-d.

Hors périmètre de cette story (à confirmer) : « mot de passe oublié » par e-mail (SMTP exclu de 002 et 003 sauf décision contraire) ; changement du mot de passe d'un autre compte par l'administrateur ; règle de complexité au-delà de 8 caractères ; historique des mots de passe ; double authentification.

## 8. Backlog de l'itération 003 — retours de la recette passe 3 (décision du chef de projet, 2026-11-17)

Inscrit au backlog de 003, **non réalisé dans 002**. Constat : CA-002-27, CA-002-28 et CA-002-37 sont validés à la recette passe 3 (CA-002-37 sur la barre fixe), CA-002-38 et CA-002-39 également. Les trois points ci-dessous sont des améliorations de ces critères validés, pas des rejets. Ils sont rédigés en langage utilisateur ; la numérotation `CA-003-x` définitive sera fixée par le product owner de 003.

**Priorités proposées** (à confirmer par le chef de projet à l'ouverture de 003) : US-19 SHOULD, US-20 MUST, US-21 SHOULD.

### US-19 — Message de confirmation visible près de l'action (SHOULD)

En tant que membre activé, je veux voir le message de confirmation de ma proposition ou de ma demande d'aide là où j'ai cliqué, afin de ne pas le manquer quand la page est longue.

Constat : le message est aujourd'hui affiché en haut de page, hors de la vue quand l'utilisateur a fait défiler la page vers l'action.

- **CA-003-i** [C] — Après « Proposer mon aide » (CA-002-27) ou « Demander de l'aide » (CA-002-28), le message de confirmation (textes M-1 et M-2 de SPEC-005, inchangés) apparaît à côté du bouton déclenché, **ou** la page défile jusqu'à lui : dans les deux cas il est visible sans défilement manuel. Le message est annoncé aux lecteurs d'écran (zone à annonce vocale polie, `aria-live`), sans rechargement de la page.

### US-20 — Cadre de focus visible sur les boutons (MUST)

En tant que membre qui navigue au clavier, je veux voir quel bouton a le focus, afin de savoir où je me trouve et quelle action je vais déclencher.

Motif : la recette est exclusivement clavier et souris ; sans cadre visible, la navigation au Tab n'est pas vérifiable à l'œil. Cette story est un prérequis de la recette clavier de 003.

- **CA-003-j** [C] — Chaque bouton de l'application (dont « Activer », « Désactiver », « Confirmer la désactivation », « Annuler » de CA-002-39, « Proposer mon aide », « Demander de l'aide », « Accepter », « Refuser », « Mon mot de passe ») affiche un cadre de focus visible lorsqu'il reçoit le focus par la touche Tab. Le cadre est nettement distinct du fond à l'écran. Au clic souris, le cadre peut ne pas apparaître ; ce n'est pas exigé.
  Vérification : le client, au seul clavier, parcourt la page et capture chaque bouton ayant le focus ; aucune capture n'est sans cadre.

### US-21 — Vérification du zoom 200 % par un moyen fiable (SHOULD)

En tant que responsable de la recette, je veux une vérification du zoom 200 % qui produise un effet observable, afin que CA-002-37 ne repose pas sur un test qui ne voit rien.

Constat : le client headless n'a produit aucun effet visible en zoom 200 % ; la vérification de CA-002-37 ne peut donc pas être considérée comme probante à ce niveau de zoom. Le moyen de vérification (navigateur réel, outil de test automatisé avec largeur équivalente à 200 %, ou autre) est choisi par l'architecte, pas par ce document.

- **CA-003-k** [C] ou [T] selon le moyen retenu — Au zoom 200 % (équivalent 320 px de largeur de contenu), la page reste utilisable : la barre du haut reste visible après défilement, un lien de la barre fonctionne pendant le défilement (CA-002-37), et il n'y a pas de défilement horizontal pour lire le texte courant. La preuve consiste en une capture à 100 % et une capture à 200 % **différentes**, le niveau de zoom étant indiqué ; une capture identique à 100 % fait échouer le critère.

### Hors périmètre de ce backlog (003)

- Refonte graphique de l'interface, nouvelle charte de couleurs (hors US-20 : seul le cadre de focus est visé).
- Échap pour fermer le bloc de confirmation (recommandé par SPEC-005.63, non exigé par CA-002-39) : à traiter avec US-20 si le chef de projet le souhaite, sinon hors périmètre.
- Annonce vocale de tous les messages de l'application : seul le message de confirmation de US-19 est visé.
- Tests du zoom 400 % ou 300 % : seul le niveau 200 % est exigé.
