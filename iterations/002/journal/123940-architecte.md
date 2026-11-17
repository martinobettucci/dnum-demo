# architecte — 2026-11-17T12:39:40+00:00

## Brief
Itération 002, tour 2, décision du chef de projet sur ADR-010, voie 1 retenue : le chef de projet a lu l'avis GHSA-8r88-6cj9-9fh5 (CVE-2025-48370, CWE-22, CVSS v4 2,7, affecte auth-js <= 2.69.1, corrigé en 2.70.0). Fonctions visées : uniquement getUserById, deleteUser, updateUserById (auth.admin.*) et listFactors, deleteFactor (MFA) ; faute : userId ou factorId non validés comme UUID, traversée de chemin d'URL. app.js n'appelle que getSession, signInWithPassword, signUp, signOut, et le front n'a pas la clé service_role. Décision : auth-js passe du cas C provisoire au cas A (non applicable, accepté), plus bloquant pour ./dev deploy service, sous condition d'une policy de non-appel FRONT-auth-js-non-appel (numéro 28) qui vérifie l'absence de admin., getUserById, updateUserById, deleteUser, listFactors et deleteFactor dans app/web/src. Écris uniquement dans specs/ : mets à jour ADR-010 (analyse, référence de l'avis, conditions, suppression du blocage), SPEC-001.15, SPEC-006 §3 (policy 28 à ajouter aux 25, 26, 27) et README. Mentionne l'itération 003 (supabase-js avec auth-js >= 2.70.0, esbuild 0.28.x). Compte rendu court.

## Compte rendu
Warning: no stdin data received in 3s, proceeding without it. If piping from a slow command, redirect stdin explicitly: < /dev/null to skip, or wait longer.
Compte rendu architecte, itération 002, tour 2 (décision ADR-010 voie 1)

**Fichiers modifiés (specs uniquement) :**
- `specs/adr/ADR-010-vulnerabilites-npm-front.md` : statut « accepté, tranché ». auth-js passe en cas A. Référence de l'avis, fonctions visées, faute, analyse et conditions sont consignées. Le blocage de `deploy service` est levé sous condition de la policy 28. Historique ajouté.
- `specs/SPEC-001-pile-supabase.md` : SPEC-001.15 (d) amendé (plus de cas C), (e) ajouté (policy 28, pas d'occurrence dans `app/web/src`). (b) passe à cas A pour `GHSA-8r88`. Amendement d'en-tête ajouté.
- `specs/SPEC-006-plan-verification.md` : §3 item 15 = policy **n° 28** `FRONT-auth-js-non-appel` (grep sur `app/web/src`). CA-002-2 renvoie à la policy 28. En-tête mis à jour.
- `specs/README.md` : index SPEC-001, SPEC-006, ADR-010 mis à jour. Section de décision ajoutée. Point ouvert n° 1 du tour 2 clos.

**Vérifications faites :**
- `grep` sur `app/` : aucune occurrence de `.admin.`, `getUserById`, `updateUserById`, `deleteUser`, `listFactors`, `deleteFactor`. Ce constat est statique.
- Le numéro 28 est libre dans `policies/checks/`.

**Points à signaler :**
- L'ADR initial prévoyait un classement **B** pour la voie 1. Vous tranchez en **A**. L'ADR le consigne comme divergence explicite.
- Réserve de portée : la policy 28 ne couvre pas le bundle `vendor/supabase.js`. La preuve C2 (metafile) reste à compléter. Je l'ai mentionnée dans l'ADR et le README.
- J'ai interprété `.admin.` comme `\.admin\.` (accès `auth.admin.*`) pour limiter les faux positifs. Dites-moi si vous voulez la forme littérale.

**Itération 003** (à inscrire au périmètre) : montée de supabase-js vers une version dont auth-js est ≥ 2.70.0 (version exacte à fixer, amendements SPEC-001.8 (b), SPEC-006 §3 item 2, ADR-002, policy 2) et montée d'esbuild vers 0.28.x.

**Reste à faire (action et policy) :** écrire et exécuter la policy 28 avant tout `deploy service`. Si elle échoue, le blocage est rétabli.
