# architecte — 2026-11-17T13:05:13+00:00

## Brief
Itération 002, tour 3 (préparation). Contexte : dnum.lelabs.tech est relayée vers la pile DEV, de vrais utilisateurs s'y inscrivent. GEL : pas de reset, teardown, deploy ni test sur la pile dev ; tout se prépare sans mise en service. Retours de recette client : (1) CA-002-28 : pas de message de confirmation après « Demander de l'aide » ; message « Proposition envoyée » sans nom de tâche ; (2) barre supérieure non fixe ; (3) pas de confirmation sur « Désactiver » ; (4) listes admin sans recherche. Écris uniquement dans specs/ : (a) SPEC-005 : comportement attendu pour chaque retour (textes exacts des messages en français, confirmation avant « Désactiver », barre supérieure fixe, recherche dans les listes admin : champ, filtrage côté client ou RPC, périmètre) ; (b) règle sur les migrations : les données réelles existent, toute migration est additive et non destructive (pas de DROP, pas de recréation de table, pas de TRUNCATE ; ALTER ... ADD, CREATE OR REPLACE FUNCTION/VIEW autorisés), idempotente, nouveau fichier NNN_<sujet>.sql, les migrations 001 à 005 déjà appliquées ne sont pas modifiées ; ADR court si utile ; (c) dis si ces retours nécessitent une migration SQL ou seulement du front. Compte rendu court : décisions, fichiers, points ouverts.

## Compte rendu
Warning: no stdin data received in 3s, proceeding without it. If piping from a slow command, redirect stdin explicitly: < /dev/null to skip, or wait longer.
Les quatre retours se traitent **en front seul** : aucune migration SQL n'est nécessaire. Les specs sont écrites, rien n'a été déployé ni testé, et `app/` n'a pas été touché.

**Décisions (SPEC-005)**
- **Confirmations (retours 1 et 3)** : messages exacts en section « Messages exacts » de SPEC-005 (M-1 à M-6). « Proposition envoyée » devient « Proposition envoyée à {nom} pour la tâche « {titre} ». », avec un équivalent pour « Demande d'aide ». Le message survit au rechargement qui suit l'action. Il est affiché une fois, puis effacé à la navigation suivante.
- **Désactiver (retour 3)** : bloc de confirmation inline (« Confirmer la désactivation » / « Annuler »), focus sur « Annuler ». Pas de `window.confirm`, qui est bloquant. Nouvelle exigence SPEC-005.63.
- **Barre fixe (retour 2)** : `position: sticky; top: 0`, hauteur ≤ 120 px en 1280×800, `scroll-padding-top` pour ne pas masquer le focus, et lien d'évitement au-dessus de la barre (SPEC-005.6).
- **Recherche (retour 4)** : un champ par liste (attente, actifs), filtrage côté client sur les données déjà chargées, insensible à la casse et aux accents, multi-mots, pas de recherche croisée. Pas de RPC. Limite notée : `PGRST_DB_MAX_ROWS=1000` (SPEC-005.62).

**Migrations (SPEC-004.18 + ADR-011)**
- Interdits : `DROP`, `TRUNCATE`, `DELETE`, recréation de table, `ALTER ... TYPE`, `RENAME`.
- Autorisés : ajouts `IF NOT EXISTS`, `CREATE OR REPLACE` de fonctions et vues, contraintes en `NOT VALID` puis `VALIDATE`, politiques dans un bloc `DO` gardé.
- Idempotence exigée. `001` à `005` figés : `db.sh` refuse déjà toute migration modifiée.
- Voie d'exception : ADR amendé, accord écrit du chef de projet, `./dev backup service` préalable. `reset` n'est plus un remède.

**(c) Migration SQL ?** Non. Les RPC `request_help`, `offer_help`, `admin_list_accounts` et `admin_set_active` restent inchangées. Les noms et messages utilisés sont déjà chargés côté front.

**Fichiers**
- Créé : `specs/adr/ADR-011-migrations-additives.md`
- Amendés : `SPEC-004` (004.18), `SPEC-005` (005.1, .5, .33, .40, .60 ; nouvelles 005.6, .7, .62, .63 ; section messages), `SPEC-006` (§2 et §3, policies 29 à 31), `specs/README.md`

**Points ouverts**
1. **Périmètre** : j'ai proposé CA-002-37 (barre), 38 (recherche) et 39 (confirmation de désactivation). Le product owner doit les inscrire, sinon ces specs n'ont pas de CA de référence. J'ai précisé CA-002-27, 28 et 34.
2. **Policies** : 29 (migrations), 30 (textes exacts) et 31 (barre fixe) sont à écrire par `policy`, qui doit vérifier que les numéros sont libres.
3. **Défauts voisins non spécifiés** : « Réaffecter », « Loguer du temps » et « Modifier » n'ont pas non plus de confirmation. C'est votre décision.
4. **Policy 29** : il faut consigner la référence git de comparaison des migrations `001`–`005` dans `mise-en-service.md` au prochain `deploy`.
5. **Mise en service plus tard** : le front doit être redéployé par `./dev deploy`, sans `reset`. La recette client se fera après la levée du gel.
