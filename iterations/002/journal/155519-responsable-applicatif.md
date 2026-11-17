# responsable-applicatif — 2026-11-17T15:55:19+00:00

## Brief
Étape DEV SEULEMENT, la pile service est HORS PÉRIMÈTRE (ne la touche pas : ni backup, ni deploy, ni écriture ; lecture de comptages seulement). Le reset de dev reste INTERDIT 7 jours ; pas de teardown. Commande par commande : 1) ./dev build. 2) ./dev deploy dev (sans reset). 3) ./dev policies : 33 respectées attendues, dont 36 et 37, nomme les violées avec cause. 4) Relève le md5 de /app.js servi sur http://10.77.0.25:8080 (attendu 4eb8c08e9af484992a63298ad56423c8) et compare le contenu de /build-sha256.txt (200, text/plain, no-cache) aux md5 et sha256 réels des fichiers servis. 5) Santé des conteneurs de dev, et conteneurs de service inchangés (ids, heures de démarrage). Si une étape échoue ou si l'empreinte de /app.js a changé : STOPPE et rapporte, sans contournement. Aucun secret, e-mail ni nom dans la réponse. Mets à jour iterations/002/mise-en-service.md.

## Compte rendu
