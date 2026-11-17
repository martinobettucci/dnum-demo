# testeur — 2026-11-17T12:39:38+00:00

## Brief
Itération 002, tour 2, partie 4. Écris dans tests/ les tests test_inscriptions_en_rafale et test_aucune_reponse_429 (SPEC-001.14 : débit GoTrue ≥ 500 inscriptions/h, ≤ 220 inscriptions par passe, ADR-006), avec le marqueur @pytest.mark.spec adapté et des comptes @test.invalid. N'EXÉCUTE PAS ./dev test ni ces tests maintenant : la recette client est en cours sur la pile et des inscriptions en rafale polluent la liste « Comptes en attente ». Vérifie seulement la syntaxe (AST) et rapporte les modifications. Ne touche pas à la pile.

## Compte rendu
Les deux tests sont écrits et la syntaxe est valide (AST). Je n'ai ni exécuté `./dev test` ni ces tests, et je n'ai pas touché à la pile : la recette client n'est pas perturbée.

## Modifications (uniquement dans `tests/`)

**`tests/conftest.py`**
- Recueil des 429 : `requests.Session.send` est encapsulé. Chaque réponse de `/auth/v1/*` est ajoutée à `RELEVES_AUTH` (méthode, chemin, statut). Cela couvre aussi les appels directs à `requests.post` des autres fichiers.
- Constante `PLAFOND_INSCRIPTIONS_PAR_PASSE = 220` (SPEC-006 §1).
- `pytest_collection_modifyitems` place `test_aucune_reponse_429` en dernier, pour qu'il voie toute la passe.

**`tests/test_001_pile.py`** (nouvelle section SPEC-001.14, marqueur `@pytest.mark.spec("SPEC-001.14")` sur les deux tests)
- `test_inscriptions_en_rafale` : 20 inscriptions consécutives sur `signup` avec `email_unique()` (`t-<uuid>@test.invalid`), attendu 200/201 avec session immédiate. Le test s'arrête au premier refus. Les comptes sont réactivés via `fabrique.activer` dans un `finally`, pour ne pas rester dans « Comptes en attente ». Il est `skip` sur la pile `service` (SPEC-003.9), comme `Fabrique`.
- `test_aucune_reponse_429` : échoue s'il existe une réponse 429 sur `/auth/v1/*`, avec le détail par chemin. Il échoue aussi si la passe dépasse 220 inscriptions (« saisir l'architecte »).

## Vérification
- `ast.parse` (Python `-I`) : `conftest.py` et `test_001_pile.py` sont valides.
- Les deux fonctions existent avec le bon nom et le bon marqueur.

## Points à noter avant le lancement
1. **Pollution de la pile dev :** la rafale crée 20 comptes, réactivés en fin de test. Ils deviennent donc des membres actifs visibles dans `team_load`, et non des comptes en attente. Si vous préférez les laisser en attente, il faut retirer le bloc `finally`.
2. **Marge de 220 :** la passe actuelle est estimée à environ 184 inscriptions. Avec les 20 de la rafale, on arrive à environ 204, soit une marge d'environ 16. Une passe de persistance supplémentaire pourrait dépasser le plafond : le test l'échouerait, ce qui est voulu.
3. **Ce qui n'est pas couvert :** le débit « ≥ 500 inscriptions/h » ne se mesure pas dans une seule passe. Le test ne vérifie que 20 inscriptions consécutives. Les 2000 connexions/h n'ont pas de test dans ce périmètre.
4. **Rapport :** je n'ai produit aucun rapport `iterations/002/tests/` pour ce tour, car rien n'a été exécuté. Le lancement (`./dev test`) reste à faire par le responsable applicatif ou à la fin de la recette.
