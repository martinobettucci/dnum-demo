#!/usr/bin/env bash
# POLICY: ENV-pas-de-secret
# REF: ENV | SPEC-003.3 | CA-002-2
# QUAND: always
# Aucun motif de secret dans les fichiers du dépôt (hors .git, .devenv, iterations, node_modules) :
# clés Anthropic, clés AWS, clés privées PEM, et JWT (eyJ….eyJ…, ex. ANON_KEY / SERVICE_ROLE_KEY).
hits=$(grep -rIlE '(sk-ant-[A-Za-z0-9_-]{10,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,})' /workspace \
  --exclude-dir=.git --exclude-dir=.devenv --exclude-dir=iterations --exclude-dir=node_modules || true)
[ -z "$hits" ] && echo "aucun motif de secret (dont JWT) dans le dépôt hors .git/.devenv/iterations/node_modules" \
  || { echo "secret probable dans : $(echo $hits | sed 's#/workspace/##g')"; exit 1; }
