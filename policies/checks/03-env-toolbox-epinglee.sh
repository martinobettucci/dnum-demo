# POLICY: ENV-toolbox-epinglee
# REF: ENV (reproductibilité — commandes absentes conteneurisées)
# QUAND: always
bad=$(grep -vE '^\s*(#|$)' /workspace/tools/toolbox/registry.conf | awk '$2 !~ /^build:/ && $2 !~ /:[0-9v][^ ]*$/ {print $1" → "$2}')
[ -z "$bad" ] && echo "toutes les images de la toolbox sont épinglées" || { echo "images non épinglées : $bad"; exit 1; }
