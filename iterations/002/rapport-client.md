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

---

## Passe 3 (N = 3) — restitution intégrale (source : `iterations/002/journal/145953-client.md`)

_(brief privé fourni, non journalisé)_
# Compte rendu de recette client — Itération 002, passe 3 (pile DEV)

Adresse : valeur par défaut de `tools/client/client.sh` (je n'ai pas pu la lire à l'écran ; aucune adresse n'a été saisie). Recharge F5 faite au départ (capture **145959-893**, écran de connexion). Comptes : `recette-1-3`, `recette-2-3`, `recette-3-3` (`recette-4-3` non créé, étape 3 hors périmètre). Mots de passe non recopiés ici. Le mot de passe de recette fourni fait 14 caractères, alors que la procédure parle de 12 ; il a été accepté.

## 1. Verdict par critère demandé

| CA | Verdict | Motif principal | Captures |
|---|---|---|---|
| CA-002-27 (message P1) | **OK** (texte exact) — réserve sur la visibilité | Message exact ; non visible à l'écran juste après le clic | 150954-130 (après clic, pas de message), 151001-128 (message en haut de page) |
| CA-002-28 (message P2) | **OK** (texte exact) — même réserve | Idem | 151102-595 (après clic), 151108-594 (message) |
| CA-002-37 (barre fixe) | **PARTIEL / BLOQUÉ** | Barre fixe OK pendant le défilement et lien clavier OK ; 200 % impossible (zoom clavier sans effet) | 151126-027 (haut de page), 151244-817 (défilé), 151320-950 (lien de la barre), 151228-581 et 151235-450 (zoom sans effet) |
| CA-002-38 (recherche admin) | **OK** sur les points observés | Filtres, message « Aucun… », casse ignorée, réinitialisation | 151354-483, 151404-452, 151413-292, 151501-660, 151512-067, 151528-760, 151537-444 |
| CA-002-39 (confirmation désactivation) | **OK** — focus non vérifiable | Texte et boutons conformes ; le cadre de focus sur « Annuler » n'est pas visible | 151601-158, 151608-369, 151616-767 |

## 2. Verdict par étape

| Étape | Verdict | Texte / observation exact | Capture(s) |
|---|---|---|---|
| 2 (préalable : inscriptions) | OK | « Votre compte est créé. Il est en attente d'activation par l'administrateur. » (×3) | 150024-252, 150038-514, 150053-559 |
| 5 (CA-002-8) | OK | Avant : `recette-1-3`, `recette-2-3`, `recette-3-3` en attente. Après activation de 1 puis 2 : elles disparaissent des attentes ; `recette-3-3` reste | 150130-996, 150136-488, 150140-855 |
| 7 (CA-002-12) | OK / non vérifié | Compte 2 arrive sur le tableau de bord (pas sur l'écran d'attente). « Recette Trois » absent : **non vérifié** (recherche Ctrl+F non concluante) | 150159-318 |
| 8 (préalable) | OK | « Tâche 1 » : À faire, 2 h | 150259-492 |
| 9 (CA-002-14) | OK | Titre vide : « Le titre est obligatoire. » ; estimation vide, 0 et −1 : « L'estimation doit être un nombre d'heures supérieur à 0. » ; aucune création (1 tâche avant et après) | 150309-683, 150323-861, 150332-465, 150342-558, 150349-091 |
| 10 (CA-002-15) | OK après 2e essai (réserve) | Après F5 : titre « Tâche 1 modifiée », estimation 3 h, description « Test ». Statut « À faire » au 1er essai (voir §3). 2e essai : « Statut : En cours · Estimation : 3 h · Temps logué : 0 h · Reste : 3 h » | 150421-518, 150427-219, 150442-111, 150449-601, 150455-714 |
| 12 (CA-002-21, partiel) | OK (3 h) | Carte « Recette Deux » : « Charge projetée : 3 h » ; tâches listées A et B (C terminée exclue). Seuil 22 non testé ici | 150800-079 |
| 16 (CA-002-27/28/29/30/32) | OK avec écart de valeur | P1 : message exact, « Propositions reçues » montre « Tâche E · En attente » puis « Acceptée » ; Tâche E disparaît de « Mes tâches » du compte 2. P2 : message exact, compteur à 1 puis 0, « Refusée » côté compte 1 et compte 2, Tâche F reste affectée. **Écart :** charge attendue 3 h, observée 6 h (voir §3) | 151020-088, 151025-642, 151032-678, 151108-594, 151126-027, 151131-596, 151138-002, 151157-112, 151205-246, 150909-816 |
| 18.1 (CA-002-34 / 39) | OK | Bloc : « Désactiver le compte de Recette Deux ? Cette personne ne verra plus les données de l'équipe. » ; « Annuler » ferme sans changement ; confirmation : « Le compte de Recette Deux est désactivé. » ; compte 2 ensuite : écran « Compte en attente d'activation » seul ; admin : aucun « Désactiver » sur sa propre ligne | 151601-158, 151608-369, 151616-767, 151633-826, 151711-112 |
| 17 bis A (CA-002-37) | Bloqué à 200 % (voir §1) | Barre fixe confirmée sur tableau de bord (pas sur « Mes tâches », non testé) | 151244-817, 151320-950 |
| 17 bis B (CA-002-38) | OK | Voir §1 | voir §1 |

## 3. Écarts et constats

**Écarts de valeurs (étape 16).** La procédure attend 3 h pour « Recette Deux » après E et F. J'observe **6 h** (A 3 h restantes + E 2 h + F 1 h). Cause : la réaffectation de la Tâche A (étape 15) n'a pas été jouée, car elle n'était pas dans votre liste. Le même décalage affecte la valeur « 1 h » attendue après acceptation de P1 (4 h théoriques, non relevées). Le produit n'est pas en cause, la procédure est incohérente sans l'étape 15.

**Statut non enregistré au 1er essai (étape 10).** Le clic sur une option de la liste déroulante native « Statut » n'a rien changé : la valeur est restée « À faire » (150442-111). Au clavier (Tab puis lettre « E »), la valeur a bien été prise et persistée (150455-714). Ce n'est donc pas un JS obsolète après rechargement. Mais la souris ne permet pas de choisir une option dans cette liste, ce qui est gênant pour une recette souris seule.

**Message de confirmation hors écran (CA-002-27/28).** Après « Proposer mon aide » et « Valider », la vue ne montre pas le message ; il faut remonter en haut de page pour le voir.

**Message ambigu pour un compte désactivé.** L'écran « Compte en attente d'activation » est identique à celui d'un compte simplement non activé (151633-826).

**Homonymes.** Des comptes d'anciennes passes portent les mêmes noms : trois « Recette Trois » en attente (`recette-3-1`, `3-2`, `3-3`), trois « Recette Un » actifs (`recette-1-1`, `1-2`, `1-3`), et des cartes « Recette Un » à 10 h « Surchargé » sur le tableau de bord. Le choix du collègue dans « Demander de l'aide » est donc ambigu ; le destinataire réel était bien mon compte 1 (151126-027).

**Incident de manipulation.** Un clic a ouvert « Modifier » de Tâche A (page défilée). Je l'ai replié sans enregistrer : aucune donnée modifiée.

**Touche non reconnue.** `press Down` a répondu « Keyboard.press: Unknown key » et le message « navigateur du client indisponible : demander une mise en service ». Le navigateur répondait encore (capture 150436-481), mais le message est trompeur.

## 4. Ressenti d'usage

- **Clarté** : les formulaires sont simples ; les messages d'erreur de création sont clairs.
- **Lenteurs / navigation** : la liste d'attente administrateur compte une centaine de comptes de test ; pour atteindre la liste des comptes actifs, il faut filtrer la liste d'attente d'abord (plusieurs dizaines de défilements sinon). Le tableau de bord est très long : retrouver une carte demande de nombreux défilements, et Ctrl+F ne déplace pas la vue de façon exploitable.
- **Incompréhensions** : le focus « Annuler » n'est pas visible ; le message de compte désactivé peut induire en erreur ; les formulaires « Loguer du temps » et « Modifier » ont leur bouton hors écran sans défilement.

## 5. Non exécuté / hors périmètre

- Étapes 1, 3, 4, 6, 6 bis, 11, 13, 14, 15, 17, 18.2 : non jouées (hors liste demandée).
- Dans l'étape 16, les CA-002-29, 30 et 32 sont observés mais non demandés.
- Session administrateur laissée ouverte à la fin.
