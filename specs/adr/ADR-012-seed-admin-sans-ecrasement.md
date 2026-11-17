# ADR-012 — Seed admin sans écrasement : la base fait foi après création

Statut : accepté (itération 002, tour 3, préparation du gel de la pile `dev`, 2026-11-17).
Amende ADR-003 (décision « seed » et « source de vérité du mot de passe admin »), SPEC-003.5, SPEC-004.8, SPEC-004.13.
Specs touchées : SPEC-003 (003.5 amendé ; 003.10 à 003.12 nouvelles), SPEC-004 (004.8 et 004.13 amendés).

## Contexte

- Relevé DevOps : `tools/deploy/seed.py` appelle `PUT /admin/users/{id}` avec `ADMIN_PASSWORD` à **chaque** `./dev deploy`.
  Le mot de passe admin est donc réécrit à chaque déploiement, y compris sur un redéploiement sans `reset` avec données réelles.
- La pile `dev` sert de vrais utilisateurs (ADR-011). Un administrateur qui change son mot de passe le perd au déploiement
  suivant. Le contrat de SPEC-003.5 (« mot de passe = `ADMIN_PASSWORD` du fichier, inchangé ») et SPEC-004.3
  (« `ADMIN_PASSWORD` n'est pas régénéré ») ne sont pas tenus par l'implémentation actuelle.
- ADR-003 posait « le fichier de secrets est la source de vérité du mot de passe admin » et acceptait l'écrasement
  (« comportement voulu tant qu'il n'y a pas de gestion de mot de passe »). Cette hypothèse ne tient plus : des
  utilisateurs réels existent et l'administrateur peut légitimement changer son mot de passe.

## Options étudiées

| Option | Description | Évaluation |
|---|---|---|
| (a) Statu quo | Le seed réécrit le mot de passe à chaque déploiement. | Rejetée : perte de mots de passe réels à chaque `deploy`, contraire à SPEC-004.3. |
| (b) Création seule | Le seed crée `ADMIN_EMAIL` s'il est absent, ne touche jamais à un compte existant ; `ADMIN_PASSWORD` sert au seul premier amorçage. | **Retenue.** Idempotent, aucune écriture sur un compte existant, base = source de vérité après création. |
| (c) Synchronisation fichier → base avec garde | Le seed compare le mot de passe et ne réécrit que si le fichier a été modifié par l'opérateur. | Écartée : impossible de distinguer « fichier modifié » de « mot de passe changé dans l'appli » sans état supplémentaire persistant, lequel n'existe pas. |
| (d) Base → fichier | Le seed relit le mot de passe courant et le réécrit dans `.devenv/secrets/<pile>.env`. | Écartée : impossible (le mot de passe est un hash en base, non réversible), et le seed ne doit pas écrire dans les secrets. |

## Décision

1. **Création seule.** `seed.py` ne crée le compte `ADMIN_EMAIL` que s'il est absent (`POST /admin/users`, e-mail confirmé,
   `ADMIN_PASSWORD`). S'il existe, il n'émet **aucune écriture** sur `auth.users` : ni `PUT`/`PATCH`/`DELETE` sur
   `/admin/users/{id}`, ni changement de mot de passe, d'e-mail ou de confirmation (SPEC-003.10).
2. **Refus explicite** si le compte existe sans e-mail confirmé : rc≠0, message sans secret, aucune modification (SPEC-003.11).
   Le compte est corrigé à la main par le responsable applicatif ; le seed ne répare pas.
3. **Rôle de `ADMIN_PASSWORD`** : mot de passe **initial**, utilisé à la création d'un compte absent (premier `deploy`
   après `reset`, premier `deploy` d'une pile neuve, restauration sur base vide sans compte admin).
   Il n'est plus la valeur de référence après création. La base fait foi (SPEC-003.12).
4. **Promotion inchangée dans son principe, rendue idempotente vérifiée.** `db.sh promote-admin` met `role='admin'` et
   `is_active=true` sur le profil de `ADMIN_EMAIL`. Relancée sur un admin déjà promu, elle met à jour exactement une ligne
   (rc=0). Ce point est testé (SPEC-003.5).
5. **Le seed ne lit ni n'écrit le fichier de secrets** au-delà de la lecture des variables de l'environnement du service.
   `gen_secrets.py` continue de ne générer que les valeurs absentes (SPEC-003.1, inchangé).
6. **Pas de changement de mot de passe admin** dans cette itération (aucune fonctionnalité d'interface ni d'outil).
   Le mot de passe admin ne peut donc changer que si un utilisateur le fait par un canal existant, ce qui est
   aujourd'hui sans objet ; le principe reste valable quand cette fonctionnalité existera.

## Conséquences

- **Fichier et base divergent après changement de mot de passe.** C'est voulu. `ADMIN_PASSWORD` dans le fichier ne prouve
  plus le mot de passe courant. Le responsable applicatif ne doit pas « resynchroniser » le fichier vers la base ni
  l'inverse. Le mot de passe courant est connu du seul administrateur (et du chef de projet s'il le communique).
- **`./dev reset`** détruit la base, donc les comptes et leurs mots de passe modifiés. Après `reset` + `deploy`, l'admin
  revient au mot de passe du fichier. C'est la définition même de `reset` (pile jetable) ; sur `dev` gelée, il reste exclu
  (ADR-011).
- **`./dev restore`** restitue `auth.users` depuis le dump, donc le hash du mot de passe au moment de la sauvegarde.
  Le seed rejoué ensuite ne change rien. SPEC-004.8 est amendée en conséquence.
- **Ordre de déploiement** : le seed amendé doit être déployé alors que la base contient encore le mot de passe du fichier
  (état actuel, après le dernier `deploy` : le relevé ne prouve pas qu'un utilisateur l'a changé). Tout changement
  intervenu depuis le dernier `deploy` a été écrasé par celui-ci ; le chef de projet doit le savoir avant la levée du gel.
- **Aucun changement de `./dev`** : la séquence de SPEC-004.15 et les variables exportées restent identiques. Le
  changement porte sur `tools/deploy/seed.py` seul (et sur les tests). Responsable : agent `action` (contrat SPEC-004,
  « Côté outillage »).
- **Vérification** : tests dans `tests/test_003_admin.py` (SPEC-003.5, 003.10, 003.11) ; policy à écrire par `policy`
  (SPEC-006 §3) : `seed.py` ne contient aucun appel `PUT`/`PATCH`/`DELETE` vers `/admin/users` hors branche de création.
  Les tests de 003.10 et 003.11 passent par un stub GoTrue local (`GOTRUE_URL`) et `seed.py` lancé directement : aucun
  `deploy`, `reset` ni pile requis, compatible avec le gel de `dev`.
- **Point à vérifier : champ de confirmation GoTrue v2.170.0.** `seed.py` teste `email_confirmed_at`, avec repli sur
  `confirmed_at` (ligne « compte existant, e-mail non confirmé »). Il faut que GoTrue v2.170.0 renvoie `email_confirmed_at`
  dans `GET /admin/users`. Le stub de test reproduit ce champ et teste le repli séparément. **Vérification : première réponse
  réelle de `GET /admin/users`** (recette `[R]`, responsable applicatif, premier déploiement hors gel). Si le champ réel
  diffère, corriger `seed.py` et le stub ensemble. Un compte confirmé dont aucun des deux champs n'est présent fait échouer
  le seed (rc≠0), ce qui est le sens sûr.

## Alternatives écartées

- Garder l'écrasement et prévenir les administrateurs de ne pas changer leur mot de passe : écarté, aucune garantie
  technique, et contraire à SPEC-004.3.
- Stocker l'état « mot de passe changé » dans un fichier ou une table dédiée : écarté, ajoute un état persistant à gérer
  pour un besoin qui se résout par la seule création conditionnelle.
