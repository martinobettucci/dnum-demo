# developpeur — 2026-11-17T13:40:15+00:00

## Brief
Itération 002, mission du chef de projet. tools/deploy/seed.py affiche l'identifiant admin (l'e-mail) dans les logs de deploy et de restore. Masque-le (par exemple « admin : a***@d*** » : première lettre du local-part, puis étoiles, domaine masqué sauf sa première lettre ; pas d'e-mail complet nulle part) et vérifie qu'aucun autre script de tools/deploy/ (db.sh, gen_secrets.py, seed.py, et tout appel depuis ./dev en lecture seule) n'affiche d'e-mail, de mot de passe, de JWT ou de clé dans stdout, stderr ou les messages d'erreur (y compris en cas d'échec : corps de réponse HTTP, traces Python). Ne modifie pas ./dev : si une correction y est nécessaire, signale-la pour l'agent action de la Team AOPR. Conserve le comportement du seed (ADR-012 : création seulement si absent, aucune écriture sur un compte existant). Aucun deploy, aucune exécution du seed, aucun conteneur touché (la pile service est en service avec des comptes réels). Vérifie avec python3 -I -m py_compile, bash -n, puis ./dev build et ./dev policies, une commande par appel. Compte rendu court : fichiers modifiés, ce qui était affiché avant/après (sans valeurs), autres fuites éventuelles.

## Compte rendu
Compte rendu développeur, itération 002, masquage des identifiants dans `tools/deploy/`.

**Fichiers modifiés** (`app/` et `stack/` non touchés, `./dev` non modifié)
- `tools/deploy/seed.py`
- `tools/deploy/db.sh`

**Ce qui était affiché avant / après** (valeurs non reproduites)
- `seed.py`, deux messages de succès (création, compte existant inchangé) : l'e-mail complet. Après : `admin : a***@d***`. Une exception non gérée (URLError, JSONDecodeError…) pouvait aussi remonter son message ; après : seul le type s'affiche, sans détail.
- `db.sh`, stderr de psql / pg_dump / pg_restore non filtré. Postgres recopie les valeurs dans ses erreurs (DETAIL, CONTEXT de COPY, LINE de requête), donc e-mails et hachages pouvaient sortir (`promote-admin` et `restore` surtout). Après : tout stderr passe par `run_masque` qui masque e-mails, JWT et hachages bcrypt. Le code retour est conservé (testé : rc=4 remonté sous `set -euo pipefail`) et le stdout reste intact (dump binaire testé).
- Comportement du seed inchangé (ADR-012) : aucun appel PUT/PATCH/DELETE, POST seulement si le compte est absent.

**Autres sorties vérifiées, sans fuite trouvée**
- `gen_secrets.py` : n'affiche que le chemin et les noms de clés. Aucune modification.
- `./dev` : les appels `config --services` / `config --images` ne sortent aucune valeur. `deploy`, `backup`, `restore` et `seed()` n'affichent pas de valeur (la sortie de seed et de promote-admin est désormais filtrée).
- Aucune correction de `./dev` n'est nécessaire, donc rien à remonter à la Team AOPR.

**Tests et vérifications**
- `python3 -I -m py_compile tools/deploy/seed.py` : OK.
- `bash -n tools/deploy/db.sh` : OK.
- Tests hors conteneur : `masque()` donne `a***@d***` pour `admin@…` (adresse factice pour le test, non reproduite ici) ; `run_masque` masque e-mail, JWT, bcrypt, préserve stdout et le code retour.
- `./dev build` : OK. Les tags `devenv/app:dev`, `devenv/runner:dev` et `devenv/client:dev` ont été reconstruits. Aucun conteneur de la pile n'a été recréé ; le prochain `deploy` les utilisera.
- `./dev policies` : 31 respectées, 0 violée, 0 non applicable (lancé deux fois, dont après la dernière modification).
- Aucun deploy, aucun seed exécuté, aucun conteneur de la pile touché.

**Specs couvertes**
- Aucune `SPEC-xxx` ne traite explicitement du masquage dans specs/. Le travail répond à la mission du chef de projet, sans changer le comportement défini par SPEC-003.10, SPEC-003.12 et ADR-012.
- Vérifié contre SPEC-003.10 et SPEC-003.12 : policy `ADMIN-seed-sans-ecrasement` respectée.

**Points ouverts**
1. Adresse complète dans le dépôt : `tools/deploy/gen_secrets.py` (valeur par défaut de `ADMIN_EMAIL`), `specs/adr/ADR-003-secrets-et-seed.md`, et `iterations/002/journal/114213-architecte.md` (une occurrence). Ce n'est pas une sortie et ce n'est pas un secret selon la policy 05, mais la consigne « pas d'e-mail complet nulle part » est couverte par le seul masquage des sorties. Décision au chef de projet : caviarder le journal, ou accepter.
2. Non examiné : `./dev logs` (sorties GoTrue et PostgREST, hors `tools/deploy/`). Je n'ai pas lu les logs de la pile en service, ce qui relève de la règle « aucun conteneur touché ».
3. Non examiné : messages d'erreur de docker compose sur un `--env-file` mal formé (la ligne fautive pourrait être recopiée). Le fichier généré par gen_secrets est valide.
4. `run_masque` ne couvre que les formats connus (e-mail, JWT, bcrypt). Un mot de passe brut qui apparaîtrait dans une erreur ne serait pas masqué ; je n'ai pas observé ce cas.
