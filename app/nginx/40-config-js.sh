#!/bin/sh
# Génère /config.js au démarrage de la passerelle (ADR-002, SPEC-001.10) à partir de SUPABASE_ANON_KEY.
# La clé anon n'est jamais dans l'image. Seule la clé anon est écrite (jamais service_role ni JWT_SECRET).
# Exécuté par l'entrypoint de l'image nginx (/docker-entrypoint.d/*.sh) avant le démarrage de nginx.
set -eu
cle="${SUPABASE_ANON_KEY:-}"
if ! printf '%s' "$cle" | grep -Eq '^eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$'; then
    echo "config.js : SUPABASE_ANON_KEY absente ou mal formée (fichier de secrets ?)" >&2
    exit 1
fi
printf 'window.DEVENV_CONFIG = Object.freeze({ anonKey: "%s" });\n' "$cle" > /usr/share/nginx/html/config.js
echo "config.js : généré (clé anon seule)"
