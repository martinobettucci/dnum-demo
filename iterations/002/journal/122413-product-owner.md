# product-owner — 2026-11-17T12:24:13+00:00

## Brief
Itération 002, tour 2. (1) Confirme les critères [R] de vérification sur l'hôte (ss -ltn, docker compose ls, curl LAN) : liste-les, dis pourquoi ils ne peuvent pas être [C] ou [T], et consigne la règle dans perimetre.md. (2) Prépare la liste de recette client : les critères [C] en langage utilisateur, pas à pas, clavier/souris, à destination de la Team DevOps (agent client), dans iterations/002/recette-client.md. US-14 et US-17 restent en MUST (décision utilisateur via le chef de projet). Tu n'écris que dans iterations/002/perimetre.md et iterations/002/recette-client.md. Compte rendu : décisions, points ouverts.

## Compte rendu
Compte rendu du tour 2 au chef de projet. Je n'ai écrit que dans `perimetre.md` et `recette-client.md`.

## Décisions

- **Règle [R] consignée** dans `perimetre.md` (§2.3). Trois critères sont [R] : CA-002-1 (`curl` LAN, `ss -ltn`, sortie de `./dev`), CA-002-33 (redéploiement sans `reset`) et CA-002-36 (`docker compose ls` / `docker volume ls` avant et après, `curl` sur :8081, refus du `reset service` sans confirmation).
- **Pourquoi pas [C] ni [T]** : le client n'a que clavier et souris et ne voit que ses captures. Le runner est dans le réseau de la pile et ne doit pas joindre `10.77.0.25` (ADR-007 §4). `ss` et `docker` interrogent l'hôte, hors de portée d'un conteneur de test. `deploy`, `reset` et `backup`/`restore` sont réservés au responsable applicatif (SPEC-004.6).
- **Règle** : un [R] est exécuté par le responsable applicatif seul, après le deploy, et consigné dans `mise-en-service.md`. Un [R] non exécuté est « non confirmé », jamais « réussi », et bloque la clôture.
- **D7 : CA-002-33 passe de [T] à [T] + [R]**. Le redéploiement ne peut pas être lancé par un test. Cela aligne le périmètre sur SPEC-006 §2.
- **D6 : US-14 et US-17 restent MUST**, confirmé.
- **Recette client** (`recette-client.md`) : 19 étapes, clavier et souris, dans l'ordre imposé par les dépendances entre comptes. Elle couvre les 24 critères [C] (CA-002-34 et 35 sont conditionnels : Could). Les valeurs de charge attendues sont données à chaque étape, par exemple 3 h, 8 h puis 3 h, 5 h, 7 h.

## Points ouverts

1. **Les [R] n'ont pas été confirmés.** Cette session n'a pas d'outil shell : je n'ai pas pu lancer `ss -ltn`, `docker compose ls` ni `curl`. La dernière observation consignée (tour 1, `mise-en-service.md`) est périmée : pile dev publiée sur `127.0.0.1:8080` seule, `10.77.0.25` non publié. Il faut un `deploy` puis les relevés par le responsable applicatif, ou me donner un accès shell.
2. **Recette bloquée tant que le deploy n'est pas vert.** Au dernier relevé, `policies/results.json` montre 9 violations (gateway, CSP, front, ports, secrets absents). Les tests de `tests/resultat.txt` échouent tous faute de `.devenv/secrets/dev.env`. Le bloc « services » du tour 1 (db, auth, rest, migrate absents) est-il corrigé ? À confirmer avant d'appeler le client.
3. **Adresse de recette** : la recette suppose `http://app` (réseau de la pile, comme `tools/client/driver.py`). Confirmez-le, ou donnez l'URL à utiliser.
4. **Comptes de recette `@test.invalid`** (`recette-1..4-<N>`) : le numéro de passe `<N>` doit être fourni par vous à chaque passe pour éviter les doublons. Confirmez que c'est acceptable.
5. **Divergence CA-002-9** : SPEC-006 §2 prévoit une vérification [C] (`#/admin` inaccessible pour un membre), le périmètre la marque [T] seule. Je ne l'ai pas ajoutée à la recette. La recette vérifie déjà l'absence de l'entrée « Administration » (étape 6). Trancher si vous voulez l'accès direct en plus.
6. **CA-002-1 (c)** (absence de `127.0.0.1` dans la sortie de `./dev`) est statique et pourrait passer en [P]. Votre décision.
7. **Concordance des identifiants admin** : les identifiants sont fournis à l'exécution et ne sont écrits dans aucun fichier. Ils ne doivent pas non plus figurer dans les captures ou les comptes rendus.
