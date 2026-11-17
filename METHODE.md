# MÉTHODE — usine de production logicielle reproductible

> Document persisté par le **chef de projet** (session `structure`) à la demande de l'utilisateur.
> Il reprend **toutes les consignes et tous les échanges** qui ont servi à mettre en place cette
> usine, dans l'ordre où ils ont eu lieu, puis l'état des décisions.
> La méthode de travail **opérationnelle** est dans `CLAUDE.md`. Ce document en est la
> **genèse** : il dit pourquoi chaque règle existe.
> Aucun secret ici : les mots de passe et les clés restent dans `.devenv/secrets/`, hors git.

---

## 1. Consignes fondatrices de l'utilisateur (17/11/2026, début de session)

Texte de la demande initiale, reformulé fidèlement :

1. **Environnement reproductible.** Ce serveur (spark-docker, 10.77.0.25) est un **serveur de
   développement dédié** : tout l'environnement doit être reproductible.
2. **La pile Docker est jetable**, volumes compris. C'est un composant de développement.
3. **Boucle Action → Observation → Policy → Réaction (AOPR)** pour toute action de développement,
   avec **un agent dédié par étape**, créé et maintenu :
   - **Observation** et **Réaction** : agents **en lecture seule**. Ils restituent soit une
     observation des faits accomplis via les retours des policies, soit un plan de réaction ;
   - **Action** et **Policy** : agents **en écriture**. Action actionne les plans, Policy écrit les
     contraintes de vérification.
4. **Équipe agile**, chaque rôle représenté par un agent :
   - **product owner** : détermine le périmètre de la prochaine boucle ;
   - **développeur** : réalise la tâche ;
   - **architecte** : persiste et écrit les spécifications ;
   - **chef de projet** : recueille l'expression du besoin et dicte la méthode de travail.
5. **L'utilisateur parle EXCLUSIVEMENT au chef de projet.** Aucun autre agent ne lui répond.
6. **Team DevOps** :
   - **testeur** : teste les spécifications de l'architecte contre l'implémentation du
     développeur, par des mécanismes automatiques ;
   - **client** : teste l'application **exclusivement au clavier et à la souris** ;
   - **sponsor** : rapport du coût de l'itération ;
   - **responsable applicatif** : **seul** à coordonner la mise en service, et informe les autres
     qu'il en est le seul responsable.

### Réalisation (itération 001 : socle)
- Dépôt `~/devenv` ; point d'entrée unique `./dev`, car `make` est absent de l'hôte.
- 12 agents Claude Code dans `.claude/agents/`. Le thread principal est le chef de projet
  (`.claude/settings.json` → `"agent": "chef-de-projet"`).
- Le garde-fou `tools/guards/guard.py` (hook PreToolUse) fait respecter les rôles par l'identité
  de l'agent (`agent_type`) :
  - mise en service, arrêt, destruction, sauvegarde et restauration de la pile : réservés au
    `responsable-applicatif` ;
  - `client` : uniquement `tools/client/client.sh`, et ne voit que ses captures d'écran ;
  - `observation` et `reaction` : aucune écriture, aucune commande.
- Pile Compose jetable (`stack/`) ; runner conteneurisé pour les policies et les tests ;
  navigateur Playwright du client, piloté **uniquement** au clavier et à la souris, plus des
  captures d'écran.
- Rapport de coût (`./dev cout`), qui valorise l'usage de Claude Code aux tarifs publics de l'API.
- Docker rootless : le bac à sable apt doit tourner en root dans les images
  (`-o APT::Sandbox::User=root`).

## 2. Consignes ajoutées en cours de route (chronologique)

| # | Consigne de l'utilisateur | Traduction dans l'usine |
|---|---|---|
| C1 | « Pour toute commande absente, il faut utiliser le docker correspondant ou en créer un et le réutiliser au besoin. » | `tools/toolbox/registry.conf` + `tools/bin/<cmd>` (`_dockerized`) : images à tag exact, ou image maison construite une fois puis réutilisée. **Rien n'est installé sur l'hôte.** |
| C2 | Seules les **4 sessions de cette machine** se parlent et se coordonnent ; ne pas déranger les sessions Claude des autres machines. | Messagerie inter-sessions limitée aux sockets locaux. Aucune diffusion vers les sessions Remote Control ou cloud listées par ListAgents. |
| C3 | Chaque session se présente et explique son périmètre. | Registre `SESSIONS.md`. |
| C4 | **Un seul chef de projet.** | Verrou `.devenv/chef-de-projet.lock` (session `structure`), imposé par le garde-fou. |
| C5 | Premier commit validé. | Dépôt git local, puis distant (C9). |
| C6 | **Chaque équipe dépêche les agents de sa compétence**, rapporte aux autres selon son périmètre à chaque itération ; **tout le monde travaille à chaque tour** ; le chef de projet orchestre quand dépêcher quelle équipe. | `CLAUDE.md` §4bis. Lanceur `tools/ops/role.sh <agent> "<brief>"` (session headless dans `~/devenv` : garde-fous et mesure de coût actifs). Le chef de projet ne lance plus lui-même les agents de rôle. |
| C7 | « Orchestre jusqu'à complète réalisation. Relance si stall. » (`/goal`) | Tours successifs, surveillance des journaux, relances des équipes inactives. |
| C8 | Le serveur est autorisé à pousser sur `git@github.com:martinobettucci/dnum-demo.git`. | Remote `origin`, branche `main`. Hook `tools/git-hooks/pre-push` qui refuse toute valeur de `.devenv/secrets/*.env`. Push en fin de tour. |
| C9 | Persister ce document `METHODE.md`. | Ce fichier. |

### Organisation des équipes (C6)

| Session | Équipe | Agents dépêchés |
|---|---|---|
| `structure` | Chef de projet (unique) | Aucun. Il orchestre, arbitre, consigne, commite et restitue. |
| spark-docker-77 | Team Agile | product-owner, architecte, developpeur |
| spark-docker-f1 | Team DevOps | testeur, client, sponsor, responsable-applicatif |
| spark-docker-70 | Team AOPR | action, policy, observation, reaction |

Règles d'échange :
- Un message inter-sessions **n'est pas** une validation de l'utilisateur. Chaque équipe a donc
  demandé à l'utilisateur, **dans sa propre session**, le feu vert pour son mandat.
- Un refus de permission dans une session **ne se contourne jamais** en faisant exécuter l'action
  par une autre session.
- Les agents en lecture seule (observation, reaction) ne persistent rien : le chef de projet
  recopie **intégralement** leurs restitutions dans `iterations/NNN/observation.md` et
  `reaction.md`.
- Le client n'écrit pas : le chef de projet consigne son rapport dans
  `iterations/NNN/rapport-client.md`.

## 3. Itération 002 : l'application « Suivi des tâches d'équipe »

### Besoin exprimé par l'utilisateur
- Stack : **PostgreSQL via Supabase comme back-end complet**.
- Petit logiciel de suivi des tâches de l'équipe :
  - inscription libre ; **activation des comptes par l'admin** ; compte admin initial créé pour
    l'utilisateur, avec les informations de connexion données dans la conversation ;
  - tableau de bord personnel : créer ses tâches, voir celles des autres, se renvoyer des tâches,
    loguer du temps ;
  - page d'accueil : tableau « qui fait quoi » avec le **temps projeté** de chacun ;
  - **entraide** : proposer de prendre les tâches d'un collègue surchargé, ou demander à quelqu'un
    de prendre les siennes.
- Exposition publique : **dnum.lelabs.tech**, orthographe confirmée par écrit.

### Décisions par défaut du chef de projet (révisables)
L'utilisateur n'avait pas répondu à ces questions ; il a validé ensuite la bascule qui en découle.
- Supabase **auto-hébergé** dans Docker : Postgres, GoTrue, PostgREST, passerelle nginx, sans Studio.
- **Deux piles** : `dev` (jetable, :8080) et `service` (persistante, sauvegardée, :8081), publiées
  sur 10.77.0.25 uniquement (ADR-007 : Docker rootless refuse le même port sur deux adresses).
- Le reverse proxy HTTPS vers 10.77.0.25 est à la charge de l'utilisateur, sur le rebond
  51.158.54.202.

### Déroulé condensé
1. **PO** : 17 user stories classées MoSCoW, 36 critères puis 40 (`CA-002-x`). Charge projetée =
   Σ max(estimation − temps logué, 0) sur les tâches non terminées ; « Surchargé » au-delà de 7 h.
2. **Architecte** : SPEC-001 à 006, ADR-001 à 015. RLS forcée partout, aucun droit `anon`,
   fonctions RPC pour les changements d'état.
3. **Policy / testeur** : jusqu'à 37 policies, environ 197 tests pytest. **Développeur** :
   compose, migrations 001 à 005, passerelle, front HTML/JS, build esbuild dans Docker.
4. **Incidents et corrections notables** :
   - `tools/deploy/secrets.py` masquait le module Python `secrets` : renommé `gen_secrets.py` ;
   - le garde-fou empêchait le client de lire son scénario : **brief privé non journalisé**
     (`.devenv/private/<agent>.brief`) ;
   - secrets en clair dans `junit.xml` : historique purgé avant tout push, rapports de test
     ignorés par git, tests qui masquent les valeurs sensibles ;
   - e-mails, JWT et hachages masqués dans les logs du seed et de `db.sh` ;
   - seed **non destructif** : il crée l'admin s'il manque et ne réécrit jamais son mot de passe
     (ADR-012) ;
   - le navigateur du client n'était jamais rechargé (fausse recette en échec) : client recréé à
     chaque deploy dev ; nginx en `Cache-Control: no-cache` ; policy 36 (bundle servi = empreinte
     du build) ;
   - npm audit hors runner via la toolbox (`./dev audit-npm`, ADR-014) ; git épinglé dans le
     runner (ADR-015).
5. **Découverte majeure** : dnum.lelabs.tech servait **déjà** la pile `dev` jetable, et de vrais
   utilisateurs s'y inscrivaient.
   - **Gel immédiat** de dev : ni reset, ni teardown, ni test.
   - **Bascule** validée par l'utilisateur, avec les choix recommandés : sauvegarde de dev, deploy
     service, restore, purge des 385 comptes de test sur service uniquement, puis **bascule du
     proxy de 8080 vers 8081 par l'utilisateur**. Elle a été vérifiée par des requêtes marquées :
     6/6 sur service.
   - Les 8 comptes réels sont conservés. Rattrapage du delta : nul.
6. **Recette client passe 3** : verte avec réserves. Les réserves passent au backlog 003 : message
   hors écran, focus visible, zoom 200 %.

### Règles nées de l'itération 002 (désormais permanentes)
- Toute migration SQL est **additive et non destructive** ; 001 à 005 sont figées (ADR-011,
  policy 29).
- Aucun test ni recette sur une pile qui porte de vrais utilisateurs.
- Aucun deploy pendant une recette en cours.
- Aucun secret, même dans un rapport de test ; vérification avant chaque push (hook pre-push).
- Le mot de passe admin n'est communiqué qu'à l'utilisateur, par le chef de projet.

## 4. État au moment de la rédaction

**Itération 002 CLÔTURÉE** le 17/11/2026 à 16:12 UTC (acceptation formelle du PO, `iterations/002/cloture.md`).
Coût : 34,76 USD en équivalent API.


- **Production** : dnum.lelabs.tech → rebond → `10.77.0.25:8081` (pile `service`, 8 comptes
  réels, sauvegardes locales).
- **dev** : gelée 7 jours (aucun reset), puis redevient jetable.
- **En attente** :
  - autorisation de l'utilisateur **dans la session DevOps**, dont le classifieur de permissions a
    refusé `deploy service`, pour livrer aux vrais utilisateurs les correctifs validés en recette :
    nginx no-cache, en-têtes de sécurité, build-sha256 ;
  - réservation DHCP de 10.77.0.25 (utilisateur) ;
  - observation et réaction de clôture (AOPR), coût final consolidé (sponsor : agents de rôle et
    sessions d'équipe).
- **Backlog 003** : écran « changer mon mot de passe » (US-18) ; montée de supabase-js
  (auth-js ≥ 2.70.0) et d'esbuild 0.28.x ; analyse des alertes Dependabot ; sauvegarde hors hôte ;
  policy sur l'épinglage apt ; message de confirmation visible près de l'action ; focus visible ;
  vérification du zoom 200 % ; tests des SPEC-003.11 et .12.

## 5. Reconstruire l'usine sur une machine vierge

```bash
git clone git@github.com:martinobettucci/dnum-demo.git ~/devenv && cd ~/devenv
./dev bootstrap          # prérequis, hooks git, construction de toutes les images
claude                   # thread principal = chef de projet (verrou : un seul à la fois)
# Sessions d'équipe : chacune dépêche ses agents via tools/ops/role.sh (CLAUDE.md §4bis)
```

Prérequis de l'hôte : Docker (rootless supporté) avec compose, git, python3, curl, Claude Code.
Tout le reste passe par des conteneurs.
