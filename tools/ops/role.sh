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
claude -p --agent "$agent" --permission-mode acceptEdits --allowedTools $tools -- "$brief" >> "$log" 2>&1
echo "$log"
