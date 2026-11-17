# SPEC-000 — Socle de l'environnement
- **SPEC-000.1** — Une fois mise en service, l'application répond `200` sur `/`. Vérif. : `tests/test_000_socle.py`, policy `APP-repond`.
- **SPEC-000.2** — L'environnement se reconstruit depuis le dépôt seul (`./dev bootstrap`), images et dépendances épinglées. Vérif. : policies `ENV-*`.
- **SPEC-000.3** — La pile est jetable : `./dev reset` puis `./dev deploy` redonne un état fonctionnel. Vérif. : recette du responsable applicatif.
