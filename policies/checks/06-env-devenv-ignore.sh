#!/usr/bin/env bash
# POLICY: ENV-devenv-ignore
# REF: SPEC-003.3 | ADR-003 | CA-002-2
# QUAND: always
# .gitignore (racine) ignore le répertoire .devenv/ (secrets, sauvegardes, journaux de déploiement).
if grep -qxE '\s*/?\.devenv/?\s*' /workspace/.gitignore 2>/dev/null; then
  echo ".gitignore ignore .devenv/"
else
  echo ".gitignore n'ignore pas .devenv/"; exit 1
fi
