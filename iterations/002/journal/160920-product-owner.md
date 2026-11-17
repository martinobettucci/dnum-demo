# product-owner — 2026-11-17T16:09:20+00:00

## Brief
Clôture de l'itération 002, dernière étape. Le chef de projet a tranché les points restants dans iterations/002/cloture.md (nouvelles lignes ; relis-les, lecture seule) : (1) C9 : écart service 3c93a08 / dev 29a3980 ACCEPTÉ temporairement (app/web et migrations identiques ; seuls nginx, build-sha256 et l'outillage diffèrent), résorbé au premier deploy service autorisé ; (2) CA-002-40, sous-cas « compte existant non confirmé » : REPORT nommé en 003 (test du stub GoTrue SPEC-003.11) ; le nominal est prouvé (policy 35, 3 tests, seed réel) ; (3) C11 : coût définitif après iteration-close, en 2 relevés ; E6 : accepté, réconcilié en 003 ; (4) E3 = U1, E4 = table A ligne 2, E7 = C5, E8 = C2 : confirmés ; C13 : configuration conforme sur service, l'absence de restart sur dev est voulue ; (5) S15 et P6 : actions de l'utilisateur, pas des décisions. Dans iterations/002/perimetre.md, section « Acceptation de clôture 002 » : consigne ces décisions (ajoute le report du sous-cas CA-002-40 au backlog 003), vérifie qu'aucun point n'est resté sans décision, puis PRONONCE l'acceptation formelle de clôture de l'itération 002 si c'est le cas, en listant ce qui reste pour l'utilisateur (mise à jour de la pile service avec les correctifs nginx, S15, P6 réservation DHCP) comme actions en attente, non comme conditions de décision ; sinon liste précisément ce qui manque sans prononcer. Tu n'écris que dans iterations/002/perimetre.md. Compte rendu court : verdict et restes.

## Compte rendu
**Verdict : acceptation de clôture 002 non prononcée.** Il reste une décision à prendre.

Les décisions de `cloture.md` sont consignées dans `perimetre.md` (§ D à F), et le report de CA-002-40 est inscrit au backlog 003 comme BL-003-6.

**Ce qui manque**
- **G1, CA-002-36 [T], refus de restauration à niveau de migration différent.** Aucun test ne le couvre : le test de restauration est SKIPPED dans `junit.xml`, et `mise-en-service.md` ne consigne pas le refus. C5 ne le couvre pas. Il faut choisir : (a) exiger la preuve (le RA lance un restore refusé et consigne la sortie brute), ou (b) reporter nommément ce sous-cas au backlog 003. Le PO recommande (a).

**Restes (actions, non conditions)**
- Mise à jour de `service` (nginx, en-têtes, `build-sha256`) avec `backup` puis `deploy` sans reset, sur autorisation de l'utilisateur. Résorbe C9.
- S15 : validation des comptes réels par l'utilisateur.
- P6 : réservation DHCP de `10.77.0.25`.
- C11 : relevé définitif du coût après `iteration-close`, par le sponsor.

Dès que G1 est tranché, je prononce l'acceptation.
