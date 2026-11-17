#!/usr/bin/env bash
# POLICY: GW-admin-bloque
# REF: SPEC-001.7 | SPEC-003.6 | ADR-001 | CA-002-3
# QUAND: deployed
# L'API d'administration GoTrue n'est pas joignable par la passerelle :
#  - GET et POST $APP_URL/auth/v1/admin/users → 403 (et GET /auth/v1/admin → 403) ;
#  - variantes de chemin (//, /./, ../, %61dmin, %2F) → jamais 2xx.
# Les requêtes portent la clé service_role (si .devenv/secrets/dev.env existe) : si GoTrue était
# atteint, il répondrait 200 ; un 403 de la passerelle est donc distinguable. Clé jamais affichée.
U="$APP_URL"
ENVF=/workspace/.devenv/secrets/dev.env
SRK=$( [ -f "$ENVF" ] && sed -n 's/^SERVICE_ROLE_KEY=//p' "$ENVF" | tr -d '"'"'"'' | head -1 )
H=()
[ -n "$SRK" ] && H=(-H "apikey: $SRK" -H "Authorization: Bearer $SRK")
code() { curl -s --path-as-is -o /dev/null -w '%{http_code}' --max-time 5 "${H[@]}" "$@"; }
bad=()
c=$(code "$U/auth/v1/admin/users");                               [ "$c" = 403 ] || bad+=("GET /auth/v1/admin/users→$c")
c=$(code -X POST -H 'Content-Type: application/json' -d '{}' "$U/auth/v1/admin/users"); [ "$c" = 403 ] || bad+=("POST /auth/v1/admin/users→$c")
c=$(code "$U/auth/v1/admin");                                     [ "$c" = 403 ] || bad+=("GET /auth/v1/admin→$c")
for p in "/auth/v1//admin/users" "/auth/v1/./admin/users" "/auth/v1/x/../admin/users" \
         "/auth/v1/%61dmin/users" "/auth/v1/admin%2Fusers" "/auth/v1/admin/users/" "/auth/v1/admin/users?x=1"; do
  c=$(code "$U$p"); [[ "$c" =~ ^2 ]] && bad+=("GET $p→$c")
done
cle=$([ -n "$SRK" ] && echo "avec clé service_role" || echo "SANS clé service_role (fichier de secrets absent)")
if [ ${#bad[@]} -eq 0 ]; then
  echo "/auth/v1/admin/* refusé par la passerelle (403, variantes de chemin jamais 2xx), $cle"
else
  echo "API admin GoTrue exposée ou mal bloquée ($cle) : ${bad[*]}"; exit 1
fi
