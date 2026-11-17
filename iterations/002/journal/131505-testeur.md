# testeur — 2026-11-17T13:15:05+00:00

## Brief
Itération 002, tour 2, partie 6 (pile DEV gelée : N'EXÉCUTE PAS ./dev test ni aucun test). Incident : junit.xml contenait ADMIN_PASSWORD et JWT_SECRET en clair. Audite tests/ (conftest.py, test_*.py) : aucun test ne doit afficher de secret dans ses messages d'assertion, ses repr, ses paramètres de test, ses ids pytest ni ses sorties capturées (ADMIN_PASSWORD, JWT_SECRET, mots de passe de comptes, clés d'API, jetons). Corrige les tests concernés (masquage, comparaisons sans valeur en clair, ids explicites). Vérifie par lecture et par analyse AST seulement. Rapporte la liste des fichiers et des fonctions modifiés, sans recopier de secret.

## Compte rendu
## Audit des secrets dans `tests/` : corrigé, non exécuté

Pile DEV gelée respectée : aucun `./dev test` ni aucun test n'a été lancé. Vérification par lecture, analyse AST et contrôles statiques uniquement. Seul `tests/` a été modifié.

### Causes identifiées

Le fuite ne venait pas seulement des messages `assert X, msg`. Pytest réaffiche aussi les sous-expressions d'une assertion en échec :
- `secrets_env.get(...)` affiche le dictionnaire complet de secrets.
- `len('…')`, `jwt_payload(jeton)`, `signup(anon_key, …)` affichent leurs arguments.
- `assert secrets_env[k] not in txt` et `assert "…" in textes` affichent le texte entier, donc `config.js`, qui contient `ANON_KEY`.
- `assert r.json().get(...)` affiche le JSON entier, qui peut contenir un jeton.
- Les messages `r.text[:N]` pouvaient aussi transporter un corps de réponse.

### Correctifs

1. **Assertions** : les valeurs sensibles sont sorties du `assert` (booléens ou entiers calculés avant). Seuls des noms de variables, des motifs ou des compteurs apparaissent dans les messages.
2. **Corps de réponse** : tous les `r.text[:N]` passent par `extrait(r, N)`, qui masque les secrets, les JWT et les mots de passe de session.
3. **Filet de sécurité** : un hook `pytest_runtest_makereport` masque `longrepr` et les sections capturées pour les échecs. Il couvre le terminal, `resultat.txt` et `junit.xml`.
4. **`Api.__repr__`** : ne montre plus que l'identifiant du compte, jamais le jeton ni le mot de passe.
5. **Ids explicites** : `test_003` (`cle`, `cle,role`) et `test_001` (`methode,chemin`) en reçoivent. Les ids étaient déjà des noms de variables, mais ils sont maintenant explicites.

### Fichiers et fonctions modifiés

**`tests/conftest.py`**
- Ajoutés : `valeurs_secretes`, `masquer`, `extrait`, `pytest_runtest_makereport` (hook), `Api.__repr__`.
- Modifiés : `anon_key` et `admin` (plus d'assert sur `secrets_env.get`), `Api` (tous les messages `r.text`), `Fabrique`, `connecter`, `compte_admin`, `jeu`, `log`, `rows`, `status`, `create_task`, `set_status`, `activer`, `__call__`.

**`tests/test_001_pile.py`**
- `test_relais_auth_token_admin_renvoie_access_token` : jeton extrait dans une variable.
- `test_passerelle_refuse_api_admin_gotrue_403` : ids explicites.
- `test_config_js_expose_la_cle_anon_courante_et_aucune_autre` : booléen et compteur, plus de `txt` ni de JWT réaffichés.
- `test_cle_service_role_absente_des_fichiers_servis` : deux booléens séparés.
- `test_fichier_servi_sans_url_vers_autre_port` : liste des motifs trouvés, sans le contenu servi.
- `test_front_utilise_window_location_origin` : booléen, sans `textes`.
- `test_inscription_ouvre_une_session_immediate` : jeton extrait.
- `test_inscription_email_deja_utilise_refusee_sans_doublon` : `signup` sorti de l'assert.
- Les autres fonctions du fichier ne changent que par `extrait`.

**`tests/test_003_admin.py`**
- `test_fichier_secrets_contient_la_cle` : booléen.
- `test_jwt_secret_au_moins_40_caracteres` : longueur calculée d'abord.
- `test_mot_de_passe_admin_genere_20_alphanumeriques` : longueur et alphabet calculés d'abord.
- `test_droits_fichier_0600_et_repertoire_0700` : modes calculés d'abord.
- `test_cle_est_un_jwt_hs256_signe_par_jwt_secret` : segments, algorithme, signature et rôle calculés d'abord. Ids explicites.
- `test_connexion_admin_200`, `test_connexion_admin_mauvais_mot_de_passe_refusee` : messages sans valeur.
- `test_un_seul_administrateur`, `test_seul_admin_email_hors_comptes_de_test` : compteurs et messages.
- `test_deploy_log_sans_secret` : seuls les noms des variables fuitées sortent.

**`tests/test_004_piles.py`**
- `test_persistance_relire` : comparaison d'empreinte et compte admin sortis de l'assert.
- `test_persistance_ecrire` : seulement `extrait`.
- `test_pile_service_repond_avec_ses_propres_secrets` : comparaison de `JWT_SECRET` sortie de l'assert.

**`tests/test_002_modele.py`**
- Aucune assertion ne manipulait de secret. Seuls les `r.text[:200]` ont été remplacés par `extrait(r, 200)`, avec l'import.

**`tests/test_000_socle.py`** : aucune modification.

### Vérifications effectuées
- `ast.parse` sur les six fichiers : syntaxe valide.
- Analyse AST des `assert` : plus aucun appel `login` / `signup` / `connecter` / `jwt_payload` / `empreinte` / `masquer` ni `.text` / `.json()` brut dans un `assert`. Il reste six appels sur des objets `Api` (`u`, `neuf`) qui passent des identifiants, et des `.json()` sur des lignes de tâches ou de comptes, sans secret.
- Aucun `print`, `logging` ou `capsys` dans les tests.
- Noms utilisés tous importés ou définis.
- Listes de fonctions obtenues en comparant l'AST à `HEAD`.

### Limites
- **Non exécuté** : le hook et les nouvelles fonctions n'ont pas été testés en pytest réel. Une passe `./dev test` sera nécessaire à la reprise de la pile, et il faudra vérifier que `junit.xml` ne contient plus de valeur.
- **Hors de mon périmètre** : `iterations/002/tests/junit.xml` et `resultat.txt` contiennent encore les valeurs de l'incident. Il faut les purger. Si ces fichiers ont été commités ou partagés, `ADMIN_PASSWORD` et `JWT_SECRET` doivent être régénérés, et l'historique git vérifié.
- **Observation** : `persistance-<pile>.json` stocke `admin_empreinte`, une empreinte SHA-256 tronquée d'`ADMIN_PASSWORD`. Ce n'est pas un secret en clair, et ce fichier n'entre pas dans `junit.xml`. Je l'ai laissé tel quel.
