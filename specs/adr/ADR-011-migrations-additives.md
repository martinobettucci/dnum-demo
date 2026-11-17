# ADR-011 — Migrations additives et non destructives sur données réelles

Statut : accepté (itération 002, tour 3, 2026-11-17). Amende SPEC-004.12 (par la nouvelle SPEC-004.18).
Specs touchées : SPEC-004.18 (nouvelle), SPEC-006 §3 (policy n° 29 `DB-migrations-additives`).

## Contexte

- La pile `dev` est relayée vers `dnum.lelabs.tech` : de vrais utilisateurs s'y inscrivent et y saisissent des
  données. Les données réelles existent donc désormais, y compris dans la pile `dev`.
- SPEC-004.12 prévoit, pour une migration modifiée après application, un refus de `db.sh` (vérifié dans
  `tools/deploy/db.sh` : comparaison de la somme sha256 au journal `private.schema_migrations`). Le remède prévu en dev
  est `./dev reset`, qui détruit les données : il est **exclu** tant que la pile sert des utilisateurs réels.
- Le gel de la pile `dev` (pas de `reset`, `teardown`, `deploy`, `test`) interdit aussi de contourner un refus.
- Les migrations 001 à 005 sont appliquées sur la pile `dev` et sur la pile `service`. Toute modification d'un de
  ces fichiers provoque un refus de déploiement, et aucun remède non destructif n'existe pour elle.

## Options étudiées

| Option | Description | Évaluation |
|---|---|---|
| (a) Migrations libres | Tout DDL autorisé ; le développeur répare les données à la main. | Rejetée : risque de perte de données réelles, non vérifiable. |
| (b) Migrations additives seulement | Ajout de colonnes, tables, index, fonctions et vues (`CREATE OR REPLACE`) ; aucun `DROP`, `TRUNCATE`, `DELETE`, renommage ni changement de type ; idempotence exigée. | **Retenue.** Compatible avec le journal, sans `reset`, et vérifiable statiquement. |
| (c) Autoriser `DROP` sous ADR | `DROP` permis au cas par cas. | Écartée comme règle générale ; reste une **voie d'exception** (voir Décision 6). |

## Décision

1. **Interdits** dans tout fichier `app/db/migrations/NNN_<sujet>.sql` : `DROP` (tout objet : table, colonne, vue,
   fonction, politique, trigger, index, contrainte, schéma, rôle), `TRUNCATE`, `DELETE`, recréation de table
   (`DROP` puis `CREATE`, ou `CREATE TABLE` sans `IF NOT EXISTS` sur une table existante), `ALTER ... TYPE`,
   renommage (`RENAME`) de table, colonne ou fonction.
2. **Autorisés** :
   - `CREATE TABLE IF NOT EXISTS` ; `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`, nullable ou avec `DEFAULT` constant
     (jamais `NOT NULL` sans `DEFAULT`) ;
   - contrainte ajoutée en deux temps : `ADD CONSTRAINT ... NOT VALID` puis `VALIDATE CONSTRAINT` ;
   - `CREATE INDEX IF NOT EXISTS` (sans `CONCURRENTLY`, SPEC-004.12) ;
   - `CREATE OR REPLACE FUNCTION` et `CREATE OR REPLACE VIEW`, sous réserve : type de retour et liste de colonnes
     existantes inchangés (les colonnes nouvelles s'ajoutent en fin) ; un changement de signature de retour se fait
     par une fonction de **nouveau nom** ;
   - `CREATE OR REPLACE TRIGGER` ; `GRANT` et `REVOKE` ;
   - création d'une politique RLS uniquement dans un bloc `DO` gardé par `IF NOT EXISTS` sur `pg_policies` ;
   - `UPDATE` uniquement pour remplir une colonne nouvellement ajoutée là où elle est `NULL`, sans écraser de valeur.
3. **Idempotence** : rejouer le fichier sur une base où il a déjà été appliqué ne modifie rien (clauses `IF NOT EXISTS`,
   `OR REPLACE`, garde `DO`). Le journal reste la garantie d'application unique ; l'idempotence est la garantie de
   reprise après incident.
4. **Fichiers existants figés** : `001` à `005` ne sont pas modifiés. Une correction passe par une migration suivante
   (`006_…`, numéro suivant, sujet en `[a-z0-9_]+`).
5. **Conséquence assumée** : un objet devenu inutile n'est pas supprimé, il est **révoqué** (`REVOKE`) et documenté.
   Une fonction de remplacement de signature différente laisse l'ancienne en place, révoquée à `authenticated`.
6. **Voie d'exception** : tout besoin de `DROP` ou de changement non additif exige (a) un amendement de cet ADR
   décrivant l'opération et son effet sur les données, (b) un accord écrit du chef de projet, (c) une sauvegarde
   préalable par `./dev backup service` consignée dans `mise-en-service.md`. En pile `dev` gelée, cette voie est fermée.

## Conséquences

- Aucune migration n'est nécessaire pour les retours de recette du tour 3 (front seul, voir `SPEC-005`). La règle
  s'applique aux migrations suivantes.
- Les erreurs de schéma se corrigent par additions ; le schéma grossit, ce qui est accepté pour une équipe de quelques
  personnes.
- Vérification : [P] `DB-migrations-additives` (policy n° 29, statique : mots-clés interdits dans les fichiers `NNN ≥ 006`,
  `001` à `005` identiques à leur version de référence dans git, clauses d'idempotence présentes) ; [R] deux `./dev deploy`
  successifs sans erreur (SPEC-004.12) ; [R] rejeu d'un fichier nouveau sur une base temporaire jetable, hors pile service.
- Limite connue : la policy 29 ne prouve pas la sémantique d'une migration ; la revue par le `developpeur` et le
  `testeur` reste nécessaire.

## Alternatives écartées

- Verrouiller le schéma par un fichier de sommes versionné (`SHA256SUMS`) : écarté, la référence git suffit et
  n'ajoute pas un artefact à maintenir.
- Accepter `reset` comme remède en dev : écarté, incompatible avec les données réelles de `dev`.
