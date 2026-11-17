# responsable-applicatif — 2026-11-17T15:55:19+00:00

## Brief
Étape DEV SEULEMENT, la pile service est HORS PÉRIMÈTRE (ne la touche pas : ni backup, ni deploy, ni écriture ; lecture de comptages seulement). Le reset de dev reste INTERDIT 7 jours ; pas de teardown. Commande par commande : 1) ./dev build. 2) ./dev deploy dev (sans reset). 3) ./dev policies : 33 respectées attendues, dont 36 et 37, nomme les violées avec cause. 4) Relève le md5 de /app.js servi sur http://10.77.0.25:8080 (attendu 4eb8c08e9af484992a63298ad56423c8) et compare le contenu de /build-sha256.txt (200, text/plain, no-cache) aux md5 et sha256 réels des fichiers servis. 5) Santé des conteneurs de dev, et conteneurs de service inchangés (ids, heures de démarrage). Si une étape échoue ou si l'empreinte de /app.js a changé : STOPPE et rapporte, sans contournement. Aucun secret, e-mail ni nom dans la réponse. Mets à jour iterations/002/mise-en-service.md.

## Compte rendu
Séquence DEV terminée, sans incident. Aucune étape n'a échoué et l'empreinte de `/app.js` est celle attendue, donc je n'ai rien arrêté.

Mise en service assurée exclusivement par le responsable applicatif. Aucun autre agent ne démarre, n'arrête ni ne détruit la pile : adressez vos demandes au chef de projet.

**Résultats**

| Étape | Résultat |
|---|---|
| 1. `./dev build` | OK (rc 0, 5,7 s) |
| 2. `./dev deploy dev` (sans reset) | OK (rc 0, 11 s), URL http://10.77.0.25:8080/ |
| 3. `./dev policies` | **33 respectées, 0 violée**. Les contrôles 36 (`front-bundle-servi-egal-source`) et 37 (`gw-cache-et-entetes`) sont respectés |
| 4. Empreinte servie | md5 de `/app.js` = `4eb8c08e9af484992a63298ad56423c8` (attendu). `/build-sha256.txt` : 200, `text/plain`, `no-cache`. Les sha256 réels de `app.js` et `vendor/supabase.js` correspondent à ce fichier |
| 5. Santé et non-intervention | Conteneurs dev : `db`, `auth`, `app` healthy ; `rest`, `client` running. Pile service inchangée (mêmes identifiants et heures de démarrage) |

**Détails**
- **Version** : commit `29a3980`. Le HEAD est passé à `ff6715f` pendant l'exécution, mais ce commit ne modifie ni `app/`, ni `stack/`, ni `web/`, ni `dev`.
- **Conteneurs recréés** : `devenv-app-1` et `devenv-client-1` ont été recréés par le déploiement, ce qui est normal. `devenv-db-1`, `devenv-auth-1` et `devenv-rest-1` n'ont pas bougé.
- **Incidents** : aucun.
- **Compte rendu** : `iterations/002/mise-en-service.md` est complété par une nouvelle section datée. Le contenu existant n'a pas été modifié. Aucun secret, adresse électronique ni nom n'y figure.
