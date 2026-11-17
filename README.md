# devenv — serveur de développement reproductible

```bash
./dev bootstrap      # prérequis + construction de toutes les images (idempotent)
claude               # depuis ce dossier : le thread principal est le chef de projet
```

- `CLAUDE.md` — méthode de travail (boucle AOPR, équipe agile, DevOps).
- `.claude/agents/` — les 12 agents : chef-de-projet, product-owner, architecte, developpeur,
  action, policy, observation, reaction, testeur, client, sponsor, responsable-applicatif.
- `.claude/settings.json` — thread principal = chef de projet ; garde-fou `tools/guards/guard.py`.
- `stack/compose.yml` — pile jetable (app, runner de vérification, navigateur du client).
- `app/` code · `specs/` spécifications et ADR · `policies/checks/` contraintes · `tests/` tests auto.
- `iterations/NNN/` — besoin, périmètre, policies, tests, captures client, observation, réaction, coût.
- `tools/bin/` — commandes absentes de l'hôte, exécutées dans Docker (`tools/toolbox/registry.conf`).

Prérequis hôte : Docker (rootless supporté) avec compose, git, python3, Claude Code, curl.
