# ADR-002 — Front : HTML + JavaScript natif (modules), supabase-js épinglé, construit dans Docker

Statut : accepté (itération 002) — couvre CA-002-2, CA-002-3 et l'ensemble des CA [C].

## Contexte
- Interface sobre, en français, utilisable **au clavier et à la souris** (le client recette par
  `tools/client/client.sh`, navigateur Chromium 1280×800, locale fr-FR).
- Aucun outil sur l'hôte ; `node` uniquement via image épinglée.
- Une dizaine d'écrans simples, rechargement de page suffisant (pas de temps réel).

## Décision
- **Pas de framework** : HTML sémantique + CSS unique + JavaScript natif en modules ES, routeur
  par fragment (`#/connexion`, `#/inscription`, `#/attente`, `#/tableau`, `#/mes-taches`,
  `#/collegue/<id>`, `#/propositions`, `#/admin`). Moins de dépendances = moins de surface et
  de maintenance ; suffisant pour le volume fonctionnel.
- **Dépendances npm (versions exactes, `package-lock.json` commité, `npm ci`)** :
  `@supabase/supabase-js@2.47.10` (seule dépendance d'exécution) et `esbuild@0.24.2`
  (dépendance de build, regroupe le JS en un fichier `app.js`).
- **Construction multi-étapes dans `app/Dockerfile`** :
  1. `node:22.12.0-alpine` : `npm ci` puis `esbuild` → `dist/` ;
  2. `nginx:1.27.3-alpine` : copie de `dist/` + configuration passerelle (ADR-001).
  Aucune étape n'utilise d'outil de l'hôte.
- **Configuration d'exécution** : l'URL Supabase est `window.location.origin` (même origine,
  jamais d'hôte ni de port en dur). La clé `anon` n'est **pas** dans l'image : nginx sert
  `/config.js` généré au démarrage à partir de la variable d'environnement `SUPABASE_ANON_KEY`
  (gabarit `/etc/nginx/templates/*.template` de l'image officielle, `envsubst`).
- **En-têtes** : `Content-Security-Policy: default-src 'self'; connect-src 'self'; img-src 'self' data:; style-src 'self'; script-src 'self'; frame-ancestors 'none'`
  — garantit techniquement que le navigateur n'appelle que la même origine (CA-002-3).
- **Sobriété / accessibilité** : police système, une couleur d'accent, pas d'animation, pas
  d'icône sans texte ; tout est un `<a>`, `<button>` ou contrôle de formulaire natif avec
  `<label>` ; focus visible ; aucune action au survol seul ni au glisser-déposer ; libellés
  français stables (SPEC-005).

## Conséquences
- Le développeur maintient `app/web/` (sources), `app/nginx/` (gabarit), `app/Dockerfile`.
- Montée de version de supabase-js = modification de `package.json` + `package-lock.json`,
  vérifiée par policy (versions exactes, pas de `^`/`~`).
- La clé anonyme est publique par nature mais reste hors git, car dérivée du secret JWT généré.
