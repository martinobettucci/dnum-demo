# ADR-000 — Environnement de développement reproductible
**Contexte** : développement sur un serveur dédié, piloté par une équipe d'agents Claude Code.
**Décision** : tout est décrit dans ce dépôt ; pile Docker Compose (rootless) jetable, volumes compris ;
outillage (policies, tests, navigateur client) conteneurisé et épinglé ; point d'entrée `./dev`.
Rôles et garde-fous définis dans `CLAUDE.md`, `.claude/agents/`, `tools/guards/guard.py`.
**Conséquences** : aucun état ne survit à `./dev reset` ; tout ce qui compte est commité.
