# SPEC-005 — Interface web (recette client au clavier et à la souris)

Itération 002. Décision : ADR-002. Couvre les CA [C] : CA-002-5 à 8, 10, 12 à 15, 17 à 19,
21 à 25, 27 à 30, 32, 34, 35.
Vérification [C] : le `client` via `tools/client/client.sh` (Chromium 1280×800, fr-FR), captures
dans `iterations/002/client/`. Le client ne connaît que l'URL de départ et les identifiants admin
transmis par le chef de projet ; il crée lui-même ses comptes de recette par l'inscription.

## Règles générales (s'appliquent à tous les écrans)
| Id | Exigence | CA | Vérification |
|---|---|---|---|
| SPEC-005.1 | Interface entièrement en français ; libellés **exacts** : « Se connecter », « Créer un compte », « Se déconnecter », « Tableau de bord », « Mes tâches », « Propositions », « Propositions reçues », « Propositions envoyées », « Administration », « Activer », « Désactiver », « Nouvelle tâche », « Enregistrer », « Loguer du temps », « Réaffecter », « Proposer mon aide », « Demander de l'aide », « Accepter », « Refuser », « Surchargé », « Aujourd'hui », « Compte en attente d'activation ». | tous [C] | [C] |
| SPEC-005.2 | Toute action est réalisable **à la souris** (clic sur un bouton/lien visible) **et au clavier** (Tab pour atteindre, Entrée/Espace pour déclencher, Entrée valide les formulaires) ; focus visible ; aucune action au survol seul, aucun glisser-déposer, aucune fenêtre modale bloquant la touche Échap. | tous [C] | [C] parcours d'une création de tâche au seul clavier |
| SPEC-005.3 | Sobriété : une colonne de contenu ≤ 1100 px, police système, une couleur d'accent, état « Surchargé » signalé par un **texte** (pas seulement une couleur) ; tout le contenu principal tient sans défilement horizontal en 1280×800. | CA-002-23 | [C] |
| SPEC-005.4 | Toute erreur de saisie ou refus de l'API s'affiche en français, en clair, à côté du formulaire concerné (zone `role="alert"`), sans perte de la saisie ; aucun message technique brut (code SQL, JSON). | CA-002-7, 14, 19 | [C] |
| SPEC-005.5 | Les données affichées sont rechargées à chaque navigation et après chaque action ; un rechargement de page (F5) conserve la session et l'écran courant. | CA-002-15, 25, 29 | [C] |

## Écrans
| Id | Exigence | CA | Vérification |
|---|---|---|---|
| SPEC-005.10 | **Connexion** (`#/connexion`, écran par défaut sans session) : champs « E-mail », « Mot de passe », bouton « Se connecter », lien « Créer un compte ». Identifiants erronés ⇒ « E-mail ou mot de passe incorrect. » | CA-002-5, CA-002-6 | [C] |
| SPEC-005.11 | **Inscription** : champs « Nom affiché », « E-mail », « Mot de passe » ; succès ⇒ message « Votre compte est créé. Il est en attente d'activation par l'administrateur. » ; e-mail déjà utilisé ⇒ « Cet e-mail est déjà utilisé. » ; mot de passe < 8 ⇒ « Le mot de passe doit contenir au moins 8 caractères. » ; aucun compte créé dans ces deux cas. | CA-002-6, CA-002-7 | [C] ; [T] côté API (SPEC-001.11) |
| SPEC-005.12 | **Attente** : un compte non activé connecté ne voit que le titre « Compte en attente d'activation », un texte explicatif et « Se déconnecter » ; aucun menu, aucun nom de collègue, aucune tâche ; toute URL interne saisie le ramène à cet écran. | CA-002-10 | [C] ; [T] SPEC-002.3 |
| SPEC-005.13 | **Après activation**, à la connexion suivante, le même compte arrive sur le tableau de bord. | CA-002-12 | [C] |
| SPEC-005.14 | **Menu** (comptes actifs) : « Tableau de bord », « Mes tâches », « Propositions (n) », « Administration » (admin uniquement), nom de l'utilisateur, « Se déconnecter ». | CA-002-5, CA-002-32 | [C] connexion admin puis membre |
| SPEC-005.20 | **Tableau de bord** (écran d'arrivée après connexion) : une carte par membre actif — nom (lien vers ses tâches), charge projetée au format français (« 3 h », « 2,75 h »), mention « Surchargé » si > 7 h, liste des tâches non terminées (titre, statut). En tête : « Vous avez n proposition(s) reçue(s) en attente » (lien vers Propositions). Les comptes non activés n'y figurent pas. | CA-002-21, 22, 23, 24, 32 | [C] avec le jeu de référence CA-002-22 saisi par le client ⇒ « 3 h » |
| SPEC-005.21 | Filtre (Could) « Aujourd'hui » / « Toutes » : « Aujourd'hui » ne montre que les tâches non terminées dont l'échéance est aujourd'hui ou passée. | CA-002-35 | [C] |
| SPEC-005.30 | **Mes tâches** : bouton « Nouvelle tâche » ⇒ formulaire Titre (obligatoire), Description (facultative), Estimation en heures (obligatoire, > 0, décimales acceptées avec virgule ou point), Échéance (Could, facultative) ; après « Enregistrer », la tâche apparaît au statut « À faire ». Erreurs : « Le titre est obligatoire. », « L'estimation doit être un nombre d'heures supérieur à 0. » | CA-002-13, CA-002-14 | [C] |
| SPEC-005.31 | Chaque tâche de « Mes tâches » affiche titre, statut, estimation, temps logué, reste ; actions : « Modifier » (titre, description, estimation, statut parmi « À faire » / « En cours » / « Terminée »), « Loguer du temps », « Réaffecter », « Demander de l'aide ». | CA-002-15, 18, 25, 28 | [C] |
| SPEC-005.32 | **Loguer du temps** : champs Heures et Minutes, Date (par défaut aujourd'hui) ; total > 0 et ≤ 24 h ; sinon « La durée doit être comprise entre 1 minute et 24 heures. » ; après validation le temps logué de la tâche augmente d'autant. | CA-002-18, CA-002-19 | [C] |
| SPEC-005.33 | **Réaffecter** / **Demander de l'aide** : liste déroulante des seuls membres actifs (hors soi), bouton de validation ; après réaffectation la tâche quitte « Mes tâches » et apparaît chez le collègue. | CA-002-25, CA-002-28 | [C] |
| SPEC-005.40 | **Tâches d'un collègue** (`#/collegue/<id>`) : titre, statut, estimation, temps logué, en lecture seule (aucun bouton de modification) ; sur chaque tâche non terminée, bouton « Proposer mon aide » ; confirmation « Proposition envoyée. » | CA-002-17, CA-002-27 | [C] |
| SPEC-005.50 | **Propositions** : section « Propositions reçues » (proposant, type « Propose son aide » / « Vous demande de l'aide », tâche, boutons « Accepter » / « Refuser » si en attente) et section « Propositions envoyées » (destinataire, tâche, statut « En attente » / « Acceptée » / « Refusée » / « Expirée »). | CA-002-27 à 30 | [C] |
| SPEC-005.51 | Après « Accepter », la tâche est chez le preneur et les charges du tableau de bord sont à jour ; après « Refuser », l'affectation est inchangée ; l'émetteur voit le nouveau statut. Proposition devenue impossible ⇒ « Cette proposition n'est plus valable. » | CA-002-29, CA-002-30, CA-002-31 | [C] |
| SPEC-005.60 | **Administration** (admin) : « Comptes en attente » (nom, e-mail, date d'inscription, bouton « Activer ») et « Comptes actifs » (nom, e-mail, rôle, bouton « Désactiver » — Could — absent sur la ligne de l'admin). Après « Activer », la ligne passe dans « Comptes actifs ». | CA-002-8, CA-002-34 | [C] |
| SPEC-005.61 | `#/admin` saisi à la main par un membre non admin ⇒ redirection vers le tableau de bord, aucune donnée d'administration affichée. | CA-002-5, CA-002-9 | [C] |
