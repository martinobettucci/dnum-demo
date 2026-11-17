# product-owner — 2026-11-17T11:40:28+00:00

## Brief
Itération 002. Lis iterations/002/besoin.md (besoin et décisions), CLAUDE.md et SESSIONS.md. Rédige iterations/002/perimetre.md selon ta définition de rôle. Contexte : l'utilisateur attend à la fin de cette boucle une application utilisable de bout en bout par une petite équipe (inscription, activation par l'admin, compte admin initial, tâches, temps, tableau de bord qui-fait-quoi avec charge projetée, propositions d'entraide). Priorise les stories (MoSCoW) pour que le cœur soit livré même si la boucle déborde. Les critères d'acceptation CA-002-x doivent être vérifiables au clavier et à la souris par un client, ou par test automatique. L'exposition HTTPS publique (dnum.lelabs.tech) est hors périmètre de réalisation pour cette boucle. Il faut seulement un port HTTP prêt à être proxifié.

## Compte rendu
J'ai rédigé `iterations/002/perimetre.md`. C'est le seul fichier que j'ai écrit.

**Objectif de la boucle :** livrer avec `./dev deploy` une application de suivi des tâches sur Supabase auto-hébergé, accessible par un seul port HTTP prêt à être proxifié. Une petite équipe doit pouvoir l'utiliser de bout en bout : inscription, activation par l'admin, tâches, temps, tableau de bord avec la charge de chacun, entraide.

**Priorités (17 stories, 36 critères d'acceptation, chacun marqué [C] pour le client au clavier/souris ou [T] pour un test automatique) :**

| Priorité | Stories | Ce qu'elles couvrent |
|---|---|---|
| **Must** | US-1 à US-9 | Pile déployable sur un port HTTP, joignable en 127.0.0.1 et en 10.77.0.25 ; compte admin initial au mot de passe généré et jamais commité ; inscription ; activation par l'admin ; aucun accès pour un compte non activé, ni par l'interface ni par l'API ; mes tâches ; tâches des autres ; temps passé ; tableau de bord « qui fait quoi » avec charge projetée et mention « Surchargé » |
| **Should** | US-10 à US-14 | Réaffectation directe ; « Proposer mon aide » et « Demander de l'aide » (proposition puis acceptation ou refus) ; listes des propositions reçues et envoyées ; données conservées lors d'un `./dev deploy` sans `reset` |
| **Could** | US-15 à US-17 | Désactivation d'un compte ; échéance et filtre « Aujourd'hui » ; pile `service` séparée avec sauvegarde et restauration |

**Choix que j'ai faits et que l'utilisateur peut revoir :**
- **Charge projetée :** c'est la somme, sur les tâches non terminées d'une personne, de l'estimation moins le temps déjà logué, jamais en dessous de 0 par tâche. Le critère CA-002-22 donne un jeu de référence dont le résultat attendu est 3 h.
- **Surcharge :** une personne est « Surchargée » au-delà de 7 h de charge. Ce seuil est fixe pour cette boucle.
- **Estimation :** elle est obligatoire à la création d'une tâche, en heures et supérieure à 0. Sans cela, la charge ne peut pas être calculée.
- **Pas d'e-mail :** l'inscription ne demande aucune confirmation par e-mail. Le compte attend simplement l'activation par l'admin.
- **Mot de passe admin :** il est stocké hors du suivi git. Le responsable applicatif le lit et vous le transmet.
- **Droits :** seule la personne affectée à une tâche peut loguer du temps dessus ou la réaffecter. Le créateur ou la personne affectée peut la modifier.

**Hors périmètre de cette boucle :** HTTPS public et reverse proxy pour dnum.lelabs.tech, e-mails et SMTP, SSO et double authentification, notifications en temps réel, exports, seuil de surcharge paramétrable, modification ou suppression des temps saisis et suppression de tâches, rôles autres qu'admin et membre. Les stories Could non réalisées passent à l'itération 003 sans bloquer la recette.

**À noter pour l'architecte et le responsable applicatif :**
- **Garder les données :** la pile `dev` est jetable, donc les données disparaissent à chaque `./dev reset`. Tant que la pile `service` (US-17) n'existe pas, il ne faut pas lancer de `reset` une fois l'équipe au travail.
- **Rôle non attribué :** le rôle de responsable applicatif n'est toujours pas confirmé pour la session spark-docker-f1 (point en attente dans `SESSIONS.md`). Rien ne peut être mis en service tant que ce n'est pas tranché.
