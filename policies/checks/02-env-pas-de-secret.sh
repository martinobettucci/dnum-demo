# POLICY: ENV-pas-de-secret
# REF: ENV (sécurité)
# QUAND: always
hits=$(grep -rIlE '(sk-ant-[A-Za-z0-9_-]{10,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----)' /workspace \
  --exclude-dir=.git --exclude-dir=iterations || true)
[ -z "$hits" ] && echo "aucun secret détecté" || { echo "secret probable dans : $hits"; exit 1; }
