# SPEC-005 — Interface web (recette client au clavier et à la souris)

Itération 002. Décision : ADR-002. Couvre les CA [C] : CA-002-5 à 8, 10, 12 à 15, 17 à 19,
21 à 25, 27 à 30, 32, 34, 35.
Vérification [C] : le `client` via `tools/client/client.sh` (Chromium 1280×800, fr-FR), captures
dans `iterations/002/client/`. Le client ne connaît que l'URL de départ et les identifiants admin
transmis par le chef de projet ; il crée lui-même ses comptes de recette par l'inscription.

**Tour 3 (retours de recette, 2026-11-17)** — quatre retours d'usage réel, traités ici (détail des messages en fin de spec) :
(1) confirmation après « Demander de l'aide » et texte « Proposition envoyée » nommant la tâche : SPEC-005.7, .33, .40 ;
(2) barre supérieure fixe : SPEC-005.6 ; (3) confirmation avant « Désactiver » : SPEC-005.63, .60 ;
(4) recherche dans les listes d'administration : SPEC-005.62, .60.
CA couverts : **CA-002-27 et CA-002-28** (précision des messages), **CA-002-34** (précision de la désactivation),
et **CA-002-37, 38, 39** (**proposés par l'architecte, à inscrire au périmètre par le product owner** : aucun CA
n'existe encore pour la barre, la recherche ni la confirmation de désactivation).
**Aucun retour du tour 3 ne demande de migration SQL** : tout est front (`app/web/src/app.js`, `app/web/style.css`),
les RPC existantes (`request_help`, `offer_help`, `admin_list_accounts`, `admin_set_active`) restent inchangées.
Déploiement : aucun effet tant que la pile `dev` est gelée (pas de `./dev deploy`).

## Règles générales (s'appliquent à tous les écrans)
| Id | Exigence | CA | Vérification |
|---|---|---|---|
| SPEC-005.1 | Interface entièrement en français ; libellés **exacts** : « Se connecter », « Créer un compte », « Se déconnecter », « Tableau de bord », « Mes tâches », « Propositions », « Propositions reçues », « Propositions envoyées », « Administration », « Activer », « Désactiver », « Nouvelle tâche », « Enregistrer », « Loguer du temps », « Réaffecter », « Proposer mon aide », « Demander de l'aide », « Accepter », « Refuser », « Surchargé », « Aujourd'hui », « Compte en attente d'activation », « Confirmer la désactivation », « Annuler », « Rechercher dans les comptes en attente », « Rechercher dans les comptes actifs ». | tous [C] | [C] |
| SPEC-005.2 | Toute action est réalisable **à la souris** (clic sur un bouton/lien visible) **et au clavier** (Tab pour atteindre, Entrée/Espace pour déclencher, Entrée valide les formulaires) ; focus visible ; aucune action au survol seul, aucun glisser-déposer, aucune fenêtre modale bloquant la touche Échap. | tous [C] | [C] parcours d'une création de tâche au seul clavier |
| SPEC-005.3 | Sobriété : une colonne de contenu ≤ 1100 px, police système, une couleur d'accent, état « Surchargé » signalé par un **texte** (pas seulement une couleur) ; tout le contenu principal tient sans défilement horizontal en 1280×800. | CA-002-23 | [C] |
| SPEC-005.4 | Toute erreur de saisie ou refus de l'API s'affiche en français, en clair, à côté du formulaire concerné (zone `role="alert"`), sans perte de la saisie ; aucun message technique brut (code SQL, JSON). | CA-002-7, 14, 19 | [C] |
| SPEC-005.5 | Les données affichées sont rechargées à chaque navigation et après chaque action ; un rechargement de page (F5) conserve la session et l'écran courant. | CA-002-15, 25, 29 | [C] |
| SPEC-005.6 | **Barre supérieure fixe (tour 3).** La barre `.entete` (titre « Suivi des tâches » et menu) reste visible en haut de la fenêtre pendant tout défilement vertical : `position: sticky; top: 0` (ou `fixed` avec marge compensée, au choix du `developpeur`, mais le rendu est seul vérifié). Hauteur ≤ 120 px en 1280×800. Le contenu défilant ne passe jamais sous la barre : `scroll-padding-top` de `html` égal à la hauteur de la barre, pour qu'un élément reçu par Tab reste visible. Le lien d'évitement « Aller au contenu » reste au-dessus de la barre (`z-index` supérieur) quand il a le focus. | CA-002-37 (proposé) | [C] : défilement molette et clavier sur « Mes tâches » avec ≥ 20 tâches : barre visible sur chaque capture ; [P] `FRONT-barre-fixe` (policy n° 31, `style.css` : `.entete` en `sticky` ou `fixed` avec `top: 0`, `scroll-padding-top` présent) |
| SPEC-005.7 | **Confirmation des actions d'entraide et d'administration (tour 3).** Une action réussie affiche un message de confirmation de la forme exacte donnée en section « Messages » (zone `role="status"`, en tête de la section). Le message ne peut pas être perdu par le rechargement de données qui suit l'action (SPEC-005.5) : il est transmis à l'écran suivant par un état mémoire de l'application (ni URL, ni stockage persistant), affiché une seule fois, et effacé à la navigation suivante. Il contient le nom de la tâche et/ou du compte concerné. Le texte est inséré en `textContent` (aucun HTML). Une erreur reste un message `role="alert"` (SPEC-005.4). | CA-002-27, CA-002-28, CA-002-34 (précisés), CA-002-39 (proposé) | [C] : après « Demander de l'aide », « Proposer mon aide » et « Désactiver » confirmé, le message exact est lu sur la capture et l'écran suivant le rappelle au même endroit ; [P] `FRONT-messages-tour3` (policy n° 30 : textes exacts présents dans `app.js`, ancien texte « Proposition envoyée. » absent) |

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
| SPEC-005.33 | **Réaffecter** / **Demander de l'aide** : liste déroulante des seuls membres actifs (hors soi), bouton de validation ; après réaffectation la tâche quitte « Mes tâches » et apparaît chez le collègue. **Tour 3 :** après « Demander de l'aide » validé, le message exact « Demande d'aide envoyée à {nom} pour la tâche « {titre} ». » s'affiche (SPEC-005.7) ; `{nom}` est le libellé du collègue choisi dans la liste. Une erreur reste affichée à côté du formulaire. | CA-002-25, CA-002-28 (précisé) | [C] |
| SPEC-005.40 | **Tâches d'un collègue** (`#/collegue/<id>`) : titre, statut, estimation, temps logué, en lecture seule (aucun bouton de modification) ; sur chaque tâche non terminée, bouton « Proposer mon aide » ; **tour 3 :** confirmation exacte « Proposition envoyée à {nom} pour la tâche « {titre} ». » (SPEC-005.7), `{nom}` = nom du collègue affiché sur la page. Remplace « Proposition envoyée. » (retour de recette : aucun nom de tâche). | CA-002-17, CA-002-27 (précisé) | [C] |
| SPEC-005.50 | **Propositions** : section « Propositions reçues » (proposant, type « Propose son aide » / « Vous demande de l'aide », tâche, boutons « Accepter » / « Refuser » si en attente) et section « Propositions envoyées » (destinataire, tâche, statut « En attente » / « Acceptée » / « Refusée » / « Expirée »). | CA-002-27 à 30 | [C] |
| SPEC-005.51 | Après « Accepter », la tâche est chez le preneur et les charges du tableau de bord sont à jour ; après « Refuser », l'affectation est inchangée ; l'émetteur voit le nouveau statut. Proposition devenue impossible ⇒ « Cette proposition n'est plus valable. » | CA-002-29, CA-002-30, CA-002-31 | [C] |
| SPEC-005.60 | **Administration** (admin) : « Comptes en attente » (nom, e-mail, date d'inscription, bouton « Activer ») et « Comptes actifs » (nom, e-mail, rôle, bouton « Désactiver » — Could — absent sur la ligne de l'admin). Après « Activer », la ligne passe dans « Comptes actifs ». **Tour 3 :** « Désactiver » n'agit qu'après confirmation (SPEC-005.63) ; chacune des deux listes a son champ de recherche (SPEC-005.62), placé au-dessus de sa liste. Un message de confirmation exact « Le compte de {nom} est désactivé. » s'affiche après désactivation (SPEC-005.7). | CA-002-8, CA-002-34 (précisé), CA-002-38 (proposé) | [C] |
| SPEC-005.62 | **Recherche dans les listes d'administration (tour 3).** Deux champs, un par liste, libellés exactement « Rechercher dans les comptes en attente » et « Rechercher dans les comptes actifs » (`type="search"`, libellé visible, pas de bouton, hors de tout formulaire : Entrée ne soumet rien). **Périmètre** : chaque champ ne filtre que sa liste ; aucune recherche entre les deux listes. **Mode** : filtrage **côté client** sur les données déjà chargées par `admin_list_accounts()` (aucun appel RPC supplémentaire, aucune migration). **Règle** : le terme est découpé en mots (espaces) ; un compte correspond si chaque mot figure, sans tenir compte de la casse ni des accents, dans le nom affiché **ou** l'e-mail ; un terme vide ou composé d'espaces ne filtre rien. Le filtrage est immédiat (à chaque saisie). Aucun résultat : « Aucun compte en attente ne correspond à « {terme} ». » ou « Aucun compte actif ne correspond à « {terme} ». ». Le terme saisi est conservé quand une action (activation, désactivation) recharge la page. Limite connue : au-delà de 1000 comptes, `PGRST_DB_MAX_ROWS` (SPEC-001.12) tronque la liste ; hors périmètre de cette itération (équipe de quelques personnes). | CA-002-38 (proposé) | [C] : saisie « ecole » retrouve « École » ; « recette un » ne retrouve que « Recette Un » ; terme sans correspondance ⇒ message exact ; [P] `FRONT-messages-tour3` (présence du champ et des libellés) |
| SPEC-005.63 | **Confirmation avant désactivation (tour 3, précise CA-002-34).** Clic sur « Désactiver » : la ligne ouvre, sous le bouton, un bloc `role="group"` contenant le texte « Désactiver le compte de {nom} ? Cette personne ne verra plus les données de l'équipe. » et les boutons « Confirmer la désactivation » et « Annuler ». Aucune fenêtre modale native (`window.confirm`) ni modale bloquante. Le focus passe sur « Annuler » (choix sûr par défaut). « Annuler » ferme le bloc sans appel RPC ; « Confirmer la désactivation » appelle `admin_set_active(…, false)` puis affiche le message de SPEC-005.7. Clavier : Tab et Entrée suffisent ; Échap ferme le bloc (non obligatoire, mais recommandé). Le bouton « Désactiver » n'est pas présent sur la ligne de l'administrateur (SPEC-005.60). | CA-002-34 (précisé), CA-002-39 (proposé) | [C] : clic « Désactiver », puis « Annuler » ⇒ compte actif inchangé ; clic « Désactiver », puis « Confirmer » ⇒ compte en attente et message exact ; [P] `FRONT-messages-tour3` (absence de `confirm(`) |

| SPEC-005.61 | `#/admin` saisi à la main par un membre non admin ⇒ redirection vers le tableau de bord, aucune donnée d'administration affichée. | CA-002-5, CA-002-9 | [C] |

## Messages exacts (tour 3)
Insérés en `textContent`. `{nom}` = nom affiché du compte ; `{titre}` = titre de la tâche ; `{terme}` = texte saisi dans la recherche.
Toute autre formulation est une non-conformité, même si le sens est identique.

| Id | Déclencheur | Texte exact | Rôle HTML |
|---|---|---|---|
| M-1 | « Proposer mon aide » réussi (SPEC-005.40) | Proposition envoyée à {nom} pour la tâche « {titre} ». | `role="status"` |
| M-2 | « Demander de l'aide » réussi (SPEC-005.33) | Demande d'aide envoyée à {nom} pour la tâche « {titre} ». | `role="status"` |
| M-3 | Bloc de confirmation de désactivation (SPEC-005.63) | Désactiver le compte de {nom} ? Cette personne ne verra plus les données de l'équipe. | texte du `role="group"` |
| M-4 | Désactivation confirmée (SPEC-005.60, .63) | Le compte de {nom} est désactivé. | `role="status"` |
| M-5 | Recherche sans résultat, « Comptes en attente » (SPEC-005.62) | Aucun compte en attente ne correspond à « {terme} ». | `role="status"` |
| M-6 | Recherche sans résultat, « Comptes actifs » (SPEC-005.62) | Aucun compte actif ne correspond à « {terme} ». | `role="status"` |

Libellés de boutons du bloc de confirmation : « Confirmer la désactivation » et « Annuler ».
L'ancien texte « Proposition envoyée. » (sans tâche) est retiré.

## Points ouverts (tour 3, pour le chef de projet)
1. **« Réaffecter »** n'a pas de message de confirmation, comme « Demander de l'aide » avant ce tour. Même défaut,
   non remonté par la recette. Proposition : message `Tâche « {titre} » réaffectée à {nom}.`, validé par le chef de projet
   avant le `developpeur`. Non spécifié ici.
2. **Autres actions sans confirmation** : « Loguer du temps » et « Modifier » ne confirment pas non plus leur succès (le
   total change à l'écran). Non spécifié ici.
3. **Périmètre des CA proposés** : CA-002-37 à 39 à inscrire au périmètre par le product owner, sinon SPEC-005.6, .7,
   .62, .63 restent sans CA de référence.
