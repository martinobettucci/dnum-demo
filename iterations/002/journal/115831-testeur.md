# testeur — 2026-11-17T11:58:31+00:00

## Brief
Itération 002, tour 1. Relis tests/ par rapport à specs/SPEC-006, puis lance ./dev test sur la pile actuelle pour établir l'état de référence. Des échecs sont attendus. Rapporte les écarts et les résultats.

## Compte rendu
Relecture de `tests/` contre SPEC-006 faite, et `./dev test` lancé sur la pile actuelle : 186 tests, 7 échecs, 5 passés, 1 sauté et 173 erreurs. Presque tout est bloqué par une seule cause : le fichier de secrets est absent.

**Bloquant d'environnement (responsable applicatif)**
- `/workspace/.devenv/secrets/dev.env` n'existe pas. `.devenv/` ne contient que `chef-de-projet.lock` et `deploy.log`.
- Cela produit 173 erreurs de setup (SPEC-002, 003, 004.3, 004.7, et la plupart de SPEC-001). Aucune conclusion fonctionnelle n'est possible sur SPEC-002 tant que ce n'est pas réglé.
- Je n'ai ni démarré, ni reconstruit, ni régénéré quoi que ce soit.

**Échecs réels à remonter**

| # | Test | Spec | Constat |
|---|---|---|---|
| F1 | accueil sur `10.77.0.25:8080` | SPEC-001.3/001.4 | Connexion refusée : `compose.yml` ne publie que `127.0.0.1:8080`, pas l'adresse LAN |
| F2–F4 | `/app.js`, `/config.js`, `/style.css` | SPEC-001.8 | 404 : `app/public/index.html` est un placeholder, le front n'est pas livré |
| F5 | `window.location.origin` dans le front | SPEC-001.8 | Conséquence de F2–F4 |
| F6 | en-tête CSP sur `/` | SPEC-001.9 | Absent (nginx 1.27.3 sans CSP, rien dans `stack/` ni `app/`) |
| F7 | droits 0600 / 0700 du secret | SPEC-003.1 | Conséquence du bloquant : fichier absent |

Ce qui passe : `/` répond 200 `text/html`, `.gitignore` contient `.devenv`, `APP_URL` par défaut joignable.

**Écarts de couverture (sans trou sur les lignes `[T]` de SPEC-006)**
- Tous les CA `[T]` de SPEC-006 §2 ont au moins une fonction de test. Ma vérification repose sur les marqueurs et les noms de fonctions, pas sur une revue ligne à ligne des assertions.
- Specs sans marqueur automatisable : SPEC-001.3 (publication des ports, à ajouter) et SPEC-003.9 (cité seulement dans un message de skip).
- Les autres specs non marquées sont `[P]`, `[R]` ou `[C]` selon SPEC-006 (dont toute la SPEC-005 : recette client).
- Question ouverte avec l'architecte : le runner doit-il pouvoir joindre `10.77.0.25` ? Le test le suppose, rien ne le confirme.

**Fichiers produits** (dans `iterations/002/tests/`) :
- `rapport.md` : matrice SPEC → test → résultat, écarts et suite proposée.
- `resultat.txt` et `junit.xml` : sorties brutes de `./dev test`.

Je n'ai modifié aucun test et aucune spec. Aucun secret n'apparaît dans le rapport.
