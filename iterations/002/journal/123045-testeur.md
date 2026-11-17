# testeur — 2026-11-17T12:30:45+00:00

## Brief
Itération 002, tour 2, partie 2. La pile DEV est en service (http://10.77.0.25:8080). Lance ./dev test (première passe), puis écris le rapport dans iterations/002/tests/ (matrice SPEC → test → résultat, échecs avec causes probables, écarts). Ne démarre, n'arrête ni ne reconstruis la pile. N'écris aucun secret.

## Compte rendu
Première passe `./dev test` terminée : **183 réussis, 3 ignorés, 0 échec**. Le rapport est dans `iterations/002/tests/rapport-tour2.md` (matrice SPEC → test → résultat complète, écarts, skips). La pile n'a pas été touchée.

**Couverture**
- 87 identifiants de spec. 44 ont au moins un test marqué `@pytest.mark.spec`. Les autres sont vérifiés par policy, recette RA ou recette client, comme prévu par SPEC-006 §2.
- 46 exigences portent `[T]`. 41 sont couvertes ; 5 n'ont pas de marqueur (voir écarts).

**Skips (attendus, aucun ne masque un échec)**
- `test_persistance_relire` (SPEC-003.5, SPEC-004.3) : la passe A vient d'écrire `persistance-dev.json`. La passe B demande un `./dev deploy` sans `reset` entre les deux.
- `test_pile_service_repond…` (SPEC-004.7) et `test_restauration_service…` (SPEC-004.8, Could) : nécessitent `DEVENV_PILE=service`. **SPEC-004.7 et 004.8 ne sont donc pas vérifiées dans cette passe.**

**Écarts à remonter**
- **E1 (principal)** : SPEC-001.14 n'a aucun de ses deux tests `[T]` : `test_inscriptions_en_rafale` et `test_aucune_reponse_429` sont absents de `tests/`. La limite de 220 inscriptions par passe (SPEC-006 §1) n'est donc pas mesurée. Je n'ai pas ajouté ces tests dans cette passe ; je les écrirai au tour suivant.
- E2, E3, E4 : `[T]` sans marqueur pour SPEC-004.13, SPEC-004.2 et SPEC-005.11/005.12. La couverture existe indirectement, mais n'est pas tracée. Décision de l'architecte.
- E5 : `persistance-dev.json` n'est pas ignoré par git (`iterations/` est versionné). Il ne contient ni mot de passe ni secret en clair, seulement une empreinte SHA-256 tronquée de `ADMIN_PASSWORD`. À trancher par le chef de projet.
- E6 : deux tests (SPEC-003.3, 003.6) portent un tag `[P]`/`[R]` et non `[T]` ; ils passent. Pas de risque, à aligner côté spec si besoin.

**Par rapport au tour 1** : les 7 échecs et 173 erreurs de setup sont résolus (publication LAN, front servi, secrets présents). Le rapport du tour 1 reste dans `rapport.md`. `resultat.txt` et `junit.xml` ont été régénérés.

**Suite proposée** : le responsable applicatif fait `./dev deploy` puis `./dev test` pour la passe B, et déploie la pile `service` pour vérifier SPEC-004.7 et 004.8.
