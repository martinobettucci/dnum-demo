#!/usr/bin/env bash
# Lance un agent de rôle en session Claude Code headless dans ~/devenv (garde-fous + mesure de coût actifs).
# Usage : tools/ops/role.sh <agent> "<brief>"     → journal dans iterations/NNN/journal/
set -euo pipefail
cd "$(dirname "$0")/../.."
agent="$1"; brief="$2"; it=$(cat iterations/CURRENT)
mkdir -p "iterations/$it/journal"; log="iterations/$it/journal/$(date +%H%M%S)-$agent.md"
tools="Read Glob Grep Write Edit"
grep -qE '^tools:.*\bBash\b' ".claude/agents/$agent.md" && tools="$tools Bash"
{ echo "# $agent — $(date -Iseconds)"; echo; echo "## Brief"; echo "$brief"; echo; echo "## Compte rendu"; } > "$log"
# Brief privé optionnel (identifiants de recette…) : .devenv/private/<agent>.brief (0600, hors git),
# ajouté au prompt mais JAMAIS écrit dans le journal ; consommé (supprimé) après usage.
priv=".devenv/private/$agent.brief"; full="$brief"
if [[ -f "$priv" ]]; then
  full="$brief

--- Brief privé (ne jamais recopier ces informations dans un compte rendu) ---
$(cat "$priv")"; rm -f "$priv"; echo "_(brief privé fourni, non journalisé)_" >> "$log"
fi
claude -p --agent "$agent" --permission-mode acceptEdits --allowedTools $tools -- "$full" >> "$log" 2>&1
echo "$log"
