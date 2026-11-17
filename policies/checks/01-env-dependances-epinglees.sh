# POLICY: ENV-dependances-epinglees
# REF: ENV (reproductibilité)
# QUAND: always
bad=$(find /workspace -name 'requirements*.txt' -not -path '*/node_modules/*' -exec grep -HvE '^\s*(#|$)|==' {} + || true)
[ -z "$bad" ] && echo "dépendances Python épinglées (==)" || { echo "non épinglées : $bad"; exit 1; }
