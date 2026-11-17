# Sessions Claude de la machine spark-docker (10.77.0.25)

Seules ces 4 sessions locales se parlent et se coordonnent. Aucune session d'une autre machine
(Remote Control, cloud) n'est contactée. Toute demande transite par le chef de projet.

| Session | Équipe | Périmètre déclaré (2026-11-17) | Écrit dans | S'interdit |
|---|---|---|---|---|
| **structure** (`cse_016Dpk6Lswn3hodPVUKtu2je`) | Chef de projet — **unique** | Seul interlocuteur de l'utilisateur ; méthode (`CLAUDE.md`), orchestration des agents de `~/devenv`, coordination des sessions | tout `~/devenv` via les agents de rôle | parler aux sessions d'autres machines |
| **spark-docker-f1** (socket 9717) | Team DevOps | Proposé, **non validé** : responsable applicatif (seul opérateur de la pile) puis testeur | rien pour l'instant | toucher la pile avant validation ; `CLAUDE.md`, `.claude/`, garde-fous ; installer sur l'hôte |
| **spark-docker-77** (socket 9977) | Team Agile | Liaison et coordination ; aucun rôle PO/architecte/développeur attribué | rien (messages uniquement) | pile ; `CLAUDE.md`, `.claude/`, garde-fous |
| **spark-docker-70** (socket 10461) | Team AOPR | Observation et réaction (lecture seule) ; comptes rendus et propositions de policies par message | rien (mémoire perso uniquement) | écrire dans `~/devenv`, lancer `./dev`, pile, rôle de chef de projet |

## Chef de projet unique
Verrou `.devenv/chef-de-projet.lock` (tenu par `structure`), imposé par `tools/guards/guard.py` :
toute autre session lancée dans `~/devenv` en tant que `chef-de-projet` est bloquée tant que la
session détentrice est vivante. Lancer une autre session avec un rôle : `claude --agent <role>`.

## Attribution des rôles (décision utilisateur, 2026-11-17)
Chaque équipe dépêche tous les agents de sa compétence (voir CLAUDE.md §4bis) :
Agile → product-owner, architecte, developpeur · DevOps → testeur, client, sponsor, responsable-applicatif ·
AOPR → action, policy, observation, reaction. Tout le monde travaille à chaque tour ; le chef de projet orchestre.
