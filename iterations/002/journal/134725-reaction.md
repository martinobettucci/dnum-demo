# reaction — 2026-11-17T13:47:25+00:00

## Brief
Itération 002, réaction FINALE AOPR. Lecture seule. À partir de iterations/002/journal/134627-observation.md (lis-la en entier, vérifie les faits sur results.json et le Dockerfile), propose la clôture de l'itération 002 de ton point de vue AOPR : ce qui est fermé, ce qui reste ouvert et à quelle équipe il revient, et si une policy de pinage apt doit être ajoutée (proposer le numéro libre et la règle, sans l'écrire). Ne modifie aucun fichier.

## Compte rendu
# Réaction finale AOPR, itération 002

## 0. Vérifications faites

Je n'ai que la lecture (Read, Glob, Grep). Je n'ai donc pas pu recalculer de sha256, lancer git ou relancer une policy. Les faits ci-dessous viennent des fichiers lus.

- **`results.json`** : 31 entrées `respectee`, 0 `violee`, 0 `non_applicable`, daté `13:46:04`. Décompte vérifié : policies 00 à 06, 10 à 17, 20 à 35. Les numéros 07, 08, 09, 18 et 19 sont libres.
- **`tools/runner/Dockerfile`** : ligne 3 épingle `git=1:2.39.5-0+deb12u3`, `curl=7.88.1-10+deb12u15`, `bash=5.2.15-2+b13`. Conforme au journal.
- **Aucune policy ne couvre les `apt-get install` des Dockerfiles.** La policy 00 ne contrôle que les `FROM`. Un grep sur `policies/checks/` ne trouve « apt » que dans 29 et 04, sans rapport.
- **`audit-npm.meta.json`** : `date 13:45:51`, postérieure à l'audit cité dans `mise-en-service.md` L316 (`13:40:30`). Le sha256 du lock est le même dans les deux fichiers.
- **Script 25** : la garde esbuild (`serve|watch|context(` dans les scripts racine) est bien implémentée. Le message de `results.json` indique « build.mjs : aucun serve/watch/context( ». Je n'ai pas relu `build.mjs` lui-même.
- **`mise-en-service.md` L318** : « et un troisième » sans nommer le paquet. Le méta ne mentionne pas `1ab0…`, cette valeur n'existe que dans le journal.

## 1. Ce qui est fermé

| Élément | Preuve | Statut |
|---|---|---|
| Policies automatiques (31/31) | `results.json`, synthèse | Fermé |
| Audit npm : statut, sha256, aucun avis haut ou critique | `audit-npm.meta.json`, script 25 | Fermé |
| Garde esbuild (ancien écart E-e) | Logique du script 25 lue, message « aucun serve/watch/context( » | Fermé |
| Horodatage périmé de l'observation précédente (E-i) | `results.json` 13:46:04 > méta 13:45:51 | Fermé |
| Épinglage des images, des dépendances et des npm | Policies 00, 01, 03, 04 | Fermé |
| Secrets absents du dépôt | Policies 02, 05, 06, 17 | Fermé |
| Versions apt dans le Dockerfile | Dockerfile L3 | Fermé pour le fichier. L'installation effective reste à prouver (voir O2). |

## 2. Ce qui reste ouvert

| Id | Écart | Preuve | Équipe | Action attendue |
|---|---|---|---|---|
| **O1** | Formulaires repliés : défaut toujours listé dans le rapport client, pas de recette postérieure au correctif | `rapport-client.md` L81 | **client** (session f1), **developpeur** si correction nécessaire | Recette clavier et souris sur le build courant. Captures à l'appui. **Bloquant pour la clôture.** |
| **O2** | Bash : installé `b7` lors du contrôle, épinglé `b13`. Pas de log de build dans `iterations/002/` | `134407` L15, Dockerfile L3 | **testeur** (tests/), **action** (build) | Prouver dans l'image runner que `bash` est en `5.2.15-2+b13` (dpkg-query dans un test). **Bloquant pour la clôture**, car l'affirmation « versions épinglées installées » ne repose que sur un journal. |
| **O3** | Compte rendu du développeur vide | `134058` E10, non relu | **developpeur** (session spark-docker-77) | Republier le compte rendu. Non bloquant si O2 est prouvé. |
| **O4** | Doc `mise-en-service.md` : date d'audit périmée (L316), troisième paquet non nommé (L318) | Lignes citées | **responsable-applicatif** (session f1) | Corriger : date `13:45:51`, nommer `@supabase/supabase-js` (low, direct, via auth-js). Non bloquant. |
| **O5** | Pinage apt non contrôlé | Voir section 3 | **policy** (session f70) | Écrire la policy proposée. Peut être reportée à l'itération 003 (voir section 4). |
| **O6** | Référence `dae9044` en dur dans la policy 29, et « modifications non commitées » dans la doc | `results.json` ; `mise-en-service.md` L114 ; policy 29 non relue | **architecte** (ADR-015 §6) | Décider si la référence reste en dur. Non bloquant : la policy est respectée. |

Je n'ai pas pu vérifier `git status`. La liste des fichiers modifiés (journal `134451` L41) reste à confirmer par le chef de projet.

## 3. Pinage apt : proposition de policy (non écrite)

- **Numéro proposé : `07`** (libre, dans la bande ENV 00-06 juste après `06-env-devenv-ignore.sh`). Vérifié : pas de fichier `07-*` dans `policies/checks/`.
- **Fichier** : `policies/checks/07-env-apt-epingle.sh`
- **POLICY** : `ENV-apt-epingle`
- **REF** : `ENV (reproductibilité)`, à compléter par l'architecte (analogie avec ADR-008).
- **QUAND** : `always`
- **Règle** : pour chaque `Dockerfile*` du dépôt (même périmètre que la policy 00, `rglob`), chaque `apt-get install` (ou `apt install`) doit lister des paquets **dont chaque nom porte `=<version>` exacte**. Les options (`-o …`, `-y`, `--no-install-recommends`) et leurs arguments sont ignorés. Un paquet sans `=`, avec `*`, ou sans version est **violée**. Un `apt-get install` sans paquet épinglé est **violée**.
- **Ce qu'elle ne prouve pas** : une version épinglée n'est pas une version installée. Cette preuve relève d'un test d'exécution (`tests/`, testeur), donc de O2.

## 4. Décision de clôture (proposition)

**Clôture conditionnelle, à ne pas prononcer aujourd'hui.** Les 31 policies sont respectées, mais deux éléments bloquent une clôture propre :

1. **O1** : la recette des formulaires repliés n'a pas eu lieu sur le build courant.
2. **O2** : l'installation de bash `b13` n'est pas prouvée dans l'image.

Une fois O1 et O2 traités, je propose la clôture de l'itération 002, avec O3 à O6 reportés en backlog. La policy `07-env-apt-epingle` peut entrer dans l'itération 003 : le Dockerfile est correct aujourd'hui, donc c'est un contrôle préventif et non un correctif d'écart.

## 5. Décisions à remonter (utilisateur ou product owner)

- **Reporter ou non** la policy `07-env-apt-epingle` à l'itération 003 (je recommande le report, le Dockerfile étant déjà conforme).
- **Accepter** une clôture avec la recette client de O1 faite ou reportée à l'itération 003. C'est un arbitrage de périmètre, qui relève du product owner et de l'utilisateur.
- **Décider** si la référence `dae9044` reste codée en dur dans la policy 29 (O6).
