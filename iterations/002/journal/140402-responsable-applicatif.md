# responsable-applicatif — 2026-11-17T14:04:02+00:00

## Brief
Canal privé pour la recette client sur dev. Crée .devenv/private/ en 0700 et .devenv/private/client.brief en 0600 (umask 077) avec exactement : « Identifiant administrateur : <ADMIN_EMAIL de .devenv/secrets/dev.env> », « Mot de passe administrateur : <ADMIN_PASSWORD de .devenv/secrets/dev.env> », « Mot de passe des comptes de recette : <chaîne aléatoire de 14 caractères alphanumériques générée par toi> ». Par un script qui ne montre jamais les valeurs (pas d'echo, pas de set -x). Vérifie seulement les droits et que git ignore le fichier. Ne touche pas à la pile. Réponds : prêt, droits, ignoré par git.

## Compte rendu
Prêt.

- **Droits :** `.devenv/private/` en 0700 et `.devenv/private/client.brief` en 0600. Le fichier contient les 3 lignes demandées, la longueur du mot de passe de recette est vérifiée à 14 caractères alphanumériques.
- **Ignoré par git :** oui, via `.gitignore:1` (règle `.devenv/`).

Les valeurs n'ont été affichées nulle part. La pile n'a pas été touchée.
