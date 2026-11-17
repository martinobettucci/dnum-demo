# responsable-applicatif — 2026-11-17T14:59:39+00:00

## Brief
Canal privé pour la recette client passe 3 sur dev. Crée .devenv/private/ en 0700 et .devenv/private/client.brief en 0600 (umask 077) avec exactement : « Identifiant administrateur : <ADMIN_EMAIL de .devenv/secrets/dev.env> », « Mot de passe administrateur : <ADMIN_PASSWORD de .devenv/secrets/dev.env> », « Mot de passe des comptes de recette : <chaîne aléatoire de 14 caractères alphanumériques générée par toi> ». Par un script qui ne montre jamais les valeurs. Vérifie seulement les droits et que git ignore le fichier. Ne touche pas à la pile. Réponds : prêt, droits, ignoré par git.

## Compte rendu
Prêt.

Droits : `.devenv/private/` en 0700, `client.brief` en 0600. Le fichier contient 3 lignes.

Ignoré par git : oui, via la règle `.devenv/` de `.gitignore`.

La pile n'a pas été touchée, et les valeurs n'ont été affichées nulle part.
