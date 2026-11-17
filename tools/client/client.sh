#!/usr/bin/env bash
# Seule interface du client : clavier et souris sur le navigateur de la pile.
set -euo pipefail
cd "$(dirname "$0")/../.."
if [[ "${1:-help}" == help ]]; then cat <<'H'
tools/client/client.sh screenshot             capture → chemin du PNG (à lire avec Read)
tools/client/client.sh move X Y               déplacer la souris
tools/client/client.sh click X Y [btn] [n]    cliquer (btn: left|right|middle, n: nb de clics)
tools/client/client.sh down|up [btn]          enfoncer / relâcher un bouton
tools/client/client.sh wheel DX DY            molette
tools/client/client.sh type "texte"           taper au clavier
tools/client/client.sh press Touche           ex. Enter, Tab, Escape, Control+A
tools/client/client.sh wait MS                attendre (max 10000)
H
exit 0; fi
it=$(cat iterations/CURRENT)
docker compose -f stack/compose.yml --profile client exec -T client python3 /driver/ctl.py "$it" "$@" \
  || { echo "navigateur du client indisponible : demander une mise en service au chef de projet"; exit 1; }
