# responsable-applicatif — 2026-11-17T14:59:55+00:00

## Brief
Lance ./dev policies sur dev (mode dev) et rapporte : nombre respectées/violées, noms des violées avec cause. Aucune écriture sur la pile, aucun deploy, reset ni teardown, service intacte. Aucun secret ni e-mail dans la réponse.

## Compte rendu
**`./dev policies` (mode dev, itération 002) : 32 respectées, 1 violée.**

Violée :
- **FRONT-bundle-servi-egal-source** (ADR-006 §2, SPEC-001.8, CA-002-2, incident de recette de l'itération 002) : `/build-sha256.txt` est absent ou non servi. La route répond 200 avec `Content-Type: text/html`, donc un repli HTML est possible. Les empreintes du build ne sont pas vérifiables. Il faut que `build.mjs` produise ce fichier dans `dist/`.

Résultats détaillés : `iterations/002/policies/results.json`.

Je n'ai effectué aucune écriture sur la pile, ni deploy, teardown ni reset. La pile `service` est intacte. Je n'ai pas écrit de `mise-en-service.md`, car aucune mise en service n'a eu lieu.
