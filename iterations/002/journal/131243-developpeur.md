# developpeur — 2026-11-17T13:12:43+00:00

## Brief
Itération 002, tour 3 (préparation, GEL : dnum.lelabs.tech sert de production de fait via la pile dev, aucun reset, teardown, deploy ni test, aucun conteneur en marche touché). Deux correctifs dans stack/ et app/web/ uniquement, à mettre en service plus tard : (1) GoTrue signale GOTRUE_JWT_ADMIN_GROUP_NAME et GOTRUE_JWT_DEFAULT_GROUP_NAME comme dépréciées : lis la documentation de l'image GoTrue épinglée en lecture seule (variables d'environnement du service, pas de docker run) et retire ou remplace ces variables dans stack/compose.yml si c'est sans effet sur le comportement (RLS, claims, rôle JWT) ; si le risque n'est pas nul, ne change rien et dis-le ; (2) retour de recette : « formulaires repliés qui décalent les boutons » : corrige la mise en page dans app/web/style.css et app/web/src/app.js (les boutons ne doivent pas bouger quand on plie ou déplie un formulaire), conformément à SPEC-005. Aucune migration SQL. Vérifie avec ./dev build puis ./dev policies, une commande par appel. Compte rendu court : fichiers modifiés, risques, résultats.

## Compte rendu
Warning: no stdin data received in 3s, proceeding without it. If piping from a slow command, redirect stdin explicitly: < /dev/null to skip, or wait longer.
## Compte rendu développeur, itération 002, tour 3 (préparation, gel respecté)

Aucune commande de mise en service n'a été lancée. Je n'ai touché ni à la pile, ni aux conteneurs, ni aux migrations. `./dev build` a seulement reconstruit les images.

### (1) GoTrue : `compose.yml` inchangé

J'ai lu le code source du tag épinglé `supabase/auth` v2.170.0 (archive lue en lecture seule, sans exécution) :

- **`GOTRUE_JWT_DEFAULT_GROUP_NAME: authenticated`** : **à conserver**. Cette variable n'a pas de valeur par défaut. Elle fixe la colonne `role` de chaque nouveau compte (`signup.go:373`), qui devient le claim `role` du JWT (`token.go:340`). La retirer donnerait un rôle vide, donc un accès refusé par RLS et PostgREST pour tous les comptes. Il n'existe pas d'équivalent non déprécié dans cette version. Un remplacement passerait par un trigger SQL, hors périmètre de cette itération.
- **`GOTRUE_JWT_ADMIN_GROUP_NAME`** : elle n'est pas dans le dépôt. Son avertissement vient de la valeur par défaut `admin` appliquée à chaque démarrage (`ApplyDefaults`), donc il apparaît quoi qu'il arrive. Aucune modification n'y change quoi que ce soit.

Le dépréciation signalée ne peut donc pas être supprimée sans risque. Le message reste visible dans les logs, sans effet fonctionnel.

### (2) Formulaires repliés : correctif front

- **`app/web/style.css`** : les formulaires `details.depliable` sortent du flux et se superposent sous leur résumé (fond, bordure, ombre). Le résumé et les boutons ne bougent plus.
- **`app/web/src/app.js`** : les cinq `details` de « Mes tâches » (« Nouvelle tâche », « Modifier », « Loguer du temps », « Réaffecter », « Demander de l'aide ») reçoivent la classe `depliable`. Un gestionnaire `toggle` ne laisse ouvert qu'un formulaire à la fois, pour éviter les superpositions empilées.

Aucune migration SQL.

### Fichiers modifiés (par moi)

- `app/web/src/app.js`
- `app/web/style.css`

Le dépôt contient aussi des modifications d'autres agents (journaux, `specs/`, `iterations/002/policies/results.json`), que je n'ai pas touchées.

### Specs couvertes

Aucune sous-clause de SPEC-005 ne décrit explicitement la stabilité des boutons. Le retour est rattaché à SPEC-005.2 (interaction clavier et souris) et SPEC-005.3 (sobriété). Je demande à l'architecte d'ajouter une sous-clause explicite.

### Résultats

- `./dev build` : **vert**. Le build front (esbuild) passe, ce qui valide la syntaxe de `app.js`.
- `./dev policies` : **17 respectées, 3 violées**, toutes hors de mon périmètre :
  - `ENV-images-epinglees` : violée déjà dans le résultat commité. `stack/compose.service.yml` utilise `devenv/app:service`, tag construit prévu par ADR-008, que le contrôle ne reconnaît pas.
  - `STACK-ports` : violée déjà dans le résultat commité. Le contrôle exige la publication sur `127.0.0.1`, que la dérogation D1 retire. Le contrôle est à réaligner par `policy`.
  - `ENV-secrets-valeurs-absentes` : **nouvelle**. `iterations/002/tests/junit.xml` contient la valeur de `ADMIN_PASSWORD` et de `JWT_SECRET`. Le fichier est ignoré par git, mais il reste sur disque. Le `testeur` doit cesser d'écrire ces valeurs dans sa sortie.

### Risques et points ouverts

- **Non vérifié visuellement** : le correctif n'est pas recetté dans un navigateur. La pile dev est gelée, et le rendu ne sera vérifié qu'après mise en service par le `responsable-applicatif`.
- **Superposition** : un formulaire ouvert masque temporairement les lignes qui suivent. Les boutons ne bougent pas, mais ils peuvent être recouverts jusqu'à la fermeture du formulaire.
- **GoTrue** : l'avertissement de dépréciation reste dans les logs. Son retrait demanderait une migration (trigger de rôle), donc une décision du chef de projet et de l'architecte.
