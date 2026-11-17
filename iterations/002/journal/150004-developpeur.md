# developpeur — 2026-11-17T15:00:04+00:00

## Brief
Demande de la Team AOPR relayée par structure (incident de recette). La policy 36 FRONT-bundle-servi-egal-source attend un fichier dist/build-sha256.txt produit au build et servi en /build-sha256.txt. Format exact : deux lignes, « <sha256>  app.js » puis « <sha256>  vendor/supabase.js » (sha256 hexadécimal, deux espaces, chemin relatif à dist/), calculées sur dist/app.js et dist/vendor/supabase.js APRÈS leur écriture finale. Implémente : (1) app/web/build.mjs écrit dist/build-sha256.txt à la fin du build (module node:crypto, pas de dépendance nouvelle) ; (2) app/Dockerfile : le fichier doit arriver dans /usr/share/nginx/html/ avec le reste de dist/ (vérifie le COPY) ; (3) app/nginx/default.conf : /build-sha256.txt servi en text/plain avec Cache-Control: no-cache et les trois en-têtes de sécurité répétés (même piège add_header que pour les autres locations) ; vérifie aussi que le fichier n'est pas bloqué par une règle existante ; (4) si une policy ou une spec existante interdit un fichier supplémentaire servi (ex. liste fermée de fichiers du front, SPEC-001.8 « aucun autre fichier .js » ne concerne que .js), signale-le sans contourner ; (5) ./dev build puis ./dev policies, une commande par appel. Contrôle que build-sha256.txt dans dist/ correspond bien aux sha256 réels (sha256sum sur dist, via ce que le build te permet sans docker run direct) et dis ce que tu n'as pas pu vérifier. Pas de deploy, pas de conteneur touché. Compte rendu court.

## Compte rendu
Warning: no stdin data received in 3s, proceeding without it. If piping from a slow command, redirect stdin explicitly: < /dev/null to skip, or wait longer.
## Compte rendu développeur : `build-sha256.txt`

**Résultat :** le fichier est produit au build et son contenu est correct. La policy 36 reste **violée** tant que la pile n'est pas redéployée : c'est attendu, le conteneur en marche sert encore l'ancienne image. Je n'ai rien déployé ni touché de conteneur.

**Fichiers modifiés**
- `app/web/build.mjs` : calcule les sha256 de `dist/app.js` et `dist/vendor/supabase.js` avec `node:crypto` (aucune dépendance ajoutée), après toutes les écritures, et écrit `dist/build-sha256.txt` au format `<sha256>  <chemin>` avec fin de ligne LF.
- `app/nginx/default.conf` : nouvelle `location = /build-sha256.txt` avec `default_type text/plain`, `Cache-Control: no-cache` et les trois en-têtes de sécurité répétés. Aucune règle existante ne la capture (la regex `/auth/v1/admin` et la regex de fichiers non hachés ne correspondent pas).
- `app/Dockerfile` : **inchangé**. Le `COPY --from=build /build/dist/` existant embarque déjà le fichier.

**Specs et policies**
- Policy 36 (`FRONT-bundle-servi-egal-source`) : cible de ce travail, toujours violée jusqu'au redéploiement.
- SPEC-001.8 et SPEC-001.9 : pas de conflit. Aucune liste fermée n'interdit un `.txt` servi. SPEC-001.8 ne vise que les `.js`, et ADR-006 §2 n'interdit que les autres `.js`.
- Policy 37 (`GW-cache-et-entetes`) : respectée.
- **Point ouvert** : aucune SPEC ne décrit `build-sha256.txt` ; seuls ADR-006 §2 et la policy 36 le font. L'architecte pourrait l'ajouter dans SPEC-001.8.

**Vérifications**
- `./dev build` : OK, `RUN npm run build` réexécuté, `nginx -t` passé pendant la construction de l'image.
- Sha256 contrôlés sur l'étape `build` exportée (`docker build --target build --output type=local`, sans conteneur) :
  - `8aa9d77d…75ba  app.js`
  - `80a218af…7feb  vendor/supabase.js`
  - Ils correspondent à `build-sha256.txt` ; l'export temporaire a été supprimé.
- `./dev policies` : 32 respectées, 1 violée (policy 36, sortie : « /build-sha256.txt absent ou non servi (statut 200, text/html) »). Le résultat est dans `iterations/002/policies/results.json`.

**Non vérifié**
- Le comportement runtime de nginx sur la nouvelle location (en-têtes et `text/plain` réellement servis) : il faudra la policy 36 et la policy 37 après redéploiement.
- L'égalité entre les octets servis et les empreintes : elle dépend du redéploiement.

**Action attendue (responsable-applicatif)** : `./dev deploy` (pile `dev`, puis `service` si voulu), puis relancer `./dev policies`. Les images `app:dev` et `app:service` sont reconstruites par `./dev build`.
