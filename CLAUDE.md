# Méthode de travail — environnement de développement reproductible

> Document dicté et maintenu par le **chef de projet**. Toute session Claude Code
> lancée dans ce dépôt doit le respecter.

## 0. Règle d'or de la conversation

L'utilisateur parle **exclusivement** au **chef de projet** (thread principal,
agent `chef-de-projet`). Aucun autre agent ne répond à l'utilisateur. Les autres
agents rendent compte au chef de projet, qui restitue.

Il n'existe **qu'un seul chef de projet** sur la machine (session `structure`, verrou
`.devenv/chef-de-projet.lock` imposé par le garde-fou). Sessions locales et périmètres : `SESSIONS.md`.

## 1. Principes d'environnement

- Ce serveur est un **serveur de développement dédié**. Tout ce qui le
  configure vit dans ce dépôt git : `./dev bootstrap` doit reconstruire
  l'environnement à l'identique sur une machine vierge (Docker rootless + git + Claude Code).
- La **pile Docker est jetable**, volumes compris (`./dev reset` = `down -v`).
  Aucune donnée qui compte ne vit dans un conteneur ou un volume : seule la
  source de vérité est le dépôt (code, specs, policies, tests, comptes rendus).
- Images épinglées (tag exact), dépendances épinglées (`tools/runner/requirements.txt`).
- Point d'entrée unique : `./dev <commande>` (voir `./dev help`).
- **Commande absente de l'hôte ⇒ conteneur.** On n'installe rien sur le serveur.
  On utilise l'image Docker correspondante (tag exact) ou on en crée une
  (`tools/toolbox/<nom>/Dockerfile`, construite une fois puis réutilisée), déclarée dans
  `tools/toolbox/registry.conf`, puis `tools/bin/regen`. Appel : `tools/bin/<commande>`
  (ex. `tools/bin/make`, `tools/bin/jq`, `tools/bin/node`). Hôte : docker, git, python3, claude, curl.

## 2. Boucle Action → Observation → Policy → Réaction (AOPR)

Toute action de développement passe par ces quatre agents dédiés :

| Étape | Agent | Droits | Rôle |
|---|---|---|---|
| Policy | `policy` | écriture (`policies/` uniquement) | Écrit **avant** l'action les contraintes de vérification exécutables (`policies/checks/*.sh`). |
| Action | `action` | écriture | Exécute le plan validé (infra, outillage, build, scripts). Le code applicatif est écrit par le `developpeur`, qui agit sous la même boucle. |
| Observation | `observation` | **lecture seule** | Restitue les faits accomplis à partir des **retours des policies** (`iterations/NNN/policies/`) et des rapports. Aucun avis, aucun plan. |
| Réaction | `reaction` | **lecture seule** | Propose un plan de réaction à partir de l'observation. N'exécute rien. |

Séquence : `policy` (contraintes) → `action`/`developpeur` (exécution) →
`./dev policies` (exécution des contraintes, résultats JSON) → `observation` →
`reaction` → décision du chef de projet (nouvelle action, ou fin).
Les agents en lecture seule ne persistent rien : le chef de projet consigne
leurs restitutions dans `iterations/NNN/observation.md` et `reaction.md`.

## 3. Équipe agile

| Agent | Rôle | Livrable |
|---|---|---|
| `chef-de-projet` | Recueille l'expression du besoin, dicte la méthode, orchestre, restitue à l'utilisateur. | `iterations/NNN/besoin.md`, ce fichier |
| `product-owner` | Détermine le périmètre de la prochaine boucle et ses critères d'acceptation. | `iterations/NNN/perimetre.md` |
| `architecte` | Persiste et écrit les spécifications (testables) et décisions d'architecture. | `specs/`, `specs/adr/` |
| `developpeur` | Réalise la tâche dans `app/` (et `stack/` si nécessaire). | code |

### Équipe DevOps

| Agent | Rôle | Contrainte forte |
|---|---|---|
| `testeur` | Teste les specs de l'architecte contre l'implémentation, par mécanismes automatiques (`tests/`, `./dev test`). | N'écrit que dans `tests/`. |
| `client` | Recette l'application **exclusivement au clavier et à la souris** (`tools/client/client.sh`). | Ne voit que ses captures d'écran. Garde-fou technique. |
| `sponsor` | Rapporte le coût de l'itération (`./dev cout`). | N'écrit que `iterations/NNN/cout.md`. |
| `responsable-applicatif` | **Seul** en charge de la mise en service (`./dev deploy`, `./dev teardown`, `./dev reset`). Informe les autres de cette exclusivité. | Garde-fou technique : tout autre agent est bloqué. |

## 4. Déroulé d'une itération

1. `chef-de-projet` : `./dev iteration-new` puis rédige `besoin.md`.
2. `product-owner` → `perimetre.md`.
3. `architecte` → specs (`specs/*.md`, critères vérifiables, identifiants `SPEC-xxx`).
4. `policy` → contraintes ; `testeur` → tests automatiques dérivés des specs.
5. `developpeur` (et `action` pour l'outillage) réalise.
6. `responsable-applicatif` → mise en service (`./dev deploy`), annonce `mise-en-service.md`.
7. `./dev policies` + `testeur` (`./dev test`) + `client` (recette clavier/souris).
8. `observation` → faits ; `reaction` → plan.
9. `sponsor` → `cout.md`.
10. `chef-de-projet` → restitution à l'utilisateur ; `./dev iteration-close`.

## 5. Règles transverses

- Personne d'autre que le `responsable-applicatif` ne lance, n'arrête ou ne
  détruit la pile (`tools/guards/guard.py` le fait respecter).
- Les sous-agents ne parlent pas entre eux : tout passe par le chef de projet,
  via les fichiers de l'itération.
- Coordination inter-sessions : seules les sessions Claude locales de cette machine
  (spark-docker, 10.77.0.25) se parlent et se coordonnent. Ne jamais contacter les sessions
  des autres machines (Remote Control, cloud) visibles dans ListAgents.
- Langue de travail : français.
- Aucun secret dans le dépôt.
