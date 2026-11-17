# architecte — 2026-11-17T15:01:56+00:00

## Brief
Itération 002. Écris uniquement dans specs/. Le fichier /build-sha256.txt (deux lignes « <sha256>  app.js » et « <sha256>  vendor/supabase.js », servi en text/plain, no-cache, avec les 3 en-têtes de sécurité, produit par app/web/build.mjs dans dist/) est utilisé par la policy 36 FRONT-bundle-servi-egal-source (servi = image = build du source, par empreintes) mais aucune SPEC ne le décrit (seuls ADR-006 §2 et la policy 36). Ajoute-le dans SPEC-001.8 (ou une nouvelle exigence 001.x de SPEC-001), avec format exact, chemin, entêtes, marqueur de vérification ([P] policy 36, [T] éventuel, [R] curl après deploy), et ajoute à SPEC-001 l'exigence Cache-Control: no-cache sur /, /index.html, /app.js, /config.js, /style.css, /vendor/supabase.js, /build-sha256.txt avec les 3 en-têtes de sécurité répétés dans chaque location (policy 37 GW-cache-et-entetes). Mets à jour SPEC-006 §3 (policies 36 et 37) et README. Compte rendu d'une ligne.

## Compte rendu
Warning: no stdin data received in 3s, proceeding without it. If piping from a slow command, redirect stdin explicitly: < /dev/null to skip, or wait longer.
