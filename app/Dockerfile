# Application : front construit dans Docker (ADR-002), servi par la passerelle nginx unique (ADR-001).
# Tags exacts (SPEC-001.2). Aucun outil de l'hôte : node et nginx viennent des images épinglées.

# Étape 1 — build du front : deux fichiers, dist/app.js et dist/vendor/supabase.js (ADR-006 §2).
FROM node:22.12.0-alpine AS build
WORKDIR /build
COPY web/package.json web/package-lock.json ./
RUN npm ci
COPY web/ ./
RUN npm run build

# Étape 2 — passerelle : relais /auth/v1 et /rest/v1, CSP, config.js généré au démarrage.
FROM nginx:1.27.3-alpine
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
# Contrôle de syntaxe de la passerelle à la construction (le build échoue si la configuration est invalide).
RUN nginx -t
COPY nginx/40-config-js.sh /docker-entrypoint.d/40-config-js.sh
RUN chmod 0755 /docker-entrypoint.d/40-config-js.sh
COPY --from=build /build/dist/ /usr/share/nginx/html/
