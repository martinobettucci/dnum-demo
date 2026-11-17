# responsable-applicatif — 2026-11-17T13:55:58+00:00

## Brief
SIGNAL du chef de projet : le proxy a basculé, dev n'est plus en production (service :8081 l'est). Plan de fin d'itération, étapes a et b. a) Sauvegarde finale de dev (./dev backup dev) ; compare les comptes réels (hors @test.invalid) et leurs tâches, temps et propositions entre dev et service ; migre vers SERVICE uniquement le delta créé sur dev après la sauvegarde de 13:33 (comptes réels et leurs données), sans doublon, sans toucher aux données déjà présentes dans service, avec un contrôle préalable qui annule la transaction si un compte existant de service serait modifié. Si le delta est nul, dis-le. Comptages en nombres seulement, avant et après. b) ./dev deploy dev SANS reset (le reset de dev reste INTERDIT 7 jours ; pas de teardown) pour servir le dernier code ; vérifie santé et 10.77.0.25:8080, et que service n'a pas bougé (conteneurs, volumes, comptes). Aucun secret, e-mail ni nom dans le compte rendu ni dans un fichier suivi par git. En cas d'échec : stoppe, donne l'incident avec les logs sans contournement. Mets à jour iterations/002/mise-en-service.md.

## Compte rendu
Mise en service assurée exclusivement par le responsable applicatif. Aucun autre agent ne démarre, n'arrête ni ne détruit la pile : adressez vos demandes au chef de projet.

## Compte rendu : fin de bascule (itération 002, tour 4)

**Résultat : succès.** Le delta à migrer vers service est **nul**. Aucune écriture n'a eu lieu sur service, et dev est redéployé et sain.

### a) Sauvegarde finale de dev et comparaison
- `./dev backup dev` : rc 0, dump `20261117-135659`.
- Le contenu des données de dev est identique entre le dump de 13:33 et celui de 13:57. Il n'y a donc eu aucune création ni modification sur dev depuis 13:33.
- Comptes réels et leurs données, dev et service : mêmes identifiants et même contenu, 0 écart dans les deux sens.
- Comptages avant (nombres seulement) :

| Élément | dev | service |
|---|---|---|
| Comptes | 393 | 8 |
| Comptes réels | 8 | 8 |
| Comptes de test | 385 | 0 |
| Tâches | 176 | 3 |
| Temps | 37 | 1 |
| Propositions | 48 | 1 |

- Aucune transaction de migration n'a été ouverte, le delta étant nul. Les 385 comptes de test de dev ne sont pas migrés, conformément au périmètre.
- Comptages après : service inchangé (8 / 8 / 3 / 1 / 1). L'empreinte des données réelles de service est identique avant et après.

### b) Redéploiement de dev
- `./dev deploy dev`, sans reset ni teardown : rc 0, 10 s. Les migrations et le compte administrateur existants ont été conservés.
- Santé : `app`, `db` et `auth` healthy, `rest` et `client` up.
- HTTP : `http://10.77.0.25:8080/` → 200 ; `http://10.77.0.25:8081/` → 200.
- Service : mêmes conteneurs (identifiants, images, statut), volume `dnum-service_db-data` présent et inchangé.
- Version : dev au commit `899ee3e`. Service reste au commit `3c93a08`, non redéployé.

### Incidents
Aucun. Aucun contournement.

### Confidentialité
Aucun secret, e-mail ni nom dans le compte rendu ni dans un fichier suivi par git. Les comptages de travail sont dans `.devenv/delta/`, ignoré par git. `iterations/002/mise-en-service.md` est mis à jour avec une section « tour 4 », non commitée. Dis-moi si tu veux un commit de ce fichier.
