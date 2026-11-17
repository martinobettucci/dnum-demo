# ADR-015 — git dans l'image du runner (contrôle d'intégrité des migrations)

Statut : accepté (itération 002, 2026-11-17). Décision D-3 de ADR-013.
Amende : ADR-011 (référence de comparaison, § Décision 4 et § Conséquences), SPEC-006 §3 (policy n° 29, item 16 (c)).
Complète : CLAUDE.md §1 (images et dépendances épinglées), ADR-003 (runner monté en lecture seule).

## Contexte

- La policy 29 (`DB-migrations-additives`), contrôle (c), vérifie que `001` à `005` sont identiques à leur version de
  référence dans git. Sans git dans le runner, le contrôle est « non exécuté », donc en échec (`results.json`, policy 29,
  `shutil.which("git")`).
- ADR-011 fixe la référence : « commit de la dernière mise en service consignée dans `mise-en-service.md` ».
- Le runner est `python:3.13.1-slim` (`tools/runner/Dockerfile`). Il ne contient que `curl` et `bash`, installés par apt
  **sans version**.
- Le dépôt est monté en lecture seule dans `/workspace` (ADR-003). Git refuse un dépôt dont le propriétaire diffère de
  l'utilisateur courant (« dubious ownership ») : un `safe.directory` est nécessaire.
- Référence déclarée dans `mise-en-service.md` : commit `dae9044`. La version déployée sur `dev` est `dfbc020` plus un
  arbre de travail non commité. Aucun `service` n'est déployé.

## Options étudiées

| Option | Description | Évaluation |
|---|---|---|
| (a) Empreintes à la place de git | Fichier de sommes versionné (`SHA256SUMS`) pour `001` à `005`. | Rejetée par ADR-011 : la référence git suffit et n'ajoute pas d'artefact. |
| (b) git dans l'image runner | Installation de git par apt, avec version exacte. | **Retenue** (décision D-3). |
| (c) Copie de `001` à `005` dans l'image | Les fichiers sont copiés dans l'image au build. | Rejetée : duplique le dépôt et ne prouve rien sur le commit. |

## Décision

1. **Installation** : git est ajouté dans `tools/runner/Dockerfile`, dans la même instruction apt que `curl` et `bash`.
2. **Version exacte** : la ligne installe `git=<version exacte>`. La version est relevée à la première construction
   (`apt-cache policy git` dans l'image de base) et consignée dans cet ADR, au champ « Version figée » ci-dessous. Un
   `apt-get install git` sans version n'est pas acceptable (CLAUDE.md §1). Les paquets `curl` et `bash`, déjà installés
   sans version, sont épinglés dans la même modification.
3. **Configuration** : `git config --system --add safe.directory /workspace` dans l'image. Aucun fichier git versionné
   du dépôt n'est modifié.
4. **Usage restreint** : la policy 29 (c) n'utilise que `git show <référence>:<chemin>` et compare le sha256 du contenu
   au fichier présent sur disque. Interdits : `git status`, `git diff` et toute commande qui écrit l'index (le dépôt est
   monté en lecture seule).
5. **Référence de l'itération 002** : commit `dae9044` (décision D-3). La comparaison prouve que `001` à `005` n'ont pas
   changé depuis `dae9044`. **Correspondance vérifiée (chef de projet, 2026-11-17)** : `dae9044` existe dans l'historique, et
   les fichiers `001` à `005` sont identiques dans `dfbc020` (version déployée sur `dev`), `dae9044` et `HEAD`. La référence
   est donc pertinente pour la version appliquée sur `dev`. Point ouvert de ADR-013 (n° 4) : clos.
6. **Référence future** : le commit consigné dans `mise-en-service.md` à chaque mise en service (ADR-011). La policy lit
   ce commit ; `dae9044` est la valeur de l'itération 002 uniquement.
6bis. **Référence figée de l'itération 002 (complément du chef de projet, 2026-11-17)** : pour les migrations `001` à `005`,
   `dae9044` est la référence **figée** de l'itération 002. Elle ne change pas, même si `mise-en-service.md` consigne
   ensuite un autre commit pour la même itération. `dfbc020` est **identique** à `dae9044` sur les migrations `001` à `005`
   (vérifié par le chef de projet) : le choix de `dae9044` plutôt que `dfbc020` ne change donc pas le résultat de la
   policy 29 (c). Le contrôle (c) se rejoue par `git show dae9044:app/db/migrations/00N_<sujet>.sql` (N de 1 à 5), sans
   autre commit de référence pour cette itération.
7. **Hôte** : git est déjà requis sur l'hôte (SPEC-004.5). Aucun changement.

## Champ à renseigner par l'action

- Version figée de git (apt) : `<à relever à la première construction>`.
- Image de base : `python:3.13.1-slim` (tag exact, SPEC-001.2).

## Conséquences

- L'image du runner grossit (git et ses dépendances).
- La version de git ne change que par décision explicite : il faut modifier le Dockerfile et ce champ.
- Si `/workspace` ne contient pas `.git`, la policy 29 reste « non exécutée » (jamais « réussie »). Le montage est à
  vérifier par l'action.
- La policy 29 vérifie d'abord que la référence existe (`git cat-file -e <référence>`), commande en lecture seule.

## Vérification

- **[P]** policy 29 `DB-migrations-additives`, contrôle (c) (SPEC-006 §3, item 16) : statut « respectée » attendu après
  installation de git. Sortie consignée : « 001 à 005 identiques à la référence <référence> ».
- **[R]** version apt de git consignée dans cet ADR (champ ci-dessus) et dans le journal de l'action.

## Alternatives écartées

- Monter `.git` avec les droits d'écriture pour éviter `safe.directory` : rejetée, le runner ne doit pas écrire dans le
  dépôt (ADR-003).
- Laisser git sans version : rejetée (épinglage).
