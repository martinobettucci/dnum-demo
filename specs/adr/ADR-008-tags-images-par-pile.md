# ADR-008 — Tags des images construites localement, propres à chaque pile

Statut : accepté (itération 002, tour 1, complément, 2026-11-17). Amende ADR-004 (piles).
Specs touchées : SPEC-004.7, SPEC-004.16 (nouvelle), SPEC-006 §3 (policy 11).

## Contexte

- `stack/compose.yml` (pile `dev`, projet `devenv`) déclare `image: devenv/app:dev`.
- La surcouche `service` (projet `dnum-service`, ADR-004) construit depuis le même contexte `../app`.
- Les deux piles partagent donc le même tag `devenv/app:dev` sur le démon Docker. Une reconstruction de l'une réécrit le
  tag utilisé par l'autre : au prochain `up` de l'autre pile, compose voit une image différente et recrée le conteneur
  (risque R5 du rapport DevOps). Le problème est faible aujourd'hui, mais il touche précisément la pile persistante.

## Décision

1. Chaque image construite localement porte **le tag de sa pile** :
   - pile `dev` (projet `devenv`) : `devenv/<service>:dev` (ex. `devenv/app:dev`, `devenv/runner:dev`, `devenv/client:dev`) ;
   - pile `service` (projet `dnum-service`) : `devenv/app:service`, fixé par la clé `image:` de
     `stack/compose.service.yml` (le `build:` reste celui de la pile de base).
2. Aucune paire `nom:tag` construite localement n'est utilisée par deux piles.
3. Les images de base restent épinglées par tag exact (SPEC-001.2), inchangé.
4. Les images `migrate` et `seed` sont des images de base épinglées : elles ne sont pas concernées.

## Alternatives écartées

- **Même tag, discipline de reconstruction** : fragile, dépend de l'ordre des opérations humaines.
- **Épinglage par digest à chaque build** : juste, mais hors de proportion pour cette boucle ; reste possible plus tard
  (nouvel ADR).

## Conséquences

- `./dev` (action) n'a rien à changer : `./dev deploy service` passe déjà `-f stack/compose.service.yml`.
- `stack/compose.service.yml` (développeur) porte la clé `image: devenv/app:service`.
- La policy (agent `policy`) vérifie l'unicité des `nom:tag` construits entre les deux fichiers compose (SPEC-004.16).
- Après un `deploy` des deux piles, `docker images devenv/app` montre deux tags distincts (`dev`, `service`).
