# Itération 002 — rapport de recette client (passe 1)

> Restitution intégrale de l'agent client (dépêché par la Team DevOps), consignée par le chef de projet. Source : `iterations/002/journal/123712-client.md`.

_(brief privé fourni, non journalisé)_
# Rapport de recette client : itération 002, tour 2 (passe 1)

Recette menée au clavier et à la souris uniquement, du début à la fin de la procédure (étapes 1 à 19), avec `http://app` comme adresse d'entrée. Les captures sont dans `iterations/002/client/` sous le nom `capture-HHMMSS-mmm.png` (je n'ai pas d'outil d'écriture pour les renommer). Les identifiants administrateur et les mots de passe du brief privé n'apparaissent dans aucun élément de ce compte rendu.

## Verdicts par étape

| Étape | Verdict | Ce qui a été observé | Captures |
|---|---|---|---|
| 1 | **OK** | Connexion administrateur, entrée « Administration » présente, déconnexion effective. | 123736-658, 123741-226 |
| 2 | **OK** | Inscriptions des comptes 1, 2 et 3 : « Votre compte est créé. Il est en attente d'activation par l'administrateur. » Aucune demande de confirmation par e-mail. | 123801-536, 123816-212, 123830-207 |
| 3 | **OK** | E-mail déjà utilisé : « Cet e-mail est déjà utilisé. ». Mot de passe de 7 caractères : « Le mot de passe doit contenir au moins 8 caractères. ». Aucun compte créé (vérifié à l'étape 5). | 123848-601, 123907-988 |
| 4 | **OK** | Compte 1 non activé : seuls « Compte en attente d'activation » et « Se déconnecter » sont affichés. | 123921-395 |
| 5 | **OK** | Liste d'attente : Recette Un, Deux et Trois présents, Recette Quatre absent. Activation de Un puis de Deux, Trois reste en attente. | 124026-691, 124032-805, 124043-302, 124057-299 |
| 6 | **OK** | Tableau de bord du compte 1 : Recette Deux et Recette Un visibles, pas d'entrée « Administration ». Recette Trois et Quatre absents (voir réserve). | 124118-617 |
| 6 bis | **OK, réserve** | `#/admin` ne montre aucune donnée d'administration, retour au tableau de bord. La barre d'adresse n'étant pas visible, je ne peux pas confirmer l'URL réellement chargée. | 124130-952 |
| 7 | **OK** | Compte 2 arrive sur le tableau de bord, Recette Trois absent. | 124150-765 |
| 8 | **OK** | « Tâche 1 » : À faire, estimation 2 h, reste 2 h. | 124228-485 |
| 9 | **OK** | Quatre refus (titre vide : « Le titre est obligatoire. » ; estimation vide, 0 et -1 : « L'estimation doit être un nombre d'heures supérieur à 0. »). Toujours une seule tâche. | 124239-869, 124254-386, 124303-189, 124313-675, 124318-792 |
| 10 | **OK** | Après F5 : titre « Tâche 1 modifiée », En cours, 3 h, description « Test ». | 124403-670, 124409-343 |
| 11 | **OK** | 1 h ajoutée : 1 h logué. 0 h, -1 h et 25 h refusés (« La durée doit être comprise entre 1 minute et 24 heures. »). Total resté à 1 h. | 124426-609, 124437-554, 124448-319, 124504-726 |
| 12 | **OK** | Tâches A (4 h), B (2 h) et C (5 h, Terminée). Charge de Recette Deux : **3 h**. | 124540-802, 124605-414, 124621-695, 124640-116, 124811-617, 124705-077 |
| 13 | **OK, avec incident d'exécution** (voir ci-dessous) | Tâche D (5 h) : charge **8 h**, « Surchargé ». D Terminée : charge **3 h**, « Surchargé » disparu. | 124901-051, 124949-223 |
| 14 | **OK** | Tâches de Recette Un : titre, statut, estimation, temps logué. Lecture seule, aucun bouton de modification ni de suppression. | 124957-475 |
| 15 | **OK** | Recette Un : 2 h → 5 h. Recette Deux : 3 h → 0 h. Tâche A disparaît de compte 2 et apparaît chez compte 1. | 125054-616, 125122-799, 125128-730, 125143-995, 125156-659, 125230-092, 125236-707 |
| 16 | **KO partiel** | Tout l'enchaînement fonctionne, sauf le message de confirmation attendu après « Demander de l'aide » (16.12) : aucun message n'apparaît, le formulaire se referme seulement. L'effet est pourtant réel (proposition reçue à 16.14). Voir détail ci-dessous. | 125355-035 à 125824-283 |
| 17 | **OK** | Recette Un : **7 h**, pas de « Surchargé ». | 125854-025 |
| 18.1 | **OK** | Désactivation de compte 2 : seul l'écran d'attente s'affiche. Sur la ligne de l'administrateur, aucun bouton « Désactiver ». | 125936-707, 130005-936, 130036-704 |
| 18.2 | **OK** | Filtre « Aujourd'hui » : Tâche G (échéance aujourd'hui) et Tâche H (en retard) visibles, Tâche I (sans échéance) absente. | 130233-204, 130240-999, 130248-691 |

## Valeurs de charge relevées

| Étape | Compte | Moment | Attendu | Relevé | Capture |
|---|---|---|---|---|---|
| 12 | 2 (Recette Deux) | Après le jeu de référence | 3 h | **3 h** | 124705-077 |
| 13 | 2 | Tâche D (5 h) ajoutée | 8 h, « Surchargé » | **8 h, « Surchargé »** | 124901-051 |
| 13 | 2 | Tâche D terminée | 3 h, pas de « Surchargé » | **3 h, pas de « Surchargé »** | 124949-223 |
| 15 | 1 (Recette Un) | Avant réaffectation | 2 h | **2 h** | 125054-616 |
| 15 | 2 (Recette Deux) | Avant réaffectation | 3 h | **3 h** | 124949-223 |
| 15 | 2 | Après réaffectation de A | 0 h | **0 h** | 125156-659 |
| 15 | 1 | Après réaffectation de A | 5 h | **5 h** | 125230-092 |
| 16 | 2 | Avant P1 (E 2 h + F 1 h) | 3 h | **3 h** | 125355-035 |
| 16 | 2 | Après P1 acceptée | 1 h | **1 h** | 125541-350 |
| 17 | 1 | Après P1 | 7 h, pas de « Surchargé » | **7 h, pas de « Surchargé »** | 125854-025 |

Dans la récapitulation de l'étape 18.2, Recette Un passe à **10 h, « Surchargé »** (capture 130233-204) : c'est l'effet attendu de Tâches G, H et I (1 h chacune) ajoutées après l'étape 17. Ce n'est pas une anomalie.

## Détail de l'étape 16

- Préalable (E et F créées) : charge de Recette Deux à 3 h.
- P1 : « Proposer mon aide » sur Tâche E affiche « Proposition envoyée. ». Ce message ne précise pas de quelle tâche il s'agit, et aucune confirmation n'est demandée avant l'envoi. Le bouton reste affiché après l'envoi.
- Acceptation côté compte 2 : la proposition passe à « Acceptée », Tâche E quitte Mes tâches de compte 2.
- P2 : « Demander de l'aide » sur Tâche F, collègue Recette Un, « Valider ». **Aucun message de confirmation** n'est visible (16.12, attendu non tenu). Le formulaire se referme et la demande est bien reçue.
- Compte 1 : compteur « Propositions (1) » et bannière « Vous avez 1 proposition(s) reçue(s) en attente » (16.13 OK). Proposition « Recette Deux — Vous demande de l'aide, Tâche F, En attente ».
- Refus : statut « Refusée », compteur revenu à 0 (16.15–16.16 OK).
- 16.17 : la vue existe sous le nom « Propositions envoyées » (sur la même page que les reçues), avec P1 « Acceptée ». Pas de vue « Mes propositions » distincte.
- Compte 2 (16.19–16.20) : « Vous demandez de l'aide à Recette Un — Tâche F · Refusée », Tâche F toujours dans sa liste.

## Incidents d'exécution (de mon fait ou non établis)

1. **Tâche D, première saisie (12:47–12:48)** : la tâche n'apparaît ni sur le tableau de bord ni dans Mes tâches après l'enregistrement. La seconde saisie a réussi, une seule Tâche D existe maintenant. Je n'ai pas pu établir la cause : clic sur une zone mal placée (la page n'était pas remontée) ou défaut applicatif. À vérifier si besoin.
2. **Déconnexion ratée (12:50)** : le clic sur « Se déconnecter » n'a pas pris, j'étais encore connecté en compte 2. J'ai tapé l'e-mail et le mot de passe de recette sur le tableau de bord, sans champ de saisie, puis Entrée. Aucun effet visible, mais ces frappes ne sont pas parties dans un formulaire de connexion. Le mot de passe de recette a donc été saisi hors formulaire.
3. **Clics perdus** : plusieurs clics sur le menu n'ont pas été reçus (page non remontée). Un clic a seulement déplié « Demander de l'aide » sur Tâche B (12:47), sans rien soumettre.
4. **Ctrl+F et Ctrl+L** : sans effet visible (pas de barre de recherche ni d'adresse). L'étape 6 bis ne repose que sur le résultat à l'écran.

## Anomalies à traiter (non corrigées par moi)

- **Inscription hors périmètre de test** : vers 13:00, une inscription au nom d'une personne réelle, avec une adresse hors domaine `@test.invalid` (domaine gouv.fr), est apparue dans la file d'attente. Je ne l'ai ni créée ni activée. À examiner : données personnelles sur un serveur de développement, et instance accessible à des inconnus.
- **Pollution des listes** : la liste d'attente et « Comptes actifs » contiennent plusieurs centaines de comptes de tests antérieurs. Trouver les comptes de recette a demandé de longs défilements.
- Après désactivation, Recette Deux revient dans « Comptes en attente » (comportement probablement attendu, à confirmer).

## Ressenti d'usage

- **Clarté** : les messages d'erreur sont lisibles. En revanche, un même message couvre des cas distincts (estimation vide, 0 et -1 ; durée 0 et négative), et « Proposition envoyée. » ne nomme pas la tâche.
- **Confirmations manquantes** : « Demander de l'aide » ne confirme rien à l'écran. « Désactiver » agit immédiatement, sans boîte de confirmation (le scénario la prévoyait).
- **Navigation (point le plus gênant)** : la barre supérieure n'est pas fixe. Après un défilement, elle sort de l'écran, et la position de défilement persiste d'une page à l'autre. C'est la source de la plupart de mes clics ratés (déconnexion non faite, tâche D non créée, saisie dans le mauvais contexte).
- **Formulaires repliés** : « Nouvelle tâche », « Modifier », « Loguer du temps », « Réaffecter » et « Demander de l'aide » se déplient au-dessus ou au-dessous du contenu, ce qui décale les éléments et oblige à repérer à nouveau les boutons.
- **Lenteurs** : aucune attente perceptible sur les actions. Les listes administrateur sont en revanche très longues, sans recherche visible.
- **Clavier** : la saisie de date au clavier, la sélection de statut par frappe (« Ter ») et la navigation par Tab fonctionnent.
- **Au chargement** : aucune erreur visible, et aucun indicateur de connexion WebSocket à l'écran (je ne peux pas vérifier le réseau).

## Couverture des critères [C]

- **OK** : CA-002-5, 6, 7, 8, 10, 12, 13, 14, 15, 17, 18, 19, 21, 22, 23, 24, 25, 29, 30, 32, 34 (Could), 35 (Could).
- **OK, réserve** : CA-002-9 (6 bis, URL non vérifiable), CA-002-27 (proposition P1 créée, mais la vérification de la tâche est indirecte).
- **KO partiel** : CA-002-28, pour le message de confirmation attendu après « Demander de l'aide » (l'effet est correct).

Résultat global : 16 étapes sur 18 entièrement conformes, 1 KO partiel (étape 16, confirmation), 1 réserve de vérification (6 bis) et un incident d'exécution à traiter (étape 13). La recette n'a pas révélé de dysfonctionnement métier. Les points qui gênent l'usage sont la navigation qui décale les contrôles et l'absence de confirmations.
