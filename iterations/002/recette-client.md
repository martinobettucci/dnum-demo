# Itération 002 — Liste de recette client (tour 2)

- Destinataire : Team DevOps, agent `client` (recette au clavier et à la souris uniquement, `tools/client/client.sh`).
- Rédigé par : product owner, 2026-11-17, à partir de `perimetre.md` (critères marqués [C]).
- Ne couvre **que** les critères [C]. Les critères [T] et [R] ne sont pas recettés ici.

## 0. Consignes

- Vous ne voyez que vos captures d'écran. Rien n'est supposé : notez ce que vous **voyez**, à chaque étape.
- Clavier et souris uniquement : Tab / Maj+Tab / Entrée / Échap, clic, saisie. Pas d'outils de développement, pas d'appel direct à l'API, pas de base.
- Une capture par étape marquée **[capture]**. Nommez-la avec le numéro d'étape.
- Adresse d'entrée : celle fournie par le chef de projet à l'exécution (par défaut `http://app`, réseau de la pile dev).
  L'adresse LAN `10.77.0.25` n'est pas recettée ici (contrôle [R]).
- **Identifiants de l'administrateur** : fournis par le chef de projet dans la conversation, à l'exécution. Ne les écrivez
  dans aucune capture ni aucun compte rendu.
- **Comptes de recette** : domaine `@test.invalid` (comptes jetables, exclus des contrôles de SPEC-003.9).
  Remplacez `<N>` par le numéro de passe de recette du jour, fourni par le chef de projet (1 pour la première passe).
  - compte 1 : nom affiché « Recette Un », e-mail `recette-1-<N>@test.invalid`
  - compte 2 : nom affiché « Recette Deux », e-mail `recette-2-<N>@test.invalid`
  - compte 3 : nom affiché « Recette Trois », e-mail `recette-3-<N>@test.invalid` (reste **non activé**)
  - mot de passe : au choix, 12 caractères, identique pour tous les comptes de recette.
- **Ordre impératif** : les étapes dépendent les unes des autres (activations, charges). Ne sautez pas d'étape.
- Pour chaque étape : verdict **OK** ou **KO**, texte observé, n° de capture. Un KO n'arrête pas la recette ; signalez-le et continuez.

## 1. Table de couverture

| CA | Étape(s) | CA | Étape(s) |
|---|---|---|---|
| CA-002-5 | 1, 6 | CA-002-19 | 11 |
| CA-002-6 | 2 | CA-002-21 | 6, 12 |
| CA-002-7 | 3 | CA-002-22 | 12 |
| CA-002-8 | 5 | CA-002-23 | 13 |
| CA-002-10 | 4 | CA-002-24 | 6 |
| CA-002-12 | 6 | CA-002-25 | 15 |
| CA-002-13 | 8 | CA-002-27 | 16 |
| CA-002-14 | 9 | CA-002-28 | 16 |
| CA-002-15 | 10 | CA-002-29 | 16 |
| CA-002-17 | 14 | CA-002-30 | 16 |
| CA-002-18 | 11 | CA-002-32 | 16 |
| CA-002-34 (Could) | 18.1 | CA-002-35 (Could) | 18.2 |

## 2. Pas à pas

### Étape 1 — Connexion de l'administrateur (CA-002-5)
1. Depuis la page d'accueil, Tab jusqu'au champ e-mail, saisissez l'e-mail administrateur fourni.
2. Tab, saisissez le mot de passe fourni, puis Entrée.
3. **Attendu** : arrivée sur le tableau de bord d'équipe ; une entrée de menu « Administration » est présente.
4. **[capture]** tableau de bord administrateur avec le menu visible.
5. Ouvrez le menu de déconnexion (souris ou Tab + Entrée) et déconnectez-vous.

### Étape 2 — Inscriptions (CA-002-6)
1. Sur l'écran de connexion, Tab jusqu'au lien « Créer un compte », puis Entrée.
2. **Attendu** : un formulaire avec nom affiché, e-mail et mot de passe.
3. Saisissez compte 1 (« Recette Un », `recette-1-<N>@test.invalid`, mot de passe choisi), validez (Entrée).
4. **Attendu** : un message indique que le compte est **en attente d'activation par l'administrateur**. Aucun e-mail de confirmation n'est demandé.
5. **[capture]** message d'attente.
6. Recommencez pour compte 2 (« Recette Deux », `recette-2-<N>@test.invalid`) puis pour compte 3 (« Recette Trois », `recette-3-<N>@test.invalid`). Capture pour chacun.
7. Revenez à l'écran de connexion (lien « Se connecter » ou Échap).

### Étape 3 — Inscriptions refusées (CA-002-7)
1. Créer un compte avec `recette-1-<N>@test.invalid` (e-mail déjà utilisé), mot de passe valide.
2. **Attendu** : message d'erreur lisible ; aucun compte créé.
3. **[capture]**.
4. Créer un compte avec `recette-4-<N>@test.invalid` et un mot de passe de **7 caractères**.
5. **Attendu** : message d'erreur lisible (mot de passe trop court) ; aucun compte créé.
6. **[capture]**. (La vérification « aucun compte créé » se fait à l'étape 5 : `recette-4` ne doit pas apparaître.)

### Étape 4 — Compte non activé (CA-002-10)
1. Connectez-vous avec compte 1 (`recette-1-<N>@test.invalid`).
2. **Attendu** : seul un écran « Compte en attente d'activation » et un bouton de déconnexion. Aucune tâche, aucun nom de collègue.
3. **[capture]**.
4. Déconnectez-vous.

### Étape 5 — Activation par l'administrateur (CA-002-8)
1. Connectez-vous en administrateur. Ouvrez « Administration ».
2. **Attendu** : la liste « Comptes en attente » contient compte 1, compte 2 et compte 3 avec nom, e-mail et date d'inscription.
   `recette-4` n'y figure **pas**.
3. **[capture]** liste d'attente avant activation.
4. Cliquez « Activer » sur **compte 1** uniquement.
5. **Attendu** : compte 1 disparaît de « Comptes en attente » et apparaît dans « Comptes actifs ».
6. Cliquez « Activer » sur **compte 2** uniquement. Même attendu.
7. **Attendu** : compte 3 reste en « Comptes en attente ».
8. **[capture]** listes après activation.
9. Déconnectez-vous.

### Étape 6 — Accès après activation (CA-002-12, CA-002-21, CA-002-24, CA-002-5 côté membre)
1. Connectez-vous avec compte 1.
2. **Attendu** : arrivée sur le tableau de bord d'équipe.
   - une carte par membre activé : « Recette Un » et « Recette Deux » ;
   - « Recette Trois » (non activé) et « Recette Quatre » (non inscrit) sont **absents** (CA-002-24) ;
   - chaque carte affiche un nom, les tâches non terminées et une charge projetée.
3. **Attendu** : aucune entrée « Administration » dans le menu (membre ordinaire).
4. **[capture]** tableau de bord de compte 1 ; **[capture]** menu.
5. Déconnectez-vous.

### Étape 7 — Accès de compte 2 après activation (CA-002-12, CA-002-24 côté membre)
1. Connectez-vous avec compte 2 (« Recette Deux »).
2. **Attendu** : arrivée sur le tableau de bord d'équipe (et non sur l'écran d'attente). « Recette Trois » reste absent.
3. **[capture]**. Déconnectez-vous.

### Étape 8 — Créer une tâche (CA-002-13)
1. Connectez-vous avec compte 1. Ouvrez « Mes tâches ».
2. Cliquez ou Tab jusqu'à « Nouvelle tâche ».
3. Saisissez le titre « Tâche 1 », laissez la description vide, estimation **2** (heures). Validez.
4. **Attendu** : « Tâche 1 » apparaît dans « Mes tâches », statut « À faire », affectée à « Recette Un ».
5. **[capture]**.

### Étape 9 — Création refusée (CA-002-14)
Pour chaque cas, notez le nombre de tâches avant et après. Le nombre ne doit pas changer.
1. Titre vide, estimation 2 → **Attendu** : message d'erreur, aucune création.
2. Titre « Tâche erreur », estimation vide → **Attendu** : message d'erreur, aucune création.
3. Titre « Tâche erreur », estimation **0** → **Attendu** : message d'erreur, aucune création.
4. Titre « Tâche erreur », estimation **-1** → **Attendu** : message d'erreur, aucune création.
5. **[capture]** après le dernier cas.

### Étape 10 — Modifier une tâche (CA-002-15)
1. Ouvrez « Tâche 1 ». Modifiez : titre « Tâche 1 modifiée », description « Test », estimation **3**, statut « En cours ». Enregistrez.
2. Rechargez la page (touche F5).
3. **Attendu** : les quatre modifications sont visibles après rechargement.
4. **[capture]**.

### Étape 11 — Temps passé (CA-002-18, CA-002-19)
1. Sur « Tâche 1 modifiée », « Ajouter du temps » (ou équivalent) : durée **1 h 0 min**, date par défaut (aujourd'hui). Validez.
2. **Attendu** : le total de temps logué passe à **1 h**.
3. Essayez une durée de **0** → **Attendu** : message d'erreur, rien n'est ajouté.
4. Essayez une durée **négative** → **Attendu** : message d'erreur, rien n'est ajouté.
5. Essayez une durée de **25 h** → **Attendu** : message d'erreur (plus de 24 h), rien n'est ajouté.
6. **[capture]** après le cas de 25 h, total toujours à 1 h.
7. Déconnectez-vous.

### Étape 12 — Jeu de référence de la charge (CA-002-21, CA-002-22)
Ce jeu est fait par **compte 2**, qui n'a encore aucune tâche : la charge doit donc venir uniquement de ce jeu.
1. Connectez-vous avec compte 2. Ouvrez « Mes tâches ».
2. Créez trois tâches :
   - « Tâche A », estimation **4** ;
   - « Tâche B », estimation **2** ;
   - « Tâche C », estimation **5**.
3. Sur « Tâche A », ajoutez **1 h** de temps. Sur « Tâche B », ajoutez **3 h** de temps.
4. Passez « Tâche C » au statut **Terminée**.
5. Ouvrez le tableau de bord.
6. **Attendu** : la carte de « Recette Deux » affiche une charge projetée de **3 h**.
   (Calcul attendu : A = 4 − 1 = 3 ; B = max(2 − 3, 0) = 0 ; C terminée = exclue ; total 3 h.)
7. **[capture]** carte de « Recette Deux ».

### Étape 13 — Indicateur « Surchargé » (CA-002-23)
1. Toujours avec compte 2, créez « Tâche D », estimation **5**.
2. **Attendu** : la charge affichée passe à **8 h** et l'indicateur **« Surchargé »** apparaît sur la carte.
3. **[capture]**.
4. Passez « Tâche D » au statut **Terminée**. Retournez au tableau de bord.
5. **Attendu** : la charge repasse à **3 h** et l'indicateur « Surchargé » **disparaît**.
6. **[capture]**.

### Étape 14 — Consulter les tâches d'un collègue (CA-002-17)
1. Toujours avec compte 2, sur le tableau de bord, cliquez sur le nom « Recette Un ».
2. **Attendu** : la liste des tâches de « Recette Un » s'affiche : titre, statut, estimation, temps logué.
3. **Attendu** : aucun bouton de modification ou de suppression (lecture seule).
4. **[capture]**.
5. Revenez au tableau de bord. Déconnectez-vous.

### Étape 15 — Réaffectation directe (CA-002-25)
1. Connectez-vous avec **compte 1**. Relevez la charge projetée de « Recette Un » sur le tableau de bord.
   **Attendu** : **2 h** (Tâche 1 modifiée : 3 − 1). **[capture]**. Déconnectez-vous.
2. Connectez-vous avec **compte 2**. Dans « Mes tâches », ouvrez « Tâche A » (affectée à compte 2, 3 h restantes).
3. Choisissez « Réaffecter » (ou équivalent), sélectionnez « Recette Un », validez.
4. **Attendu** : « Tâche A » disparaît de « Mes tâches » de compte 2.
5. Relevez la charge de « Recette Deux » : **attendu 0 h** (avant : 3 h). **[capture]**.
6. Déconnectez-vous. Connectez-vous avec **compte 1**.
7. **Attendu** : « Tâche A » apparaît dans « Mes tâches » de « Recette Un » ; la charge de « Recette Un » est **5 h** (avant : 2 h). **[capture]**.
8. Déconnectez-vous.

### Étape 16 — Entraide : propositions (CA-002-27, CA-002-28, CA-002-29, CA-002-30, CA-002-32)
Préalable — compte 2 crée deux tâches :
1. Connectez-vous avec **compte 2**. Dans « Mes tâches », créez « Tâche E », estimation **2**, puis « Tâche F », estimation **1**.
2. Relevez la charge de « Recette Deux » : **attendu 3 h** (E 2 + F 1). Déconnectez-vous.

Proposition P1 — « Proposer mon aide » (CA-002-27, CA-002-29) :
3. Connectez-vous avec **compte 1**. Sur le tableau de bord, cliquez « Recette Deux », puis sur **« Tâche E »** (non terminée, affectée à compte 2).
4. Cliquez « Proposer mon aide », confirmez.
5. **Attendu** : message de confirmation. **[capture]**. Déconnectez-vous.
6. Connectez-vous avec **compte 2**. Ouvrez « Propositions reçues ».
7. **Attendu** : une proposition de « Recette Un » sur « Tâche E » est visible, avec le nom du proposant et la tâche.
8. Cliquez « Accepter ».
9. **Attendu** : « Tâche E » n'est plus dans « Mes tâches » de compte 2 ; la charge de « Recette Deux » passe à **1 h** (F).
10. **[capture]**. Déconnectez-vous.

Proposition P2 — « Demander de l'aide » (CA-002-28, CA-002-32, CA-002-30) :
11. Toujours avec **compte 2**, sur « Tâche F » (non terminée), cliquez « Demander de l'aide », choisissez « Recette Un », validez.
12. **Attendu** : message de confirmation. Déconnectez-vous.
13. Connectez-vous avec **compte 1**. Sur le tableau de bord, **Attendu** : le compteur de propositions reçues en attente affiche **1**. **[capture]**.
14. Ouvrez « Propositions reçues ». **Attendu** : la proposition de « Recette Deux » sur « Tâche F » est visible.
15. Cliquez « Refuser ».
16. **Attendu** : la proposition disparaît des propositions en attente ; le compteur revient à **0**. **[capture]**.
17. Ouvrez « Mes propositions » (envoyées). **Attendu** : la proposition P1 est au statut **« Acceptée »** (si la vue existe ; sinon, notez-le).
18. Déconnectez-vous.

Vérification finale de P2 :
19. Connectez-vous avec **compte 2**. Ouvrez « Mes propositions ».
20. **Attendu** : la proposition P2 est au statut **« Refusée »**. « Tâche F » reste dans « Mes tâches » de compte 2 (affectation inchangée). **[capture]**.
21. Déconnectez-vous.

### Étape 17 — Vérification de la charge de « Recette Un » (CA-002-22, seuil)
1. Connectez-vous avec **compte 1**. Relevez la charge de « Recette Un ».
2. **Attendu** : **7 h** (5 + E 2). Aucun indicateur « Surchargé » : le seuil est **strictement supérieur à 7 h**.
3. **[capture]**. Déconnectez-vous.

### Étape 18 — Fonctions Could (conditionnelles)
À exécuter **seulement si** les stories US-15 et US-16 sont livrées dans cette itération. Sinon, notez « non applicable ».

**18.1 — Désactivation (CA-002-34)**
1. Connectez-vous en administrateur. Ouvrez « Administration », « Comptes actifs ».
2. Cliquez « Désactiver » sur **compte 2**, confirmez.
3. Déconnectez-vous. Connectez-vous avec compte 2.
4. **Attendu** : seul l'écran « Compte en attente d'activation » est affiché.
5. **[capture]**. Déconnectez-vous.
6. Connectez-vous en administrateur. Sur la ligne de l'administrateur lui-même, tentez « Désactiver ».
7. **Attendu** : l'action est impossible (bouton absent ou refus avec message). **[capture]**.

**18.2 — Tâches du jour (CA-002-35)**
1. Connectez-vous avec **compte 1**. Créez « Tâche G » avec une échéance **aujourd'hui**, « Tâche H » avec une échéance **hier**, « Tâche I » sans échéance (estimation 1 pour chacune).
2. Sur le tableau de bord, activez le filtre « Aujourd'hui ».
3. **Attendu** : « Tâche G » et « Tâche H » (en retard) sont visibles ; « Tâche I » est absente.
4. **[capture]**.
5. Déconnectez-vous.

### Étape 19 — Fin de recette
1. Rapportez le tableau : un verdict OK/KO par étape, les valeurs de charge relevées (étapes 12, 13, 15, 16, 17), et la liste des captures.

## 3. Valeurs attendues de charge (récapitulatif)

| Étape | Compte | Moment | Charge attendue |
|---|---|---|---|
| 12 | 2 | après jeu de référence | 3 h |
| 13 | 2 | Tâche D (5 h) ajoutée | 8 h, « Surchargé » |
| 13 | 2 | Tâche D terminée | 3 h, pas de « Surchargé » |
| 15 | 1 | avant réaffectation | 2 h |
| 15 | 2 | avant réaffectation | 3 h |
| 15 | 2 | après réaffectation de A | 0 h |
| 15 | 1 | après réaffectation de A | 5 h |
| 16 | 2 | avant P1 | 3 h |
| 16 | 2 | après P1 acceptée | 1 h |
| 17 | 1 | après P1 | 7 h, pas de « Surchargé » |

## 4. Couverture

Les 24 critères [C] de l'itération 002 sont tous couverts par la table du §1 :
CA-002-5, 6, 7, 8, 10, 12, 13, 14, 15, 17, 18, 19, 21, 22, 23, 24, 25, 27, 28, 29, 30, 32, 34 (Could), 35 (Could).
Hors recette ici, par construction : CA-002-1, 33, 36 ([R] et [T]) ; CA-002-2, 3, 4, 9, 11, 16, 20, 26, 31 ([T] ou [P]).
