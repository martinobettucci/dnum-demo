# POLICY: ENV-images-epinglees
# REF: ENV (reproductibilité)
# QUAND: always
# Toute image de base doit avoir un tag exact (pas de :latest, pas d'image sans tag).
bad=$(grep -rhE '^\s*FROM\s+' /workspace --include=Dockerfile | grep -vE 'FROM\s+\S+:[0-9v][^ ]*' || true)
[ -z "$bad" ] && echo "toutes les images FROM sont épinglées" || { echo "images non épinglées : $bad"; exit 1; }
