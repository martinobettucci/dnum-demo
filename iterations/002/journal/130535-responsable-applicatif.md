# responsable-applicatif — 2026-11-17T13:05:35+00:00

## Brief
GEL de la pile DEV (décision du chef de projet) : elle est en production de fait via un proxy sur 10.77.0.25:8080. INTERDIT : ./dev reset, teardown, tout redeploy qui recrée la base ou régénère les secrets, ./dev test, recette, suppression ou activation de comptes. Ta mission : PRÉPARER SANS EXÉCUTER le plan de bascule, dans iterations/002/mise-en-service.md (nouvelle section « Plan de bascule dev vers service ») : déployer la pile service sur :8081 (après les policies 25 à 28 de la Team AOPR), migrer les comptes réels de dev vers service (méthode, ordre, vérifications, risques de perte de mots de passe/hash, fenêtre de coupure), bascule du proxy de 8080 vers 8081 par l'utilisateur, puis dev redevient jetable. Inclus sauvegarde préalable de dev (backup), points de contrôle [R] CA-002-1, 33, 36, retour arrière, et les décisions à prendre par l'utilisateur. Lecture seule sur la pile : aucune commande qui modifie un conteneur, un volume, la base ou les secrets. Ne déploie rien. N'affiche aucun secret ni e-mail réel.

## Compte rendu
Mise en service assurée exclusivement par le responsable applicatif. Aucun autre agent ne démarre, n'arrête ni ne détruit la pile : adressez vos demandes au chef de projet.

**Plan de bascule préparé dans `iterations/002/mise-en-service.md`, section « Plan de bascule dev vers service ». Statut : préparé, non exécuté.** Je n'ai lancé aucun `deploy`, `teardown`, `reset`, `backup`, `restore`, `test` ni recette. Je n'ai fait que des lectures (`docker ps`, `docker compose ls`, `docker volume ls`, `ss -ltn`, lecture des specs, policies et scripts). Aucun secret ni e-mail n'apparaît dans le document. Je n'ai pas pu utiliser l'outil d'édition, j'ai donc ajouté la section en fin de fichier.

**Constats qui bloquent le déploiement de `service` :**
- **Policies 25 à 28 absentes.** `policies/checks/` ne contient que 00 à 24. La Team AOPR doit les écrire et les faire passer.
- **Policy 00 en échec, faux positif.** `devenv/app:service` est signalé comme image non épinglée alors que ADR-008 autorise le tag local par pile.
- **Policy 21 obsolète.** Elle vérifie encore `127.0.0.1`, alors que ADR-007 impose la publication unique sur `${APP_LAN_IP}`.
- **`dev` ligne 115 imprime encore `http://127.0.0.1:…`.** Cela contredit SPEC-004.17 et CA-002-1 [P].
- **Pas de commit.** `perimetre.md`, `recette-client.md` et `junit.xml` sont modifiés non commités.
- **Adresse LAN `10.77.0.25` en DHCP.** Une réservation est nécessaire avant la bascule (ADR-007, risque R3).

**Points à retenir du plan :**
- La méthode reprend `./dev backup dev` puis `./dev restore service <dump>` (SPEC-004.8). Les condensats bcrypt sont copiés tels quels, car les deux piles utilisent la même image GoTrue `v2.170.0`.
- **Le seed réécrit le mot de passe admin à chaque `deploy`,** donc le condensat de l'admin change à chaque déploiement. Le contrôle CA-002-33 ne compare donc pas cette ligne et vérifie la connexion admin à la place.
- **Risque principal : écriture sur dev après la sauvegarde finale.** L'accès direct `10.77.0.25:8080` doit être bloqué pendant la fenêtre, en plus de la page de maintenance au proxy.
- Les points de contrôle [R] sont CA-002-1 (a, b), CA-002-33 (deux `deploy` horodatés, condensats identiques) et CA-002-36 (a, b, c). La partie « après reset » de CA-002-1 ne peut pas être jouée, car `reset` est interdit. Un écart doit être déclaré et validé par le product-owner.
- Le retour arrière est prévu en quatre niveaux (R0 à R3), avec une règle : aucun `reset` de dev avant la fin de la période de retour.

**Décisions à prendre par l'utilisateur (D1 à D8) :**
- **D1** : date et durée de la fenêtre de coupure.
- **D2** : méthode de gel de dev (page de maintenance et blocage LAN recommandés).
- **D3** : reprise des clés et du mot de passe admin de dev vers service (recommandé, les sessions et le mot de passe admin sont conservés), ou régénération (tous les membres doivent se reconnecter).
- **D4** : durée de conservation de dev après bascule (7 jours proposés).
- **D5** : copie de la sauvegarde hors de l'hôte. Aujourd'hui les données ne vivent que sur `10.77.0.25`.
- **D6** : accès direct à dev après bascule.
- **D7** : message aux utilisateurs pendant la fenêtre.
- **D8** : validation de la bascule par l'utilisateur sur ses comptes réels, les agents n'en utilisant pas.

**Ordre proposé :** lever les prérequis P1 à P7, puis répétition (`backup dev`, `deploy service` à blanc), puis fenêtre de coupure. L'utilisateur bascule le proxy de 8080 vers 8081.

Je n'ai pas agi sur la pile. Aucun compte n'a été touché et aucune donnée n'a été lue au-delà des comptages prévus par le plan. Le message d'exclusivité ci-dessus est à diffuser tel quel.
